import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NocoDBService {
  Future<List<Map<String, dynamic>>> fetchRows(int offset, {int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? baseUrl = prefs.getString('nocodb_url');
    final String? apiToken = prefs.getString('nocodb_token');
    final String? tableId = prefs.getString('nocodb_table_id');
    final String? viewId = prefs.getString('nocodb_view_id');
    final bool ignoreSsl = prefs.getBool('nocodb_ignore_ssl') ?? false;

    if (baseUrl == null || baseUrl.isEmpty ||
        apiToken == null || apiToken.isEmpty ||
        tableId == null || tableId.isEmpty) {
      throw Exception('Missing NocoDB configuration. Please check settings.');
    }

    // Clean up base URL if it ends with slash
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    String urlString = '$cleanBaseUrl/api/v2/tables/$tableId/records?offset=$offset&limit=$limit';
    if (viewId != null && viewId.isNotEmpty) {
      urlString += '&viewId=$viewId';
    }
    final url = Uri.parse(urlString);
    
    http.Client client;
    if (ignoreSsl) {
      final ioc = HttpClient();
      ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      client = IOClient(ioc);
    } else {
      client = http.Client();
    }

    try {
      final response = await client.get(
        url,
        headers: {
          'xc-token': apiToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('list')) {
          final list = data['list'] as List;
          return list.map((e) => e as Map<String, dynamic>).toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load rows: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to NocoDB: $e');
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>?> fetchRow(int offset) async {
    final rows = await fetchRows(offset, limit: 1);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<void> updateRow(Map<String, dynamic> row) async {
    final prefs = await SharedPreferences.getInstance();
    final String? baseUrl = prefs.getString('nocodb_url');
    final String? apiToken = prefs.getString('nocodb_token');
    final String? tableId = prefs.getString('nocodb_table_id');
    final bool ignoreSsl = prefs.getBool('nocodb_ignore_ssl') ?? false;

    if (baseUrl == null || baseUrl.isEmpty ||
        apiToken == null || apiToken.isEmpty ||
        tableId == null || tableId.isEmpty) {
      throw Exception('Missing NocoDB configuration. Please check settings.');
    }

    // Clean up base URL if it ends with slash
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final url = Uri.parse('$cleanBaseUrl/api/v2/tables/$tableId/records');

    http.Client client;
    if (ignoreSsl) {
      final ioc = HttpClient();
      ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      client = IOClient(ioc);
    } else {
      client = http.Client();
    }

    try {
      final response = await client.patch(
        url,
        headers: {
          'xc-token': apiToken,
          'Content-Type': 'application/json',
        },
        body: json.encode([row]),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update row: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating NocoDB: $e');
    } finally {
      client.close();
    }
  }
}
