class TokenStore {
  Future<(String?, String?)> read() async => (null, null);

  Future<void> write(String refreshToken) async {}

  Future<void> clear() async {}
}
