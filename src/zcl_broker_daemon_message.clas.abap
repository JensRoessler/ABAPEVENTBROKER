"! <p class="shorttext synchronized">EEE - Broker inter-daemon message (PoC)</p>
"! Carries a produced event between publish daemon and broker daemon.
"! Use the static factory methods to create specific message types.
CLASS zcl_broker_daemon_message DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES:
      /iwxbe/if_daemon_message.

    CONSTANTS:
      gc_type_event      TYPE /iwxbe/if_daemon_message_types=>ty_e_message_type VALUE 'BROKER_EVENT'      ##NO_TEXT,
      gc_type_ack        TYPE /iwxbe/if_daemon_message_types=>ty_e_message_type VALUE 'BROKER_ACK'        ##NO_TEXT,
      gc_type_fail       TYPE /iwxbe/if_daemon_message_types=>ty_e_message_type VALUE 'BROKER_FAIL'       ##NO_TEXT,
      gc_type_connect    TYPE /iwxbe/if_daemon_message_types=>ty_e_message_type VALUE 'BROKER_CONNECT'    ##NO_TEXT,
      gc_type_disconnect TYPE /iwxbe/if_daemon_message_types=>ty_e_message_type VALUE 'BROKER_DISCONNECT' ##NO_TEXT,
      gc_field_event_id  TYPE /iwxbe/if_daemon_message_types=>ty_s_message_field-name VALUE 'EVENT_ID'    ##NO_TEXT,
      gc_type_config       TYPE /iwxbe/if_daemon_message_types=>ty_e_message_type VALUE 'BROKER_CONFIG'         ##NO_TEXT,
      gc_type_reconfigure  TYPE /iwxbe/if_daemon_message_types=>ty_e_message_type VALUE 'BROKER_RECONFIGURE'    ##NO_TEXT,
      gc_field_config_json TYPE /iwxbe/if_daemon_message_types=>ty_s_message_field-name VALUE 'CONFIG_JSON'     ##NO_TEXT,
      gc_field_broker      TYPE /iwxbe/if_daemon_message_types=>ty_s_message_field-name VALUE 'BROKER'          ##NO_TEXT,
      gc_field_topic       TYPE /iwxbe/if_daemon_message_types=>ty_s_message_field-name VALUE 'TOPIC'           ##NO_TEXT.

    CLASS-METHODS:
      "! <p class="shorttext synchronized">Create an event message (publish→broker)</p>
      create_event
        IMPORTING is_event        TYPE /iwxbe/if_runtime_types=>ty_s_produced_event
        RETURNING VALUE(ro_msg)   TYPE REF TO zcl_broker_daemon_message,
      "! <p class="shorttext synchronized">Create an ack message (broker→publish)</p>
      create_ack
        IMPORTING is_event        TYPE /iwxbe/if_runtime_types=>ty_s_produced_event
        RETURNING VALUE(ro_msg)   TYPE REF TO zcl_broker_daemon_message,
      "! <p class="shorttext synchronized">Create a fail message (broker→publish)</p>
      create_fail
        IMPORTING is_event        TYPE /iwxbe/if_runtime_types=>ty_s_produced_event
        RETURNING VALUE(ro_msg)   TYPE REF TO zcl_broker_daemon_message,
      "! <p class="shorttext synchronized">Create a connect message</p>
      create_connect
        RETURNING VALUE(ro_msg)   TYPE REF TO zcl_broker_daemon_message,
      "! <p class="shorttext synchronized">Create a disconnect message</p>
      create_disconnect
        RETURNING VALUE(ro_msg)   TYPE REF TO zcl_broker_daemon_message,
      create_config
        IMPORTING iv_config_json  TYPE string
        RETURNING VALUE(ro_msg)   TYPE REF TO zcl_broker_daemon_message,
      create_event_msg
        IMPORTING is_event        TYPE /iwxbe/if_runtime_types=>ty_s_produced_event
                  iv_broker       TYPE zif_broker_types=>ty_e_broker
                  iv_topic        TYPE /iwxbe/descr_topic
        RETURNING VALUE(ro_msg)   TYPE REF TO /iwxbe/if_daemon_message,
      create_reconfigure
        RETURNING VALUE(ro_msg)   TYPE REF TO /iwxbe/if_daemon_message,
      create_ack_for_event
        IMPORTING iv_event_id     TYPE sysuuid_c32
                  iv_broker       TYPE zif_broker_types=>ty_e_broker
        RETURNING VALUE(ro_msg)   TYPE REF TO /iwxbe/if_daemon_message,
      create_fail_for_event
        IMPORTING iv_event_id     TYPE sysuuid_c32
                  iv_broker       TYPE zif_broker_types=>ty_e_broker
        RETURNING VALUE(ro_msg)   TYPE REF TO /iwxbe/if_daemon_message.

    METHODS:
      "! <p class="shorttext synchronized">Return the carried event</p>
      get_event
        RETURNING VALUE(rs_event)  TYPE /iwxbe/if_runtime_types=>ty_s_produced_event,
      get_broker
        RETURNING VALUE(rv_broker) TYPE zif_broker_types=>ty_e_broker,
      get_topic
        RETURNING VALUE(rv_topic)  TYPE /iwxbe/descr_topic.

  PRIVATE SECTION.
    DATA:
      mv_type        TYPE /iwxbe/if_daemon_message_types=>ty_e_message_type,
      ms_event       TYPE /iwxbe/if_runtime_types=>ty_s_produced_event,
      mv_config_json TYPE string,
      mv_broker      TYPE zif_broker_types=>ty_e_broker,
      mv_topic       TYPE /iwxbe/descr_topic.

    METHODS:
      constructor
        IMPORTING
          iv_type        TYPE /iwxbe/if_daemon_message_types=>ty_e_message_type
          is_event       TYPE /iwxbe/if_runtime_types=>ty_s_produced_event OPTIONAL
          iv_config_json TYPE string OPTIONAL.

