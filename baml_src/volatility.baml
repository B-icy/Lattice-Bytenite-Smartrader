// =============================================
// Volatility Analysis Agent
// Using Alpaca for market data
// =============================================

// Data Models
class VolatilityMetrics {
    ticker string
    period_analyzed string
    historical_volatility float
    implied_volatility float?
    beta float?
    sharpe_ratio float?
    max_drawdown float
    volatility_regime string // "low", "moderate", "high", "extreme"
}

class RiskAssessment {
    overall_risk_level string
    volatility_trends string[]
    risk_factors string[]
    hedging_recommendations string[]
}

class VolatilityAnalysisReport {
    metrics VolatilityMetrics
    risk_assessment RiskAssessment
    outlook string
    key_insights string[]
}

// Tool Functions
function CalculateVolatilityMetrics(price_data: PricePoint[], ticker: string, benchmark_data: PricePoint[]) -> VolatilityMetrics {
    client AnalysisClient
    prompt #"
    Calculate comprehensive volatility metrics for {{ ticker }} using the provided price data.

    Data:
    {{ price_data }}

    Benchmark data for beta calculation:
    {{ benchmark_data }}

    Calculate:
    1. Historical volatility (annualized standard deviation of returns)
    2. Beta vs benchmark
    3. Sharpe ratio (assuming 2% risk-free rate)
    4. Maximum drawdown
    5. Current volatility regime classification

    If either dataset has fewer than 30 observations, return null for the affected metrics instead of extrapolating.
    {{ ctx.output_format }}
    "#
}

// Main Analysis Function
function GenerateVolatilityReport(ticker: string, period: string, benchmark: string) -> VolatilityAnalysisReport {
    client ReportClient
    prompt #"
    Generate a specialized volatility analysis report for {{ ticker }} using Alpaca market data.

    ANALYSIS PERIOD: {{ period }}
    BENCHMARK: {{ benchmark }}

    DATA SOURCES:
    - Alpaca Market Data API (env.ALPACA_API_KEY, env.ALPACA_SECRET_KEY)
      Fetch historical bars via /v2/stocks/{{ ticker }}/bars and /v2/stocks/{{ benchmark }}/bars

    Report Structure:
    1. VOLATILITY METRICS
       - Historical volatility percentage
       - Beta coefficient
       - Sharpe ratio
       - Maximum drawdown
       - Volatility regime (low/moderate/high/extreme)

    2. RISK ASSESSMENT
       - Overall risk level
       - Key volatility trends
       - Risk factors
       - Hedging recommendations

    3. VOLATILITY OUTLOOK
       - Forward-looking volatility expectations
       - Market conditions impact

    4. KEY INSIGHTS
       - 3-5 actionable insights about volatility patterns

    Use actual price data and statistical methods for calculations.
    Focus on risk management implications.
    If calculations cannot be performed with sufficient data quality, set the relevant fields to null and note the limitation in the narrative sections.

    {{ ctx.output_format }}
    "#
}

// Test Configuration
test TestVolatilityAnalysis {
    functions [GenerateVolatilityReport]
    args {
        ticker "AAPL"
        period "1y"
        benchmark "SPY"
    }
}
