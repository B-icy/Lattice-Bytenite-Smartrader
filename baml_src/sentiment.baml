// =============================================
// Sentiment Analysis Agent
// Using multiple sources for sentiment data
// =============================================

// Data Models
class SentimentSource {
    source_type string // "news", "social_media", "options", "analyst"
    sentiment_score float // -1 to 1
    confidence_level float
    key_indicators string[]
}

class MarketSentiment {
    overall_sentiment string // "extremely_bullish", "bullish", "neutral", "bearish", "extremely_bearish"
    sentiment_score float // -1 to 1
    sources SentimentSource[]
    sentiment_trend string[]
}

class OptionsFlow {
    put_call_ratio float
    unusual_activity string[]
    institutional_sentiment string
}

class SentimentAnalysisReport {
    ticker string
    market_sentiment MarketSentiment
    options_flow OptionsFlow?
    social_sentiment string
    analyst_sentiment string
    key_insights string[]
}

// Tool Functions
function AnalyzeNewsSentimentForSentiment(ticker: string) -> SentimentSource {
    client AnalysisClient
    prompt #"
    Analyze news sentiment for {{ ticker }} from recent articles.

    Fetch and analyze recent news articles to determine:
    1. Sentiment score (-1 to 1)
    2. Confidence level (0-1)
    3. Key positive/negative indicators

    Return sentiment analysis focused on market perception.
    "#
}

function AnalyzeSocialSentiment(ticker: string) -> SentimentSource {
    client AnalysisClient
    prompt #"
    Analyze social media sentiment for {{ ticker }}.

    Search social media platforms (Twitter, Reddit, etc.) for recent discussions about {{ ticker }}.

    Determine:
    1. Overall social sentiment score
    2. Confidence in the analysis
    3. Key themes driving sentiment

    Focus on retail investor sentiment and trending topics.
    If social data is sparse or unavailable, return neutral sentiment_score and a confidence_level of 0.
    "#
}

function AnalyzeOptionsSentiment(ticker: string) -> OptionsFlow {
    client AnalysisClient
    prompt #"
    Analyze options market sentiment for {{ ticker }}.

    Examine options data to determine:
    1. Put/call ratio
    2. Unusual options activity
    3. Institutional positioning sentiment

    Use options flow data to gauge market expectations.
    If you cannot obtain options data with sufficient depth, set all numeric fields to null and describe the limitation.
    "#
}

// Main Analysis Function
function GenerateSentimentAnalysisReport(ticker: string) -> SentimentAnalysisReport {
    client ReportClient
    prompt #"
    Generate a comprehensive sentiment analysis report for {{ ticker }}.

    Report Structure:
    1. MARKET SENTIMENT OVERVIEW
       - Overall sentiment score and classification
       - Breakdown by source (news, social, options, analyst)

    2. SENTIMENT SOURCES ANALYSIS
       - News sentiment with key indicators
       - Social media sentiment trends
       - Options flow analysis
       - Analyst sentiment summary

    3. SENTIMENT TREND
       - How sentiment has changed recently
       - Potential drivers of sentiment shifts

    4. KEY INSIGHTS
       - 3-5 actionable insights from sentiment analysis
       - Risk considerations based on sentiment extremes

    Integrate multiple data sources for a holistic sentiment view.
    Consider contrarian indicators and sentiment extremes.
    If any upstream analysis returned nulls, carry those forward and explicitly call out the data gaps instead of extrapolating.

    {{ ctx.output_format }}
    "#
}

// Test Configuration
test TestSentimentAnalysis {
    functions [GenerateSentimentAnalysisReport]
    args {
        ticker "AAPL"
    }
}