ENDCLASS.



CLASS zcl_broker_daemon_message IMPLEMENTATION.


  METHOD constructor.
    mv_type        = iv_type.
    ms_event       = is_event.
    mv_config_json = iv_config_json.
  ENDMETHOD.


  METHOD create_event.
    ro_msg = NEW #( iv_type = gc_type_event  is_event = is_event ).
  ENDMETHOD.

  METHOD create_ack.
    ro_msg = NEW #( iv_type = gc_type_ack    is_event = is_event ).
  ENDMETHOD.

  METHOD create_fail.
    ro_msg = NEW #( iv_type = gc_type_fail   is_event = is_event ).
  ENDMETHOD.

  METHOD create_connect.
    ro_msg = NEW #( iv_type = gc_type_connect ).
  ENDMETHOD.

  METHOD create_disconnect.
    ro_msg = NEW #( iv_type = gc_type_disconnect ).
  ENDMETHOD.

  METHOD create_config.
    ro_msg = NEW #( iv_type = gc_type_config iv_config_json = iv_config_json ).
  ENDMETHOD.

  METHOD create_event_msg.
    DATA(lo_msg) = NEW zcl_broker_daemon_message( iv_type = gc_type_event  is_event = is_event ).
    lo_msg->mv_broker = iv_broker.
    lo_msg->mv_topic  = iv_topic.
    ro_msg = lo_msg.
  ENDMETHOD.

  METHOD create_reconfigure.
    ro_msg = NEW zcl_broker_daemon_message( iv_type = gc_type_reconfigure ).
  ENDMETHOD.

  METHOD create_ack_for_event.
    DATA(lo_msg) = NEW zcl_broker_daemon_message( iv_type  = gc_type_ack
                                                  is_event = VALUE #( event_id = iv_event_id ) ).
    lo_msg->mv_broker = iv_broker.
    ro_msg = lo_msg.
  ENDMETHOD.

  METHOD create_fail_for_event.
    DATA(lo_msg) = NEW zcl_broker_daemon_message( iv_type  = gc_type_fail
                                                  is_event = VALUE #( event_id = iv_event_id ) ).
    lo_msg->mv_broker = iv_broker.
    ro_msg = lo_msg.
  ENDMETHOD.


  METHOD get_event.
    rs_event = ms_event.
  ENDMETHOD.

  METHOD get_broker.
    rv_broker = mv_broker.
  ENDMETHOD.

  METHOD get_topic.
    rv_topic = mv_topic.
  ENDMETHOD.


  METHOD /iwxbe/if_daemon_message~get_type.
    rv_type = mv_type.
  ENDMETHOD.


  METHOD /iwxbe/if_daemon_message~get_field.
    CASE iv_name.
      WHEN gc_field_event_id.
        rv_value = CONV #( ms_event-event_id ).
      WHEN gc_field_config_json.
        rv_value = mv_config_json.
      WHEN gc_field_broker.
        rv_value = CONV #( mv_broker ).
      WHEN gc_field_topic.
        rv_value = CONV #( mv_topic ).
    ENDCASE.
  ENDMETHOD.


  METHOD /iwxbe/if_daemon_message~get_fields.
    rt_field = VALUE #(
      ( name = /iwxbe/if_daemon_message_types=>gcs_message_field-type value = mv_type )
      ( name = gc_field_event_id                                       value = CONV #( ms_event-event_id ) )
      ( name = gc_field_config_json                                    value = mv_config_json )
      ( name = gc_field_broker                                         value = CONV #( mv_broker ) )
      ( name = gc_field_topic                                          value = CONV #( mv_topic ) ) ).
  ENDMETHOD.


  METHOD /iwxbe/if_daemon_message~convert_to_pcp_message.
    TRY.
        ro_message = cl_ac_message_type_pcp=>create( ).
        ro_message->set_field( i_name  = /iwxbe/if_daemon_message_types=>gcs_message_field-channel
                               i_value = CONV #( iv_channel_name ) ).
        ro_message->set_field( i_name  = /iwxbe/if_daemon_message_types=>gcs_message_field-type
                               i_value = mv_type ).
        ro_message->set_field( i_name  = gc_field_event_id
                               i_value = CONV #( ms_event-event_id ) ).
        IF mv_config_json IS NOT INITIAL.
          ro_message->set_field( i_name  = gc_field_config_json
                                 i_value = mv_config_json ).
        ENDIF.
        IF mv_broker IS NOT INITIAL.
          ro_message->set_field( i_name  = gc_field_broker
                                 i_value = CONV #( mv_broker ) ).
        ENDIF.
        IF mv_topic IS NOT INITIAL.
          ro_message->set_field( i_name  = gc_field_topic
                                 i_value = CONV #( mv_topic ) ).
        ENDIF.
        IF ms_event-payload IS NOT INITIAL.
          ro_message->set_binary( ms_event-payload ).
        ENDIF.
      CATCH cx_ac_message_type_pcp_error INTO DATA(lx_error).
        RAISE EXCEPTION NEW /iwxbe/cx_daemon( textid   = /iwxbe/cx_daemon=>message_conversion_failed
                                              previous = lx_error ).
    ENDTRY.
  ENDMETHOD.


  METHOD /iwxbe/if_daemon_message~convert_from_pcp_message.
    TRY.
        DATA(lv_type)        = CONV /iwxbe/if_daemon_message_types=>ty_e_message_type(
                                 io_message->get_field( /iwxbe/if_daemon_message_types=>gcs_message_field-type ) ).
        DATA(lv_event_id)    = CONV /iwxbe/if_runtime_types=>ty_s_produced_event-event_id(
                                 io_message->get_field( gc_field_event_id ) ).
        DATA(lv_config_json) = io_message->get_field( gc_field_config_json ).
        DATA(lo_msg)         = NEW zcl_broker_daemon_message(
          iv_type        = lv_type
          is_event       = VALUE #( event_id = lv_event_id )
          iv_config_json = lv_config_json ).
        lo_msg->mv_broker = CONV #( io_message->get_field( gc_field_broker ) ).
        lo_msg->mv_topic  = CONV #( io_message->get_field( gc_field_topic ) ).
        ro_message = lo_msg.
      CATCH cx_ac_message_type_pcp_error INTO DATA(lx_error).
        RAISE EXCEPTION NEW /iwxbe/cx_daemon( textid   = /iwxbe/cx_daemon=>message_conversion_failed
                                              previous = lx_error ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
