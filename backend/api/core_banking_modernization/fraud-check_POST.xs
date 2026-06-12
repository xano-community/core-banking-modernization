// Score a proposed transfer against the fraud rules engine (pure, no writes).
query "fraud-check" verb=POST {
  api_group = "CoreBankingModernization"

  input {
    text from_status?="active" { description = "Status of the source account: active, frozen, or closed" }
    decimal amount { description = "Transfer amount" }
    decimal daily_total_so_far?=0 { description = "Sum of the source account's debits already today" }
    bool is_new_payee?=false { description = "True if the recipient has not been paid before" }
    bool recipient_blocklisted?=false { description = "True if the recipient is on a blocklist" }
    decimal daily_limit?=10000 { description = "Daily debit limit before the velocity rule fires" }
    decimal large_txn_threshold?=5000 { description = "Single-transfer amount above which the large-amount rule fires" }
  }

  stack {
    function.run "cbm_fraud_check" {
      input = {from_status: $input.from_status, amount: $input.amount, daily_total_so_far: $input.daily_total_so_far, is_new_payee: $input.is_new_payee, recipient_blocklisted: $input.recipient_blocklisted, daily_limit: $input.daily_limit, large_txn_threshold: $input.large_txn_threshold}
    } as $result
  }

  response = $result
  guid = "Y_Io7CXr3nrCItOGCyAZupbTh8w"
}
