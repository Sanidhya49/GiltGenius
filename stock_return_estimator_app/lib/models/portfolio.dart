class Holding {
  final String ticker;
  final double quantity;
  Holding({required this.ticker, required this.quantity});

  Map<String, dynamic> toJson() => {'ticker': ticker, 'quantity': quantity};

  factory Holding.fromJson(Map<String, dynamic> json) => Holding(
    ticker: json['ticker'],
    quantity: (json['quantity'] as num).toDouble(),
  );
}

class Portfolio {
  final List<Holding> holdings;
  Portfolio({required this.holdings});

  Map<String, dynamic> toJson() => {
    'holdings': holdings.map((h) => h.toJson()).toList(),
  };

  factory Portfolio.fromJson(Map<String, dynamic> json) => Portfolio(
    holdings: (json['holdings'] as List)
        .map((h) => Holding.fromJson(h))
        .toList(),
  );
}
