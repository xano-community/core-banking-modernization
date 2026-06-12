function "cbm_reconcile" {
  description = "Reconcile a core-banking account's stored balance against its double-entry ledger (sum of credits minus sum of debits), and optionally against a legacy system's reported balance. Returns the stored balance, the computed ledger balance, both discrepancies, and an in_sync flag (ledger ties out within a half-cent)."

  input {
    text legacy_account_no { description = "Account to reconcile" }
    decimal legacy_balance? { description = "Balance reported by the legacy system, for cross-check" }
  }

  stack {
    db.get "cbm_account" {
      field_name = "legacy_account_no"
      field_value = $input.legacy_account_no
    } as $account

    precondition ($account != null) {
      error_type = "notfound"
      error = "Account not found"
    }

    db.query "cbm_ledger_entry" {
      where = $db.cbm_ledger_entry.account_id == $account.id && $db.cbm_ledger_entry.direction == "credit"
      return = {type: "list"}
    } as $credits
    db.query "cbm_ledger_entry" {
      where = $db.cbm_ledger_entry.account_id == $account.id && $db.cbm_ledger_entry.direction == "debit"
      return = {type: "list"}
    } as $debits

    var $credit_total { value = (($credits|map:$$.amount)|sum) }
    var $debit_total { value = (($debits|map:$$.amount)|sum) }
    var $computed { value = (($credit_total) - ($debit_total)) }

    var $discrepancy { value = (($account.balance) - ($computed)) }

    var $legacy_discrepancy { value = null }
    conditional {
      if ($input.legacy_balance != null) {
        var.update $legacy_discrepancy { value = (($account.balance) - ($input.legacy_balance)) }
      }
    }

    var $in_sync { value = false }
    conditional {
      if ($discrepancy < 0.005 && $discrepancy > -0.005) {
        var.update $in_sync { value = true }
      }
    }
  }

  response = {
    account_balance: $account.balance,
    computed_ledger_balance: $computed,
    legacy_balance: $input.legacy_balance,
    discrepancy: $discrepancy,
    legacy_discrepancy: $legacy_discrepancy,
    in_sync: $in_sync
  }
  guid = "uA7x1FnhEQVoGe2X1Ez8_TOYfhE"
}
