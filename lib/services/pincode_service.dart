import 'dart:convert';
import 'package:http/http.dart' as http;

class PincodeLookupResult {
  final String state;
  final List<String> cities;

  PincodeLookupResult({required this.state, required this.cities});
}

// India Post's public pincode API — free, no API key required. Given a
// 6-digit pincode it returns every post office serving that pincode; we
// use their (usually singular) State and the set of District names as the
// city options, since one pincode occasionally spans more than one locality.
class PincodeService {
  Future<PincodeLookupResult?> lookup(String pincode) async {
    final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$pincode'));
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body) as List;
    if (decoded.isEmpty) return null;

    final first = decoded.first as Map<String, dynamic>;
    if (first['Status'] != 'Success') return null;

    final postOffices = (first['PostOffice'] as List?) ?? [];
    if (postOffices.isEmpty) return null;

    final state = postOffices.first['State'] as String;
    final cities = postOffices
        .map((po) => (po as Map<String, dynamic>)['District'] as String)
        .toSet()
        .toList();

    return PincodeLookupResult(state: state, cities: cities);
  }
}
