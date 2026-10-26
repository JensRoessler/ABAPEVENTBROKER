CLASS zcl_broker_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS:
      create_broker
        IMPORTING
          iv_broker      TYPE zif_broker_types=>ty_e_broker
          iv_description TYPE string OPTIONAL
        RAISING
          zcx_broker
          /iwxbe/cx_exception,

      delete_broker
        IMPORTING
          iv_broker TYPE zif_broker_types=>ty_e_broker
        RAISING
          zcx_broker
          /iwxbe/cx_exception,

      reconfigure_broker
        IMPORTING
          iv_broker TYPE zif_broker_types=>ty_e_broker
        RAISING
          zcx_broker
          /iwxbe/cx_exception,

      stop_broker_daemon
        RAISING
          /iwxbe/cx_exception.

  PRIVATE SECTION.
    CONSTANTS:
      gc_start_timeout_sec TYPE i VALUE 30,
      gc_daemon_class      TYPE abap_daemon_class_name VALUE 'ZCL_BROKER_DAEMON',
      gc_daemon_name       TYPE abap_daemon_name VALUE 'TESTBROKER'.

    CLASS-METHODS:
      get_channel
        RETURNING
          VALUE(ro_channel) TYPE REF TO /iwxbe/if_channel_cfg
        RAISING
          /iwxbe/cx_exception,

      create_daemon_config
        RAISING
          /iwxbe/cx_exception,

      start_broker_daemon
        RAISING
          /iwxbe/cx_exception.

ENDCLASS.



