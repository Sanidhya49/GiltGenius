const String backendUrl = 'http://127.0.0.1:5000/predict';

const List<String> allFeatures = [
  'Return_Lag_1',
  'Return_Lag_5',
  'MA_10',
  'RSI_14',
  'BBL_20',
  'BBM_20',
  'BBU_20',
  'MACD',
  'MACD_signal',
  'MACD_hist',
  'STOCH_k',
  'STOCH_d',
  'ATR_14',
];

const Map<String, String> featureLabels = {
  'Return_Lag_1': '1-Day Return Lag',
  'Return_Lag_5': '5-Day Return Lag',
  'MA_10': '10-Day Moving Avg',
  'RSI_14': 'RSI (14)',
  'BBL_20': 'BB Lower (20)',
  'BBM_20': 'BB Middle (20)',
  'BBU_20': 'BB Upper (20)',
  'MACD': 'MACD',
  'MACD_signal': 'MACD Signal',
  'MACD_hist': 'MACD Histogram',
  'STOCH_k': 'Stochastic %K',
  'STOCH_d': 'Stochastic %D',
  'ATR_14': 'ATR (14)',
};
