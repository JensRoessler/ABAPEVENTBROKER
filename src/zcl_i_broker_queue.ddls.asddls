@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Broker Queue'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZCL_I_BROKER_QUEUE
  as select from zcl_l_queue
  association to parent ZCL_I_BROKER as _Broker on $projection.Broker = _Broker.Broker
  composition [0..*] of ZCL_I_BROKER_Q_SUB as _Sub
  composition [0..*] of ZCL_I_BROKER_EVENT as _Event
{
  key broker      as Broker,
  key queue       as Queue,
      description as Description,
      _Broker,
      _Sub,
      _Event
}
