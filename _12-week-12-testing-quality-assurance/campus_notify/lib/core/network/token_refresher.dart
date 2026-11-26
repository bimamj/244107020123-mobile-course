abstract interface class TokenRefresher {
  Future<String> refresh(String refreshToken);
}
