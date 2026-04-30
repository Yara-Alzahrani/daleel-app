class AppConfig {
  static const String n8nWebhookUrl =
      'https://REDACTED.n8n.cloud/webhook/generate-trip';

  static const String n8nRegenerateUrl =
      'https://REDACTED.n8n.cloud/webhook/regenerate-slot';

  static const Map<String, String> budgetRanges = {
    'economy': '100-300',
    'mid-range': '300-600',
    'comfort': '600-1000',
    'luxury': '1000+',
  };
}
