// =============================================
// Insider Trading Analysis Agent
// Using FMP for insider data
// =============================================

// Data Models
class InsiderTrade {
    name string
    title string
    transaction_type string // "Buy", "Sell"
    shares int
    price float
    value float
    transaction_date string
    filing_date string
    security_type string
}

class InsiderActivitySummary {
    total_buy_volume int
    total_sell_volume int
    net_insider_activity float
    key_insiders string[]
    activity_trend string // "accumulating", "distributing", "neutral"
}

class InsiderAnalysisReport {
    ticker string
    recent_transactions InsiderTrade[]
    activity_summary InsiderActivitySummary
    significance_assessment string
    key_insights string[]
}

// Tool Functions
function AnalyzeInsiderActivity(transactions: InsiderTrade[], ticker: string) -> InsiderActivitySummary {
    client AnalysisClient
    prompt #"
    Analyze insider trading activity patterns for {{ ticker }}.

    Transactions:
    {{ transactions }}

    Analyze:
    1. Total buy vs sell volumes
    2. Net insider activity (buy - sell value)
    3. Key insiders making transactions
    4. Overall activity trend (accumulating/distributing/neutral)

    Ignore placeholder or anonymized names and flag situations with fewer than 2 valid transactions by marking totals as null.
    Calculate volumes and values in appropriate units.

    {{ ctx.output_format }}
    "#
}

// Main Analysis Function
function GenerateInsiderReport(ticker: string) -> InsiderAnalysisReport {
    client ReportClient
    prompt #"
    Generate a specialized insider trading analysis report for {{ ticker }} using FMP insider data.

    DATA SOURCES:
    - Financial Modeling Prep Insider Trading API (env.FMP_API_KEY)
      Endpoint: /v4/insider-trading?symbol={{ ticker }}

    Report Structure:
    1. RECENT INSIDER TRANSACTIONS
       - List of 5-10 most recent transactions
       - Include insider name, title, type, shares, price, date

    2. ACTIVITY SUMMARY
       - Total buy/sell volumes
       - Net insider activity
       - Key active insiders

    3. SIGNIFICANCE ASSESSMENT
       - What the insider activity suggests about company outlook
       - Potential market implications

    4. KEY INSIGHTS
       - 3-5 actionable insights from insider trading patterns

    Focus on significant transactions and patterns that may indicate insider confidence or concerns.
    Exclude entries older than 12 months and omit placeholder names like "John Doe"; if no qualifying transactions exist, return an empty list and explain the limitation.

    {{ ctx.output_format }}
    "#
}

// Test Configuration
test TestInsiderAnalysis {
    functions [GenerateInsiderReport]
    args {
        ticker "AAPL"
    }
}
