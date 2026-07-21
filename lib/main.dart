import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'post_page.dart';
import 'task_page.dart';
// streak feature removed per request
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // ★これを追加します！
//githubログイン実装コードここから
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'github_api.dart';
import 'dart:ui';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigningIn = false;
  StreamSubscription<User?>? _authSub;

  Future<void> _login(BuildContext context) async {
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    try {//ウェブアプリかスマホアプリかで自動で切り替えているコード
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GithubAuthProvider());
      } else {
        await FirebaseAuth.instance.signInWithProvider(GithubAuthProvider());
      }
if (kIsWeb) {
  await FirebaseAuth.instance.signInWithPopup(GithubAuthProvider());
} else {
  await FirebaseAuth.instance.signInWithProvider(GithubAuthProvider());
}

// ここに追加
final user = FirebaseAuth.instance.currentUser;

debugPrint('GitHub UID: ${user?.uid}');
debugPrint('GitHub email: ${user?.email}');
debugPrint('GitHub name: ${user?.displayName}');

if (!context.mounted) return;

Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => const HomePage(),
  ),
);
      if (!context.mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(//画面切り替えアニメーション
          builder: (_) => const HomePage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'GitHubログインに失敗しました。もう一度お試しください。'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ログイン処理中にエラーが発生しました。しばらくしてから再度お試しください。'),
        ),
      );
    } finally {//ミスを元通り
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // サインインが外部フロー（redirect など）で復帰する場合に備え、
    // authStateChanges を監視してログイン復帰時に自動でホームへ遷移する。
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) {
        // 重複ナビゲーションを避ける: 現在のルートが LoginPage のままなら遷移する
        final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
        if (isCurrent) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth >= 600 ? 96.0 : 72.0;

    return Scaffold(
      backgroundColor: const Color(0xFF060A18),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GitHubでログイン',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '続けるには GitHub アカウントでログインしてください',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: _isSigningIn ? null : () => _login(context),
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFF24292F).withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF6E7781).withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF24292F).withValues(alpha: 0.28),
                          blurRadius: 18,
                          spreadRadius: 1,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(//ロード中のくるくるアイコン
                      child: _isSigningIn
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.login_rounded,
                              size: 34,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ============================================================
// エントリーポイント
// ============================================================

Future<void> main() async {// Flutterの初期化とFirebaseの初期化を行う
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const SyncApp());
}

/// Firebase / Firestoreの初期化（オフラインキャッシュを有効化）//先に保存されてるからオフラインでもそのデータが出る
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(// Firebaseの初期化
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // ✅ ログイン状態をアプリ再起動後も保持するように設定
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      debugPrint('✅ ウェブ: セッション永続化を有効化');
    } else {
      // スマホアプリの場合、デフォルトでセッション保持されるが、確認用ログ出力
      debugPrint('✅ スマホアプリ: デフォルトでセッション保持（キーチェーン/SharedPreferences）');
    }
    
    // ✅ 保存されたセッション復帰を最大10秒待機（ネットワーク遅延に対応）
    debugPrint('⏳ 保存されたセッション復帰を確認中...');

    // ログ: authStateChanges の各 emit を出力（デバッグ用）
    FirebaseAuth.instance.authStateChanges().listen((u) {
      debugPrint("🔔 authStateChanges emit: ${u?.uid ?? 'null'} (${u?.email ?? 'null'})");
    });

    try {
      // authStateChanges() が最初の emit を返すまで最大10秒待機（ネットワーク遅延対策）
      final firstAuthState = await FirebaseAuth.instance.authStateChanges()
          .first
          .timeout(const Duration(seconds: 10));

      if (firstAuthState != null) {
        debugPrint('✅ 前回のセッション復帰成功: ${firstAuthState.email}');
        debugPrint('   UID: ${firstAuthState.uid}');
      } else {
        debugPrint('ℹ️  ログイン状態なし（新規ユーザー）');
      }
    } on TimeoutException {
      // タイムアウト → セッション復帰中の可能性
      debugPrint('⚠️  セッション復帰タイムアウト（ネットワーク遅延の可能性）');
      debugPrint('   AuthGate がセッション復帰を待機します');
    }
    
