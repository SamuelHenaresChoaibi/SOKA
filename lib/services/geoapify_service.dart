import 'dart:convert';

import 'package:http/http.dart' as http;

class GeoapifyService {
  GeoapifyService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String apiKey = String.fromEnvironment(
    'GEOAPIFY_API_KEY',
    defaultValue: 'b77a8697964a4f5d8b0a3e134ad32b1b',
  );

  static bool get hasApiKey => apiKey.trim().isNotEmpty;

  Future<List<GeoapifySuggestion>> suggest(
    String query, {
    int limit = 5,
    String language = 'es',
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    if (!hasApiKey) return [];

    final uri = Uri.https(
      'api.geoapify.com',
      '/v1/geocode/autocomplete',
      {
        'text': trimmed,
        'limit': limit.toString(),
        'lang': language,
        'apiKey': apiKey,
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) return [];

    final Map<String, dynamic> data = json.decode(response.body);
    final features = data['features'] as List<dynamic>? ?? const [];

    return features
        .map((raw) => GeoapifySuggestion.fromJson(raw as Map<String, dynamic>))
        .toList();
  }

  Future<GeocodingResult> validateAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      return GeocodingResult.invalid('La ubicacion no puede estar vacia.');
    }

    if (!hasApiKey) {
      return GeocodingResult.invalid(
        'Configura GEOAPIFY_API_KEY para validar la ubicacion.',
      );
    }

    final suggestions = await suggest(trimmed, limit: 1);
    if (suggestions.isEmpty) {
      return GeocodingResult.invalid('No encontramos esa ubicacion.');
    }

    return GeocodingResult.valid();
  }
}

class GeoapifySuggestion {
  final String? placeId;
  final String name;
  final String? formatted;
  final String? addressLine1;
  final String? addressLine2;
  final double? lat;
  final double? lon;
  final String? city;
  final String? state;
  final String? postcode;
  final String? country;

  const GeoapifySuggestion({
    required this.name,
    this.placeId,
    this.formatted,
    this.addressLine1,
    this.addressLine2,
    this.lat,
    this.lon,
    this.city,
    this.state,
    this.postcode,
    this.country,
  });

  factory GeoapifySuggestion.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>? ?? const {};
    return GeoapifySuggestion(
      placeId: properties['place_id']?.toString(),
      name: properties['name']?.toString() ??
          properties['address_line1']?.toString() ??
          properties['formatted']?.toString() ??
          '',
      formatted: properties['formatted']?.toString(),
      addressLine1: properties['address_line1']?.toString(),
      addressLine2: properties['address_line2']?.toString(),
      lat: (properties['lat'] as num?)?.toDouble(),
      lon: (properties['lon'] as num?)?.toDouble(),
      city: properties['city']?.toString() ??
          properties['town']?.toString() ??
          properties['village']?.toString(),
      state: properties['state']?.toString(),
      postcode: properties['postcode']?.toString(),
      country: properties['country']?.toString(),
    );
  }

  String get displayLabel {
    if (formatted != null && formatted!.trim().isNotEmpty) {
      return formatted!;
    }
    if (addressLine1 != null && addressLine1!.trim().isNotEmpty) {
      return addressLine2 == null || addressLine2!.trim().isEmpty
          ? addressLine1!
          : '${addressLine1!}, ${addressLine2!}';
    }
    return name;
  }
}

class GeocodingResult {
  final bool isValid;
  final String? message;

  const GeocodingResult._(this.isValid, this.message);

  factory GeocodingResult.valid() => const GeocodingResult._(true, null);

  factory GeocodingResult.invalid(String message) {
    return GeocodingResult._(false, message);
  }
}
