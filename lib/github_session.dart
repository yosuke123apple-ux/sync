class GitHubSession {
  static String? accessToken;
  static Map<String, dynamic>? currentUser;
  static Map<String, dynamic>? selectedRepo;
  static List<Map<String, dynamic>> repositories = [];

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
