CLASS zcl_broker_config DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS gc_action_ack        TYPE string VALUE 'ACK'.
    CONSTANTS gc_action_fail       TYPE string VALUE 'FAIL'.
    CONSTANTS gc_action_drop       TYPE string VALUE 'DROP'.
    CONSTANTS gc_action_delay      TYPE string VALUE 'DELAY'.
    CONSTANTS gc_action_disconnect TYPE string VALUE 'DISCONNECT'.

    CONSTANTS gc_trigger_every_nth     TYPE string VALUE 'EVERY_NTH'.
    CONSTANTS gc_trigger_after_n_total TYPE string VALUE 'AFTER_N_TOTAL'.
    CONSTANTS gc_trigger_always        TYPE string VALUE 'ALWAYS'.

    TYPES:
      BEGIN OF ty_s_rule,
        trigger   TYPE string,
        nth       TYPE i,
        action    TYPE string,
        delay_sec TYPE i,
      END OF ty_s_rule.
    TYPES ty_t_rules TYPE STANDARD TABLE OF ty_s_rule WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_config,
        default_action TYPE string,
        rules          TYPE ty_t_rules,
      END OF ty_s_config.

    CLASS-METHODS to_json
      IMPORTING is_config      TYPE ty_s_config
      RETURNING VALUE(rv_json) TYPE string.

    CLASS-METHODS from_json
      IMPORTING iv_json         TYPE string
      RETURNING VALUE(rs_config) TYPE ty_s_config.

    CLASS-METHODS get_default
      RETURNING VALUE(rs_config) TYPE ty_s_config.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_broker_config IMPLEMENTATION.

  METHOD to_json.
    CALL TRANSFORMATION id
      SOURCE config = is_config
      RESULT XML rv_json.
  ENDMETHOD.

  METHOD from_json.
    CALL TRANSFORMATION id
      SOURCE XML iv_json
      RESULT config = rs_config.
  ENDMETHOD.

  METHOD get_default.
    rs_config-default_action = gc_action_ack.
    CLEAR rs_config-rules.
  ENDMETHOD.

ENDCLASS.
