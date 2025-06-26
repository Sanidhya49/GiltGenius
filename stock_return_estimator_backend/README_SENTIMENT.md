# Sentiment Analysis Setup Guide

This guide will help you set up the sentiment analysis feature for the Stock Return Estimator app.

## Features

The sentiment analysis module provides:
- **News Sentiment Analysis**: Analyzes recent news articles about stocks using TextBlob
- **Technical Sentiment Factors**: Combines price momentum, volume, and market cap data
- **Comprehensive Sentiment Score**: Weighted combination of multiple factors
- **Real-time News**: Fetches recent news articles from NewsAPI

## Setup Instructions

### 1. Get a NewsAPI Key

1. Go to [NewsAPI.org](https://newsapi.org/)
2. Sign up for a free account
3. Get your API key from the dashboard
4. The free tier allows 1,000 requests per day

### 2. Configure Environment Variables

Set your NewsAPI key as an environment variable:

**Windows (PowerShell):**
```powershell
$env:NEWS_API_KEY="your_api_key_here"
```

**Windows (Command Prompt):**
```cmd
set NEWS_API_KEY=your_api_key_here
```

**Linux/Mac:**
```bash
export NEWS_API_KEY="your_api_key_here"
```

### 3. Install Dependencies

Install the required Python packages:

```bash
pip install textblob newsapi-python
```

Or update your requirements.txt and run:
```bash
pip install -r requirements.txt
```

### 4. Initialize TextBlob

On first run, TextBlob will download required NLTK data:

```python
from textblob import TextBlob
# This will trigger the download of required data
```

## Usage

### Backend API

The sentiment analysis is available via the `/sentiment` endpoint:

```bash
POST /sentiment
Content-Type: application/json

{
  "ticker": "AAPL"
}
```

### Response Format

```json
{
  "status": "success",
  "data": {
    "ticker": "AAPL",
    "overall_sentiment": "bullish",
    "sentiment_score": 0.245,
    "sentiment_factors": [
      {
        "factor": "News Sentiment",
        "value": 0.3,
        "weight": 0.4,
        "description": "News sentiment: positive"
      },
      {
        "factor": "Price Momentum",
        "value": 0.15,
        "weight": 0.3,
        "description": "30-day price change: 15.00%"
      }
    ],
    "news_data": {
      "articles": [...],
      "sentiment_summary": {
        "polarity": 0.3,
        "subjectivity": 0.5,
        "sentiment": "positive",
        "article_count": 15
      }
    },
    "stock_info": {
      "name": "Apple Inc.",
      "sector": "Technology",
      "industry": "Consumer Electronics",
      "market_cap": 3000000000000,
      "current_price": 150.0
    }
  }
}
```

### Flutter App

1. Navigate to the home page
2. Click the "Sentiment Analysis" button
3. Enter a stock ticker (e.g., AAPL, TSLA, GOOGL)
4. View comprehensive sentiment analysis

## Sentiment Factors

The sentiment score is calculated using these weighted factors:

1. **News Sentiment (40%)**: Analysis of recent news articles
2. **Price Momentum (30%)**: 30-day price change
3. **Volume (20%)**: Current volume vs. average volume
4. **Market Cap (10%)**: Company size factor

## Sentiment Categories

- **Bullish**: Sentiment score > 0.2
- **Neutral**: Sentiment score between -0.2 and 0.2
- **Bearish**: Sentiment score < -0.2

## Troubleshooting

### Common Issues

1. **"News API error"**: Check your API key and daily request limit
2. **"No news articles found"**: Try a different ticker or wait for more news
3. **"Network error"**: Check your internet connection
4. **TextBlob errors**: Ensure NLTK data is downloaded

### API Limits

- NewsAPI free tier: 1,000 requests/day
- Consider caching results for frequently accessed tickers
- Implement rate limiting for production use

## Customization

You can customize the sentiment analysis by modifying:

- **Factor weights** in `get_stock_sentiment()` function
- **News search period** (default: 7 days)
- **Sentiment thresholds** for bullish/bearish classification
- **Additional technical indicators** for sentiment calculation

## Security Notes

- Never commit your API key to version control
- Use environment variables for sensitive data
- Consider implementing API key rotation for production
- Monitor API usage to avoid rate limits 