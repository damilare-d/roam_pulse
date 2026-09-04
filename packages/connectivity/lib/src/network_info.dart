class NetworkInfo {
  const NetworkInfo({required this.carrierName, required this.technology});

  final String carrierName;
  final String technology;

  factory NetworkInfo.fromJson(Map<String, dynamic> json) {
    return NetworkInfo(
      carrierName: json['carrierName'] as String,
      technology: json['technology'] as String,
    );
  }
}
