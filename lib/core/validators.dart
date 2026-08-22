class Validators {
  static String? required(String? value, [String field = 'This field']) =>
      value == null || value.trim().isEmpty ? '$field is required.' : null;
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
        ? null
        : 'Enter a valid email address.';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    return value.length < 8 ? 'Password must be at least 8 characters.' : null;
  }
}
