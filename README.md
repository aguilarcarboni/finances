# Personal finances

This repository stores the personal spending plan and paper IBKR portfolio strategy as documents and data. The Swift/Xcode app was retired on October 26, 2026.

- [`budget.json`](budget.json) is the canonical salary and spending plan: both half-month salaries, recurring expenses, rolling reserves, planning exchange rate, and preserved savings policy.
- [`docs/portfolio/ibkr-portfolio-strategy.md`](docs/portfolio/ibkr-portfolio-strategy.md) remains the canonical paper portfolio strategy. Its baseline evidence remains in `docs/portfolio/evidence/`.
- [`archive/app-defaults.json`](archive/app-defaults.json) preserves the superseded expense model and unverified asset/loan examples. Do not include them in the active budget or treat them as current balances or debts.

## Editing the budget

Amounts and rates are decimal strings, for example `"700.00"`. Salary, regular expenses, and rolling targets use `planning_currency` (USD); the savings policy explicitly uses CRC. `planning_usd_to_crc_rate` is a planning assumption, not a bank settlement rate. Reports display CRC. Keep stable IDs when changing names or amounts.

A regular expense may include `amount_crc` when the user confirms a fixed colón bill. This exact CRC amount takes precedence over converting its `amount`; `amount` remains a rounded USD planning equivalent. Preserve `amount_crc` when the exchange rate changes. Optional `payment_day` and `recurrence` record a confirmed monthly schedule, with `confirmed_on` dating that confirmation; they do not establish payment. A verified current rate can replace the planning rate with its date, source and buy/sell basis recorded in `planning_exchange_rate_evidence`. Use the compra rate for USD income converted to CRC; it remains a reference, not a verified bank settlement rate.

`first` covers days 1–15, and `second` covers day 16 through month end. A regular expense belongs to one period. Each rolling `contribution_per_period` applies to both periods. Monthly regular expenses sum both periods; monthly rolling reserves are twice the per-period sum. Planned remainder subtracts both regular expenses and rolling reserves from salary. These calculations describe the plan, not available cash.

Run the dependency-free check after editing:

```sh
python3 scripts/check_budget.py
```

The check validates structure, IDs, currencies, decimal amounts, dates, and savings shares, then prints planned totals and due-date review notices. You may pass another JSON file as its first argument. A past sample due date is a request to review the plan; it does not prove a bill is overdue. Recurrence text and due dates were copied without rescheduling them.

## Actual spending and savings

Actual spending continues to come from the personal Gmail BAC label through the Finances plugin. Dated user confirmations in the automation memory or conversation take precedence over inferred categorization and unverified defaults. This file does not establish deposited salary, paid bills, funded reserves, savings balances, or complete bank spending. Do not count planned contributions as savings deposits. Do not count random example transactions as evidence.

The savings policy's emergency target and 50/50 excess allocation were preserved from the app with `unverified_app_defaults` status. Confirm their applicability before using them as commitments. Unknown balances remain unknown; a dated user confirmation of a zero balance remains valid until superseded.

## App retirement and provenance

Source snapshot: [`267b8b7cdd4bfad86f0782eee0bb92b79ae27c28`](https://github.com/aguilarcarboni/finances/tree/267b8b7cdd4bfad86f0782eee0bb92b79ae27c28).

The former app had Expenses, Savings, and Assets tabs, including budget comparisons, simulated savings history, asset depreciation, and loan payoff calculators. It had no database, bank integration, or persistent data store in the inspected source. Savings transactions were randomly generated at startup; assets were loaded by `loadMockAssets`. Runtime edits were held in memory. The source remains recoverable from Git history.

All 18 configured regular expenses, 7 rolling plans, both salaries, and the exchange rate were copied from `PlannerStore.swift`. Savings settings were copied from `SavingsAccount.swift`. Conflicting `ExpensesAccount.swift` budgets and `AssetsManager.swift` examples were preserved separately in the archive. Initial UI payment/savings zeros are documented there as defaults, not evidence. Actual transaction generation and the app UI/calculators were removed.

The Finances plugin reads `budget.json` through GitHub at a resolved current commit, preserving its read-only BAC review and existing reporting rules. Its portfolio skill and scheduled review continue to use the unchanged strategy document.
