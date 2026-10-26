@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Broker Event'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZCL_I_BROKER_EVENT
  as select from zcl_l_event_q
  association to parent ZCL_I_BROKER_QUEUE as _Queue on  $projection.Broker = _Queue.Broker
                                                     and $projection.Queue  = _Queue.Queue
  association        to ZCL_I_BROKER       as _Broker on $projection.Broker = _Broker.Broker
{
  key broker       as Broker,
  key queue        as Queue,
  key topic        as Topic,
  key event_id     as EventId,
      arrival_time as ArrivalTime,
      status       as Status,
      _Queue,
      _Broker
}
