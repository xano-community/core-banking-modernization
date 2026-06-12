// Approve or reject a transfer that is awaiting manual approval.
query "transfers/{id}/approve" verb=POST {
  api_group = "CoreBankingModernization"

  input {
    int id { description = "Id of the cbm_transfer awaiting approval" }
    text decision { description = "approve or reject" }
    text approver? { description = "Who made the decision" }
  }

  stack {
    function.run "cbm_approve_transfer" {
      input = {transfer_id: $input.id, decision: $input.decision, approver: $input.approver}
    } as $result
  }

  response = $result
  guid = "T8_P3mENhUdrWYCE46Ul0PjkGOM"
}
