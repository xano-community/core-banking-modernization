table "cbm_fraud_flag" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int transfer_id?
    int account_id?
    text rule
    int score
    json detail?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "transfer_id"}]}
    {type: "btree", field: [{name: "account_id"}]}
  ]
  guid = "j_ndDcdO9aldQCz_6uRA6Z23dqg"
}
