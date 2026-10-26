"! <p class="shorttext synchronized">EEE - AMC-backed runtime channel for test broker (PoC)</p>
"! Sends events to the broker daemon via send_message / ZCL_BROKER_DAEMON_MESSAGE.
"! Acks are delivered back by the broker daemon calling acknowledge_events( ).
CLASS zcl_amc_channel DEFINITION
  PUBLIC
  INHERITING FROM /iwxbe/cl_runtime_channel
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES:
      /iwxbe/if_rt_channel_publish,
      zif_amc_client_handler.
    METHODS:
      constructor
        IMPORTING
          !io_channel TYPE REF TO /iwxbe/if_channel,
      /iwxbe/if_runtime_channel~check_connection REDEFINITION,
      /iwxbe/if_runtime_channel~subscribe        REDEFINITION,
      /iwxbe/if_runtime_channel~unsubscribe      REDEFINITION.

  PROTECTED SECTION.
    METHODS:
      send REDEFINITION.

  PRIVATE SECTION.
    DATA:
      mo_amc_client TYPE REF TO zif_amc_client.

      METHODS:
        get_amc_client
          RETURNING VALUE(ro_amc_client) TYPE REF TO zif_amc_client.

ENDCLASS.



CLASS zcl_amc_channel IMPLEMENTATION.

  METHOD constructor.
    super->constructor( io_channel ).
    TRY.
       mo_amc_client = get_amc_client( ).
      CATCH cx_amc_error.
    ENDTRY.
  ENDMETHOD.

  METHOD get_amc_client.
    IF mo_amc_client IS NOT BOUND.
        mo_amc_client = NEW zcl_amc_client(
            iv_application_id  = 'ZAMC_BROKER'
            iv_send_channel_id = '/broker_in'
            iv_recv_channel_id = '/broker_out'
            io_handler         = me ).
    ENDIF.

    RETURN mo_amc_client.
  ENDMETHOD.

  METHOD /iwxbe/if_rt_channel_publish~get_event_batch_size.
    return 1000.
  ENDMETHOD.

  METHOD /iwxbe/if_rt_channel_publish~has_capacity.
    RETURN abap_true.

  ENDMETHOD.

  METHOD /iwxbe/if_runtime_channel~check_connection ##needed.
  ENDMETHOD.


  METHOD /iwxbe/if_runtime_channel~subscribe ##needed.
  ENDMETHOD.


  METHOD /iwxbe/if_runtime_channel~unsubscribe ##needed.
  ENDMETHOD.


  METHOD send.

    DATA(lo_msg) = zcl_broker_daemon_message=>create_event_msg(
        is_event  = is_event
        iv_broker = mo_channel->get_name( )
        iv_topic  = is_event-topic ).
    TRY.
        get_amc_client( )->send( lo_msg ).
        rs_send_result-action = success.
      CATCH cx_amc_error /iwxbe/cx_exception.
        rs_send_result-action = retry.
    ENDTRY.

  ENDMETHOD.


  METHOD zif_amc_client_handler~on_connect.
    " no-op in v1
  ENDMETHOD.


  METHOD zif_amc_client_handler~on_disconnect.
    mo_daemon->soft_restart( ).
  ENDMETHOD.


  METHOD zif_amc_client_handler~on_message.
    DATA(lv_broker) = CAST zcl_broker_daemon_message( io_message )->get_broker( ).
    CHECK lv_broker = mo_channel->get_name( ).

    CASE io_message->get_type( ).
      WHEN zcl_broker_daemon_message=>gc_type_ack.
        DATA(lv_id) = io_message->get_field( zcl_broker_daemon_message=>gc_field_event_id ).
        ASSIGN mt_event_in_flight[ event_id = lv_id ] TO FIELD-SYMBOL(<ls_event>).
        CHECK <ls_event> IS ASSIGNED.
        acknowledge_events( VALUE #( ( <ls_event> ) ) ).

      WHEN zcl_broker_daemon_message=>gc_type_fail.
        lv_id = io_message->get_field( zcl_broker_daemon_message=>gc_field_event_id ).
        ASSIGN mt_event_in_flight[ event_id = lv_id ] TO FIELD-SYMBOL(<ls_event2>).
        CHECK <ls_event2> IS ASSIGNED.
        fail_events( VALUE #( ( <ls_event2> ) ) ).
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
