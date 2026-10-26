INTERFACE zif_amc_client PUBLIC.
  METHODS:
    send
      IMPORTING
        io_message TYPE REF TO /iwxbe/if_daemon_message
      RAISING
        cx_amc_error
        /iwxbe/cx_exception.
ENDINTERFACE.
