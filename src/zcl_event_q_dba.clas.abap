CLASS zcl_event_q_dba DEFINITION PUBLIC CREATE PUBLIC FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      create
        IMPORTING iv_broker   TYPE zif_broker_types=>ty_e_broker
                  iv_queue    TYPE zif_broker_types=>ty_e_queue
                  iv_topic    TYPE /iwxbe/descr_topic
                  iv_event_id TYPE sysuuid_c32
                  iv_payload  TYPE xstring
        RAISING   zcx_broker,
      get_events
        IMPORTING iv_broker        TYPE zif_broker_types=>ty_e_broker
                  iv_queue         TYPE zif_broker_types=>ty_e_queue
        RETURNING VALUE(rt_events) TYPE zif_broker_types=>ty_t_event,
      delete_by_broker
        IMPORTING iv_broker TYPE zif_broker_types=>ty_e_broker.
ENDCLASS.

CLASS zcl_event_q_dba IMPLEMENTATION.
  METHOD create.
    DATA lv_ts TYPE timestamp.
    DATA ls_row TYPE zcl_l_event_q.
    GET TIME STAMP FIELD lv_ts.
    ls_row = VALUE #(
        broker       = iv_broker
        queue        = iv_queue
        topic        = iv_topic
        event_id     = iv_event_id
        payload      = iv_payload
        arrival_time = lv_ts
        status       = 'N' ).
    INSERT zcl_l_event_q FROM ls_row.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_broker
        EXPORTING mv_text = |Event { iv_event_id } already exists|.
    ENDIF.
  ENDMETHOD.

  METHOD get_events.
    SELECT broker, queue, topic, event_id, payload, arrival_time, status
      FROM zcl_l_event_q
      WHERE broker = @iv_broker AND queue = @iv_queue
      INTO CORRESPONDING FIELDS OF TABLE @rt_events.
  ENDMETHOD.

  METHOD delete_by_broker.
    DELETE FROM zcl_l_event_q WHERE broker = iv_broker.
  ENDMETHOD.

ENDCLASS.
