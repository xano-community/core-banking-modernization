function "cbm_fraud_check" {
  description = "Deterministic fraud rules engine for a proposed transfer. Pure transform — no database writes. Scores a transfer against a fixed rule set (frozen source account, large amount, daily velocity, new payee, recipient blocklist) and returns a numeric score, a risk band (low/medium/high), and the individual rule flags that fired."

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
    var $score { value = 0 }
    var $flags { value = [] }

    conditional {
      if ($input.from_status == "frozen") {
        var.update $score { value = (($score) + 100) }
        var.update $flags { value = ($flags|push:{rule: "frozen_account", score: 100}) }
      }
    }

    conditional {
      if ($input.amount > $input.large_txn_threshold) {
        var.update $score { value = (($score) + 40) }
        var.update $flags { value = ($flags|push:{rule: "large_amount", score: 40}) }
      }
    }

    conditional {
      if ((($input.daily_total_so_far) + ($input.amount)) > $input.daily_limit) {
        var.update $score { value = (($score) + 50) }
        var.update $flags { value = ($flags|push:{rule: "velocity_daily_limit", score: 50}) }
      }
    }

    conditional {
      if ($input.is_new_payee == true) {
        var.update $score { value = (($score) + 20) }
        var.update $flags { value = ($flags|push:{rule: "new_payee", score: 20}) }
      }
    }

    conditional {
      if ($input.recipient_blocklisted == true) {
        var.update $score { value = (($score) + 100) }
        var.update $flags { value = ($flags|push:{rule: "blocklist", score: 100}) }
      }
    }

    var $risk { value = "low" }
    conditional {
      if ($score >= 70) {
        var.update $risk { value = "high" }
      }
      elseif ($score >= 30) {
        var.update $risk { value = "medium" }
      }
      else {
        var.update $risk { value = "low" }
      }
    }
  }

  response = {score: $score, risk: $risk, flags: $flags}

  test "clean small transfer scores zero and is low risk" {
    input = {amount: 100}
    expect.to_equal ($response.score) { value = 0 }
    expect.to_equal ($response.risk) { value = "low" }
  }

  test "blocklisted recipient is high risk" {
    input = {amount: 100, recipient_blocklisted: true}
    expect.to_be_greater_than ($response.score) { value = 99 }
    expect.to_equal ($response.risk) { value = "high" }
  }

  test "large new-payee transfer is medium risk" {
    input = {amount: 6000, is_new_payee: true}
    expect.to_equal ($response.score) { value = 60 }
    expect.to_equal ($response.risk) { value = "medium" }
  }

  test "frozen source account flags immediately" {
    input = {from_status: "frozen", amount: 100}
    expect.to_equal ($response.risk) { value = "high" }
    expect.to_be_greater_than ($response.score) { value = 99 }
  }
  guid = "FGCO46CEMfgEjfJbmklKskpITMg"
}
