INTERFACE zif_amc_client_handler PUBLIC.
  METHODS:
    on_connect
      RAISING /iwxbe/cx_exception,
    on_disconnect
      RAISING /iwxbe/cx_exception,
    on_message
      IMPORTING io_message TYPE REF TO /iwxbe/if_daemon_message
      RAISING   /iwxbe/cx_exception.
ENDINTERFACE.
