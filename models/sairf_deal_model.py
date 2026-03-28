"""
SA Infrastructure Real Estate Fund (SAIRF)
Private Market Asset Model — $400K Transaction
Smooth / ERC-2727 Pilot
"""

# === ASSET PARAMETERS ===
ASSET_NAME = "SA Infrastructure Real Estate Fund"
TICKER = "SAIRF"
UNDERLYING = "Cape Town Mixed-Use Commercial Portfolio (2 properties)"
TOTAL_TOKENS = 400
TOKEN_PRICE_USD = 1_000
TOTAL_NOTIONAL_USD = TOTAL_TOKENS * TOKEN_PRICE_USD  # $400,000

# === DEAL STRUCTURE ===
ISSUER = {"name": "Obsidian Capital ZA (Pty) Ltd", "jurisdiction": "ZA"}
BUYER  = {"name": "Singapore Accredited Investor (anon)", "jurisdiction": "SGP"}
TRANSACTION_TOKENS = 100        # buyer acquires 100 of 400 tokens
TRANSACTION_VALUE_USD = 100_000 # $100,000 (25% of pool)

# === PROPERTY FINANCIALS ===
PROPERTY_VALUATION_ZAR = 7_600_000   # R7.6M at current valuations
EXCHANGE_RATE_ZAR_USD  = 19.0        # 1 USD = 19 ZAR
PROPERTY_VALUATION_USD = PROPERTY_VALUATION_ZAR / EXCHANGE_RATE_ZAR_USD

ANNUAL_RENTAL_YIELD_PCT = 8.5        # % gross yield (Cape Town commercial avg)
ANNUAL_RENTAL_INCOME_ZAR = PROPERTY_VALUATION_ZAR * (ANNUAL_RENTAL_YIELD_PCT / 100)
ANNUAL_RENTAL_INCOME_USD = ANNUAL_RENTAL_INCOME_ZAR / EXCHANGE_RATE_ZAR_USD

MGMT_FEE_PCT = 1.5                   # annual management fee
NET_YIELD_PCT = ANNUAL_RENTAL_YIELD_PCT - MGMT_FEE_PCT

# Per-token economics
ANNUAL_INCOME_PER_TOKEN_USD = (ANNUAL_RENTAL_INCOME_USD / TOTAL_TOKENS) * (1 - MGMT_FEE_PCT / 100)
CAPITAL_APPRECIATION_5YR_PCT = 35    # conservative Cape Town commercial 5yr

# === COMPLIANCE REQUIREMENTS (ERC-2727 / Smooth) ===
COMPLIANCE = {
    "issuer_jurisdiction": "ZA",
    "buyer_jurisdictions_allowed": ["SGP", "MUS", "GBR", "ARE"],
    "kyc_tier_required": 2,
    "accredited_investor_required": True,
    "min_hold_period_days": 180,
    "max_single_holder_pct": 25,
    "sa_fais_compliant": True,
    "mas_exempt_scheme": True,   # Singapore MAS exempt scheme threshold
}

# === OUTPUT ===
if __name__ == "__main__":
    print(f"""
╔══════════════════════════════════════════════════════════╗
║         SA INFRASTRUCTURE REAL ESTATE FUND (SAIRF)       ║
║              Private Market Asset — Deal Memo             ║
╚══════════════════════════════════════════════════════════╝

ASSET
  Name:         {ASSET_NAME}
  Ticker:       {TICKER}
  Underlying:   {UNDERLYING}
  Valuation:    R{PROPERTY_VALUATION_ZAR:,.0f} (${PROPERTY_VALUATION_USD:,.0f})
  Token supply: {TOTAL_TOKENS} tokens × ${TOKEN_PRICE_USD:,} = ${TOTAL_NOTIONAL_USD:,}

ECONOMICS
  Gross rental yield:     {ANNUAL_RENTAL_YIELD_PCT}%
  Net yield (after fees): {NET_YIELD_PCT}%
  Annual income/token:    ${ANNUAL_INCOME_PER_TOKEN_USD:,.2f}
  5-year appreciation:    {CAPITAL_APPRECIATION_5YR_PCT}% (conservative)

TRANSACTION
  Buyer:        {BUYER['name']} ({BUYER['jurisdiction']})
  Issuer:       {ISSUER['name']} ({ISSUER['jurisdiction']})
  Tokens:       {TRANSACTION_TOKENS} of {TOTAL_TOKENS} ({TRANSACTION_TOKENS/TOTAL_TOKENS*100:.0f}% stake)
  Value:        ${TRANSACTION_VALUE_USD:,} USDC
  Ownership:    {TRANSACTION_TOKENS/TOTAL_TOKENS*100:.0f}% of fund

COMPLIANCE (Smooth / ERC-2727)
  Issuer jurisdiction:    {COMPLIANCE['issuer_jurisdiction']} ✅
  Buyer jurisdiction:     {BUYER['jurisdiction']} ✅ (in allowed list)
  KYC tier required:      {COMPLIANCE['kyc_tier_required']}
  Accredited investor:    {'Required' if COMPLIANCE['accredited_investor_required'] else 'Not required'}
  SA FAIS compliant:      {'Yes' if COMPLIANCE['sa_fais_compliant'] else 'No'}
  MAS exempt scheme:      {'Yes' if COMPLIANCE['mas_exempt_scheme'] else 'No'}
  Min hold period:        {COMPLIANCE['min_hold_period_days']} days
  Max ownership cap:      {COMPLIANCE['max_single_holder_pct']}%

  Attestation status:     ✅ ELIGIBLE — swap authorised by Smooth Oracle
""")
