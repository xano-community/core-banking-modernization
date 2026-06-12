function "cbm_approve_transfer" {
  description = "Decide a transfer that is awaiting manual approval. On approve, the transfer is settled (debit/credit accounts + ledger postings) and marked completed; on reject it is marked rejected. The matching cbm_approval row is updated with the decision, approver, and decision time. Returns the resulting cbm_transfer row."

  input {
    int transfer_id { description = "Id of the cbm_transfer awaiting approval" }
    text decision { description = "approve or reject" }
    text approver? { description = "Who made the decision" }
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

    precondition ($transfer.status == "pending_approval") {
      error_type = "inputerror"
      error = "Transfer is not awaiting approval"
    }

    db.query "cbm_approval" {
      where = $db.cbm_approval.transfer_id == $transfer.id
      sort = {created_at: "desc"}
      return = {type: "single"}
    } as $approval

    var $result { value = null }

    conditional {
      if ($input.decision == "approve") {
        function.run "cbm_execute_transfer" {
          input = {transfer_id: $transfer.id}
        } as $settled
        var.update $result { value = $settled }

        conditional {
          if ($approval != null) {
            db.edit "cbm_approval" {
              field_name = "id"
              field_value = $approval.id
              data = {
                status: "approved",
                approver: $input.approver,
                decided_at: now
              }
            } as $approval_updated
          }
        }
      }
      else {
        db.edit "cbm_transfer" {
          field_name = "id"
          field_value = $transfer.id
          data = {
            status: "rejected",
            reason: "approval_rejected"
          }
        } as $rejected
        var.update $result { value = $rejected }

        conditional {
          if ($approval != null) {
            db.edit "cbm_approval" {
              field_name = "id"
              field_value = $approval.id
              data = {
                status: "rejected",
                approver: $input.approver,
                decided_at: now
              }
            } as $approval_updated
          }
        }
      }
    }
  }

  response = $result
  guid = "EoHHCuF3xZYYDzv549iIvn37tnk"
}
