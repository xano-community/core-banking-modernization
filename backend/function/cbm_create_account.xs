function "cbm_create_account" {
  description = "Create (or update in place) a core-banking account, keyed on legacy_account_no. If an opening balance is supplied, an opening credit ledger entry is posted so the double-entry ledger reconciles against the stored balance from day one."

  input {
    text legacy_account_no { description = "Legacy core-banking account number (unique key)" }
    text customer_ref? { description = "Your app's customer/owner id" }
    text type?="checking" { description = "Account type: checking, savings, or loan" }
    decimal balance?=0 { description = "Opening balance" }
    text currency?="USD" { description = "ISO currency code" }
  }

  stack {
    db.add_or_edit "cbm_account" {
      field_name = "legacy_account_no"
      field_value = $input.legacy_account_no
      data = {
        legacy_account_no: $input.legacy_account_no,
        customer_ref: $input.customer_ref,
        type: $input.type,
        balance: $input.balance,
        currency: $input.currency,
        status: "active",
        updated_at: now
      }
    } as $account

    conditional {
      if ($input.balance > 0) {
        db.add "cbm_ledger_entry" {
          data = {
            account_id: $account.id,
            transfer_id: null,
            direction: "credit",
            amount: $input.balance,
            balance_after: $input.balance
          }
        } as $opening
      }
    }
  }

  response = $account
  guid = "OTBQiSd0hBVxps_WgGuK5BH0jSQ"
}
