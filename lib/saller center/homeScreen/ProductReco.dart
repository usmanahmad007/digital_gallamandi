class ProductReco {
  final String season;
  final List<String> crops;
  final List<String> fruits;
  final List<String> vegetables;

  ProductReco({
    required this.season,
    required this.crops,
    required this.fruits,
    required this.vegetables,
  });

  factory ProductReco.fromJson(Map<String, dynamic> json) {
    return ProductReco(
      season: json['Season'],
      crops: json['Crops'].split(', '),
      fruits: json['Fruits'].split(', '),
      vegetables: json['Vegetables'].split(', '),
    );
  }
}