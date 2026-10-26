*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

**********************************************************************
* Handler for root entity Broker
**********************************************************************
CLASS lhc_broker DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Broker RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Broker RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Broker.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Broker.

    METHODS cba_Queue FOR MODIFY
      IMPORTING entities_cba FOR CREATE Broker\_Queue.
ENDCLASS.

CLASS lhc_broker IMPLEMENTATION.

  METHOD get_global_authorizations.
    " PoC: grant all
  ENDMETHOD.

  METHOD get_instance_authorizations.
    " PoC: grant all
  ENDMETHOD.

  METHOD create.
    LOOP AT entities INTO DATA(ls_broker).
      TRY.
          zcl_broker_service=>create_broker(
            iv_broker      = CONV #( ls_broker-Broker )
            iv_description = CONV string( ls_broker-Description ) ).
        CATCH zcx_broker INTO DATA(lx_broker).
          APPEND VALUE #( %cid = ls_broker-%cid %key = ls_broker-%key ) TO failed-broker.
          APPEND VALUE #( %cid = ls_broker-%cid %key = ls_broker-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = lx_broker->get_text( ) ) ) TO reported-broker.
        CATCH /iwxbe/cx_exception INTO DATA(lx_fw).
          APPEND VALUE #( %cid = ls_broker-%cid %key = ls_broker-%key ) TO failed-broker.
          APPEND VALUE #( %cid = ls_broker-%cid %key = ls_broker-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = lx_fw->get_text( ) ) ) TO reported-broker.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      TRY.
          zcl_broker_service=>delete_broker( iv_broker = CONV #( ls_key-Broker ) ).
        CATCH zcx_broker INTO DATA(lx_broker).
          APPEND VALUE #( %key = ls_key-%key ) TO failed-broker.
          APPEND VALUE #( %key = ls_key-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = lx_broker->get_text( ) ) ) TO reported-broker.
        CATCH /iwxbe/cx_exception INTO DATA(lx_fw).
          APPEND VALUE #( %key = ls_key-%key ) TO failed-broker.
          APPEND VALUE #( %key = ls_key-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = lx_fw->get_text( ) ) ) TO reported-broker.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD cba_Queue.
    LOOP AT entities_cba INTO DATA(ls_cba).
      DATA(lv_broker) = ls_cba-Broker.
      LOOP AT ls_cba-%target INTO DATA(ls_queue).
        TRY.
            zcl_broker=>get( CONV #( lv_broker )
              )->add_queue( iv_queue       = CONV #( ls_queue-Queue )
                            iv_description = CONV string( ls_queue-Description ) )->save( ).
            zcl_broker_service=>reconfigure_broker( iv_broker = CONV #( lv_broker ) ).
          CATCH zcx_broker INTO DATA(lx_broker).
            APPEND VALUE #( %cid = ls_queue-%cid %key = ls_queue-%key ) TO failed-queue.
            APPEND VALUE #( %cid = ls_queue-%cid %key = ls_queue-%key
                            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                          text     = lx_broker->get_text( ) ) ) TO reported-queue.
          CATCH /iwxbe/cx_exception INTO DATA(lx_fw).
            APPEND VALUE #( %cid = ls_queue-%cid %key = ls_queue-%key ) TO failed-queue.
            APPEND VALUE #( %cid = ls_queue-%cid %key = ls_queue-%key
                            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                          text     = lx_fw->get_text( ) ) ) TO reported-queue.
        ENDTRY.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

**********************************************************************
* Handler for entity Queue
**********************************************************************
CLASS lhc_queue DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Queue.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Queue.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Queue.

    METHODS cba_Sub FOR MODIFY
      IMPORTING entities_cba FOR CREATE Queue\_Sub.
ENDCLASS.