// Firestoreのオフラインキャッシュを有効化
    final firestore = FirebaseFirestore.instance;
    await firestore.enableNetwork();
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 40 * 1024 * 1024, // 40MB
    );
    // デバッグ用に初期化成功メッセージを出力
    debugPrint('✅ Firebase初期化成功');
    debugPrint('✅ Firestore接続完了');
  } catch (e, stackTrace) {
    debugPrint('❌ Firebase初期化エラー: $e');
    debugPrint('スタックトレース: $stackTrace');
  }
}

class SyncApp extends StatelessWidget {
  const SyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SyncCrew',
      theme: ThemeData.dark(),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse, // マウスでの横スクロール（ドラッグ）を有効化
        PointerDeviceKind.trackpad, // トラックパッドでの操作も有効化
      },
    ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ✅ ログイン状態の遷移をトラッキング
        if (snapshot.hasError) {
          debugPrint('❌ 認証エラー: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Text('認証エラー: ${snapshot.error}'),
            ),
          );
        }
        
        // ✅ 最初の emit を待機（セッション復帰の確認完了を待つ）
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('⏳ セッション確認中...');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'セッション復帰中...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          debugPrint('🔓 ログイン画面を表示（セッション無効）');
          return const LoginPage();
        }

        debugPrint('✅ ログイン成功: ${user.email}');
        debugPrint('   UID: ${user.uid}');
        return const HomePage();
      },
    );
  }
}

// ============================================================
// テーマ（カラー定義）
// ============================================================

/// アプリ全体で使用するカラー定義
///
/// 色の値があちこちに直書きされていたため、意味のある名前でここに集約した。
class AppColors {
  // ── 背景 ──
  static const Color backgroundBase = Color(0xFF060A18);
  static const Color mainBackground = Color(0xff020710);
  static const Color contentBackground = Color(0xff050b14);

  // ── ブランドカラー ──
  static const Color primaryBlue = Color(0xff2f80ed);

  // ── 参加ボタン用グラデーション ──
  static const Color joinButtonStart = Color(0xff8b5cf6);
  static const Color joinButtonEnd = Color(0xff7c3aed);

  // ── 右サイドバーのカード枠線 ──
  static const Color infoCardBorder = Color(0xFF6C5CE7);

  // ── プロジェクトカードのアクセントカラー（色分け用パレット） ──
  static const List<Color> projectAccentPalette = [
    Color(0xff8b5cf6),
    Color(0xff22d3ee),
    Color(0xfff59e0b),
    Color(0xff34d399),
    Color(0xfff472b6),
    Color(0xff60a5fa),
  ];

  /// モード別の募集カードアクセントカラー
  static Color accentForRole(String role) {
    switch (role) {
      case '本気モード':
        return const Color(0xffEF4444);
      case '初心者モード':
        return const Color(0xffF59E0B);
      case '学生組':
        return const Color(0xff10B981);
      case '勉強モード':
        return const Color(0xff3B82F6);
      default:
        return const Color(0xff8B5CF6);
    }
  }
}

// ============================================================
// データモデル
// ============================================================

/// プロジェクト（募集）情報を表すモデル
///
/// 元コードは「Firestoreから取得したデータ」と「モックデータ」で
/// ほぼ同じUIを2箇所に丸ごとコピペしていた（最大のDRY違反）。
/// この1つのモデルに統一することで、カードUIは1種類だけで済むようにした。
class ProjectInfo {
  final String id;
  final String title;
  final String description;
  final String ownerInfo;
  final String ownerId; // ←追加
  final String role;
  final int currentMembers;
  final int? maxMembers;
  final List<String> tags;

