class PaymentConfig {
  static const bool paypalSandboxMode =
      bool.fromEnvironment('PAYPAL_SANDBOX_MODE', defaultValue: true);

  static const bool paypalOverrideInsecureClientCredentials =
      bool.fromEnvironment('PAYPAL_OVERRIDE_INSECURE_CLIENT_CREDENTIALS', defaultValue: false);

  static const String paypalClientId =
      String.fromEnvironment('PAYPAL_CLIENT_ID', defaultValue: 'Ab9IqE_uBKMB7WfDNszWV-AECEb3E17WxKC5Hug_QREtaJYq7kLMOHDiEKooXA0pekncezSSRYhNjsNL');

  static const String paypalSecretKey =
      String.fromEnvironment('PAYPAL_SECRET_KEY', defaultValue: 'EN_zvYfYTAP1Ezm9MnIlyPKneoRfdL6vwL-vtWKa0f70u6sjR2mazJHQYJ3h5uY2rVj_QBxTRSYhWhJa');

  static bool get isPayPalConfigured =>
      paypalClientId.trim().isNotEmpty && paypalSecretKey.trim().isNotEmpty;
}