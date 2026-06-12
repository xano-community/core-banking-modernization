// List core-banking accounts, optionally filtered by status.
query "accounts" verb=GET {
  api_group = "CoreBankingModernization"

  input {
    text status? { description = "Filter to one status: active, frozen, or closed" }
    int page?=1 filters=min:1
    int per_page?=50 filters=min:1|max:200
  }

  stack {
    db.query "cbm_account" {
      where = $db.cbm_account.status ==? $input.status
      sort = {created_at: "desc"}
      return = {type: "list", paging: {page: $input.page, per_page: $input.per_page, totals: true}}
    } as $accounts
  }

  response = $accounts
  guid = "NdPIlRpISJnOdervdB699xVbn8A"
}
