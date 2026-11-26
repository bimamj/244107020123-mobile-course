import '../../domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required super.access, required super.refresh});

  factory AuthSessionModel.fromJson(Map<String, Object?> json) {
    return AuthSessionModel(
      access: json['access_token'] as String? ?? '',
      refresh: json['refresh_token'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'access_token': access,
    'refresh_token': refresh,
  };
}
