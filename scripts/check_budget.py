#!/usr/bin/env python3
"""Validate the canonical plan and print its totals; never read actuals or write files."""

import json
import re
import sys
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from zoneinfo import ZoneInfo


def require(condition, message):
    if not condition:
        raise ValueError(message)


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f'duplicate JSON key: {key}')
        result[key] = value
    return result


def money(value):
    require(isinstance(value, str) and re.fullmatch(r'(0|[1-9][0-9]*)\.[0-9]{2}', value),
            f'expected nonnegative decimal string with two places, got {value!r}')
    return Decimal(value)


def rows(value, label):
    require(isinstance(value, list) and value, f'{label} must be a nonempty list')
    require(all(isinstance(row, dict) for row in value), f'{label} entries must be objects')
    return value


def identifiers(items, label):
    ids = [row['id'] for row in items]
    require(all(isinstance(i, str) and re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', i) for i in ids),
            f'{label} IDs must use lowercase letters, digits and hyphens')
    require(len(set(ids)) == len(ids), f'duplicate {label} ID')


def validate(plan):
    require(isinstance(plan, dict), 'budget must be an object')
    require(type(plan['schema_version']) is int and plan['schema_version'] == 1, 'unsupported schema_version')
    date.fromisoformat(plan['updated_on'])
    require(plan['timezone'] == 'America/Costa_Rica', 'unsupported timezone')
    require(plan['planning_currency'] == 'USD' and plan['report_currency'] == 'CRC', 'unsupported currencies')
    rate = money(plan['planning_usd_to_crc_rate'])
    require(rate > 0, 'planning exchange rate must be positive')
    require(plan['provenance']['status'] == 'configured_plan_migrated_from_app', 'unknown plan provenance')
    require(re.fullmatch(r'[0-9a-f]{40}', plan['provenance']['source_commit']), 'invalid source commit')
    periods = rows(plan['pay_periods'], 'pay_periods')
    identifiers(periods, 'pay period')
    require({p['id'] for p in periods} == {'first', 'second'}, 'expected first and second pay periods')
    expenses = rows(plan['expenses'], 'expenses')
    rolling = rows(plan['rolling_expenses'], 'rolling_expenses')
    identifiers(expenses, 'expense')
    identifiers(rolling, 'rolling expense')
    for row in expenses + rolling:
        require(all(isinstance(row[k], str) and row[k].strip() for k in ('name', 'category')), 'empty expense name/category')
    for row in expenses:
        require(row['period'] in {'first', 'second'}, f'unknown expense period: {row["period"]}')
        money(row['amount'])
        if 'amount_crc' in row:
            money(row['amount_crc'])
        if 'payment_day' in row:
            require(type(row['payment_day']) is int and 1 <= row['payment_day'] <= 31, 'invalid monthly payment day')
            require(row.get('recurrence') == 'Monthly', 'payment_day requires Monthly recurrence')
            date.fromisoformat(row['confirmed_on'])
    for row in rolling:
        money(row['contribution_per_period'])
        money(row['target_amount'])
        date.fromisoformat(row['due_date'])
        require(isinstance(row['recurrence'], str) and row['recurrence'].strip(), 'missing recurrence')
        require(row['due_date_status'] in {'migrated_app_default_needs_review', 'user_confirmed'}, 'unknown due-date evidence status')
    policy = plan['savings_policy']
    require(policy['currency'] == 'CRC', 'savings policy currency must be explicit CRC')
    require(policy['status'] in {'unverified_app_defaults', 'user_confirmed'}, 'unknown savings policy evidence status')
    money(policy['emergency_fund_target'])
    allocation = rows(policy['excess_allocation'], 'excess_allocation')
    names = [p['name'] for p in allocation]
    require(all(isinstance(n, str) and n.strip() for n in names) and len(set(names)) == len(names), 'invalid/duplicate savings allocation names')
    shares = []
    for part in allocation:
        share = part['share']
        require(isinstance(share, str) and re.fullmatch(r'(?:0(?:\.[0-9]+)?|1(?:\.0+)?)', share), 'savings share must be a decimal string between 0 and 1')
        shares.append(Decimal(share))
    require(sum(shares) == 1, 'savings allocation shares must sum to 1')
    require(all(isinstance(plan['actuals_policy'][key], str) and plan['actuals_policy'][key].strip()
                for key in ('transaction_source', 'confirmed_context_source', 'note')), 'missing actuals source policy')
    reserve = sum(money(r['contribution_per_period']) for r in rolling)
    totals = []
    for period in periods:
        salary = money(period['salary'])
        expected_days = '1-15' if period['id'] == 'first' else '16-month-end'
        require(period['days'] == expected_days and isinstance(period['label'], str) and period['label'].strip(), 'invalid period definition')
        regular = sum(((money(r['amount_crc']) / rate if 'amount_crc' in r else money(r['amount'])) for r in expenses if r['period'] == period['id']), Decimal(0))
        totals.append((period['label'], salary, regular, reserve, salary - regular - reserve))
    return totals, rate


def main():
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1] / 'budget.json'
    try:
        plan = json.loads(path.read_text(), object_pairs_hook=unique_object)
        totals, rate = validate(plan)
    except (ValueError, KeyError, TypeError, OSError) as error:
        print(f'Invalid budget: {error}', file=sys.stderr)
        return 1
    print(f'Valid budget: {len(plan["expenses"])} expenses, {len(plan["rolling_expenses"])} rolling plans')
    print('Planned totals in CRC at the configured planning rate (not bank balances):')
    print('Period | Salary | Regular expenses | Rolling reserves | Remainder')
    monthly = tuple(sum(row[i] for row in totals) for i in range(1, 5))
    for label, *values in totals + [('Monthly', *monthly)]:
        print(label + ' | ' + ' | '.join(f'{value * rate:,.2f}' for value in values))
    today = datetime.now(ZoneInfo(plan['timezone'])).date()
    for row in plan['rolling_expenses']:
        if row['due_date_status'] == 'migrated_app_default_needs_review' or date.fromisoformat(row['due_date']) < today:
            print(f'Review due date: {row["name"]}: {row["due_date"]} ({row["due_date_status"]}); no overdue-payment conclusion')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
