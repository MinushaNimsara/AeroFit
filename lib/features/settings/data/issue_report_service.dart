import 'dart:convert';

import 'package:http/http.dart' as http;

class IssueReportService {
  IssueReportService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://formspree.io/f/mykajpwb';

  Future<void> submitReport({
    required String email,
    required String message,
  }) async {
    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'message': message.trim(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Formspree error ${response.statusCode}: ${response.body}',
      );
    }
  }

  void dispose() => _client.close();
}
