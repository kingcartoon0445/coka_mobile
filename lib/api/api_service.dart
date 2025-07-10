import 'package:flutter/material.dart';
import 'api_client.dart';

class ApiService {
  late ApiClient _client;

  ApiService() {
    _client = ApiClient();
  }

  void updateContext(BuildContext context) {
    _client = ApiClient();
  }

  ApiClient get client => _client;
}
