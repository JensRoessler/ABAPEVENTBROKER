INTERFACE zif_queue PUBLIC.
  METHODS:
    get_name
      RETURNING VALUE(rv_queue) TYPE zif_broker_types=>ty_e_queue,
    add_subscription
      IMPORTING iv_topic TYPE /iwxbe/descr_topic
      RAISING   zcx_broker,
    remove_subscription
      IMPORTING iv_topic TYPE /iwxbe/descr_topic
      RAISING   zcx_broker,
    get_subscriptions
      RETURNING VALUE(rt_subs) TYPE zif_broker_types=>ty_t_q_sub,
    get_events
      RETURNING VALUE(rt_events) TYPE zif_broker_types=>ty_t_event,
    delete
      RAISING zcx_broker,
    save
      RAISING zcx_broker.
ENDINTERFACE.
