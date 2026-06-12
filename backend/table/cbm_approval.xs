table "cbm_approval" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    timestamp decided_at?
    int transfer_id? {
      table = "cbm_transfer"
    }
    enum status?="pending" {
      values = ["pending", "approved", "rejected"]
    }
    text approver?
    decimal threshold_amount?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "transfer_id"}]}
    {type: "btree", field: [{name: "status"}]}
  ]
  guid = "KpAl0DR-tMMZcI_4OR3EeKpL0_g"
}
