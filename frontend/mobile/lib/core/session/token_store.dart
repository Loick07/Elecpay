import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/models/auth_models.dart';

/// Les jetons d'une session, tels qu'ils sont gardés sur le téléphone.
@immutable
class StoredTokens {
  const StoredTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.userId,
  });

  factory StoredTokens.fromResponse(TokenResponse response) => StoredTokens(
    accessToken: response.accessToken,
    refreshToken: response.refreshToken,
    accessExpiresAt: response.accessExpiresAt,
    userId: response.user.id,
  );

  factory StoredTokens.fromJson(Map<String, dynamic> json) => StoredTokens(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    accessExpiresAt: DateTime.parse(json['access_expires_at'] as String),
    userId: json['user_id'] as int,
  );

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;

  /// Propriétaire de la session : sert aussi à ranger le cache hors ligne par utilisateur (F1.4).
  final int userId;

  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'access_expires_at': accessExpiresAt.toUtc().toIso8601String(),
    'user_id': userId,
  };

  @override
  bool operator ==(Object other) =>
      other is StoredTokens &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken &&
      other.accessExpiresAt == accessExpiresAt &&
      other.userId == userId;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, accessExpiresAt, userId);

  /// Jamais les jetons en clair dans un journal.
  @override
  String toString() => 'StoredTokens(utilisateur $userId, accès jusqu’à $accessExpiresAt)';
}

/// Où les jetons sont gardés. En production : [SecureTokenStore], nulle part ailleurs.
abstract interface class TokenStore {
  Future<StoredTokens?> read();
  Future<void> write(StoredTokens tokens);
  Future<void> clear();
}

/// Jetons dans `flutter_secure_storage` (chiffrés par une clé du Keystore Android).
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const key = 'elecpay.session';

  final FlutterSecureStorage _storage;

  @override
  Future<StoredTokens?> read() async {
    try {
      final raw = await _storage.read(key: key);
      if (raw == null) return null;
      return StoredTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Contenu illisible (format ancien, clé du Keystore perdue après un transfert de téléphone…) :
      // on repart d'une session vide plutôt que de bloquer l'application.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(StoredTokens tokens) =>
      _storage.write(key: key, value: jsonEncode(tokens.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: key);
}
