import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubApi {
  static Future<Map<String, dynamic>> getRepo({
    required String owner,
    required String repo,
  }) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$owner/$repo'),
    );

    if (response.statusCode != 200) {
      throw Exception('GitHub API Error: ${response.statusCode}');
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getLanguages({
    required String owner,
    required String repo,
  }) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$owner/$repo/languages'),
    );

    if (response.statusCode != 200) {
      throw Exception('GitHub API Error: ${response.statusCode}');
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getPullRequests({
    required String owner,
    required String repo,
  }) async {
    final response = await http.get(
      Uri.parse(
        'https://api.github.com/repos/$owner/$repo/pulls?state=all&per_page=100',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('GitHub API Error: ${response.statusCode}');
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getIssues({
    required String owner,
    required String repo,
  }) async {
    final response = await http.get(
      Uri.parse(
        'https://api.github.com/repos/$owner/$repo/issues?state=all&per_page=100',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('GitHub API Error: ${response.statusCode}');
    }

    return jsonDecode(response.body);
  }
}