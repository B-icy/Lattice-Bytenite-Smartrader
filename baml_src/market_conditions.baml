// =============================================
// General Market Conditions Agent
// Using Alpaca and FMP for market data
// =============================================

// Data Models
class MarketIndex {
    symbol string
    name string
    current_value float
    change_percent float
    volume int?
}

class EconomicIndicator {
    name string
    value string
    date string
    change string
    significance string
}

class SectorPerformance {
    sector_name string
    performance_percent float
    leading_stocks string[]
    trend string
}

class MarketOverview {
    overall_market_sentiment string // "bullish", "bearish", "neutral"
    vix_level float
    market_breadth string
    key_drivers string[]
}

class MarketConditionsAnalysisReport {
    market_overview MarketOverview
    major_indices MarketIndex[]
    economic_indicators EconomicIndicator[]
    sector_performance SectorPerformance[]
    outlook string
    key_insights string[]
}

// Tool Functions
function AnalyzeSectorPerformance() -> SectorPerformance[] {
    client AnalysisClient
    prompt #"
    Analyze performance of major market sectors.

    Sectors to analyze:
    - Technology
    - Healthcare
    - Financials
    - Energy
    - Consumer Discretionary
    - Industrials

    For each sector:
    1. Performance percentage (YTD or recent period)
    2. Leading stocks
    3. Current trend (uptrend, downtrend, sideways)

    Use sector ETF data or index data.
    If any sector lacks recent data, set its performance_percent to null and explain the gap in the trend field.
    "#
}

// Main Analysis Function
function GenerateMarketConditionsReport() -> MarketConditionsAnalysisReport {
    client ReportClient
    prompt #"
    Generate a comprehensive general market conditions report using Alpaca and FMP data.

    DATA SOURCES:
    - Alpaca Market Data API (env.ALPACA_API_KEY, env.ALPACA_SECRET_KEY)
      Fetch indices via /v2/stocks/SPY/bars, /v2/stocks/DIA/bars, etc.
    - Financial Modeling Prep APIs (env.FMP_API_KEY)
      Economic indicators via /api/v3/economic, market performance via /api/v3/market-performance

    Report Structure:
    1. MARKET OVERVIEW
       - Overall market sentiment
       - VIX level and volatility assessment
       - Market breadth (advancing vs declining stocks)

    2. MAJOR INDICES PERFORMANCE
       - Current values and daily changes for key indices
       - Volume analysis

    3. ECONOMIC INDICATORS
       - Key economic data and trends
       - Implications for markets

    4. SECTOR PERFORMANCE
       - Performance by sector
       - Leading and lagging sectors

    5. MARKET OUTLOOK
       - Short-term market direction
       - Key drivers and risks

    6. KEY INSIGHTS
       - 3-5 actionable insights for investors
       - Tactical considerations

    Provide context for how these conditions might affect individual stocks.
    Highlight any data limitations or stale indicators rather than filling them with estimates.

    {{ ctx.output_format }}
    "#
}

// Test Configuration
test TestMarketConditions {
    functions [GenerateMarketConditionsReport]
    args {}
}
