import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'github_session.dart';
import 'github_api.dart';
class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final _formKey = GlobalKey<FormState>();
  bool _showLanguages = false;
  final _repoNameController = TextEditingController();
final _repoDescriptionController = TextEditingController();
bool _showRepoSettings = false;
bool _repoPrivate = false;
bool _createRepository = true;
bool _privateRepo = false;
  //↑複数の入力欄をまとめて操作するリモコン
  final _titleController = TextEditingController();// タイトル入力欄のテキストを管理するコントローラー
  final _descriptionController = TextEditingController();// 説明入力欄のテキストを管理するコントローラー
  final _firestore = FirebaseFirestore.instance;// Firebase Firestoreのインスタンスを取得

  String? _selectedRole;// 選択された役割
  String? _selectedLevel;// 選択されたレベル
  int? _selectedMemberCount; // ← 変更: int型で人数を保持
  final List<String> _selectedLanguages = [];
  String _submitPhase = 'idle'; // idle, loading, success

  final List<String> _roles = [
    '本気モード',
    '初心者モード',
    '勉強モード',
  ];

  final List<String> _levels = ['始めたて',  '初級開発者', '中級開発者', '上級開発者','エキスパート'];

  final List<String> _languages = [
    'Dart',
    'JavaScript',
    'TypeScript',
    'Python',
    'Java',
    'Swift',
    'Kotlin',
    'Go',
    'C++',
    'C#',
    'Ruby',
    'PHP',
    'Rust',
    'C',
    'HTML',
    'CSS',
    'SQL',
    'Lua',

  ];

  @override
  void dispose() {
    _repoNameController.dispose();
_repoDescriptionController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFF0C1324),
      labelStyle: const TextStyle(color: Color(0xFFB7C0D8)),
      hintStyle: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.35)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF25314B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF25314B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF7C5CFF), width: 1.6),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle, {
    required String step,
    required Color accent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              alignment: Alignment.center,
              child: Text(
                step,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: 46,
          height: 3,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF8A94B2),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      if (!mounted) return;
      setState(() {
        _submitPhase = 'loading';
      });
 try {
  final user = FirebaseAuth.instance.currentUser;
  final ownerId = user?.uid ?? '';

  final ownerLogin =
      GitHubSession.currentLogin ??
      user?.email?.split('@').first ??
      'unknown';

  final ownerInfo = GitHubSession.displayName ?? ownerLogin;

  final accessToken = GitHubSession.accessToken;
  if (accessToken == null) {
    throw Exception('GitHubアクセストークンがありません');
  }
debugPrint('AccessToken: $accessToken');
  final repo = await GitHubApi.createRepository(
  token: accessToken,

  // 詳細設定が空ならタイトルを使う
  name: _repoNameController.text.trim().isEmpty
      ? _titleController.text.trim()
      : _repoNameController.text.trim(),

  // 詳細設定が空なら募集説明を使う
  description: _repoDescriptionController.text.trim().isEmpty
      ? _descriptionController.text.trim()
      : _repoDescriptionController.text.trim(),

  // Switchの値
  isPrivate: _repoPrivate,
);

  await _firestore.collection('projects').add({
    'repoId': repo['id'],
    'repoName': repo['name'],
    'repoOwner': repo['owner']['login'],
    'repoUrl': repo['html_url'],


 'githubPrivate': _repoPrivate,
  'githubRepoName': repo['name'],
  'githubRepoUrl': repo['html_url'],

    'title': _titleController.text.trim(),
    'description': _descriptionController.text.trim(),

    'memberCount': _selectedMemberCount ?? 1,
    'currentMembers': 1,

    'participantIds': ownerId.isEmpty ? <String>[] : <String>[ownerId],

    'participantProfiles': ownerId.isEmpty
        ? <Map<String, dynamic>>[]
        : [
            {
              'uid': ownerId,
              'githubLogin': ownerLogin,
              'githubName': ownerInfo,
              'avatarUrl': user?.photoURL ?? '',
              'isOwner': true,
            },
          ],

    'role': _selectedRole,
    'level': _selectedLevel,
    'languages': _selectedLanguages,

    'ownerInfo': ownerInfo,
    'ownerId': ownerId,

    'createdAt': FieldValue.serverTimestamp(),
  });
}
catch (e, stackTrace) {
  debugPrint('❌ Firebase送信エラー: $e');
  debugPrintStack(stackTrace: stackTrace);

  if (!mounted) return;

  setState(() {
    _submitPhase = 'idle';
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('投稿に失敗しました\n$e'),
    ),
  );

  return;
} 

      if (!mounted) return;
      setState(() {
        _submitPhase = 'success';
      });

      await Future.delayed(const Duration(milliseconds: 220));

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Widget _buildIntroPanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth >= 1100 ? 400.0 : double.infinity;

    return Container(
      width: panelWidth,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171033), Color(0xFF0B1022)],
        ),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(124, 92, 255, 0.12),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(124, 92, 255, 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color.fromRGBO(124, 92, 255, 0.28),
              ),
            ),
            child: const Text(
              'POST / PROJECT',
              style: TextStyle(
                color: Color(0xFFC9BEFF),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '募集ページを\n一気に組み立てる',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'タイトル、説明、募集人数、役割、レベル感、使用言語を入力すれば、投稿の骨組みがそのまま作れます。',
            style: TextStyle(
              color: const Color.fromRGBO(255, 255, 255, 0.72),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          _buildSideStat('入力項目', '6', '投稿に必要な基本情報', const Color(0xFF7C5CFF)),
          const SizedBox(height: 10),
          _buildSideStat(
            'Mode',
            '3',
            '人数は3人まで選択可',
            const Color(0xFF22D3EE),
          ),
          const SizedBox(height: 10),
          _buildSideStat(
            '雰囲気',
            'Dark',
            'Sync の世界観に合わせる',
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildSideStat(
    String label,
    String value,
    String description,
    Color accent,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.16),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  color: accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: const Color.fromRGBO(255, 255, 255, 0.55),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16102E), Color(0xFF0C1023)],
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22D3EE), Color(0xFF7C5CFF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(124, 92, 255, 0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'みんなに見せる募集を作る',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '必要な情報を入れるだけで、募集のたたき台が完成します。',
              style: TextStyle(
                color: const Color.fromRGBO(255, 255, 255, 0.7),
                height: 1.45,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle(
              'タイトル',
              '一番伝えたい名前を短く、強く。',
              step: '01',
              accent: const Color(0xFF7C5CFF),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                'タイトル',
                hint: '例: Flutterで学習管理アプリを作りたい',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'タイトルを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _sectionTitle(
              '説明',
              '何を作るのか、どんな雰囲気かを伝える。',
              step: '02',
              accent: const Color(0xFF22D3EE),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: _inputDecoration(
                '説明',
                hint: '例: 学習記録を見える化するアプリを一緒に作りたいです。',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '説明を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                        '募集人数',
                        '何人ほしいかを選ぶ（上限3人）。',
                        step: '03',
                        accent: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedMemberCount,
                        dropdownColor: const Color(0xFF0C1324),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('募集人数'),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1人')),
                          DropdownMenuItem(value: 2, child: Text('2人')),
                          DropdownMenuItem(value: 3, child: Text('3人')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedMemberCount = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return '募集人数を選んでください';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                        'モード選択',
                        '一緒にやってほしい担当を選ぶ。',
                        step: '04',
                        accent: const Color(0xFF34D399),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        dropdownColor: const Color(0xFF0C1324),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('モード選択'),
                        items: _roles
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'モードを選んでください';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                        'レベル感',
                        'どのくらいの経験値を求めるか。',
                        step: '05',
                        accent: const Color(0xFFF472B6),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLevel,
                        dropdownColor: const Color(0xFF0C1324),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('レベル感'),
                        items: _levels
                            .map(
                              (level) => DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLevel = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'レベル感を選んでください';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                        '使用言語',
                        '使う技術を複数選べるようにする。',
                        step: '06',
                        accent: const Color(0xFF60A5FA),
                      ),
                      const SizedBox(height: 10),
                    Container(
  width: double.infinity,
  decoration: BoxDecoration(
    color: const Color(0xFF0C1324),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: const Color(0xFF25314B),
    ),
  ),
  child: Column(
    children: [
      InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _showLanguages = !_showLanguages;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedLanguages.isEmpty
                      ? '使用言語を選択'
                      : _selectedLanguages.length <= 3
                          ? _selectedLanguages.join(', ')
                          : '${_selectedLanguages.take(3).join(', ')} ほか${_selectedLanguages.length - 3}件',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              AnimatedRotation(
                turns: _showLanguages ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),

      AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: _showLanguages
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: const SizedBox.shrink(),
        secondChild: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languages.map((language) {
              final isSelected = _selectedLanguages.contains(language);

              return FilterChip(
                selected: isSelected,
                label: Text(language),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFFCED5E8),
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: const Color(0xFF111A30),
                selectedColor: const Color(0xFF7C5CFF),
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF7C5CFF)
                      : const Color(0xFF25314B),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLanguages.add(language);
                    } else {
                      _selectedLanguages.remove(language);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ),
    ],
  ),
)
                    ],
                  ),
                ),
              
              ],
            ),
            const SizedBox(height: 18),
          Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    

      const SizedBox(height: 20),

      _sectionTitle(
        'GitHubリポジトリ',
        '作成するリポジトリの設定を変更できます。 ※クリックして展開',
        step: '06',
        accent: const Color(0xFF7C5CFF),
      ),
      const SizedBox(height: 10),

      Container(
  decoration: BoxDecoration(
    color: const Color(0xFF0C1324),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: const Color(0xFF25314B),
    ),
  ),
  child: Theme(
    data: Theme.of(context).copyWith(
      dividerColor: Colors.transparent,
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16,
      ),
      collapsedIconColor: Colors.white,
      iconColor: Colors.white,
      title: const Text(
        '詳細設定',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      
      children: [
        TextFormField(
          controller: _repoNameController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('リポジトリ名'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _repoDescriptionController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('説明'),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
  title: const Text('非公開リポジトリ'),
  subtitle: const Text('オンにすると招待したメンバーのみ閲覧できます'),
  value: _repoPrivate,
  onChanged: (value) {
    setState(() {
      _repoPrivate = value;
    });
  },
)
      ],
    ),
  ),
)
    ],
  ),
),
const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitPhase == 'idle' ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C5CFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(
                  _submitPhase == 'idle'
                      ? '投稿する'
                      : _submitPhase == 'loading'
                      ? '保存中...'
                      : '完了',
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'まずはたたき台を作って、あとから整えていけばOKです。',
                style: TextStyle(
                  color: const Color.fromRGBO(255, 255, 255, 0.45),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _submitPhase == 'idle' ? 0 : 1,
          child: Container(
            color: Colors.black.withValues(alpha: 0.55),
            child: Center(
              child: Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final dialogWidth = screenWidth * 0.9 > 420 ? 420.0 : screenWidth * 0.9;
                  return Container(
                    width: dialogWidth,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF141C35), Color(0xFF0B1022)],
                      ),
                      border: Border.all(
                        color: const Color(0xFF34D399).withValues(alpha: 0.45),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF34D399).withValues(alpha: 0.18),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF34D399), Color(0xFF22D3EE)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF34D399).withValues(alpha: 0.25),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '完了',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ホーム画面へ戻ります。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050B14),
        elevation: 0,
        title: const Text(
          '募集を投稿',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {

              final showIntro = constraints.maxWidth >= 1400;
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1600),
                      child: SizedBox(
                        width: double.infinity,
                        height: constraints.maxHeight,
                        child: showIntro
    ? Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIntroPanel(),
          const SizedBox(width: 24),
          Expanded(
            child: _buildFormPanel(),
          ),
        ],
      )
    : _buildFormPanel(),
                      ),
                    ),
                  ),
                ),
                _buildSuccessOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }
}
