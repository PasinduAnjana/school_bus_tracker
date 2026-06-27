class DevBypass {
  DevBypass._();

  /// Phone number that triggers dev bypass (no real SMS needed).
  static const String phone = '0770000000';

  /// OTP code accepted for the dev bypass phone.
  static const String code = '4592';

  /// Whether the dev bypass is enabled at all.
  static const bool enabled = true;
}
