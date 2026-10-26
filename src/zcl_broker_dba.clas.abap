CLASS zcl_broker_dba DEFINITION PUBLIC CREATE PUBLIC FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      create
        IMPORTING is_broker TYPE zif_broker_types=>ty_s_broker
        RAISING   zcx_broker,
      get
        IMPORTING iv_broker        TYPE zif_broker_types=>ty_e_broker
        RETURNING VALUE(rs_broker) TYPE zif_broker_types=>ty_s_broker
        RAISING   zcx_broker,
      does_exist
        IMPORTING iv_broker        TYPE zif_broker_types=>ty_e_broker
        RETURNING VALUE(rv_exists) TYPE abap_bool,
      delete
        IMPORTING iv_broker TYPE zif_broker_types=>ty_e_broker
        RAISING   zcx_broker,
      get_all
        RETURNING VALUE(rt_brokers) TYPE zif_broker_types=>ty_t_broker,
      update_status
        IMPORTING iv_broker TYPE zif_broker_types=>ty_e_broker
                  iv_status TYPE c
        RAISING   zcx_broker.
ENDCLASS.

CLASS zcl_broker_dba IMPLEMENTATION.
  METHOD create.
    DATA lv_ts TYPE timestamp.
    DATA ls_row TYPE zcl_l_broker.
    GET TIME STAMP FIELD lv_ts.
    ls_row = VALUE #(
        broker      = is_broker-broker
        description = is_broker-description
        status      = is_broker-status
        created_by  = sy-uname
        created_ts  = lv_ts ).
    INSERT zcl_l_broker FROM ls_row.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_broker
        EXPORTING mv_text = |Broker { is_broker-broker } already exists|.
    ENDIF.
  ENDMETHOD.

  METHOD get.
    SELECT SINGLE broker, description, status
      FROM zcl_l_broker
      WHERE broker = @iv_broker
      INTO CORRESPONDING FIELDS OF @rs_broker.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_broker
        EXPORTING mv_text = |Broker { iv_broker } not found|.
    ENDIF.
  ENDMETHOD.

  METHOD does_exist.
    SELECT SINGLE @abap_true FROM zcl_l_broker
      WHERE broker = @iv_broker
      INTO @rv_exists.
  ENDMETHOD.

  METHOD delete.
    DELETE FROM zcl_l_broker WHERE broker = iv_broker.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_broker
        EXPORTING mv_text = |Broker { iv_broker } not found for deletion|.
    ENDIF.
  ENDMETHOD.

  METHOD get_all.
    SELECT broker, description, status FROM zcl_l_broker
      INTO CORRESPONDING FIELDS OF TABLE @rt_brokers.
  ENDMETHOD.

  METHOD update_status.
    UPDATE zcl_l_broker SET status = iv_status
      WHERE broker = iv_broker.
  ENDMETHOD.
ENDCLASS.