CLASS lhc_queue IMPLEMENTATION.

  METHOD create.
    LOOP AT entities INTO DATA(ls_queue).
      TRY.
          zcl_broker=>get( CONV #( ls_queue-Broker )
            )->add_queue( iv_queue       = CONV #( ls_queue-Queue )
                          iv_description = CONV string( ls_queue-Description ) )->save( ).
          zcl_broker_service=>reconfigure_broker( iv_broker = CONV #( ls_queue-Broker ) ).
        CATCH zcx_broker INTO DATA(lx_broker).
          APPEND VALUE #( %cid = ls_queue-%cid %key = ls_queue-%key ) TO failed-queue.
          APPEND VALUE #( %cid = ls_queue-%cid %key = ls_queue-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = lx_broker->get_text( ) ) ) TO reported-queue.
        CATCH /iwxbe/cx_exception INTO DATA(lx_fw).
          APPEND VALUE #( %cid = ls_queue-%cid %key = ls_queue-%key ) TO failed-queue.
          APPEND VALUE #( %cid = ls_queue-%cid %key = ls_queue-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = lx_fw->get_text( ) ) ) TO reported-queue.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    " Description change -> re-add not supported by domain; treat as no-op persistence.
    " Domain layer owns queue attributes; nothing to persist here for PoC.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      TRY.
          DATA(lo_broker) = zcl_broker=>get( CONV #( ls_key-Broker ) ).
          lo_broker->delete_queue( iv_queue = CONV #( ls_key-Queue ) ).
          lo_broker->save( ).
          zcl_broker_service=>reconfigure_broker( iv_broker = CONV #( ls_key-Broker ) ).
        CATCH zcx_broker INTO DATA(lx_broker).
          APPEND VALUE #( %key = ls_key-%key ) TO failed-queue.
          APPEND VALUE #( %key = ls_key-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = lx_broker->get_text( ) ) ) TO reported-queue.
        CATCH /iwxbe/cx_exception INTO DATA(lx_fw).
          APPEND VALUE #( %key = ls_key-%key ) TO failed-queue.
          APPEND VALUE #( %key = ls_key-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = lx_fw->get_text( ) ) ) TO reported-queue.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD cba_Sub.
    LOOP AT entities_cba INTO DATA(ls_cba).
      DATA(lv_broker) = ls_cba-Broker.
      DATA(lv_queue)  = ls_cba-Queue.
      LOOP AT ls_cba-%target INTO DATA(ls_sub).
        TRY.
            DATA(lt_queues) = zcl_broker=>get( CONV #( lv_broker ) )->get_queues( ).
            DATA lo_queue TYPE REF TO zif_queue.
            CLEAR lo_queue.
            LOOP AT lt_queues INTO DATA(lo_q).
              IF lo_q->get_name( ) = lv_queue.
                lo_queue = lo_q.
                EXIT.
              ENDIF.
            ENDLOOP.
            IF lo_queue IS BOUND.
              lo_queue->add_subscription( iv_topic = CONV #( ls_sub-Topic ) ).
              lo_queue->save( ).
              zcl_broker_service=>reconfigure_broker( iv_broker = CONV #( lv_broker ) ).
            ELSE.
              APPEND VALUE #( %cid = ls_sub-%cid %key = ls_sub-%key ) TO failed-sub.
              APPEND VALUE #( %cid = ls_sub-%cid %key = ls_sub-%key
                              %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                            text     = |Queue { lv_queue } not found| ) ) TO reported-sub.
            ENDIF.
          CATCH zcx_broker INTO DATA(lx_broker).
            APPEND VALUE #( %cid = ls_sub-%cid %key = ls_sub-%key ) TO failed-sub.
            APPEND VALUE #( %cid = ls_sub-%cid %key = ls_sub-%key
                            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                          text     = lx_broker->get_text( ) ) ) TO reported-sub.
          CATCH /iwxbe/cx_exception INTO DATA(lx_fw).
            APPEND VALUE #( %cid = ls_sub-%cid %key = ls_sub-%key ) TO failed-sub.
            APPEND VALUE #( %cid = ls_sub-%cid %key = ls_sub-%key
                            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                          text     = lx_fw->get_text( ) ) ) TO reported-sub.
        ENDTRY.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

**********************************************************************
* Handler for entity Sub (subscription)
**********************************************************************
CLASS lhc_sub DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Sub.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Sub.

    METHODS find_queue
      IMPORTING iv_broker       TYPE zif_broker_types=>ty_e_broker
                iv_queue        TYPE zif_broker_types=>ty_e_queue
      RETURNING VALUE(ro_queue) TYPE REF TO zif_queue
      RAISING   zcx_broker.
ENDCLASS.

CLASS lhc_sub IMPLEMENTATION.

  METHOD find_queue.
    DATA(lt_queues) = zcl_broker=>get( iv_broker )->get_queues( ).
    LOOP AT lt_queues INTO DATA(lo_q).
      IF lo_q->get_name( ) = iv_queue.
        ro_queue = lo_q.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD create.
    LOOP AT entities INTO DATA(ls_sub).
      TRY.
          DATA(lo_queue) = find_queue( iv_broker = CONV #( ls_sub-Broker )
                                       iv_queue  = CONV #( ls_sub-Queue ) ).
          IF lo_queue IS BOUND.
            lo_queue->add_subscription( iv_topic = CONV #( ls_sub-Topic ) ).
            lo_queue->save( ).
            zcl_broker_service=>reconfigure_broker( iv_broker = CONV #( ls_sub-Broker ) ).
          ELSE.
            APPEND VALUE #( %cid = ls_sub-%cid %key = ls_sub-%key ) TO failed-sub.
            APPEND VALUE #( %cid = ls_sub-%cid %key = ls_sub-%key
                            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                          text     = |Queue { ls_sub-Queue } not found| ) ) TO reported-sub.
          ENDIF.
        CATCH zcx_broker INTO DATA(lx_broker).
          APPEND VALUE #( %cid = ls_sub-%cid %key = ls_sub-%key ) TO failed-sub.
          APPEND VALUE #( %cid = ls_sub-%cid %key = ls_sub-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = lx_broker->get_text( ) ) ) TO reported-sub.
        CATCH /iwxbe/cx_exception INTO DATA(lx_fw).
          APPEND VALUE #( %cid = ls_sub-%cid %key = ls_sub-%key ) TO failed-sub.
          APPEND VALUE #( %cid = ls_sub-%cid %key = ls_sub-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = lx_fw->get_text( ) ) ) TO reported-sub.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      TRY.
          DATA(lo_queue) = find_queue( iv_broker = CONV #( ls_key-Broker )
                                       iv_queue  = CONV #( ls_key-Queue ) ).
          IF lo_queue IS BOUND.
            lo_queue->remove_subscription( iv_topic = CONV #( ls_key-Topic ) ).
            lo_queue->save( ).
            zcl_broker_service=>reconfigure_broker( iv_broker = CONV #( ls_key-Broker ) ).
          ELSE.
            APPEND VALUE #( %key = ls_key-%key ) TO failed-sub.
            APPEND VALUE #( %key = ls_key-%key
                            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                          text     = |Queue { ls_key-Queue } not found| ) ) TO reported-sub.
          ENDIF.
        CATCH zcx_broker INTO DATA(lx_broker).
          APPEND VALUE #( %key = ls_key-%key ) TO failed-sub.
          APPEND VALUE #( %key = ls_key-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = lx_broker->get_text( ) ) ) TO reported-sub.
        CATCH /iwxbe/cx_exception INTO DATA(lx_fw).
          APPEND VALUE #( %key = ls_key-%key ) TO failed-sub.
          APPEND VALUE #( %key = ls_key-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = lx_fw->get_text( ) ) ) TO reported-sub.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

**********************************************************************
* Saver class (unmanaged). Persistence already done synchronously by
* the domain layer (zcl_broker / zcl_broker_service call save/COMMIT),
* so save_modified is a no-op here.
**********************************************************************
*CLASS lsc_zcl_i_broker DEFINITION INHERITING FROM cl_abap_behavior_saver FINAL.
*  PROTECTED SECTION.
*    METHODS save_modified REDEFINITION.
*ENDCLASS.
*
*CLASS lsc_zcl_i_broker IMPLEMENTATION.
*
*  METHOD save_modified.
*    " No-op: domain classes already persisted (save/COMMIT) during the
*    " handler modify phase. Nothing to flush here.
*  ENDMETHOD.
*
*ENDCLASS.

