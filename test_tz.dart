import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://timeapi.io/api/TimeZone/coordinate?latitude=41.0&longitude=28.9');
  final resp = await http.get(url);
  print(resp.statusCode);
  print(resp.body);
}
