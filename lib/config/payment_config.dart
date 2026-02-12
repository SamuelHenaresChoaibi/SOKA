class PaymentConfig {
  static const bool paypalSandboxMode =
      bool.fromEnvironment('PAYPAL_SANDBOX_MODE', defaultValue: true);

  static const bool paypalOverrideInsecureClientCredentials =
      bool.fromEnvironment('PAYPAL_OVERRIDE_INSECURE_CLIENT_CREDENTIALS', defaultValue: false);

  static const String paypalClientId =
      String.fromEnvironment('PAYPAL_CLIENT_ID', defaultValue: '');

  static const String paypalSecretKey =
      String.fromEnvironment('PAYPAL_SECRET_KEY', defaultValue: '');

  static bool get isPayPalConfigured =>
      paypalClientId.trim().isNotEmpty && paypalSecretKey.trim().isNotEmpty;
}