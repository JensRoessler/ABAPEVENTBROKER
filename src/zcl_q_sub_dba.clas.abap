CLASS zcl_q_sub_dba DEFINITION PUBLIC CREATE PUBLIC FINAL.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_s_queue_with_subs,
        queue TYPE zif_broker_types=>ty_e_queue,
        subs  TYPE zif_broker_types=>ty_t_q_sub,
      END OF ty_s_queue_with_subs,
      ty_t_queue_with_subs TYPE STANDARD TABLE OF ty_s_queue_with_subs WITH DEFAULT KEY.

    CLASS-METHODS:
      create
        IMPORTING iv_broker TYPE zif_broker_types=>ty_e_broker
                  iv_queue  TYPE zif_broker_types=>ty_e_queue
                  iv_topic  TYPE /iwxbe/descr_topic
        RAISING   zcx_broker,
      delete
        IMPORTING iv_broker TYPE zif_broker_types=>ty_e_broker
                  iv_queue  TYPE zif_broker_types=>ty_e_queue
                  iv_topic  TYPE /iwxbe/descr_topic
        RAISING   zcx_broker,
      get_subscriptions
        IMPORTING iv_broker      TYPE zif_broker_types=>ty_e_broker
                  iv_queue       TYPE zif_broker_types=>ty_e_queue
        RETURNING VALUE(rt_subs) TYPE zif_broker_types=>ty_t_q_sub,
      get_queues_with_subs
        IMPORTING iv_broker        TYPE zif_broker_types=>ty_e_broker
        RETURNING VALUE(rt_result) TYPE ty_t_queue_with_subs,
      update_subscriptions
        IMPORTING iv_broker TYPE zif_broker_types=>ty_e_broker
                  iv_queue  TYPE zif_broker_types=>ty_e_queue
                  it_subs   TYPE zif_broker_types=>ty_t_q_sub
        RAISING   zcx_broker.
ENDCLASS.

CLASS zcl_q_sub_dba IMPLEMENTATION.
  METHOD create.
    DATA ls_row TYPE zcl_l_q_sub.
    ls_row = VALUE #( broker = iv_broker
                      queue  = iv_queue  topic  = iv_topic ).
    INSERT zcl_l_q_sub FROM ls_row.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_broker
        EXPORTING mv_text = |Subscription { iv_topic } already exists|.
    ENDIF.
  ENDMETHOD.

  METHOD delete.
    DELETE FROM zcl_l_q_sub
      WHERE broker = iv_broker
        AND queue  = iv_queue AND topic  = iv_topic.
  ENDMETHOD.

  METHOD get_subscriptions.
    SELECT topic FROM zcl_l_q_sub
      WHERE broker = @iv_broker AND queue = @iv_queue
      INTO TABLE @DATA(lt_raw).
    rt_subs = VALUE #( FOR ls IN lt_raw ( topic = ls-topic data_state = '0' ) ).
  ENDMETHOD.

  METHOD get_queues_with_subs.
    SELECT queue, topic FROM zcl_l_q_sub
      WHERE broker = @iv_broker
      ORDER BY queue
      INTO TABLE @DATA(lt_raw).
    LOOP AT lt_raw INTO DATA(ls).
      ASSIGN rt_result[ queue = ls-queue ] TO FIELD-SYMBOL(<lq>).
      IF <lq> IS NOT ASSIGNED.
        APPEND VALUE #( queue = ls-queue ) TO rt_result.
        ASSIGN rt_result[ queue = ls-queue ] TO <lq>.
      ENDIF.
      INSERT VALUE #( topic = ls-topic data_state = '0' ) INTO TABLE <lq>-subs.
    ENDLOOP.
  ENDMETHOD.

  METHOD update_subscriptions.
    LOOP AT it_subs INTO DATA(ls_sub).
      CASE ls_sub-data_state.
        WHEN '2'.  " deleted
          DELETE FROM zcl_l_q_sub
            WHERE broker = iv_broker
              AND queue = iv_queue AND topic = ls_sub-topic.
        WHEN '1'.  " new
          DATA ls_new TYPE zcl_l_q_sub.
          ls_new = VALUE #( broker = iv_broker
                            queue  = iv_queue  topic  = ls_sub-topic ).
          INSERT zcl_l_q_sub FROM ls_new.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