CLASS zcl_broker_service IMPLEMENTATION.

  METHOD get_channel.
    IF /iwxbe/cl_channel=>does_exist( 'TESTBROKER' ) = abap_true.
      ro_channel = CAST #( /iwxbe/cl_channel=>get( 'TESTBROKER' ) ).
    ELSE.
      ro_channel = CAST #( /iwxbe/cl_channel=>create_test_broker( ) ).
    ENDIF.

    TRY.
        ro_channel->create_outbound_binding(
            iv_topic        = 'sap/eee/iwxbe/testproducer/v1/Event/Created/v1'
            is_producer_key = VALUE #(
                repository_id = /iwxbe/if_registry_types=>gcs_repository_id-default
                id            = '/IWXBE/TESTPRODUCER'
                version       = '1' ) ).
      CATCH /iwxbe/cx_channel ##NO_HANDLER.
        " binding already exists — idempotent
    ENDTRY.
  ENDMETHOD.

  METHOD create_broker.
    IF zcl_broker=>does_exist( iv_broker ) = abap_true.
      RAISE EXCEPTION TYPE zcx_broker
        EXPORTING mv_text = |Broker { iv_broker } already exists|.
    ENDIF.

    zcl_broker=>create_instance(
        iv_broker      = iv_broker
        iv_description = iv_description
    )->save( ).

    DATA(lo_channel) = get_channel( ).
    lo_channel->activate( ).
    lo_channel->save( ).

    create_daemon_config( ).

    WAIT UP TO 5 seconds.

    start_broker_daemon( ).

    DATA lv_elapsed TYPE i.
    DATA(lo_daemon_manager) = /iwxbe/cl_daemon_manager=>create( CAST #( lo_channel ) ).
    WHILE lo_daemon_manager->is_daemon_running( gc_daemon_class ) = abap_false.
      IF lv_elapsed >= gc_start_timeout_sec.
        zcl_broker_dba=>update_status( iv_broker = iv_broker iv_status = 'D' ).
        RETURN.
      ENDIF.
      WAIT UP TO 1 SECONDS.
      ADD 1 TO lv_elapsed.
    ENDWHILE.

    zcl_broker_dba=>update_status( iv_broker = iv_broker iv_status = 'A' ).
  ENDMETHOD.

  METHOD delete_broker.
    IF zcl_broker=>does_exist( iv_broker ) = abap_false.
      RAISE EXCEPTION TYPE zcx_broker
        EXPORTING mv_text = |Broker { iv_broker } does not exist|.
    ENDIF.

    stop_broker_daemon( ).

    get_channel( )->delete( ).
    get_channel( )->save( ).

    DATA(lo_broker) = zcl_broker=>get( iv_broker ).
    lo_broker->delete( ).
    lo_broker->save( ).
  ENDMETHOD.

  METHOD create_daemon_config.
    TRY.
        DATA(lo_params) = cl_ac_message_type_pcp=>create( ).
        lo_params->set_field(
            i_name  = /iwxbe/if_daemon_message_types=>gcs_message_field-channel
            i_value = CONV #( gc_daemon_name ) ).

        DATA(lo_startup) = cl_abap_daemon_startup_manager=>create_for_secure_env( ).
        IF lo_startup->exists_daemon( i_class_name = gc_daemon_class i_name = gc_daemon_name ) = abap_false.
          lo_startup->insert_by_trusted_user(
              i_class_name    = gc_daemon_class
              i_name          = gc_daemon_name
              i_user_name     = sy-uname
              i_parameter     = lo_params
              i_language      = sy-langu
              i_topology_type = if_abap_daemon_startup_config=>startup_topology_type-server_group
              i_instances     = 1 ).
          lo_startup->execute( ).
        ENDIF.
      CATCH cx_abap_daemon_startup_error cx_ac_message_type_pcp_error INTO DATA(lx).
        RAISE EXCEPTION NEW /iwxbe/cx_daemon( previous = lx
                                              textid   = /iwxbe/cx_daemon=>daemon_start_failed ).
    ENDTRY.
  ENDMETHOD.

  METHOD start_broker_daemon.
    TRY.
        DATA(lo_startup) = cl_abap_daemon_startup_manager=>create_for_secure_env( ).
        lo_startup->unlock( i_class_name = gc_daemon_class i_name = gc_daemon_name ).
        lo_startup->execute( ).
      CATCH cx_abap_daemon_startup_error INTO DATA(lx).
        RAISE EXCEPTION NEW /iwxbe/cx_daemon( previous = lx
                                              textid   = /iwxbe/cx_daemon=>daemon_start_failed ).
    ENDTRY.
  ENDMETHOD.

  METHOD stop_broker_daemon.
    TRY.
        DATA(lo_startup) = cl_abap_daemon_startup_manager=>create_for_current_program( ).
        IF lo_startup->exists_daemon( i_class_name = gc_daemon_class i_name = gc_daemon_name ).
          lo_startup->lock( i_class_name = gc_daemon_class i_name = gc_daemon_name ).
          lo_startup->delete(
              i_class_name = gc_daemon_class
              i_name       = gc_daemon_name ).
          lo_startup->execute( ).
        ENDIF.
      CATCH cx_abap_daemon_startup_error INTO DATA(lx).
        RAISE EXCEPTION NEW /iwxbe/cx_daemon( previous = lx
                                              textid   = /iwxbe/cx_daemon=>daemon_stop_failed ).
    ENDTRY.
  ENDMETHOD.

  METHOD reconfigure_broker.
    " Guard: broker must exist
    IF zcl_broker=>does_exist( iv_broker ) = abap_false.
      RAISE EXCEPTION TYPE zcx_broker
        EXPORTING mv_text = |Broker { iv_broker } does not exist|.
    ENDIF.

    " Send RECONFIGURE control message to the running broker daemon instance(s)
    " via the daemon handle. The daemon framework only accepts handle messages
    " from the owning caller class (this service), which is the security model
    " for control traffic. The message lands in ZCL_BROKER_DAEMON->handle_message.
    TRY.
        DATA(lt_info) = cl_abap_daemon_client_manager=>get_daemon_info( gc_daemon_class ).
        DATA(lo_pcp)  = zcl_broker_daemon_message=>create_reconfigure(
                                                     )->convert_to_pcp_message( CONV #( gc_daemon_name ) ).

        LOOP AT lt_info ASSIGNING FIELD-SYMBOL(<ls_info>) WHERE name = gc_daemon_name.
          DATA(lo_handle) = cl_abap_daemon_client_manager=>attach( <ls_info>-instance_id ).
          lo_handle->send( lo_pcp ).
        ENDLOOP.

      CATCH cx_abap_daemon_error cx_ac_message_type_pcp_error /iwxbe/cx_exception INTO DATA(lx).
        RAISE EXCEPTION NEW /iwxbe/cx_daemon( previous = lx ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
