// Indian digit grouping: last 3 digits, then groups of 2 (e.g. 149950 -> "1,49,950").
String formatInr(num amount) {
  final rounded = amount.round().abs();
  final digits = rounded.toString();

  if (digits.length <= 3) {
    return '₹$digits';
  }

  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) {
    groups.insert(0, rest);
  }

  return '₹${groups.join(',')},$last3';
}
