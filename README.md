# Lattice Smartrader V2

This project generates a comprehensive suite of market intelligence reports by
combining BoundaryML (BAML) agents with targeted post-processing guardrails.
Given a diversified watchlist of tickers, the system collects historical
performance, volatility statistics, news coverage, insider activity, and
sentiment signals, then consolidates the findings into Markdown documents under
the `reports/` directory.

## Project Structure

- `main.py` – Asynchronous entrypoint that schedules report generation for the
  full ticker list and writes bundled Markdown outputs.
- `report_generator.py` – Hosts the `ReportGenerator` class, which orchestrates
  the BAML agent calls, applies data-quality filters, and formats the Markdown
  sections for each report type.
- `config.py` – Small helper module that validates required environment
  variables, emits warnings for optional providers, and resolves the report
  "as-of" date (honouring the `REPORT_AS_OF_DATE` override).
- `data_utils.py` – Shared utilities for vetting agent responses (e.g. bounding
  volatility, dividend yields, insider names) and formatting numeric output so
  that Markdown stays consistent.
- `baml_src/` – BAML definitions for every agent. Each `.baml` file specifies
  the schema, prompts, and data-quality requirements for:
  - `historical_prism.baml` – Long-form historical analysis
  - `volatility.baml` – Risk and volatility profiling
  - `news.baml` – Recent news synthesis and sentiment
  - `insider_trading.baml` – Insider transaction analysis
  - `sentiment.baml` – Cross-source sentiment aggregation
  - `market_conditions.baml` – Macro backdrop report
- `baml_client/` – Generated Python bindings created by `baml-cli generate`; do
  not edit manually.
- `reports/` – Output directory for generated Markdown summaries.
- `.env` – Local configuration for API keys and optional report parameters.

## Data Flow Overview

1. **Configuration** – `main.py` loads `.env`, checks for mandated credentials
   (`OPENROUTER_API_KEY`) and warns when optional providers (Alpaca, FMP) are
   absent. The report date defaults to `datetime.date.today()` unless
   `REPORT_AS_OF_DATE` is provided.
2. **Agent Execution** – For each ticker, `ReportGenerator.generate_all_reports`
   launches five BAML agent calls concurrently:
   `GenerateHistoricalAnalysisReport`, `GenerateVolatilityReport`,
   `GenerateNewsReport`, `GenerateInsiderReport`, and
   `GenerateSentimentAnalysisReport`. A sixth call produces the
   cross-market `GenerateMarketConditionsReport` once all tickers are processed.
3. **Validation & Formatting** – The raw agent payloads are passed through the
   safeguards in `data_utils.py`, which remove placeholder insiders, reject
   stale articles, clamp unrealistic statistics, and ensure consistent currency
   / percent formatting.
4. **Emission** – Cleaned sections are concatenated into Markdown bundles (one
   file per report category) and written to the `reports/` directory.

## Requirements

- **Python**: 3.10 or newer is recommended (project uses type hints and
  `asyncio` features from modern versions).
- **Network access**: Required for BAML to reach OpenRouter, Alpaca, and FMP
  APIs.
- **API keys**:
  - `OPENROUTER_API_KEY` (mandatory) – used for the Mercury Coder model.
  - `ALPACA_API_KEY` / `ALPACA_SECRET_KEY` (optional but recommended) – enable
    refined volatility and market data.
  - `FMP_API_KEY` (optional but recommended) – enables richer news and insider
    feeds.

### Python Packages

Install dependencies into a virtual environment:

```bash
python -m venv env
source env/bin/activate  # or env\Scripts\activate on Windows
pip install --upgrade pip
pip install baml python-dotenv
```

> **Note:** Running the agents assumes `baml-cli` generated the code inside
> `baml_client/`. If you modify anything in `baml_src/`, regenerate bindings
> with `baml generate` (or `baml-cli generate`) and reinstall the matching BAML
> version.

## Configuration

Create a `.env` file based on the example below:

```ini
OPENROUTER_API_KEY=sk-or-...
ALPACA_API_KEY=your_alpaca_key
ALPACA_SECRET_KEY=your_alpaca_secret
FMP_API_KEY=your_fmp_key

# Optional overrides
# REPORT_AS_OF_DATE=2025-09-19
# REPORT_BENCHMARK=SPY
# REPORT_PERIOD=1y
# REPORT_INTERVAL=1d
```

Omitted optional keys will trigger friendly warnings and disable the
corresponding data sources gracefully.

## Running the Project

1. Activate your virtual environment.
2. Ensure the `.env` file is populated as described above.
3. From the repository root, execute:

   ```bash
   python main.py
   ```

4. Monitor the console for per-ticker progress. When the run completes, inspect
   the Markdown reports in `reports/`:
   - `historical.md`
   - `volatility.md`
   - `news.md`
   - `insider_trading.md`
   - `sentiment.md`
   - `market_conditions.md`

If you prefer to call the orchestration logic from another script, instantiate
`ReportGenerator` and await `generate_all_reports()` from an asyncio event loop.

## Extending & Customising

- **Ticker universe** – Modify `ReportGenerator.stock_tickers` (or supply your
  own list) to align with a different portfolio.
- **Report cadence** – Override `REPORT_AS_OF_DATE`, `REPORT_PERIOD`, and
  `REPORT_INTERVAL` in the environment to re-run historical comparisons for the
  desired timeframe.
- **Prompt tuning** – Update the relevant `.baml` files under `baml_src/` to
  adjust agent behaviour. Remember to regenerate the client bindings via `baml
  generate` afterwards.
- **Quality guardrails** – `data_utils.py` centralises the heuristics that
  reject hallucinated values. Adjust, extend, or tighten the thresholds there
  as your use case demands.

## Troubleshooting

- **Missing keys** – A `RuntimeError` from `ensure_env_var` indicates that the
  mandatory `OPENROUTER_API_KEY` was not set.
- **Data gaps** – Sections may print “Data unavailable or did not meet quality
  checks.” when upstream APIs return empty or implausible results. This is
  intentional to avoid misleading analytics.
- **Regeneration errors** – If you edit the `.baml` files and see attribute
  errors at runtime, regenerate the Python bindings (`baml generate`) so that
  the client matches the new schema.

With the environment configured and dependencies installed, the project can be
run end-to-end to produce multi-dimensional trading intelligence snapshots with
strong safeguards against hallucinated metrics.