  const ProjectInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerInfo,
    required this.ownerId,
    required this.role,
    required this.currentMembers,
    required this.tags,
    this.maxMembers,
  });

  /// Firestoreのドキュメントデータから生成する
  factory ProjectInfo.fromFirestore(String id, Map<String, dynamic> data) {
    final role = data['role'] as String? ?? '役割未設定';
    final level = data['level'] as String? ?? 'レベル未設定';
    final languages =
        (data['languages'] as List?)?.whereType<String>().toList() ??
        const <String>[];
    final maxMembers = data['memberCount'] as int?;

return ProjectInfo(
  id: id,
  title: _textOrFallback(data['title'] as String?, '無題の募集'),
  description: _textOrFallback(data['description'] as String?, '説明がありません'),
  ownerInfo: _textOrFallback(data['ownerInfo'] as String?, '投稿者情報なし'),
  ownerId: data['ownerId'] as String? ?? '',
  role: role,
  currentMembers: data['currentMembers'] as int? ?? 1,
  maxMembers: maxMembers,
  tags: [role, level, ...languages.take(3)],
);
  }

  /// 人数表示用ラベル（例: 定員ありなら"1/3"、なしなら"1/募集中"）
  String get memberLabel {
    if (maxMembers != null) {
      return '$currentMembers/$maxMembers';
    }
    return '$currentMembers/募集中';
  }
}
/// 文字列がnullまたは空文字ならフォールバック値を返す
String _textOrFallback(String? value, String fallback) {
  final text = value?.trim();
  return (text == null || text.isEmpty) ? fallback : text;
}

/// 左サイドバーのメニュー1件分の情報
class MenuItemInfo {
  final String label;
  final String description;
  final IconData icon;
  final Color iconColor;
  final int index;

  const MenuItemInfo({
    required this.label,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.index,
  });
}

// ============================================================
// 固定データ
// ============================================================

/// 左サイドバーのメニュー一覧
const List<MenuItemInfo> _menuItems = [
  MenuItemInfo(
    label: 'ホーム',
    description: 'すべての募集をチェック',
    icon: Icons.home_outlined,
    iconColor: Colors.white,
    index: 0,
  ),
  MenuItemInfo(
    label: '本気モード',
    description: '本気でやり成果を残す！',
    icon: Icons.local_fire_department_outlined,
    iconColor: Color(0xffEF4444),
    index: 1,
  ),
  MenuItemInfo(
    label: '初心者モード',
    description: '簡単なことから始めよう',
    icon: Icons.rocket_launch_outlined,
    iconColor: Color(0xffF59E0B),
    index: 2,
  ),
  MenuItemInfo(
    label: '学生組',
    description: 'みんなで協力',
    icon: Icons.people_outline,
    iconColor: Color(0xff10B981),
    index: 3,
  ),
  MenuItemInfo(
    label: 'フレンド機能',
    description: 'つながりを作ろう',
    icon: Icons.person_add_outlined,
    iconColor: Color(0xff3B82F6),
    index: 4,
  ),
  MenuItemInfo(
    label: '勉強モード',
    description: 'みんなと一緒にがんばろう',
    icon: Icons.music_note_outlined,
    iconColor: Color(0xffEC4899),
    index: 5,
  ),
];

/// Firestoreが空・エラー時に表示するフォールバック用モックデータ
///
/// 元コードは同じ内容の ProjectInfo を6個ベタ書きしていたため、
/// List.generate で「同じ内容を6件表示する」という意図を1箇所にまとめた。




// ============================================================
// サービス層（Firestore通信）
// ============================================================

