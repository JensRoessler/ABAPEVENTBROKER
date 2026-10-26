@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Broker Root'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: [ 'Broker' ]
define root view entity ZCL_I_BROKER
  as select from zcl_l_broker
  composition [0..*] of ZCL_I_BROKER_QUEUE as _Queue
{
  key broker      as Broker,
      description as Description,
      status      as Status,
      created_by  as CreatedBy,
      created_ts  as CreatedTs,
      _Queue
}
