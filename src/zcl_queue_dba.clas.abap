CLASS zcl_queue_dba DEFINITION PUBLIC CREATE PUBLIC FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      create
        IMPORTING iv_broker      TYPE zif_broker_types=>ty_e_broker
                  iv_queue       TYPE zif_broker_types=>ty_e_queue
                  iv_description TYPE string OPTIONAL
        RAISING   zcx_broker,
      does_exist
        IMPORTING iv_broker        TYPE zif_broker_types=>ty_e_broker
                  iv_queue         TYPE zif_broker_types=>ty_e_queue
        RETURNING VALUE(rv_exists) TYPE abap_bool,
      delete
        IMPORTING iv_broker TYPE zif_broker_types=>ty_e_broker
                  iv_queue  TYPE zif_broker_types=>ty_e_queue
        RAISING   zcx_broker,
      get_queues
        IMPORTING iv_broker        TYPE zif_broker_types=>ty_e_broker
        RETURNING VALUE(rt_queues) TYPE zif_broker_types=>ty_t_queue.
ENDCLASS.

CLASS zcl_queue_dba IMPLEMENTATION.
  METHOD create.
    DATA ls_row TYPE zcl_l_queue.
    ls_row = VALUE #(
        broker      = iv_broker
        queue       = iv_queue
        description = iv_description ).
    INSERT zcl_l_queue FROM ls_row.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_broker
        EXPORTING mv_text = |Queue { iv_queue } already exists on broker { iv_broker }|.
    ENDIF.
  ENDMETHOD.

  METHOD does_exist.
    SELECT SINGLE @abap_true FROM zcl_l_queue
      WHERE broker = @iv_broker AND queue = @iv_queue
      INTO @rv_exists.
  ENDMETHOD.

  METHOD delete.
    DELETE FROM zcl_l_queue WHERE broker = iv_broker AND queue = iv_queue.
  ENDMETHOD.

  METHOD get_queues.
    SELECT queue, description FROM zcl_l_queue
      WHERE broker = @iv_broker
      INTO CORRESPONDING FIELDS OF TABLE @rt_queues.
  ENDMETHOD.
ENDCLASS.
