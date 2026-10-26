INTERFACE zif_broker_types PUBLIC.
  TYPES:
    ty_e_broker      TYPE c LENGTH 30,
    ty_e_queue       TYPE c LENGTH 30,
    ty_en_data_state TYPE n LENGTH 1.

  CONSTANTS:
    BEGIN OF gcs_data_state,
      unchanged TYPE zif_broker_types=>ty_en_data_state VALUE '0',
      new       TYPE zif_broker_types=>ty_en_data_state VALUE '1',
      deleted   TYPE zif_broker_types=>ty_en_data_state VALUE '2',
      modified  TYPE zif_broker_types=>ty_en_data_state VALUE '3',
    END OF gcs_data_state.

  TYPES:
    BEGIN OF ty_s_broker,
      broker      TYPE zif_broker_types=>ty_e_broker,
      description TYPE string,
      status      TYPE c LENGTH 1,
    END OF ty_s_broker,
    ty_t_broker TYPE STANDARD TABLE OF ty_s_broker WITH DEFAULT KEY,

    BEGIN OF ty_s_q_sub,
      topic      TYPE /iwxbe/descr_topic,
      data_state TYPE zif_broker_types=>ty_en_data_state,
    END OF ty_s_q_sub,
    ty_t_q_sub TYPE SORTED TABLE OF ty_s_q_sub WITH UNIQUE KEY topic,

    BEGIN OF ty_s_queue,
      queue       TYPE zif_broker_types=>ty_e_queue,
      description TYPE string,
      data_state  TYPE zif_broker_types=>ty_en_data_state,
    END OF ty_s_queue,
    ty_t_queue TYPE STANDARD TABLE OF ty_s_queue WITH DEFAULT KEY,

    BEGIN OF ty_s_event,
      broker       TYPE zif_broker_types=>ty_e_broker,
      queue        TYPE zif_broker_types=>ty_e_queue,
      topic        TYPE /iwxbe/descr_topic,
      event_id     TYPE sysuuid_c32,
      payload      TYPE xstring,
      arrival_time TYPE timestamp,
      status       TYPE c LENGTH 1,
    END OF ty_s_event,
    ty_t_event TYPE STANDARD TABLE OF ty_s_event WITH DEFAULT KEY.
ENDINTERFACE.
