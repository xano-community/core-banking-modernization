// Reconcile an account's stored balance against its double-entry ledger.
query "reconcile" verb=POST {
  api_group = "CoreBankingModernization"

  input {
    text legacy_account_no { description = "Account to reconcile" }
    decimal legacy_balance? { description = "Balance reported by the legacy system, for cross-check" }
  }

  stack {
    function.run "cbm_reconcile" {
      input = {legacy_account_no: $input.legacy_account_no, legacy_balance: $input.legacy_balance}
    } as $result
  }

  response = $result
  guid = "jzDQzYj3OsP9yDfAmY4AfQhCPmk"
}
