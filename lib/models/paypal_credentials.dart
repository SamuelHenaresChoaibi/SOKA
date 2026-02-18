class PaypalCredentials {
  final String clientId;
  final String secretKey;
  final bool sandboxMode;

  PaypalCredentials({
    required this.clientId,
    required this.secretKey,
    required this.sandboxMode,
  });

  void validate() {
    if (clientId.trim().isEmpty) {
      throw ArgumentError('Client ID cannot be empty');
    }
    if (secretKey.trim().isEmpty) {
      throw ArgumentError('Secret cannot be empty');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'secretKey': secretKey,
      'sandboxMode': sandboxMode,
    };
  }

  factory PaypalCredentials.fromJson(Map<String, dynamic> json) {
    return PaypalCredentials(
      clientId: json['clientId']?.toString() ?? '',
      secretKey: json['secretKey']?.toString() ?? '',
      sandboxMode: _parseSandboxMode(json['sandboxMode']),
    );
  }

  static bool _parseSandboxMode(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' ||
          normalized == '1' ||
          normalized == 'sandbox') {
        return true;
      }
      if (normalized == 'false' ||
          normalized == '0' ||
          normalized == 'live' ||
          normalized == 'production') {
        return false;
      }
    }
    return true;
  }
}
