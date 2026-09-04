/// Presentation-only formatting for the dashboard — kept at the app
/// layer, not in `packages/plans`, since none of it is domain logic.
library;

/// A country code ("JP") to its flag emoji via Unicode regional indicator
/// symbols — no dependency needed for two letters of arithmetic.
String flagEmoji(String countryCode) {
  final code = countryCode.toUpperCase();
  if (code.length != 2) {
    return '';
  }
  const base = 0x1F1E6; // Regional Indicator Symbol Letter A
  const letterA = 0x41;
  final first = base + (code.codeUnitAt(0) - letterA);
  final second = base + (code.codeUnitAt(1) - letterA);
  return String.fromCharCode(first) + String.fromCharCode(second);
}

/// Formats a size already expressed in megabytes as "X.X GB" once it
/// crosses 1000 MB, otherwise "X MB".
String formatMegabytes(double megabytes) {
  if (megabytes >= 1000) {
    return '${(megabytes / 1000).toStringAsFixed(1)} GB';
  }
  return '${megabytes.round()} MB';
}

/// Formats a raw byte count the same way.
String formatBytes(int bytes) => formatMegabytes(bytes / (1024 * 1024));

String expiryLabel(int daysRemaining) {
  if (daysRemaining <= 0) {
    return 'Expires today';
  }
  if (daysRemaining == 1) {
    return 'Expires tomorrow';
  }
  return 'Expires in $daysRemaining days';
}

const Map<String, String> usageCategoryLabels = {
  'maps': 'Maps',
  'social': 'Social',
  'video': 'Video',
  'browsing': 'Browsing',
  'other': 'Other',
};

String usageCategoryLabel(String category) =>
    usageCategoryLabels[category] ?? category;

/// A small local formatter rather than pulling in `intl`/`timeago` for one
/// label — RoamPulse doesn't need locale-aware relative time yet.
String relativeTime(DateTime since) {
  final elapsed = DateTime.now().difference(since);
  if (elapsed < const Duration(minutes: 1)) {
    return 'moments ago';
  }
  if (elapsed < const Duration(hours: 1)) {
    final minutes = elapsed.inMinutes;
    return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
  }
  if (elapsed < const Duration(days: 1)) {
    final hours = elapsed.inHours;
    return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
  }
  final days = elapsed.inDays;
  return '$days ${days == 1 ? 'day' : 'days'} ago';
}
