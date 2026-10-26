CLASS zcl_broker_channel_smoke_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_broker_channel_smoke_test IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    CONSTANTS: lc_broker    TYPE zif_broker_types=>ty_e_broker VALUE 'TESTBROKER',
               lc_queue     TYPE zif_broker_types=>ty_e_queue  VALUE 'Q1',
               lc_topic     TYPE /iwxbe/descr_topic            VALUE 'ABAP/EVENT/BROKER/ce/sap/eee/iwxbe/testproducer/v1/Event/Created/v1',
               lc_num_events TYPE i VALUE 1,
               lc_wait_sec   TYPE i VALUE 10.

    " --- 0. Cleanup leftover state from previous runs ---
    TRY.
        zcl_broker_service=>stop_broker_daemon( ).
      CATCH /iwxbe/cx_exception INTO DATA(lx_stop_cleanup).
        out->write( |Cleanup daemon stop warning: { lx_stop_cleanup->get_text( ) }| ).
    ENDTRY.
    zcl_event_q_dba=>delete_by_broker( lc_broker ).
    IF zcl_broker=>does_exist( lc_broker ) = abap_true.
      TRY.
          DATA(lo_cleanup) = zcl_broker=>get( lc_broker ).
          lo_cleanup->delete( ).
          lo_cleanup->save( ).
        CATCH zcx_broker INTO DATA(lx_cleanup).
          out->write( |Cleanup warning: { lx_cleanup->get_text( ) }| ).
      ENDTRY.
    ENDIF.
    out->write( 'Cleanup done.' ).

    " --- 1. Create broker (persists aggregate + activates channel + starts ZCL_BROKER_DAEMON) ---
    TRY.
        zcl_broker_service=>create_broker(
          iv_broker      = lc_broker
          iv_description = 'Smoke test broker' ).
        out->write( 'Broker created and daemon started.' ).
      CATCH cx_root INTO DATA(lx_create).
        out->write( |Create broker failed ({ cl_abap_classdescr=>get_class_name( lx_create ) }): { lx_create->get_text( ) }| ).
        TRY.
            DATA(lx_prev) = CAST cx_dynamic_check( lx_create )->previous.
            WHILE lx_prev IS BOUND.
              out->write( |  caused by ({ cl_abap_classdescr=>get_class_name( lx_prev ) }): { lx_prev->get_text( ) }| ).
              lx_prev = CAST cx_dynamic_check( lx_prev )->previous.
            ENDWHILE.
          CATCH cx_sy_move_cast_error ##NO_HANDLER.
        ENDTRY.
        RETURN.
    ENDTRY.

    " --- 2. Add queue + subscription via broker aggregate ---
    TRY.
        DATA(lo_broker) = zcl_broker=>get( lc_broker ).
        DATA(lo_queue)  = lo_broker->add_queue( lc_queue ).
        lo_queue->add_subscription( lc_topic ).
        lo_broker->save( ).
        out->write( |Queue '{ lc_queue }' with topic '{ lc_topic }' added.| ).
      CATCH zcx_broker /iwxbe/cx_exception INTO DATA(lx_queue).
        out->write( |Queue setup failed: { lx_queue->get_text( ) }| ).
        zcl_broker_service=>delete_broker( lc_broker ).
        RETURN.
    ENDTRY.

    " --- 3. Send RECONFIGURE so the daemon picks up the new queue ---
    TRY.
        zcl_broker_service=>reconfigure_broker( lc_broker ).
      CATCH zcx_broker /iwxbe/cx_exception INTO DATA(lx_reconf).
        out->write( |Reconfigure failed: { lx_reconf->get_text( ) }| ).
    ENDTRY.

    " --- 4. Send events via the framework producer ---
    DATA lo_producer TYPE REF TO /iwxbe/if_producer.
    TRY.
        lo_producer = /iwxbe/cl_producer_factory=>create_producer(
          VALUE #( repository_id = /iwxbe/if_registry_types=>gcs_repository_id-default
                   id            = '/IWXBE/TESTPRODUCER'
                   version       = '1' ) ).
      CATCH /iwxbe/cx_exception INTO DATA(lx_prod).
        out->write( |Producer creation failed: { lx_prod->get_text( ) }| ).
        zcl_broker_service=>delete_broker( lc_broker ).
        RETURN.
    ENDTRY.

    DATA lv_sent TYPE i VALUE 0.
    DO lc_num_events TIMES.
      TRY.
          lo_producer->create_topic( 'Event' )->add_segment( 'Created' )->add_segment( 'v1'
            )->create_event( )->set_business_data( VALUE /iwxbe/cl_test_event_descrip=>ty_s_created( message = 'Hi' )
            )->send( ).
          COMMIT WORK.
          ADD 1 TO lv_sent.
        CATCH /iwxbe/cx_exception INTO DATA(lx_send).
          out->write( |Event { sy-index } send failed: { lx_send->get_text( ) }| ).
      ENDTRY.
    ENDDO.
    out->write( |Sent { lv_sent } of { lc_num_events } events.| ).

    " --- 5. Wait for daemon to enqueue events ---
    WAIT UP TO lc_wait_sec SECONDS.

    " --- 6. Check events landed in the broker queue ---
    TRY.
        DATA(lt_queues) = zcl_broker=>get( lc_broker )->get_queues( ).
        LOOP AT lt_queues INTO DATA(lo_q).
          DATA(lt_ev) = lo_q->get_events( ).
          out->write( |Queue '{ lo_q->get_name( ) }': { lines( lt_ev ) } event(s) enqueued.| ).
          LOOP AT lt_ev INTO DATA(ls_ev).
            out->write( |  event_id={ ls_ev-event_id } status={ ls_ev-status } topic={ ls_ev-topic }| ).
          ENDLOOP.
        ENDLOOP.
      CATCH zcx_broker /iwxbe/cx_exception INTO DATA(lx_read).
        out->write( |Event read failed: { lx_read->get_text( ) }| ).
    ENDTRY.

    " --- 7. Check framework publish-channel persistency ---

    TRY.
        DATA(lo_channel) = /iwxbe/cl_channel=>get( 'TESTBROKER' ).
        DATA(lo_persis)  = CAST /iwxbe/if_event_persis_pub_chn(
          NEW /iwxbe/cl_event_persis_builder( )->for_publishing( )->with_channel( lo_channel )->build( ) ).

        out->write( '-- Framework persistency (TESTBROKER channel) --' ).
        out->write( |Acknowledged   : { lo_persis->get_acknowledged_event_count( ) }| ).
        out->write( |Unacknowledged : { lo_persis->get_unacknowledged_event_count( ) }| ).
        out->write( |Failed         : { lines( lo_persis->get_failed_events( ) ) }| ).
        out->write( |To be sent     : { lines( lo_persis->get_events_to_be_sent( ) ) }| ).
        out->write( |Unsent (never) : { lines( lo_persis->get_unsent_events( ) ) }| ).
        out->write( |Undelivered    : { lines( lo_persis->get_undelivered_events( ) ) }| ).
      CATCH /iwxbe/cx_exception INTO DATA(lx_persis).
        out->write( |Persistency check failed: { lx_persis->get_text( ) }| ).
    ENDTRY.

    " --- 7. Delete broker (stops daemon + deletes channel + clears aggregate) ---
    TRY.
        zcl_broker_service=>delete_broker( lc_broker ).
        out->write( 'Broker deleted.' ).
      CATCH zcx_broker /iwxbe/cx_exception INTO DATA(lx_del).
        out->write( |Delete broker failed: { lx_del->get_text( ) }| ).
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
