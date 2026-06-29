String formatE164(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) {
    return '+94${digits.substring(1)}';
  }
  if (digits.startsWith('94')) {
    return '+$digits';
  }
  return '+94$digits';
}
