class AppConfig {
  // Paste your n8n webhook URL here once you have it from n8n.
  // Example: 'https://yourname.app.n8n.cloud/webhook/generate-trip'
  static const String n8nWebhookUrl = 'https://REDACTED.n8n.cloud/webhook/generate-trip';

  // Budget tier → daily range mapping (SAR per person)
  static const Map<String, String> budgetRanges = {
    'economy': '100-300',
    'mid-range': '300-600',
    'comfort': '600-1000',
    'luxury': '1000+',
  };
}
