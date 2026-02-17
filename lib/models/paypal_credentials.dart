class PaypalCredentials {
  final String clientId;
  final String secretKey;

  PaypalCredentials({
    required this.clientId,
    required this.secretKey,
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
    };
  }

  factory PaypalCredentials.fromJson(Map<String, dynamic> json) {
    return PaypalCredentials(
      clientId: json['clientId']?.toString() ?? '',
      secretKey: json['secretKey']?.toString() ?? '',
    );
  }

}