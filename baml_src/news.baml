// =============================================
// News Analysis Agent
// Using FMP for news data
// =============================================

// Data Models
class NewsArticle {
    title string
    content string
    published_date string
    source string
    url string
    sentiment_score float? // -1 to 1
    relevance_score float?
}

class NewsSentimentAnalysis {
    overall_sentiment string // "bullish", "bearish", "neutral"
    sentiment_trend string[]
    key_themes string[]
    market_impact_assessment string
}

class NewsAnalysisReport {
    ticker string
    articles NewsArticle[]
    sentiment_analysis NewsSentimentAnalysis
    summary string
    key_insights string[]
}

// Tool Functions
function AnalyzeNewsSentiment(articles: NewsArticle[], ticker: string) -> NewsSentimentAnalysis {
    client AnalysisClient
    prompt #"
    Analyze sentiment and market impact of news articles for {{ ticker }}.

    Articles:
    {{ articles }}

    Analyze:
    1. Overall sentiment (bullish/bearish/neutral)
    2. Sentiment trends over time
    3. Key themes and topics
    4. Potential market impact assessment

    If there are fewer than 2 recent articles, return null fields and note the insufficiency rather than extrapolating.
    Use natural language processing to determine sentiment scores.

    {{ ctx.output_format }}
    "#
}

// Main Analysis Function
function GenerateNewsReport(ticker: string) -> NewsAnalysisReport {
    client ReportClient
    prompt #"
    Generate a specialized news analysis report for {{ ticker }} using FMP news data.

    DATA SOURCES:
    - Financial Modeling Prep Stock News API (env.FMP_API_KEY)
      Endpoint: /v3/stock_news?tickers={{ ticker }}

    Report Structure:
    1. RECENT NEWS ARTICLES
       - List of 5-10 most recent relevant articles
       - Include title, source, date, and brief summary

    2. SENTIMENT ANALYSIS
       - Overall market sentiment from news
       - Sentiment trends and changes
       - Key themes emerging from coverage

    3. MARKET IMPACT ASSESSMENT
       - How news might affect stock price
       - Potential catalysts or headwinds

    4. NEWS SUMMARY
       - Concise overview of recent developments

    5. KEY INSIGHTS
       - 3-5 actionable insights from news analysis

    Focus on high-quality, relevant news sources and objective analysis.
    Only include articles published within the last 120 days relative to the report date.
    Do not fabricate headlines or metrics; if no qualifying articles are returned, provide an empty list and explain the limitation in the summary.

    {{ ctx.output_format }}
    "#
}

// Test Configuration
test TestNewsAnalysis {
    functions [GenerateNewsReport]
    args {
        ticker "AAPL"
    }
}
