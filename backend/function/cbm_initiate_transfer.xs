function "cbm_initiate_transfer" {
  description = "Initiate a transfer from a legacy core-banking account. Validates the source account is active and funded, runs the fraud rules engine, and either settles the transfer immediately, routes it to manual approval (high fraud risk or amount at/above the approval threshold), or rejects it. Returns the resulting cbm_transfer row."

  input {
    text from_account { description = "Source legacy account number" }
    text to_account { description = "Destination legacy account number" }
    decimal amount { description = "Transfer amount" }
    text requested_by? { description = "Who requested the transfer" }
    decimal approval_threshold?=5000 { description = "Amount at/above which the transfer requires manual approval" }
    bool is_new_payee?=false { description = "True if the recipient has not been paid before" }
    bool recipient_blocklisted?=false { description = "True if the recipient is on a blocklist" }
  }

  stack {
    db.get "cbm_account" {
      field_name = "legacy_account_no"
      field_value = $input.from_account
    } as $from

    precondition ($from != null) {
      error_type = "notfound"
      error = "Source account not found"
    }

    var $result { value = null }

    conditional {
      if ($from.status != "active") {
        db.add "cbm_transfer" {
          data = {
            from_account: $input.from_account,
            to_account: $input.to_account,
            amount: $input.amount,
            status: "rejected",
            fraud_score: 0,
            reason: ("account_" ~ $from.status),
            requested_by: $input.requested_by
          }
        } as $rejected
        var.update $result { value = $rejected }
      }
      elseif ($from.balance < $input.amount) {
        db.add "cbm_transfer" {
          data = {
            from_account: $input.from_account,
            to_account: $input.to_account,
            amount: $input.amount,
            status: "rejected",
            fraud_score: 0,
            reason: "insufficient_funds",
            requested_by: $input.requested_by
          }
        } as $rejected
        var.update $result { value = $rejected }
      }
      else {
        var $since { value = (now - 86400000) }
        db.query "cbm_ledger_entry" {
          where = $db.cbm_ledger_entry.account_id == $from.id && $db.cbm_ledger_entry.direction == "debit" && $db.cbm_ledger_entry.created_at >= $since
          return = {type: "list"}
        } as $debits
        var $daily { value = (($debits|map:$$.amount)|sum) }

        function.run "cbm_fraud_check" {
          input = {
            from_status: $from.status,
            amount: $input.amount,
            daily_total_so_far: $daily,
            is_new_payee: $input.is_new_payee,
            recipient_blocklisted: $input.recipient_blocklisted
          }
        } as $fraud

        conditional {
          if ($fraud.risk == "high" || $input.amount >= $input.approval_threshold) {
            db.add "cbm_transfer" {
              data = {
                from_account: $input.from_account,
                to_account: $input.to_account,
                amount: $input.amount,
                status: "pending_approval",
                fraud_score: $fraud.score,
                requested_by: $input.requested_by
              }
            } as $pending

            foreach ($fraud.flags) {
              each as $flag {
                db.add "cbm_fraud_flag" {
                  data = {
                    transfer_id: $pending.id,
                    account_id: $from.id,
                    rule: $flag.rule,
                    score: $flag.score,
                    detail: $flag
                  }
                } as $ff
              }
            }

            db.add "cbm_approval" {
              data = {
                transfer_id: $pending.id,
                status: "pending",
                threshold_amount: $input.approval_threshold
              }
            } as $approval

            var.update $result { value = $pending }
          }
          else {
            db.add "cbm_transfer" {
              data = {
                from_account: $input.from_account,
                to_account: $input.to_account,
                amount: $input.amount,
                status: "pending",
                fraud_score: $fraud.score,
                requested_by: $input.requested_by
              }
            } as $created

            foreach ($fraud.flags) {
              each as $flag {
                db.add "cbm_fraud_flag" {
                  data = {
                    transfer_id: $created.id,
                    account_id: $from.id,
                    rule: $flag.rule,
                    score: $flag.score,
                    detail: $flag
                  }
                } as $ff
              }
            }

            function.run "cbm_execute_transfer" {
              input = {transfer_id: $created.id}
            } as $settled

            var.update $result { value = $settled }
          }
        }
      }
    }
  }

  response = $result
  guid = "JLWDflEYfh6A7XnO-W7uubciGMk"
}
