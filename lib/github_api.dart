import 'dart:convert';

import 'package:http/http.dart' as http;

class GitHubApi {
  static const String _baseUrl = 'https://api.github.com';

  static Future<dynamic> _get(
    String path, {
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Accept': 'application/vnd.github+json',
        if (token != null)
          'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub API Error: ${response.statusCode}\n${response.body}',
      );
    }

    return jsonDecode(response.body);
  }

  // 自分のリポジトリ一覧
  static Future<List<dynamic>> getRepositories({
    required String token,
  }) async {
    return await _get(
      '/user/repos?per_page=100',
      token: token,
    );
  }

  // リポジトリ情報
  static Future<Map<String, dynamic>> getRepo({
    required String owner,
    required String repo,
    String? token,
  }) async {
    return await _get(
      '/repos/$owner/$repo',
      token: token,
    );
  }

  // 使用言語
  static Future<Map<String, dynamic>> getLanguages({
    required String owner,
    required String repo,
    String? token,
  }) async {
    return await _get(
      '/repos/$owner/$repo/languages',
      token: token,
    );
  }

  // Pull Request
  static Future<List<dynamic>> getPullRequests({
    required String owner,
    required String repo,
    String? token,
  }) async {
    return await _get(
      '/repos/$owner/$repo/pulls?state=all&per_page=100',
      token: token,
    );
  }

  // Issues
  static Future<List<dynamic>> getIssues({
    required String owner,
    required String repo,
    String? token,
  }) async {
    return await _get(
      '/repos/$owner/$repo/issues?state=all&per_page=100',
      token: token,
    );
  }

  // 最新コミット一覧
  static Future<List<dynamic>> getCommits({
    required String owner,
    required String repo,
    String? token,
    int perPage = 20,
  }) async {
    return await _get(
      '/repos/$owner/$repo/commits?per_page=$perPage',
      token: token,
    );
  }

  // コミット詳細
  static Future<Map<String, dynamic>> getCommitDetails({
    required String owner,
    required String repo,
    required String sha,
    String? token,
  }) async {
    return await _get(
      '/repos/$owner/$repo/commits/$sha',
      token: token,
    );
  }

  // ログインユーザー情報
  static Future<Map<String, dynamic>> getCurrentUser({
    required String token,
  }) async {
    return await _get(
      '/user',
      token: token,
    );
  }
}
