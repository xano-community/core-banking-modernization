table "cbm_transfer" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    timestamp completed_at?
    text from_account filters=trim
    text to_account filters=trim
    decimal amount
    text currency?="USD" filters=trim|upper
    enum status?="pending" {
      values = ["pending", "pending_approval", "approved", "completed", "rejected", "failed"]
    }
    int fraud_score?
    text reason?
    text requested_by?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree", field: [{name: "from_account"}]}
  ]
  guid = "qx_34u48KXEpf7Mc8PViK5OGpVQ"
}
