CLASS zcl_broker_factory DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS:
      start
        IMPORTING
          is_config TYPE zcl_broker_config=>ty_s_config
        RAISING
          /iwxbe/cx_exception,
      delete_channel
        RAISING
          /iwxbe/cx_exception.

  PRIVATE SECTION.
    CONSTANTS:
      gc_start_timeout_sec TYPE i VALUE 30.

    CLASS-METHODS:
      get_channel
        RETURNING
          VALUE(ro_channel) TYPE REF TO /iwxbe/if_channel_cfg
        RAISING
          /iwxbe/cx_exception.
ENDCLASS.



CLASS zcl_broker_factory IMPLEMENTATION.

  METHOD get_channel.
    IF /iwxbe/cl_channel=>does_exist( 'TESTBROKER' ) = abap_true.
      ro_channel = CAST #( /iwxbe/cl_channel=>get( 'TESTBROKER' ) ).
    ELSE.
      ro_channel = CAST #( /iwxbe/cl_channel=>create_test_broker( ) ).
    ENDIF.
  ENDMETHOD.

  METHOD start.
    DATA(lo_channel) = get_channel( ).
    TRY.
        lo_channel->get_outbound_binding( '*' ).
      CATCH /iwxbe/cx_exception.
        lo_channel->create_outbound_binding(
          iv_topic        = 'sap/eee/iwxbe/testproducer/v1/Event/Created/v1'
          is_producer_key = VALUE #( repository_id = /iwxbe/if_registry_types=>gcs_repository_id-default
                                     id            = '/IWXBE/TESTPRODUCER'
                                     version       = '1' ) ).
    ENDTRY.
    lo_channel->activate( ).
    lo_channel->save( ).

    DATA lv_elapsed TYPE i.
    DATA(lo_daemon_manager) = /iwxbe/cl_daemon_manager=>create( CAST #( lo_channel ) ).
    WHILE lo_daemon_manager->is_daemon_running( 'ZCL_BROKER_DAEMON' ) = abap_false.
      IF lv_elapsed >= gc_start_timeout_sec.
        RAISE EXCEPTION NEW /iwxbe/cx_daemon( textid = /iwxbe/cx_daemon=>daemon_start_failed ).
      ENDIF.
      WAIT UP TO 1 SECONDS.
      ADD 1 TO lv_elapsed.
    ENDWHILE.

    DATA(lt_instances) = lo_daemon_manager->get_running_daemons( 'ZCL_BROKER_DAEMON' ).
    CHECK lt_instances IS NOT INITIAL.

    lo_daemon_manager->send_message(
      it_instance_id = VALUE #( FOR ls IN lt_instances ( ls-instance_id ) )
      io_message     = zcl_broker_daemon_message=>create_config(
                         zcl_broker_config=>to_json( is_config ) ) ).
  ENDMETHOD.

  METHOD delete_channel.
    get_channel( )->delete( ).
    get_channel( )->save( ).
  ENDMETHOD.

ENDCLASS.
