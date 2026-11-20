class AppConfig {
  // Provided at build time, e.g.:
  // flutter run --dart-define=N8N_WEBHOOK_URL=... --dart-define=N8N_REGENERATE_URL=...
  static const String n8nWebhookUrl = String.fromEnvironment('N8N_WEBHOOK_URL');

  static const String n8nRegenerateUrl =
      String.fromEnvironment('N8N_REGENERATE_URL');

  static const Map<String, String> budgetRanges = {
    'economy': '100-300',
    'mid-range': '300-600',
    'comfort': '600-1000',
    'luxury': '1000+',
  };
}
