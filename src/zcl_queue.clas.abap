CLASS zcl_queue DEFINITION
  PUBLIC
  CREATE PRIVATE
  FINAL.

  PUBLIC SECTION.
    INTERFACES zif_queue.
    CLASS-METHODS:
      create_instance
        IMPORTING iv_broker      TYPE zif_broker_types=>ty_e_broker
                  iv_queue       TYPE zif_broker_types=>ty_e_queue
                  iv_description TYPE string OPTIONAL
        RETURNING VALUE(ro_queue) TYPE REF TO zif_queue,
      get_queues
        IMPORTING iv_broker        TYPE zif_broker_types=>ty_e_broker
        RETURNING VALUE(rt_queues) TYPE zif_broker=>ty_t_queue_ref.

  PRIVATE SECTION.
    DATA mv_broker      TYPE zif_broker_types=>ty_e_broker.
    DATA mv_queue       TYPE zif_broker_types=>ty_e_queue.
    DATA mv_description TYPE string.
    DATA mv_data_state  TYPE zif_broker_types=>ty_en_data_state.
    DATA mt_subs        TYPE zif_broker_types=>ty_t_q_sub.
ENDCLASS.



CLASS zcl_queue IMPLEMENTATION.

  METHOD create_instance.
    DATA(lo_q) = NEW zcl_queue( ).
    lo_q->mv_broker      = iv_broker.
    lo_q->mv_queue       = iv_queue.
    lo_q->mv_description = iv_description.
    lo_q->mv_data_state  = zif_broker_types=>gcs_data_state-new.
    ro_queue = lo_q.
  ENDMETHOD.

  METHOD get_queues.
    DATA(lt_raw) = zcl_q_sub_dba=>get_queues_with_subs( iv_broker ).
    " Also get queues that have no subs
    DATA(lt_q) = zcl_queue_dba=>get_queues( iv_broker ).
    LOOP AT lt_q INTO DATA(ls_q).
      DATA(lo_q) = NEW zcl_queue( ).
      lo_q->mv_broker     = iv_broker.
      lo_q->mv_queue      = ls_q-queue.
      lo_q->mv_description = ls_q-description.
      lo_q->mv_data_state = zif_broker_types=>gcs_data_state-unchanged.
      " Load subs if present
      ASSIGN lt_raw[ queue = ls_q-queue ] TO FIELD-SYMBOL(<lqs>).
      IF <lqs> IS ASSIGNED.
        lo_q->mt_subs = <lqs>-subs.
      ENDIF.
      APPEND lo_q TO rt_queues.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_queue~get_name.
    rv_queue = mv_queue.
  ENDMETHOD.

  METHOD zif_queue~add_subscription.
    IF line_exists( mt_subs[ topic = iv_topic ] ).
      RAISE EXCEPTION TYPE zcx_broker
        EXPORTING mv_text = |Topic { iv_topic } already subscribed|.
    ENDIF.
    INSERT VALUE #( topic = iv_topic data_state = zif_broker_types=>gcs_data_state-new )
      INTO TABLE mt_subs.
  ENDMETHOD.

  METHOD zif_queue~remove_subscription.
    ASSIGN mt_subs[ topic = iv_topic ] TO FIELD-SYMBOL(<ls>).
    IF <ls> IS NOT ASSIGNED.
      RAISE EXCEPTION TYPE zcx_broker
        EXPORTING mv_text = |Topic { iv_topic } not subscribed|.
    ENDIF.
    <ls>-data_state = zif_broker_types=>gcs_data_state-deleted.
  ENDMETHOD.

  METHOD zif_queue~get_subscriptions.
    rt_subs = mt_subs.
  ENDMETHOD.

  METHOD zif_queue~get_events.
    rt_events = zcl_event_q_dba=>get_events(
        iv_broker = mv_broker
        iv_queue  = mv_queue ).
  ENDMETHOD.

  METHOD zif_queue~delete.
    mv_data_state = zif_broker_types=>gcs_data_state-deleted.
    " Mark all subs as deleted
    LOOP AT mt_subs ASSIGNING FIELD-SYMBOL(<ls>).
      <ls>-data_state = zif_broker_types=>gcs_data_state-deleted.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_queue~save.
    zcl_q_sub_dba=>update_subscriptions(
        iv_broker = mv_broker
        iv_queue  = mv_queue
        it_subs   = mt_subs ).
    CASE mv_data_state.
      WHEN zif_broker_types=>gcs_data_state-new.
        zcl_queue_dba=>create(
            iv_broker      = mv_broker
            iv_queue       = mv_queue
            iv_description = mv_description ).
      WHEN zif_broker_types=>gcs_data_state-deleted.
        zcl_queue_dba=>delete(
            iv_broker = mv_broker
            iv_queue  = mv_queue ).
    ENDCASE.
    mv_data_state = zif_broker_types=>gcs_data_state-unchanged.
  ENDMETHOD.

ENDCLASS.
