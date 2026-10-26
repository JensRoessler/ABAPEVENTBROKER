"! <p class="shorttext synchronized">EEE - Test broker daemon (PoC)</p>
"! Receives events via AMC (ZCL_BROKER_DAEMON_MESSAGE) and enqueues them
"! into the broker aggregate, then acknowledges back via ZIF_AMC_CLIENT.
CLASS zcl_broker_daemon DEFINITION
  PUBLIC
  INHERITING FROM /iwxbe/cl_daemon FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_amc_client_handler.
    METHODS if_abap_daemon_extension~on_accept REDEFINITION.

  PROTECTED SECTION.
    METHODS: handle_before_restart      REDEFINITION,
             handle_continue_processing REDEFINITION,
             handle_error               REDEFINITION,
             handle_message             REDEFINITION,
             handle_restart             REDEFINITION,
             handle_server_shutdown     REDEFINITION,
             handle_start               REDEFINITION,
             handle_stop                REDEFINITION,
             handle_system_shutdown     REDEFINITION.

  PRIVATE SECTION.
    DATA mo_broker     TYPE REF TO zif_broker.
    DATA mo_amc_client TYPE REF TO zif_amc_client.

    METHODS:
      enqueue_event
        IMPORTING is_event TYPE zif_broker_types=>ty_s_event,
      send_ack
        IMPORTING is_event TYPE zif_broker_types=>ty_s_event.

ENDCLASS.



CLASS zcl_broker_daemon IMPLEMENTATION.


  METHOD if_abap_daemon_extension~on_accept.
    e_setup_mode = co_setup_mode-accept.
  ENDMETHOD.


  METHOD handle_start.
    DATA(lv_broker_name) = mo_channel->get_name( ).
    TRY.
        mo_broker = zcl_broker=>get( lv_broker_name ).
      CATCH zcx_broker.
    ENDTRY.
    mo_amc_client = NEW zcl_amc_client(
        iv_application_id  = 'ZAMC_BROKER'
        iv_send_channel_id = '/broker_out'
        iv_recv_channel_id = '/broker_in'
        io_handler         = me ).
  ENDMETHOD.


  METHOD handle_stop ##needed.
  ENDMETHOD.


  METHOD handle_restart.
    TRY.
        mo_broker = zcl_broker=>get( mo_channel->get_name( ) ).
      CATCH zcx_broker.
    ENDTRY.
  ENDMETHOD.


  METHOD handle_before_restart ##needed.
  ENDMETHOD.


  METHOD handle_error ##needed.
  ENDMETHOD.


  METHOD handle_server_shutdown ##needed.
  ENDMETHOD.


  METHOD handle_system_shutdown ##needed.
  ENDMETHOD.


  METHOD handle_continue_processing ##needed.
  ENDMETHOD.


  METHOD handle_message.
    " Control messages (e.g. reconfigure) arrive via the daemon handle, sent
    " by the owning caller class ZCL_BROKER_SERVICE. Data-plane traffic
    " (events/acks) arrives separately over AMC via zif_amc_client_handler.
    CASE io_message->get_type( ).
      WHEN zcl_broker_daemon_message=>gc_type_reconfigure.
        TRY.
            mo_broker = zcl_broker=>get( mo_channel->get_name( ) ).
          CATCH zcx_broker.
        ENDTRY.
    ENDCASE.
  ENDMETHOD.


  METHOD zif_amc_client_handler~on_connect.
    " no-op — daemon framework manages lifecycle
  ENDMETHOD.


  METHOD zif_amc_client_handler~on_disconnect.
    " no-op — daemon framework manages lifecycle
  ENDMETHOD.


  METHOD zif_amc_client_handler~on_message.
    DATA(lv_broker) = CAST zcl_broker_daemon_message( io_message )->get_broker( ).
    CHECK lv_broker = mo_channel->get_name( ).

    CASE io_message->get_type( ).
      WHEN zcl_broker_daemon_message=>gc_type_event.
        DATA(lo_msg) = CAST zcl_broker_daemon_message( io_message ).
        DATA(ls_event) = VALUE zif_broker_types=>ty_s_event(
            broker   = lv_broker
            topic    = lo_msg->get_topic( )
            event_id = lo_msg->/iwxbe/if_daemon_message~get_field( zcl_broker_daemon_message=>gc_field_event_id )
            payload  = lo_msg->get_event( )-payload ).
        enqueue_event( ls_event ).
        send_ack( ls_event ).
    ENDCASE.
  ENDMETHOD.


  METHOD enqueue_event.
    LOOP AT mo_broker->get_queues( ) INTO DATA(lo_q).
      LOOP AT lo_q->get_subscriptions( ) INTO DATA(ls_sub).
        CHECK ls_sub-topic = is_event-topic.
        TRY.
            zcl_event_q_dba=>create(
                iv_broker   = is_event-broker
                iv_queue    = lo_q->get_name( )
                iv_topic    = is_event-topic
                iv_event_id = is_event-event_id
                iv_payload  = is_event-payload ).
          CATCH zcx_broker.
        ENDTRY.
        EXIT.
      ENDLOOP.
    ENDLOOP.
    COMMIT WORK.
  ENDMETHOD.


  METHOD send_ack.
    TRY.
        mo_amc_client->send(
            zcl_broker_daemon_message=>create_ack_for_event(
                iv_event_id = is_event-event_id
                iv_broker   = is_event-broker ) ).
      CATCH cx_amc_error /iwxbe/cx_exception.
        " fire and forget — ignore send failures
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

