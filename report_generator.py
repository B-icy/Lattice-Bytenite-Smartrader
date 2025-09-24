"""Coordinator that calls BAML agents and writes the markdown outputs."""

import asyncio
import datetime
import os
from typing import Optional

from dotenv import load_dotenv
from baml_client.async_client import b
from config import ensure_env_var, warn_if_missing, get_report_date
from data_utils import (
    is_price_analysis_reliable,
    sanitize_dividend_yield,
    format_percent,
    format_ratio,
    format_currency,
    format_integer,
    filter_recent_articles,
    filter_recent_transactions,
    is_valid_volatility_metrics,
)


class ReportGenerator:
    """Orchestrates asynchronous generation of every report bundle."""

    def __init__(self):
        self.stock_tickers = [
            # Original Diversified Core
            "AAPL", "MSFT", "JPM", "JNJ", "PG", "XOM", "UNH", "CAT", "COST", "NEE",
            "WM", "O", "NVDA", "BRK-B", "LMT", "SBUX", "ALB", "BX", "VRTX", "ETSY",

            # New Small-Cap Additions
            "APPS", "PLCE", "CENX", "PACW", "LNTH",

            # New High-Risk Biotech Additions
            "CRSP", "SAVA", "ARQT",
        ]

    async def generate_all_reports(self):
        """Generate the full suite of reports and persist them to disk."""
        load_dotenv()
        openrouter_key = ensure_env_var('OPENROUTER_API_KEY')
        os.environ['OPENROUTER_API_KEY'] = openrouter_key

        warn_if_missing('ALPACA_API_KEY')
        warn_if_missing('ALPACA_SECRET_KEY')
        warn_if_missing('FMP_API_KEY')

        report_date = get_report_date()

        benchmark = os.getenv('REPORT_BENCHMARK', 'SPY')
        period = os.getenv('REPORT_PERIOD', '1y')
        interval = os.getenv('REPORT_INTERVAL', '1d')

        # Initialize aggregated markdown strings
        historical_all = f"# Historical Analysis Reports (as of {report_date.isoformat()})\n\n"
        volatility_all = f"# Volatility Analysis Reports (as of {report_date.isoformat()})\n\n"
        news_all = f"# News Analysis Reports (as of {report_date.isoformat()})\n\n"
        insider_all = f"# Insider Trading Analysis Reports (as of {report_date.isoformat()})\n\n"
        sentiment_all = f"# Sentiment Analysis Reports (as of {report_date.isoformat()})\n\n"

        for ticker in self.stock_tickers:
            print(f"Generating reports for: {ticker}...")

            try:
                # Run the 5 agent calls in parallel for this ticker
                historical_report, volatility_report, news_report, insider_report, sentiment_report = await asyncio.gather(
                    b.GenerateHistoricalAnalysisReport(
                        ticker=ticker,
                        period=period,
                        benchmark=benchmark,
                        interval=interval,
                    ),
                    b.GenerateVolatilityReport(
                        ticker=ticker,
                        period=period,
                        benchmark=benchmark,
                    ),
                    b.GenerateNewsReport(
                        ticker=ticker,
                    ),
                    b.GenerateInsiderReport(
                        ticker=ticker,
                    ),
                    b.GenerateSentimentAnalysisReport(
                        ticker=ticker,
                    ),
                )

                # Append to historical
                historical_all += self._generate_historical_section(ticker, report_date, historical_report)

                # Append to volatility
                volatility_all += self._generate_volatility_section(ticker, report_date, volatility_report, benchmark)

                # Append to news
                news_all += self._generate_news_section(ticker, report_date, news_report)

                # Append to insider
                insider_all += self._generate_insider_section(ticker, report_date, insider_report)

                # Append to sentiment
                sentiment_all += self._generate_sentiment_section(ticker, report_date, sentiment_report)

                print(f"✅ Successfully generated reports for {ticker}.")

            except Exception as e:
                print(f"❌ An error occurred while processing {ticker}: {e}")
                # Continue to next ticker

        # Generate Market Conditions Report (general, not per ticker)
        market_report = await b.GenerateMarketConditionsReport()

        market_md = self._generate_market_conditions_section(report_date, market_report)

        # Write all aggregated reports
        self._write_report("reports/historical.md", historical_all)
        self._write_report("reports/volatility.md", volatility_all)
        self._write_report("reports/news.md", news_all)
        self._write_report("reports/insider_trading.md", insider_all)
        self._write_report("reports/sentiment.md", sentiment_all)
        self._write_report("reports/market_conditions.md", market_md)

        print("\n--- Analysis Complete ---")
        print("Reports generated:")
        print("- historical.md")
        print("- volatility.md")
        print("- news.md")
        print("- insider_trading.md")
        print("- sentiment.md")
        print("- market_conditions.md")

    def _generate_historical_section(self, ticker: str, report_date: datetime.date, report) -> str:
        """Build the historical markdown section for a single ticker."""
        section = f"## {ticker} (as of {report_date.isoformat()})\n\n"
        section += f"### Executive Summary\n{report.executive_summary}\n\n"

        pa = getattr(report, "price_analysis", None)
        section += "### Price Analysis\n"
        if pa is not None and is_price_analysis_reliable(pa):
            section += f"- **Total Return (1y):** {format_percent(pa.total_return_percent)}\n"
            section += f"- **Volatility:** {format_percent(pa.volatility)}\n"
            section += f"- **Price Range (1y):** {format_currency(pa.min_price)} - {format_currency(pa.max_price)}\n"
            section += f"- **Average Volume:** {format_integer(pa.average_volume)}\n"
            section += f"- **Trend Direction:** {pa.trend_direction.title()}\n\n"
        else:
            section += "Data unavailable or did not meet quality checks.\n\n"

        fa = getattr(report, "fundamental_analysis", None)
        if fa:
            div_value = sanitize_dividend_yield(getattr(fa, "dividend_yield", None))
            div_display = format_percent(div_value, assume_fractional=True) if div_value is not None else "N/A"
            section += "### Fundamental Analysis\n"
            section += f"- **P/E Ratio:** {format_ratio(getattr(fa, 'pe_ratio', None))}\n"
            section += f"- **Forward P/E Ratio:** {format_ratio(getattr(fa, 'forward_pe_ratio', None))}\n"
            section += f"- **PEG Ratio:** {format_ratio(getattr(fa, 'peg_ratio', None))}\n"
            section += f"- **Price-to-Book Ratio:** {format_ratio(getattr(fa, 'price_to_book', None))}\n"
            section += f"- **Dividend Yield:** {div_display}\n"
            section += f"- **52-Week High:** {format_currency(getattr(fa, 'fifty_two_week_high', None))}\n"
            section += f"- **52-Week Low:** {format_currency(getattr(fa, 'fifty_two_week_low', None))}\n\n"

        if report.technical_analysis:
            ta = report.technical_analysis
            section += "### Technical Analysis\n"
            section += f"- **20-Day SMA:** {format_currency(getattr(ta, 'sma_20', None))}\n"
            section += f"- **50-Day SMA:** {format_currency(getattr(ta, 'sma_50', None))}\n"
            section += f"- **RSI:** {format_ratio(getattr(ta, 'rsi', None))}\n"
            section += f"- **Support Level:** {format_currency(getattr(ta, 'support_level', None))}\n"
            section += f"- **Resistance Level:** {format_currency(getattr(ta, 'resistance_level', None))}\n\n"

        if report.market_comparison:
            mc = report.market_comparison
            section += f"### Market Comparison (vs. {mc.benchmark_ticker})\n"
            section += f"- **Outperformance:** {format_percent(getattr(mc, 'outperformance_percent', None))}\n"
            beta_value = getattr(mc, 'beta', None)
            section += f"- **Beta:** {beta_value if beta_value is not None else 'N/A'}\n"
            corr_value = getattr(mc, 'correlation', None)
            section += f"- **Correlation:** {format_ratio(corr_value, 4)}\n"
            section += f"- **Relative Strength:** {getattr(mc, 'relative_strength', 'N/A')}\n\n"

        section += f"### Risk Assessment\n{report.risk_assessment}\n\n"
        section += f"### Investment Outlook\n{report.investment_outlook}\n\n"

        if report.key_recommendations:
            section += f"### Key Recommendations\n"
            for rec in report.key_recommendations:
                section += f"- {rec}\n"
            section += "\n---\n\n"

        return section

    def _generate_volatility_section(self, ticker: str, report_date: datetime.date, report, benchmark: str) -> str:
        """Render the volatility markdown section, applying guardrails."""
        section = f"## {ticker} (as of {report_date.isoformat()})\n\n"
        section += "### Volatility Metrics\n"

        vol_metrics = getattr(report, "metrics", None)
        if vol_metrics is not None and is_valid_volatility_metrics(vol_metrics):
            section += f"- **Historical Volatility:** {format_percent(vol_metrics.historical_volatility)}\n"
            beta_val = getattr(vol_metrics, 'beta', None)
            section += f"- **Beta vs {benchmark}:** {beta_val if beta_val is not None else 'N/A'}\n"
            sr_val = getattr(vol_metrics, 'sharpe_ratio', None)
            section += f"- **Sharpe Ratio:** {format_ratio(sr_val)}\n"
            section += f"- **Max Drawdown:** {format_percent(vol_metrics.max_drawdown)}\n"
            section += f"- **Volatility Regime:** {vol_metrics.volatility_regime}\n\n"
        else:
            section += "Data unavailable or did not meet quality checks.\n\n"

        risk_assessment = getattr(report, "risk_assessment", None)
        if risk_assessment:
            section += "### Risk Assessment\n"
            section += f"- **Overall Risk Level:** {risk_assessment.overall_risk_level}\n"
            section += f"- **Volatility Trends:** {', '.join(risk_assessment.volatility_trends or [])}\n"
            section += f"- **Risk Factors:** {', '.join(risk_assessment.risk_factors or [])}\n"
            section += f"- **Hedging Recommendations:** {', '.join(risk_assessment.hedging_recommendations or [])}\n\n"

        section += f"### Outlook\n{getattr(report, 'outlook', 'N/A')}\n\n"
        section += "### Key Insights\n"
        for insight in getattr(report, "key_insights", []) or []:
            section += f"- {insight}\n"
        section += "\n---\n\n"

        return section

    def _generate_news_section(self, ticker: str, report_date: datetime.date, report) -> str:
        """Summarise recency-filtered news coverage for the ticker."""
        section = f"## {ticker} (as of {report_date.isoformat()})\n\n"
        section += "### Recent News Articles\n"

        recent_articles = filter_recent_articles(getattr(report, "articles", []), report_date)
        if not recent_articles:
            section += "No reliable articles within the last 120 days.\n\n"
        else:
            for article in recent_articles[:3]:  # Limit to freshest 3 per stock
                snippet = (article.content or "").strip()
                if len(snippet) > 240:
                    snippet = snippet[:237].rstrip() + "..."
                section += f"- **{article.title}**\n"
                section += f"  - Source: {article.source}\n"
                section += f"  - Date: {article.published_date}\n"
                if snippet:
                    section += f"  - Content: {snippet}\n"
                section += "\n"

        sentiment_analysis = getattr(report, "sentiment_analysis", None)
        section += "### Sentiment Analysis\n"
        if sentiment_analysis:
            trend = ', '.join(sentiment_analysis.sentiment_trend or [])
            themes = ', '.join(sentiment_analysis.key_themes or [])
            section += f"- **Overall Sentiment:** {sentiment_analysis.overall_sentiment}\n"
            section += f"- **Sentiment Trend:** {trend or 'N/A'}\n"
            section += f"- **Key Themes:** {themes or 'N/A'}\n"
            section += f"- **Market Impact:** {sentiment_analysis.market_impact_assessment}\n\n"
        else:
            section += "Sentiment data unavailable.\n\n"

        section += f"### Summary\n{getattr(report, 'summary', 'N/A')}\n\n"
        section += f"### Key Insights\n"
        for insight in report.key_insights or []:
            section += f"- {insight}\n"
        section += "\n---\n\n"

        return section

    def _generate_insider_section(self, ticker: str, report_date: datetime.date, report) -> str:
        """Describe insider activity while filtering stale or fake entries."""
        section = f"## {ticker} (as of {report_date.isoformat()})\n\n"
        section += "### Recent Transactions\n"

        recent_txns = filter_recent_transactions(getattr(report, "recent_transactions", []), report_date)
        if not recent_txns:
            section += "No insider trades reported within the last 12 months.\n\n"
        else:
            for txn in recent_txns[:3]:  # Limit to 3
                section += f"- **{txn.name}** ({txn.title})\n"
                section += f"  - Type: {txn.transaction_type}\n"
                section += f"  - Shares: {txn.shares}\n"
                section += f"  - Price: {format_currency(getattr(txn, 'price', None))}\n"
                section += f"  - Value: {format_currency(getattr(txn, 'value', None))}\n"
                section += f"  - Date: {txn.transaction_date}\n\n"

        activity_summary = getattr(report, "activity_summary", None)
        if activity_summary:
            section += "### Activity Summary\n"
            section += f"- **Total Buy Volume:** {format_integer(getattr(activity_summary, 'total_buy_volume', None))}\n"
            section += f"- **Total Sell Volume:** {format_integer(getattr(activity_summary, 'total_sell_volume', None))}\n"
            net_activity = getattr(activity_summary, 'net_insider_activity', None)
            if net_activity is not None:
                section += f"- **Net Insider Activity:** {format_currency(net_activity)}\n"
            insiders = getattr(activity_summary, 'key_insiders', []) or []
            section += f"- **Key Insiders:** {', '.join(insiders) if insiders else 'N/A'}\n"
            section += f"- **Activity Trend:** {getattr(activity_summary, 'activity_trend', 'N/A')}\n\n"

        section += f"### Significance Assessment\n{getattr(report, 'significance_assessment', 'N/A')}\n\n"
        section += "### Key Insights\n"
        for insight in getattr(report, "key_insights", []) or []:
            section += f"- {insight}\n"
        section += "\n---\n\n"

        return section

    def _generate_sentiment_section(self, ticker: str, report_date: datetime.date, report) -> str:
        """Aggregate multi-source sentiment for the ticker."""
        section = f"## {ticker} (as of {report_date.isoformat()})\n\n"
        market_sentiment = getattr(report, "market_sentiment", None)
        section += "### Market Sentiment\n"
        if market_sentiment:
            section += f"- **Overall Sentiment:** {market_sentiment.overall_sentiment}\n"
            section += f"- **Sentiment Score:** {getattr(market_sentiment, 'sentiment_score', 0):.2f}\n"
            sentiment_trend = ', '.join(market_sentiment.sentiment_trend or []) if hasattr(market_sentiment, 'sentiment_trend') else 'N/A'
            section += f"- **Sentiment Trend:** {sentiment_trend}\n\n"
            section += "### Sources Breakdown\n"
            for source in getattr(market_sentiment, 'sources', []) or []:
                section += f"- **{source.source_type}:** {source.sentiment_score:.2f} ({source.confidence_level:.2f} confidence)\n"
                section += f"  - Indicators: {', '.join(source.key_indicators or [])}\n\n"
        else:
            section += "Unable to retrieve reliable sentiment data.\n\n"

        if getattr(report, "options_flow", None):
            options_flow = report.options_flow
            section += "### Options Flow\n"
            section += f"- **Put/Call Ratio:** {getattr(options_flow, 'put_call_ratio', 0):.2f}\n"
            unusual = ', '.join(getattr(options_flow, 'unusual_activity', []) or [])
            section += f"- **Unusual Activity:** {unusual or 'None noted'}\n"
            section += f"- **Institutional Sentiment:** {getattr(options_flow, 'institutional_sentiment', 'N/A')}\n\n"

        section += f"### Social Sentiment\n{getattr(report, 'social_sentiment', 'N/A')}\n\n"
        section += f"### Analyst Sentiment\n{getattr(report, 'analyst_sentiment', 'N/A')}\n\n"
        section += "### Key Insights\n"
        for insight in getattr(report, "key_insights", []) or []:
            section += f"- {insight}\n"
        section += "\n---\n\n"

        return section

    def _generate_market_conditions_section(self, report_date: datetime.date, report) -> str:
        """Generate the top-level market backdrop report."""
        section = f"# General Market Conditions Report (as of {report_date.isoformat()})\n\n"
        section += f"## Market Overview\n"
        section += f"- **Overall Sentiment:** {report.market_overview.overall_market_sentiment}\n"
        section += f"- **VIX Level:** {report.market_overview.vix_level:.2f}\n"
        section += f"- **Market Breadth:** {report.market_overview.market_breadth}\n"
        section += f"- **Key Drivers:** {', '.join(report.market_overview.key_drivers)}\n\n"
        section += f"## Major Indices\n"
        for idx in report.major_indices:
            section += f"- **{idx.name} ({idx.symbol}):** {idx.current_value:.2f} ({idx.change_percent:+.2f}%)\n"
        section += "\n"
        section += f"## Economic Indicators\n"
        for ind in report.economic_indicators:
            section += f"- **{ind.name}:** {ind.value} ({ind.change}) - {ind.significance}\n"
        section += "\n"
        section += f"## Sector Performance\n"
        for sector in report.sector_performance:
            section += f"- **{sector.sector_name}:** {sector.performance_percent:+.2f}% ({sector.trend})\n"
            section += f"  - Leading Stocks: {', '.join(sector.leading_stocks)}\n"
        section += "\n"
        section += f"## Outlook\n{report.outlook}\n\n"
        section += f"## Key Insights\n"
        for insight in report.key_insights:
            section += f"- {insight}\n"
        section += "\n"

        return section

    def _write_report(self, filename: str, content: str):
        """Write content to disk with UTF-8 encoding."""
        with open(filename, "w", encoding="utf-8") as f:
            f.write(content)