/// Firestoreとのやり取りを担当するサービス層
///
/// Streamの時点でProjectInfoに変換しておくことで、
/// UI側はFirestoreのQuerySnapshotを直接扱わなくてよい。
class ProjectService {/// Firestoreのprojectsコレクションを監視し、最新20件を取得する
  static Stream<List<ProjectInfo>> watchProjects() {
    return FirebaseFirestore.instance
        .collection('projects')
        .orderBy('createdAt', descending: true)//作成日時順で並び返されている
        .limit(200)//取得する最大件数
        .snapshots()//データが変わるたびにまた監視する
          .map(//流れてきたデータを別の形に変換する//toList ProjectInfoを1つのリストにまとめなおすための命令
        (snapshot) => snapshot.docs//projectInfo.fromFirestoreでアプリ用のきれいなデータに変換する
          .map((doc) => ProjectInfo.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }
}

// ============================================================
// ロジック（参加フロー）
// ============================================================

/// 「参加する」ボタンが押されたときの一連の処理
///
/// ダイアログ表示や画面遷移はUIの一部だが、状態を持たない単純な処理なので
/// StatefulWidgetのメソッドとしてHomePageに埋め込まず、関数として切り出した。
//Futureフューチャーでまだ返さないけど終わったら返すよって未来に返すことが約束されてるからフューチャー
Future<void> _handleJoinPressed(
  BuildContext context, {
  required ProjectInfo project,
}) async {
  await _confirmJoinAndOpenTask(
    context,
    project: project,
  );
}
Future<void> _confirmJoinAndOpenTask(
  BuildContext context, {
  required ProjectInfo project,
}) async {
  final user = FirebaseAuth.instance.currentUser;

final isOwnProject = project.ownerId == user?.uid;
  final dialogTitle = isOwnProject ? '自分の募集です' : 'このチームに参加しますか';
  final dialogContent = isOwnProject
      ? '自分が投稿した募集でも、そのままタスクページへ進めます。'
      : '参加すると、タスクページへ進みます。';

  final shouldJoin = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF0B1022),
      title: Text(dialogTitle, style: const TextStyle(color: Colors.white)),
      content: Text(
        dialogContent,
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(isOwnProject ? '開く' : '参加する'),
        ),
      ],
    ),
  );

  if (shouldJoin != true || !context.mounted) return;

  if (!isOwnProject) {
    if (project.maxMembers != null && project.currentMembers >= project.maxMembers!) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('この募集はすでに上限に達しています')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(project.id)
          .update({
            'currentMembers': FieldValue.increment(1),
          });
    } catch (e, stackTrace) {
      debugPrint('❌ 参加人数更新エラー: $e');
      debugPrint('$stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('参加処理に失敗しました。もう一度お試しください。')),
      );
      return;
    }
  }

  if (!context.mounted) return;

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TaskPage(
        projectTitle: project.title,
        ownerInfo: project.ownerInfo,
        isOwnProject: isOwnProject,
        projectId: project.id,
      ),
    ),
  );
}

// ============================================================
// ウィジェット：小さな部品
// ============================================================

/// 右サイドバーで繰り返し使われるカード型コンテナ
///
/// 「おすすめカテゴリ」「トレンドタグ」「最近の投稿」「リアルタイム
/// アクティビティ」の4箇所で全く同じBoxDecorationがコピペされていたため、
/// タイトル＋中身だけを渡せる共通ウィジェットにまとめた。
class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _InfoCard({
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: AppColors.infoCardBorder.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.infoCardBorder.withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// プロジェクトカードの「参加する」ボタン
class _JoinButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _JoinButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.joinButtonStart, AppColors.joinButtonEnd],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.joinButtonStart.withValues(alpha: 0.5),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_add, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                '参加する',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ウィジェット：募集カード
// ============================================================

/// 募集カード1件分のUI
///
/// 元コードではFirestoreのデータとモックデータでほぼ同じUIが
/// 2箇所に丸ごとコピペされていた。ProjectInfoにデータを統一したことで、
/// このウィジェット1つだけで両方描画できる。
class _ProjectCard extends StatelessWidget {
  final ProjectInfo project;
  final Color accent;
  final VoidCallback onJoinPressed;

  const _ProjectCard({
    required this.project,
    required this.accent,
    required this.onJoinPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xff0a1220),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildIcon(),
              const SizedBox(width: 18),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
        Positioned(top: 8, right: 8, child: _buildMenuButton()),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.25),
            accent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(Icons.auto_awesome, color: accent, size: 38),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                project.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(-30.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Color(0xff9f7aea),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    project.ownerInfo,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          project.description,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildTags()),
            _buildMemberCount(),
            const SizedBox(width: 10),
            _JoinButton(onPressed: onJoinPressed),
          ],
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: project.tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMemberCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group, color: accent, size: 16),
          const SizedBox(width: 6),
          Text(
            project.memberLabel,
            style: TextStyle(color: accent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
      onSelected: (value) => debugPrint('カードメニュー選択: $value'),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'share', child: Text('共有')),
        PopupMenuItem(value: 'save', child: Text('保存')),
        PopupMenuItem(value: 'report', child: Text('通報')),
      ],
    );
  }
}

