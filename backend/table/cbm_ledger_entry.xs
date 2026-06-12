table "cbm_ledger_entry" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int account_id? {
      table = "cbm_account"
    }
    int transfer_id?
    enum direction {
      values = ["debit", "credit"]
    }
    decimal amount
    decimal balance_after?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "account_id"}]}
    {type: "btree", field: [{name: "transfer_id"}]}
    {type: "btree", field: [{name: "direction"}]}
  ]
  guid = "kWJny7oG4Z04xckZm7o2WIW6DCQ"
}
