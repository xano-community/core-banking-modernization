// Create or update a core-banking account (posts an opening ledger entry if funded).
query "accounts" verb=POST {
  api_group = "CoreBankingModernization"

  input {
    text legacy_account_no { description = "Legacy core-banking account number (unique key)" }
    text customer_ref? { description = "Your app's customer/owner id" }
    text type?="checking" { description = "Account type: checking, savings, or loan" }
    decimal balance?=0 { description = "Opening balance" }
    text currency?="USD" { description = "ISO currency code" }
  }

  stack {
    function.run "cbm_create_account" {
      input = {legacy_account_no: $input.legacy_account_no, customer_ref: $input.customer_ref, type: $input.type, balance: $input.balance, currency: $input.currency}
    } as $result
  }

  response = $result
  guid = "9_P0p8dgAKuOBzgvEugUeV_BM4I"
}
