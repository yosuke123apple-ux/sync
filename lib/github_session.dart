import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'github_api.dart';

class GitHubSession {
  static String? accessToken;
  static Map<String, dynamic>? currentUser;
  static Map<String, dynamic>? selectedRepo;
  static List<Map<String, dynamic>> repositories = [];

  static const String _accessTokenKey = 'github_access_token';
  static const String _currentUserKey = 'github_current_user';
  static const String _selectedRepoKey = 'github_selected_repo';
  static const String _repositoriesKey = 'github_repositories';

  static String? get currentLogin {
    final user = currentUser;
    if (user == null) return null;
    return user['login'] as String?;
  }

  static String? get displayName {
    final user = currentUser;
    if (user == null) return null;
    final name = user['name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }
    return user['login'] as String?;
  }

  static void clear() {
    accessToken = null;
    currentUser = null;
    selectedRepo = null;
    repositories = [];
  }

  static Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null && accessToken!.isNotEmpty) {
      await prefs.setString(_accessTokenKey, accessToken!);
    } else {
      await prefs.remove(_accessTokenKey);
    }

    if (currentUser != null) {
      await prefs.setString(_currentUserKey, jsonEncode(currentUser));
    } else {
      await prefs.remove(_currentUserKey);
    }

    if (selectedRepo != null) {
      await prefs.setString(_selectedRepoKey, jsonEncode(selectedRepo));
    } else {
      await prefs.remove(_selectedRepoKey);
    }

    await prefs.setString(_repositoriesKey, jsonEncode(repositories));
  }

  static Future<void> restoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    accessToken = prefs.getString(_accessTokenKey);

    final currentUserRaw = prefs.getString(_currentUserKey);
    currentUser = _decodeMap(currentUserRaw);

    final selectedRepoRaw = prefs.getString(_selectedRepoKey);
    selectedRepo = _decodeMap(selectedRepoRaw);

    final repositoriesRaw = prefs.getString(_repositoriesKey);
    repositories = _decodeList(repositoriesRaw);

    if (accessToken != null && accessToken!.isNotEmpty) {
      currentUser ??= await _tryFetchCurrentUser(accessToken!);
      if (repositories.isEmpty) {
        repositories = await _tryFetchRepositories(accessToken!);
      }
    }

    if (selectedRepo == null && repositories.isNotEmpty) {
      selectedRepo = repositories.first;
    }

    await saveToPrefs();
  }

  static Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  static List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>?> _tryFetchCurrentUser(String token) async {
    try {
      return await GitHubApi.getCurrentUser(token: token);
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> _tryFetchRepositories(
    String token,
  ) async {
    try {
      final repositoriesRaw = await GitHubApi.getRepositories(token: token);
      return repositoriesRaw
          .whereType<Map>()
          .map((repo) => Map<String, dynamic>.from(repo))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Map<String, dynamic>? currentMemberProfile({
    required String uid,
    bool isOwner = false,
  }) {
    final user = currentUser;
    if (user == null) return null;

    final login = user['login'] as String?;
    final name = displayName;
    return {
      'uid': uid,
      'githubLogin': login ?? '',
      'githubName': name ?? login ?? '',
      'avatarUrl': user['avatar_url'] as String? ?? '',
      'isOwner': isOwner,
    };
  }
}
