// =============================================
// Yahoo Finance Historical Data Analysis BAML Script
// Using Mercury Coder on OpenRouter
// =============================================

// Data Models (Updated for Broader Statistics)
class StockStatistics {
    pe_ratio float?
    forward_pe_ratio float?
    peg_ratio float?
    dividend_yield float?
    price_to_book float?
    fifty_two_week_high float?
    fifty_two_week_low float?
}

class StockData {
    ticker string
    company_name string
    current_price float
    currency string
    market_cap string?
    statistics StockStatistics // Nested class for detailed stats
}

class PricePoint {
    date string
    open float
    high float
    low float
    close float
    volume int
    adj_close float?
}

class PriceAnalysis {
    ticker string
    period_analyzed string
    total_return_percent float
    volatility float
    max_price float
    min_price float
    average_volume int
    trend_direction string // "bullish", "bearish", "sideways"
    key_insights string[]
}

class TechnicalIndicators {
    sma_20 float?
    sma_50 float?
    rsi float?
    bollinger_upper float?
    bollinger_lower float?
    support_level float?
    resistance_level float?
}

class MarketComparison {
    ticker string
    benchmark_ticker string
    outperformance_percent float
    beta float?
    correlation float
    relative_strength string
}

class ComprehensiveReport {
    executive_summary string
    price_analysis PriceAnalysis
    technical_analysis TechnicalIndicators
    fundamental_analysis StockStatistics // Added for fundamental metrics
    market_comparison MarketComparison?
    risk_assessment string
    investment_outlook string
    key_recommendations string[]
}

// Tool Functions (Updated)
function FetchHistoricalData(ticker: string, period: string, interval: string) -> PricePoint[] {
    client YahooFinanceClient
    prompt #"
    Fetch historical price data for ticker {{ ticker }} over {{ period }} period with {{ interval }} intervals.

    Use the Yahoo Finance API endpoint:
    https://query1.finance.yahoo.com/v8/finance/chart/{{ ticker }}?period1={{ start_timestamp }}&period2={{ end_timestamp }}&interval={{ interval }}

    Extract and return the following data points for each trading session:
    - Date (YYYY-MM-DD format)
    - Opening price
    - High price
    - Low price
    - Closing price
    - Trading volume
    - Adjusted closing price (if available)

    {{ ctx.output_format }}
    "#
}

function GetStockInfo(ticker: string) -> StockData {
    client YahooFinanceClient
    prompt #"
    Retrieve detailed stock information for ticker {{ ticker }} from Yahoo Finance.

    Use the quote summary endpoint with multiple modules:
    https://query1.finance.yahoo.com/v10/finance/quoteSummary/{{ ticker }}?modules=price,summaryDetail,defaultKeyStatistics

    Extract the following data:
    - From 'price' module:
        - longName (map to company_name)
        - regularMarketPrice (map to current_price)
        - currency
        - marketCap (map to market_cap)
    - From 'summaryDetail' and 'defaultKeyStatistics' modules:
        - trailingPE (map to statistics.pe_ratio)
        - forwardPE (map to statistics.forward_pe_ratio)
        - pegRatio (map to statistics.peg_ratio)
        - dividendYield (map to statistics.dividend_yield)
        - priceToBook (map to statistics.price_to_book)
        - fiftyTwoWeekHigh (map to statistics.fifty_two_week_high)
        - fiftyTwoWeekLow (map to statistics.fifty_two_week_low)

    {{ ctx.output_format }}
    "#
}

function CalculateTechnicalIndicators(price_data: PricePoint[], ticker: string) -> TechnicalIndicators {
    client AnalysisClient
    prompt #"
    Given this historical price data for {{ ticker }}:
    {{ price_data }}

    Calculate the following technical indicators:
    1. Simple Moving Average (20-day and 50-day)
    2. Relative Strength Index (RSI) - current value
    3. Bollinger Bands (upper and lower)
    4. Support and resistance levels based on recent price action

    Use standard financial calculation methods for each indicator.

    {{ ctx.output_format }}
    "#
}

function AnalyzePricePerformance(price_data: PricePoint[], ticker: string, period: string) -> PriceAnalysis {
    client AnalysisClient
    prompt #"
    Analyze the price performance for {{ ticker }} over {{ period }} period using this data:
    {{ price_data }}

    Calculate and provide:
    1. Total return percentage (first to last price)
    2. Price volatility (standard deviation of daily returns)
    3. Maximum and minimum prices in the period
    4. Average daily trading volume
    5. Overall trend direction (bullish/bearish/sideways)
    6. 3-5 key insights about price movement patterns

    Base your analysis on actual price movements and trading patterns.

    {{ ctx.output_format }}
    "#
}

