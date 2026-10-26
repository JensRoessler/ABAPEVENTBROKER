@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Queue Subscription'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZCL_I_BROKER_Q_SUB
  as select from zcl_l_q_sub
  association to parent ZCL_I_BROKER_QUEUE as _Queue on  $projection.Broker = _Queue.Broker
                                                     and $projection.Queue  = _Queue.Queue
  association        to ZCL_I_BROKER       as _Broker on $projection.Broker = _Broker.Broker
{
  key broker as Broker,
  key queue  as Queue,
  key topic  as Topic,
      _Queue,
      _Broker
}
