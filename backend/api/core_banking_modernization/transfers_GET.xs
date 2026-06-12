// List transfers, optionally filtered by status.
query "transfers" verb=GET {
  api_group = "CoreBankingModernization"

  input {
    text status? { description = "Filter to one status (pending, pending_approval, completed, rejected, ...)" }
    int page?=1 filters=min:1
    int per_page?=50 filters=min:1|max:200
  }

  stack {
    db.query "cbm_transfer" {
      where = $db.cbm_transfer.status ==? $input.status
      sort = {created_at: "desc"}
      return = {type: "list", paging: {page: $input.page, per_page: $input.per_page, totals: true}}
    } as $transfers
  }

  response = $transfers
  guid = "dkX7eXlIZ2rbwr0ubdNBmoUV6TY"
}
