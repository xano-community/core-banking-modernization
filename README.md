# Core Banking Modernization (Xano module)

Wrap a **legacy core-banking system** in a **modern transfer API**. Instead of issuing raw balance updates against a 40-year-old ledger, you route money through one opinionated pipeline: every transfer is **balance-checked**, scored by a **deterministic fraud rules engine**, **routed to approval** when it's risky or large, and settled with **double-entry ledger postings** you can **reconcile** at any time.

Drop this module into any Xano workspace. It ships five tables and a small public function surface; you load accounts into it, move money through `cbm_initiate_transfer`, and audit with `cbm_reconcile`.

## What you get

**Tables**

| Table | Purpose |
| --- | --- |
| `cbm_account` | One row per account, keyed by `legacy_account_no` (unique). Stored `balance`, `type`, `status` (`active`/`frozen`/`closed`). |
| `cbm_transfer` | A transfer with a state machine: `pending` → `completed`, `pending_approval` → `approved`/`completed`, or `rejected`/`failed`. |
| `cbm_approval` | One approval task per held transfer, with the decision, approver, and threshold. |
| `cbm_fraud_flag` | The individual fraud rules that fired for a transfer, each with a score and detail. |
| `cbm_ledger_entry` | Double-entry ledger: one `debit`/`credit` row per side of each settled transfer, plus opening balances. |

**Public function surface** (call from any XanoScript via `function.run`)

| Function | What it does |
| --- | --- |
| `cbm_fraud_check` | Pure rules engine: proposed transfer → `{score, risk, flags}`. |
| `cbm_create_account` | Upsert an account; opening balance posts an opening ledger credit. |
| `cbm_initiate_transfer` | Balance-check + fraud-score + route/settle/reject a transfer. |
| `cbm_approve_transfer` | Approve or reject a held transfer (settles on approve). |
| `cbm_reconcile` | Ledger vs. stored balance (and optional legacy balance) reconciliation. |

> `cbm_execute_transfer` is an internal settlement helper used by initiate/approve. You normally don't call it directly.

**HTTP endpoints** (API group `core-banking-modernization`)

| Method | Path | Wraps |
| --- | --- | --- |
| `POST` | `/accounts` | `cbm_create_account` |
| `GET`  | `/accounts` | list `cbm_account` (filter `status`) |
| `POST` | `/transfers` | `cbm_initiate_transfer` |
| `GET`  | `/transfers` | list `cbm_transfer` (filter `status`) |
| `POST` | `/transfers/{id}/approve` | `cbm_approve_transfer` |
| `POST` | `/fraud-check` | `cbm_fraud_check` |
| `POST` | `/reconcile` | `cbm_reconcile` |

## Install

### Option A — Ask Claude Code
With the [Xano MCP](https://github.com/xano-labs/mcp-server) enabled, paste:

> Install the module at https://github.com/xano-community/core-banking-modernization into my Xano workspace.

### Option B — Xano CLI
```sh
git clone https://github.com/xano-community/core-banking-modernization.git
cd core-banking-modernization
xano workspace push backend -w <your-workspace-id>
```

## Usage

```xs
// Seed accounts (opening balance posts an opening ledger credit).
function.run "cbm_create_account" {
  input = { legacy_account_no: "ACC-A", balance: 10000 }
} as $a
function.run "cbm_create_account" {
  input = { legacy_account_no: "ACC-B", balance: 0 }
} as $b

// Move money — balance-checked, fraud-scored, approval-routed.
function.run "cbm_initiate_transfer" {
  input = { from_account: "ACC-A", to_account: "ACC-B", amount: 1000 }
} as $t
// $t.status == "completed"   (small, low-risk, below threshold)

// A large transfer is held for approval:
function.run "cbm_initiate_transfer" {
  input = { from_account: "ACC-A", to_account: "ACC-B", amount: 6000 }
} as $big
// $big.status == "pending_approval"   (>= approval_threshold of 5000)

function.run "cbm_approve_transfer" {
  input = { transfer_id: $big.id, decision: "approve", approver: "ops-mgr" }
} as $approved
// settles: debits ACC-A, credits ACC-B, posts ledger rows, status "completed"

// Audit any time:
function.run "cbm_reconcile" {
  input = { legacy_account_no: "ACC-A" }
} as $rec
// $rec.in_sync == true; computed_ledger_balance == account_balance
```

## The fraud rules engine

`cbm_fraud_check` is deterministic and pure (easy to unit test). Rules and their scores:

| Rule | Fires when | Score |
| --- | --- | --- |
| `frozen_account` | source account status is `frozen` | +100 |
| `large_amount` | `amount` > `large_txn_threshold` (default 5000) | +40 |
| `velocity_daily_limit` | today's debits + `amount` > `daily_limit` (default 10000) | +50 |
| `new_payee` | `is_new_payee` is true | +20 |
| `blocklist` | `recipient_blocklisted` is true | +100 |

Risk band: `score >= 70` → **high**, `score >= 30` → **medium**, else **low**. A transfer is routed to approval when risk is **high** *or* the amount is at/above the `approval_threshold`.

## Double-entry & reconciliation

Every settled transfer posts a `debit` on the source account and (if the destination is also a core-banking account) a matching `credit` on the destination. Opening balances post a `credit`. `cbm_reconcile` recomputes the balance as `sum(credits) - sum(debits)` and flags any drift between the ledger, the stored balance, and an optional legacy-reported balance.

## License

MIT — see [LICENSE](./LICENSE).
