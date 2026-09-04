class UsageSummary {
  const UsageSummary({
    required this.planId,
    required this.totalBytesUsed,
    required this.byCategory,
  });

  final String planId;
  final int totalBytesUsed;
  final Map<String, int> byCategory;

  factory UsageSummary.fromJson(Map<String, dynamic> json) {
    final rawByCategory =
        (json['byCategory'] as Map<String, dynamic>?) ?? const {};
    return UsageSummary(
      planId: json['planId'] as String,
      totalBytesUsed: json['totalBytesUsed'] as int,
      byCategory: rawByCategory.map(
        (key, value) => MapEntry(key, value as int),
      ),
    );
  }
}