function CompareToMarket(ticker: string, price_data: PricePoint[], benchmark_ticker: string) -> MarketComparison {
    client AnalysisClient
    prompt #"
    Compare {{ ticker }} performance against {{ benchmark_ticker }} benchmark using the provided price data:
    {{ price_data }}

    You'll need to fetch {{ benchmark_ticker }} data for the same period and calculate:
    1. Relative outperformance/underperformance percentage
    2. Beta coefficient (if possible to estimate)
    3. Correlation with the benchmark
    4. Relative strength assessment

    Provide a clear comparison of how {{ ticker }} performed relative to the market.

    {{ ctx.output_format }}
    "#
}

// Main Analysis Function (Updated)
function GenerateHistoricalAnalysisReport(
    ticker: string,
    period: string,
    benchmark: string,
    interval: string
) -> ComprehensiveReport {
    client ReportClient
    prompt #"
    Generate a comprehensive historical analysis report for {{ ticker }} with these requirements:

    ANALYSIS PERIOD: {{ period }}
    DATA INTERVAL: {{ interval }}
    BENCHMARK: {{ benchmark }}

    Your report must include:

    1. EXECUTIVE SUMMARY (2-3 paragraphs)
       - Overall performance assessment
       - Key highlights (technical and fundamental)
       - Market context

    2. PRICE ANALYSIS
       - Analyze total returns, volatility, and price ranges
       - Identify trend patterns

    3. TECHNICAL ANALYSIS
       - Assess moving averages, momentum indicators, and trading signals
       - Identify support/resistance levels

    4. FUNDAMENTAL ANALYSIS (New Section)
       - Analyze key valuation metrics: P/E, Forward P/E, PEG, P/B
       - Discuss dividend yield
       - Contextualize current price with 52-week range

    5. MARKET COMPARISON
       - Compare performance vs {{ benchmark }}
       - Assess relative strength and correlation

    6. RISK ASSESSMENT
       - Evaluate price volatility and valuation risk (e.g., high P/E)
       - Assess drawdown periods

    7. INVESTMENT OUTLOOK
       - Provide a forward-looking perspective combining technical and fundamental factors.
       - Discuss potential scenarios

    8. KEY RECOMMENDATIONS
       - Provide 3-5 actionable insights based on the holistic analysis
       - Include risk considerations

    Base all analysis on actual historical data and established financial principles.
    Ensure the report is professional, data-driven, and actionable.

    {{ ctx.output_format }}
    "#
}

// OpenRouter Client Configurations with Mercury Coder
client YahooFinanceClient {
    provider openai
    options {
        model "inception/mercury-coder"
        api_key env.OPENROUTER_API_KEY
        base_url "https://openrouter.ai/api/v1"
        max_tokens 2000
        temperature 0.1
        default_headers {
            "HTTP-Referer" "https://localhost:3000"
            "X-Title" "BAML Yahoo Finance Analysis"
        }
    }
}

client AnalysisClient {
    provider openai
    options {
        model "inception/mercury-coder"
        api_key env.OPENROUTER_API_KEY
        base_url "https://openrouter.ai/api/v1"
        max_tokens 1500
        temperature 0.2
        default_headers {
            "HTTP-Referer" "https://localhost:3000"
            "X-Title" "BAML Financial Analysis"
        }
    }
}

client ReportClient {
    provider openai
    options {
        model "inception/mercury-coder"
        api_key env.OPENROUTER_API_KEY
        base_url "https://openrouter.ai/api/v1"
        max_tokens 3000
        temperature 0.3
        default_headers {
            "HTTP-Referer" "https://localhost:3000"
            "X-Title" "BAML Report Generation"
        }
    }
}

// Test Configuration
test TestAppleAnalysis {
    functions [GenerateHistoricalAnalysisReport]
    args {
        ticker "AAPL"
        period "1y"
        benchmark "SPY"
        interval "1d"
    }
}

test TestTeslaQuarterlyAnalysis {
    functions [GenerateHistoricalAnalysisReport]
    args {
        ticker "TSLA"
        period "3mo"
        benchmark "QQQ"
        interval "1d"
    }
}

test TestCryptoAnalysis {
    functions [GenerateHistoricalAnalysisReport]
    args {
        ticker "BTC-USD"
        period "6mo"
        benchmark "^IXIC"
        interval "1d"
    }
}