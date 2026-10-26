INTERFACE zif_broker PUBLIC.
  TYPES ty_t_queue_ref TYPE STANDARD TABLE OF REF TO zif_queue WITH DEFAULT KEY.
  METHODS:
    get_config
      RETURNING VALUE(rs_config) TYPE zif_broker_types=>ty_s_broker,
    add_queue
      IMPORTING iv_queue       TYPE zif_broker_types=>ty_e_queue
                iv_description TYPE string OPTIONAL
      RETURNING VALUE(ro_queue) TYPE REF TO zif_queue
      RAISING   zcx_broker,
    delete_queue
      IMPORTING iv_queue TYPE zif_broker_types=>ty_e_queue
      RAISING   zcx_broker,
    get_queues
      RETURNING VALUE(rt_queues) TYPE zif_broker=>ty_t_queue_ref,
    delete
      RAISING zcx_broker,
    save
      RAISING zcx_broker.
ENDINTERFACE.
