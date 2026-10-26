CLASS zcl_broker DEFINITION
  PUBLIC
  CREATE PRIVATE
  FINAL.

  PUBLIC SECTION.
    INTERFACES zif_broker.
    CLASS-METHODS:
      create_instance
        IMPORTING iv_broker      TYPE zif_broker_types=>ty_e_broker
                  iv_description TYPE string OPTIONAL
        RETURNING VALUE(ro_broker) TYPE REF TO zif_broker,
      get
        IMPORTING iv_broker       TYPE zif_broker_types=>ty_e_broker
        RETURNING VALUE(ro_broker) TYPE REF TO zif_broker
        RAISING   zcx_broker,
      does_exist
        IMPORTING iv_broker       TYPE zif_broker_types=>ty_e_broker
        RETURNING VALUE(rv_exists) TYPE abap_bool.

  PRIVATE SECTION.
    DATA ms_config     TYPE zif_broker_types=>ty_s_broker.
    DATA mv_data_state TYPE zif_broker_types=>ty_en_data_state.
    DATA mt_queues     TYPE zif_broker=>ty_t_queue_ref.
ENDCLASS.



CLASS zcl_broker IMPLEMENTATION.

  METHOD create_instance.
    DATA(lo_b) = NEW zcl_broker( ).
    lo_b->ms_config    = VALUE #( broker = iv_broker description = iv_description status = 'D' ).
    lo_b->mv_data_state = zif_broker_types=>gcs_data_state-new.
    ro_broker = lo_b.
  ENDMETHOD.

  METHOD get.
    DATA(ls_config) = zcl_broker_dba=>get( iv_broker ).
    DATA(lo_b) = NEW zcl_broker( ).
    lo_b->ms_config    = ls_config.
    lo_b->mv_data_state = zif_broker_types=>gcs_data_state-unchanged.
    lo_b->mt_queues    = zcl_queue=>get_queues( iv_broker ).
    ro_broker = lo_b.
  ENDMETHOD.

  METHOD does_exist.
    rv_exists = zcl_broker_dba=>does_exist( iv_broker ).
  ENDMETHOD.

  METHOD zif_broker~get_config.
    rs_config = ms_config.
  ENDMETHOD.

  METHOD zif_broker~add_queue.
    " Check for duplicate — LOOP used because table_line->method() predicates on
    " REF tables may not compile in all ABAP releases.
    LOOP AT mt_queues INTO DATA(lo_existing).
      IF lo_existing->get_name( ) = iv_queue.
        RAISE EXCEPTION TYPE zcx_broker
          EXPORTING mv_text = |Queue { iv_queue } already exists|.
      ENDIF.
    ENDLOOP.
    ro_queue = zcl_queue=>create_instance(
        iv_broker      = ms_config-broker
        iv_queue       = iv_queue
        iv_description = iv_description ).
    APPEND ro_queue TO mt_queues.
  ENDMETHOD.

  METHOD zif_broker~delete_queue.
    LOOP AT mt_queues INTO DATA(lo_q).
      IF lo_q->get_name( ) = iv_queue.
        lo_q->delete( ).
        RETURN.
      ENDIF.
    ENDLOOP.
    RAISE EXCEPTION TYPE zcx_broker
      EXPORTING mv_text = |Queue { iv_queue } not found|.
  ENDMETHOD.

  METHOD zif_broker~get_queues.
    rt_queues = mt_queues.
  ENDMETHOD.

  METHOD zif_broker~delete.
    mv_data_state = zif_broker_types=>gcs_data_state-deleted.
    LOOP AT mt_queues INTO DATA(lo_q).
      lo_q->delete( ).
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_broker~save.
    CASE mv_data_state.
      WHEN zif_broker_types=>gcs_data_state-new.
        zcl_broker_dba=>create( ms_config ).
      WHEN zif_broker_types=>gcs_data_state-deleted.
        zcl_broker_dba=>delete( ms_config-broker ).
    ENDCASE.
    mv_data_state = zif_broker_types=>gcs_data_state-unchanged.
    LOOP AT mt_queues INTO DATA(lo_q).
      lo_q->save( ).
    ENDLOOP.
    COMMIT WORK.
  ENDMETHOD.

ENDCLASS.
