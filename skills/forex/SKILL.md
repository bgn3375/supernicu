---
name: forex
description: Multi-currency and exchange rate skill. BNR rates, currency conversion, RON/EUR/USD/GBP. Fires on "exchange rate", "currency conversion", "BNR", "multi-currency", "forex".
---

# Forex — Multi-Currency + BNR Exchange Rates

Conversie automată între RON, EUR, USD, GBP pe baza cursului BNR.

## Surse curs valutar

1. **Primară:** Bono Forex API (serviciu intern BONO)
2. **Fallback:** XML-ul public BNR (bnr.ro/nbrfxrates.xml)

## Sincronizare

- Automat zilnic la 08:00 UTC
- Backfill ultimele 7 zile (prinde zile ratate)
- Stochează în MariaDB: `forex_rates` tabel

```sql
CREATE TABLE forex_rates (
  id CHAR(36) NOT NULL,
  team_id CHAR(36) NOT NULL,
  currency VARCHAR(3) NOT NULL,
  rate DECIMAL(18,6) NOT NULL,
  rate_date DATE NOT NULL,
  source VARCHAR(20) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_forex_team_date (team_id, rate_date, currency)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## Conversie pe cheltuieli

Când se salvează o cheltuială:
```
amount_ron = amount * exchange_rate (dacă currency != RON)
amount_eur = amount_ron / eur_rate
```

## Reguli

1. **Cheltuieli draft fără curs** → ignorate silențios (nu eroare).
2. **Cheltuieli non-draft fără curs** → eroare (OperationResult.Failure).
3. **Monede suportate:** RON, EUR, USD, GBP.
4. **Tabele financiare** stochează: `amount_ron`, `amount_eur`, `currency`, `exchange_rate`.
5. **NHibernate** mapping pe `forex_rates`, cu tenantFilter.
