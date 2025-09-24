// =============================================
// Yahoo Finance Historical Data Analysis BAML Script
// Using Mercury Coder on OpenRouter
// =============================================

// Data Models (unchanged)
class StockData {
    ticker string
    company_name string
    current_price float
    currency string
    market_cap string?
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

class FundamentalAnalysis {
    pe_ratio float?
    forward_pe_ratio float?
    peg_ratio float?
    price_to_book float?
    dividend_yield float?
    fifty_two_week_high float?
    fifty_two_week_low float?
}

class ComprehensiveReport {
    executive_summary string
    price_analysis PriceAnalysis
    fundamental_analysis FundamentalAnalysis?
    technical_analysis TechnicalIndicators
    market_comparison MarketComparison?
    risk_assessment string
    investment_outlook string
    key_recommendations string[]
}




// Tool Functions
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

    If the API request fails or returns no data, return an empty list rather than fabricated values.
    {{ ctx.output_format }}
    "#
}

function GetStockInfo(ticker: string) -> StockData {
    client YahooFinanceClient
    prompt #"
    Retrieve basic stock information for ticker {{ ticker }} from Yahoo Finance.
    
    Use the quote summary endpoint:
    https://query1.finance.yahoo.com/v10/finance/quoteSummary/{{ ticker }}?modules=price,summaryDetail
    
    Extract:
    - Company name
    - Current stock price
    - Currency
    - Market capitalization
    
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

// Main Analysis Function
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
       - Key highlights and lowlights
       - Market context

    2. PRICE ANALYSIS
       - Use the historical data to calculate total returns
       - Analyze volatility and price ranges
       - Identify trend patterns
       - Highlight significant price movements

    3. FUNDAMENTAL ANALYSIS
       - P/E ratio, forward P/E, PEG ratio
       - Price-to-book ratio
       - Dividend yield
       - 52-week high and low

    4. TECHNICAL ANALYSIS
       - Calculate moving averages
       - Assess momentum indicators
       - Identify support/resistance levels
       - Evaluate trading signals

    5. MARKET COMPARISON
       - Compare performance vs {{ benchmark }}
       - Calculate relative strength
       - Assess correlation patterns

    6. RISK ASSESSMENT
       - Evaluate price volatility
       - Identify risk factors
       - Assess drawdown periods

    7. INVESTMENT OUTLOOK
       - Provide forward-looking perspective
       - Consider technical and fundamental factors
       - Discuss potential scenarios

    8. KEY RECOMMENDATIONS
       - Provide 3-5 actionable insights
       - Include risk considerations
       - Suggest monitoring points
    
    QUALITY REQUIREMENTS
    - Base all analysis strictly on the retrieved quantitative data; never invent metrics.
    - If any required metric cannot be produced, set the corresponding field to null and explain the gap in prose.
    - Express dividend_yield as a decimal fraction (e.g., 0.021 for 2.1%).
    - Keep commentary focused on the trailing period ending on the most recent available trading day.

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
