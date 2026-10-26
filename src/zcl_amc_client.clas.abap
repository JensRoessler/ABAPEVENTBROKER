CLASS zcl_amc_client DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_amc_client.
    INTERFACES if_amc_message_receiver_pcp.
    METHODS constructor
      IMPORTING
        iv_application_id  TYPE if_abap_channel_types=>ty_amc_application_id
        iv_send_channel_id TYPE if_abap_channel_types=>ty_amc_channel_id
        iv_recv_channel_id TYPE if_abap_channel_types=>ty_amc_channel_id
        io_handler         TYPE REF TO zif_amc_client_handler OPTIONAL.

  PRIVATE SECTION.
    DATA mo_producer     TYPE REF TO if_amc_message_producer_pcp.
    DATA mo_consumer     TYPE REF TO if_amc_message_consumer.
    DATA mo_handler      TYPE REF TO zif_amc_client_handler.
    DATA mv_channel_name TYPE /iwxbe/channel_name.
ENDCLASS.



CLASS zcl_amc_client IMPLEMENTATION.

  METHOD constructor.
    mv_channel_name = CONV #( iv_send_channel_id ).
    mo_handler      = io_handler.
    TRY.
        mo_producer = CAST if_amc_message_producer_pcp(
            cl_amc_channel_manager=>create_message_producer(
                i_application_id = iv_application_id
                i_channel_id     = iv_send_channel_id ) ).

        mo_consumer = cl_amc_channel_manager=>create_message_consumer(
            i_application_id = iv_application_id
            i_channel_id     = iv_recv_channel_id ).
        mo_consumer->start_message_delivery( i_receiver = me ).

        IF mo_handler IS BOUND.
          mo_handler->on_connect( ).
        ENDIF.
      CATCH cx_amc_error /iwxbe/cx_exception ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD zif_amc_client~send.
    CHECK mo_producer IS BOUND.
    DATA(lo_pcp) = io_message->convert_to_pcp_message( mv_channel_name ).
    mo_producer->send( lo_pcp ).
  ENDMETHOD.

  METHOD if_amc_message_receiver_pcp~receive.
    CHECK mo_handler IS BOUND.
    TRY.
        DATA(lo_message) = zcl_broker_daemon_message=>/iwxbe/if_daemon_message~convert_from_pcp_message( i_message ).
        CASE lo_message->get_type( ).
          WHEN zcl_broker_daemon_message=>gc_type_disconnect.
            mo_handler->on_disconnect( ).
          WHEN OTHERS.
            mo_handler->on_message( lo_message ).
        ENDCASE.
      CATCH /iwxbe/cx_exception ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
