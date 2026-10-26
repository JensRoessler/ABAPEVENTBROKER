"! <p class="shorttext synchronized">EEE - Test Broker Plan Channel (PoC)</p>
CLASS zcl_channel_test_broker DEFINITION
    PUBLIC
    INHERITING FROM /iwxbe/cl_channel
    CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING
          iv_data_state      TYPE /iwxbe/if_runtime_types=>ty_data_state
          iv_is_active       TYPE /iwxbe/channel_active
          iv_changed_ts      TYPE tzntstmps OPTIONAL
          iv_changed_by      TYPE uname OPTIONAL.

  PROTECTED SECTION.
    METHODS:
      check_subscription_properties REDEFINITION.

  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_channel_test_broker IMPLEMENTATION.


  METHOD check_subscription_properties.

    CONSTANTS: lc_max_number_of_subscriptions TYPE i VALUE 10.


    super->check_subscription_properties( iv_address       = iv_address
                                          iv_type_kind     = iv_type_kind
                                          iv_event_purpose = iv_event_purpose ).

    " only 10 subscriptions are allowed per test broker channel
    " (mirrors default plan limitation to 10 AMQP receivers)
    IF get_number_of_subscriptions( ) >= lc_max_number_of_subscriptions.
      RAISE EXCEPTION NEW /iwxbe/cx_channel( textid       = /iwxbe/cx_channel=>subscription_limit_exceeded
                                             channel_name = get_channel_name( ) ).
    ENDIF.

    " check type kind
    IF iv_type_kind = /iwxbe/if_channel_types=>gcs_subscription_type_kind-raw_address.
      " Raw address subscription only allowed for sap managed channel
      RAISE EXCEPTION NEW /iwxbe/cx_channel( textid               = /iwxbe/cx_channel=>raw_address_sub_not_allowed
                                             channel_name         = get_channel_name( )
                                             subscription_address = iv_address ).
    ENDIF.

    " check if namespace of EMS i.e. topic space of channel matches first three segments
    /iwxbe/cl_topic_syntax=>check_topic_space_of_queue( iv_queue_address = iv_address
                                                        iv_topic_space   = get_topic_space( ) ).

    IF iv_event_purpose <> /iwxbe/if_runtime_types=>gcs_event_purpose-business_event.
      " only business event subscriptions allowed for user managed channels
      RAISE EXCEPTION NEW /iwxbe/cx_channel(
                              textid                     = /iwxbe/cx_channel=>subscript_purpose_not_allowed
                              channel_name               = get_channel_name( )
                              subscription_event_purpose = iv_event_purpose ).
    ENDIF.

  ENDMETHOD.


  METHOD constructor.

    super->constructor( iv_channel_name    = 'TESTBROKER'
                        iv_data_state      = iv_data_state
                        iv_description     = 'Channel to TestBroker'
                        iv_destination     = ''
                        iv_is_active       = iv_is_active
                        iv_management_type = /iwxbe/if_channel_types=>gcs_channel_management_types-customer
                        iv_protocol        = /iwxbe/if_channel_types=>gcs_messaging_protocols-amc
                        iv_topic_space     = 'ABAP/EVENT/BROKER'
                        iv_service_plan    = /iwxbe/if_channel_types=>ges_event_mesh_service_plan-test
                        iv_status          = /iwxbe/if_channel_types=>ges_status-ok
                        iv_status_error_id = ''
                        iv_changed_ts      = iv_changed_ts
                        iv_changed_by      = iv_changed_by ).

    IF /iwxbe/if_channel_cfg~does_parameter_exist( /iwxbe/if_channel_types=>gcs_parameter_name-daemon_user ) = abap_false.
      /iwxbe/if_channel_cfg~create_parameter(
        iv_name  = /iwxbe/if_channel_types=>gcs_parameter_name-daemon_user
        iv_value = CONV #( sy-uname ) ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
