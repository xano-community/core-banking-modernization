// Initiate a transfer: balance-checked, fraud-scored, approval-routed.
query "transfers" verb=POST {
  api_group = "CoreBankingModernization"

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
    function.run "cbm_initiate_transfer" {
      input = {from_account: $input.from_account, to_account: $input.to_account, amount: $input.amount, requested_by: $input.requested_by, approval_threshold: $input.approval_threshold, is_new_payee: $input.is_new_payee, recipient_blocklisted: $input.recipient_blocklisted}
    } as $result
  }

  response = $result
  guid = "hyu9IDUP7RxM8NNGWuIUFCmGFVA"
}
