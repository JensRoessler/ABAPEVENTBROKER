"! <p class="shorttext synchronized">EEE - Daemon manager for test broker plan (PoC)</p>
"! Starts ZCL_DAEMON_PUBLISH_BROKER and ZCL_BROKER_DAEMON in addition to
"! the standard consume and subscribe daemons.
CLASS zcl_daemon_manager_test DEFINITION
  PUBLIC
  INHERITING FROM /iwxbe/cl_daemon_manager
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING
          io_channel TYPE REF TO /iwxbe/if_channel.

ENDCLASS.



CLASS zcl_daemon_manager_test IMPLEMENTATION.

  METHOD constructor.
    super->constructor(
      io_channel       = io_channel
      it_daemon_config = VALUE #(
        ( class_name          = /iwxbe/if_daemon_types=>gcs_daemon_class-consume
          number_of_instances = gc_min_no_of_daemons )
        ( class_name          = /iwxbe/if_daemon_types=>gcs_daemon_class-subscribe
          number_of_instances = gc_min_no_of_daemons )
        ( class_name          = 'ZCL_DAEMON_PUBLISH_BROKER'
          number_of_instances = gc_min_no_of_daemons )
        ( class_name          = 'ZCL_BROKER_DAEMON'
          number_of_instances = gc_min_no_of_daemons ) ) ).
  ENDMETHOD.

ENDCLASS.