/// 募集一覧（Firestoreから取得。エラー/未取得時はモックデータにフォールバック）
class _ProjectList extends StatelessWidget {
  const _ProjectList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProjectInfo>>(
      stream: ProjectService.watchProjects(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('❌ Firestore読み込みエラー: ${snapshot.error}');
        
        }

        final projects = snapshot.data;
        if (projects == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (projects.isEmpty) {
          return Center(
            child: Text(
              'まだ募集がありません。右上の「投稿」から作ってみよう。',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 14,
              ),
            ),
          );
        }

        return _buildList(context, projects);
      },
    );
  }

  Widget _buildList(BuildContext context, List<ProjectInfo> projects) {
    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        final accent = AppColors.accentForRole(project.role);
        return _ProjectCard(
          project: project,
          accent: accent,
          onJoinPressed: () => _handleJoinPressed(
            context,
            project: project,
          ),
        );
      },
    );
  }
}

// ============================================================
// ウィジェット：左サイドバー
// ============================================================

/// 左サイドバーのメニュー1項目
class _MenuCard extends StatelessWidget {
  final MenuItemInfo item;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 220,
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    item.iconColor.withValues(alpha: 0.25),
                    item.iconColor.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected ? null : const Color(0xFF0A1020),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? item.iconColor.withValues(alpha: 0.5)
                : const Color(0xFF1D2742),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: item.iconColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 画面左側のサイドバー（ロゴ・メニュー一覧・プロフィールカード・設定）
class _HomeSidebarLeft extends StatelessWidget {
  final List<MenuItemInfo> menuItems;
  final int selectedIndex;
  final ValueChanged<int> onMenuSelected;

  const _HomeSidebarLeft({
    required this.menuItems,
    required this.selectedIndex,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.backgroundBase,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLogo(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    ...menuItems.map(
                      (item) => _MenuCard(
                        item: item,
                        isSelected: selectedIndex == item.index,
                        onTap: () => onMenuSelected(item.index),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            _buildProfileCard(context),
            _buildSettingsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 16, bottom: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff7c4dff), Color(0xff5c6bc0)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Syncating',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
              Text(
                'team together',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1D2742)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xff7c4dff).withValues(alpha: 0.25),
                      const Color(0xff5c6bc0).withValues(alpha: 0.15),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff7c4dff).withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xff987FFF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'やまた_Dev',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '@yama_dev',
                      style: TextStyle(color: Color(0xff7B849D), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xff7c4dff), Color(0xff5c6bc0)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'はじめの一歩',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildSettingsRow() {
    return GestureDetector(
      onTap: () => debugPrint('設定をタップしました'),
      child: Container(
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.settings_outlined,
              color: Colors.white.withValues(alpha: 0.4),
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              '設定',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.15),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ウィジェット：中央（検索バー・ヒーローバナー）
// ============================================================

/// 画面右上の検索バー・通知アイコン・投稿ボタン
///
/// 検索バーの幅は固定値ではなく、Expanded + ConstrainedBoxで
/// 画面幅に応じて伸縮するようにしている。
class _SearchAndPostBar extends StatelessWidget {
  const _SearchAndPostBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: _buildSearchField(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications),
          color: Colors.white,
          onPressed: () => debugPrint('通知アイコンが押されました'),
        ),
        const SizedBox(width: 10),
        _buildPostButton(context),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xff0a1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
          hintText: 'プロジェクトを検索...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPostButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostPage()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.send, size: 18),
          SizedBox(width: 8),
          Text(
            '募集を投稿',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// バナー内の統計1件（アイコン＋数値＋ラベル）
///
/// 元コードでは同じ構造が3回コピペされていたため内部ウィジェット化した。
class _HeroStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _HeroStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFFF8FAFF),
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9BA4C7),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// トップページ上部の「Collaboration Space」バナー
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 229,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff17103a), Color(0xff0d1028)],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTextSection()),
          const SizedBox(
            width: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _HeroIllustrationBackground(),
                Icon(Icons.code_rounded, size: 90, color: Color(0xff7c5cff)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xff7c5cff).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xff7c5cff).withValues(alpha: 0.25),
            ),
          ),
          child: const Text(
            'Collaboration Space',
            style: TextStyle(
              color: Color(0xffB9B3FF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              const TextSpan(
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: -1.0,
                  shadows: [
                    Shadow(
                      color: Color(0x44000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                children: [
                  TextSpan(
                    text: '一緒に、',
                    style: TextStyle(color: Color(0xFFF8FAFF)),
                  ),
                  TextSpan(
                    text: 'アイデアをカタチにしよう。',
                    style: TextStyle(color: Color(0xff8F7CFF)),
                  ),
                ],
              ),
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '少人数で、本気で、最高のプロダクトを。',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.72),
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        const SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                child: _HeroStat(
                  icon: Icons.schedule_outlined,
                  color: Color(0xFF7C5CFF),
                  value: '100時間',
                  label: '今週の総作業時間',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _HeroStat(
                  icon: Icons.trending_up_outlined,
                  color: Color(0xFF3B82F6),
                  value: '92%',
                  label: 'また組みたい率',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _HeroStat(
                  icon: Icons.folder_open_outlined,
                  color: Color(0xFFEC4899),
                  value: '3件',
                  label: '応募中のプロジェクト',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroIllustrationBackground extends StatelessWidget {
  const _HeroIllustrationBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xff7c5cff).withValues(alpha: 0.08),
      ),
    );
  }
}

// ============================================================
// ウィジェット：右サイドバー
// ============================================================

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: Colors.white24),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }
}

class _RecentPostTile extends StatelessWidget {
  final String title;
  final String timeAgo;
  const _RecentPostTile({required this.title, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        timeAgo,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }
}

/// 元コードでは同じ構造のListTileが4個ベタ書きされていたため共通化した
class _ActivityTile extends StatelessWidget {
  final String text;
  final String timeAgo;
  const _ActivityTile({required this.text, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.flash_on, color: Color(0xFF6C5CE7)),
        title: Text(text, style: const TextStyle(color: Colors.white)),
        subtitle: Text(timeAgo, style: const TextStyle(color: Colors.white54)),
      ),
    );
  }
}

