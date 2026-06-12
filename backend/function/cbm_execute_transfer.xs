function "cbm_execute_transfer" {
  description = "Settle an existing transfer: debit the source account, credit the destination account (if it exists in core banking), post matching double-entry ledger rows, and mark the transfer completed. Idempotency is the caller's responsibility — call only on a transfer that is cleared to settle."

  input {
    int transfer_id { description = "Id of the cbm_transfer row to settle" }
  }

  stack {
    db.get "cbm_transfer" {
      field_name = "id"
      field_value = $input.transfer_id
    } as $transfer

    precondition ($transfer != null) {
      error_type = "notfound"
      error = "Transfer not found"
    }

    db.get "cbm_account" {
      field_name = "legacy_account_no"
      field_value = $transfer.from_account
    } as $from

    precondition ($from != null) {
      error_type = "notfound"
      error = "Source account not found"
    }

    var $amount { value = $transfer.amount }
    var $newfrom { value = (($from.balance) - ($amount)) }

    db.edit "cbm_account" {
      field_name = "id"
      field_value = $from.id
      data = {
        balance: $newfrom,
        updated_at: now
      }
    } as $from_updated

    db.add "cbm_ledger_entry" {
      data = {
        account_id: $from.id,
        transfer_id: $transfer.id,
        direction: "debit",
        amount: $amount,
        balance_after: $newfrom
      }
    } as $debit_entry

    db.get "cbm_account" {
      field_name = "legacy_account_no"
      field_value = $transfer.to_account
    } as $to

    conditional {
      if ($to != null) {
        var $newto { value = (($to.balance) + ($amount)) }
        db.edit "cbm_account" {
          field_name = "id"
          field_value = $to.id
          data = {
            balance: $newto,
            updated_at: now
          }
        } as $to_updated
        db.add "cbm_ledger_entry" {
          data = {
            account_id: $to.id,
            transfer_id: $transfer.id,
            direction: "credit",
            amount: $amount,
            balance_after: $newto
          }
        } as $credit_entry
      }
    }

    db.edit "cbm_transfer" {
      field_name = "id"
      field_value = $transfer.id
      data = {
        status: "completed",
        completed_at: now
      }
    } as $settled
  }

  response = $settled
  guid = "tGjJFceUJp85XYTdk6tyYx3WOvo"
}
