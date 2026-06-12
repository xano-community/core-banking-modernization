table "cbm_account" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    timestamp updated_at?
    text legacy_account_no filters=trim
    text customer_ref? filters=trim
    enum type?="checking" {
      values = ["checking", "savings", "loan"]
    }
    text currency?="USD" filters=trim|upper
    decimal balance?=0
    enum status?="active" {
      values = ["active", "frozen", "closed"]
    }
    int risk_score?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "legacy_account_no"}]}
    {type: "btree", field: [{name: "customer_ref"}]}
    {type: "btree", field: [{name: "status"}]}
  ]
  guid = "NPQ0og-dg0zoAUsp6IvErDQ9kMM"
}