/// 画面右側のサイドバー（おすすめカテゴリ・トレンドタグ・最近の投稿・アクティビティ）
class _HomeSidebarRight extends StatelessWidget {
  const _HomeSidebarRight();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.2,
      color: AppColors.backgroundBase,
      padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(
              padding: const EdgeInsets.all(30),
              title: 'おすすめカテゴリ',
              child: const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CategoryChip('Flutter'),
                  _CategoryChip('Web'),
                  _CategoryChip('AI'),
                  _CategoryChip('Unity'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _InfoCard(
              title: 'トレンドタグ',
              child: Text(
                '#Flutter\n#個人開発\n#AI\n#Python',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.8,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _InfoCard(
              title: '最近の投稿',
              child: Column(
                children: [
                  _RecentPostTile(title: 'Flutter仲間募集', timeAgo: '3分前'),
                  _RecentPostTile(title: 'AIアプリ開発中', timeAgo: '12分前'),
                ],
              ),
            ),
            const SizedBox(height: 25),
            _InfoCard(
              title: 'リアルタイムアクティビティ',
              child: Column(
                children: List.generate(
                  4,
                  (_) => const _ActivityTile(
                    text: 'Flutter開発者が参加しました',
                    timeAgo: '2分前',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ホーム画面（全体のレイアウト組み立て）
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedMenuIndex = 0;

  @override
  void initState() {
    super.initState();
 
    WidgetsBinding.instance.addObserver(this);
    // 起動時にも記録を試みる
    _recordTodayIfNeeded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // フォアグラウンド復帰時に記録を試みる
      _recordTodayIfNeeded();
    }
  }

  Future<void> _recordTodayIfNeeded() async {
    // Streak feature removed — no-op to avoid runtime errors.
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: Row(
        children: [
          _HomeSidebarLeft(
            menuItems: _menuItems,
            selectedIndex: _selectedMenuIndex,
            onMenuSelected: (index) =>
                setState(() => _selectedMenuIndex = index),
          ),
          Expanded(
            child: Container(
              color: AppColors.contentBackground,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SearchAndPostBar(),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 1250),
                    child: const _HeroBanner(),
                  ),
                  const SizedBox(height: 25),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 1250),
                      child: const _ProjectList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _HomeSidebarRight(),
        ],
      ),
    );
  }
}
