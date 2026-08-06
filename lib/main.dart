import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'firebase_options.dart';
import 'post_page.dart';
import 'task_page.dart';
import 'github_session.dart';
// streak feature removed per request
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // ★これを追加します！
//githubログイン実装コードここから
import 'github_api.dart';
import 'dart:ui';
import 'SeriousModePage.dart';
import 'BeginnerModePage.dart';
import 'StudyModePage.dart';
import 'AppleModePage.dart';
import 'FriendModePage.dart';
import 'setting.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigningIn = false;
  StreamSubscription<User?>? _authSub;
//StreamSubscriptionとは;ostem()でデータを受け取りしたときに操作ができる
  Future<void> _login(BuildContext context) async {
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    try {
      // ウェブアプリかスマホアプリかで自動で切り替える
      UserCredential userCredential;

      if (kIsWeb) {//KIsWeb=スマホかウェブ
        final provider = GithubAuthProvider()
  ..addScope('repo');

userCredential = await FirebaseAuth.instance.signInWithPopup(
  provider,
);
      } else {
       final provider = GithubAuthProvider()
  ..addScope('repo');

userCredential = await FirebaseAuth.instance.signInWithProvider(
  provider,
);
      }

      final githubCredential =//credential=googleの情報をgithubの認証情報とする
          userCredential.credential as OAuthCredential?;
//githubのアクセストークンをgithubsessionに保存する
      GitHubSession.accessToken = githubCredential?.accessToken;
      await GitHubSession.saveToPrefs();
//savaToPrefs小さい情報をオゾンするもの
      debugPrint('GitHub Token: ${GitHubSession.accessToken}');
      final user = FirebaseAuth.instance.currentUser;

      debugPrint('GitHub UID: ${user?.uid}');
      debugPrint('GitHub email: ${user?.email}');
      debugPrint('GitHub name: ${user?.displayName}');

      final token = GitHubSession.accessToken;
      if (token != null) {
        try {//次回ここから
          GitHubSession.currentUser = await GitHubApi.getCurrentUser(
            token: token,
          );
          final repositories = await GitHubApi.getRepositories(token: token);
          GitHubSession.repositories = repositories
              .whereType<Map>()//map型のデータを残す
              .map((repo) => Map<String, dynamic>.from(repo))//map(string,dynamic)の形にする扱いやすい
              .toList();  //リスト化する
          if (repositories.isNotEmpty) {
            GitHubSession.selectedRepo =
                repositories.first as Map<String, dynamic>;
          } else {
            GitHubSession.selectedRepo = null;
          }
          await GitHubSession.saveToPrefs();
          // Firestoreに保存済みのカスタム表示名があれば読み込む
          await GitHubSession.loadCustomDisplayName();
          debugPrint('GitHub current user: ${GitHubSession.currentLogin}');
          debugPrint(
            'GitHub selected repo: ${GitHubSession.selectedRepo?['full_name']}',
          );
        } catch (e) {
          debugPrint('GitHub API連携に失敗: $e');
        }
      }

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



    return Scaffold(
        resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF060A18),
      body: Center(
          child: SingleChildScrollView(
        child: Container(
          width: 500, // お好みの幅に調整してください
          
    // 内側の余白（枠線とテキスト・アイコンの間の隙間）
    padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
    
    // 枠線とデザインの設定
    decoration: BoxDecoration(
      color: const Color(0xFF060A18), // 背景色（画像のダークカラーに合わせる場合）
      border: Border.all(
        color: Colors.white24, // 枠線の色（少し透過させた白など）
        width: 1.5,            // 枠線の太さ
      ),
      borderRadius: BorderRadius.circular(16.0), // 角を丸くする
    ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
  FontAwesomeIcons.github,
  size: 45,
),
SizedBox(height:  10),
              const Text(
                'GitHubでログイン',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
              
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '続けるには GitHub アカウントでログインしてください',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              Row(
  children: const [
    // 左側の線
    Expanded(
      child: Divider(
        color: Colors.grey, // 線の色
        thickness: 1,       // 線の太さ
      ),
    ),
    
    // 中央のアイコン（左右に余白を調整）
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0),
      child: Icon(
        Icons.verified_user_outlined, // 類似のシールドアイコン
        color: Colors.grey,           // アイコンの色
        size: 20,                      // アイコンのサイズ
      ),
    ),
    
    // 右側の線
    Expanded(
      child: Divider(
        color: Colors.grey, // 線の色
        thickness: 1,       // 線の太さ
      ),
    ),
  ],
),
              const SizedBox(height: 28),
            Material(
  // 1. 波紋エフェクトなどのための親Materialの色を透明（または白）に
  color: Colors.transparent, 
  child: InkWell(
    // InkWellの角丸もContainerの22に合わせるとタップ時のエフェクトがはみ出ません
    borderRadius: BorderRadius.circular(22),
    onTap: _isSigningIn ? null : () => _login(context),
    child: Container(
      width: 400,
      height: 71,
      decoration: BoxDecoration(
        // 2. カードの背景色を「白」に変更
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          // 3. 白背景に合わせて枠線の色を薄いグレーに調整
          color: const Color(0xFF6E7781).withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            // 4. 影の色も自然な明るい黒（透過）に調整
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: _isSigningIn
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  // 5. くるくるアイコンを白から暗めの色（黒）に変更
                  color: Color(0xFF24292F),
                ),
              )
          : Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 24.0, // 左右の余白（画像に合わせて少し外側に広げています）
      vertical: 12.0,
    ),
    child: Row(
      children: const [
        // 1. GitHubアイコン
        FaIcon(
          FontAwesomeIcons.github,
          size: 28,
          color: Color(0xFF24292F),
        ),
        SizedBox(width: 14), // アイコンとテキストの間隔
        
        // 2. テキスト（GitHubの「H」は本来大文字）
        Text(
          'GitHubでログイン',
          style: TextStyle(
            color: Color(0xFF24292F),
            fontSize: 17,
            fontWeight: FontWeight.w700, // 少し太めの読みやすい太さ
          ),
        ),
        
        // 3. 右端に押し出す余白
        Spacer(),
        
        // 4. 右側のまっすぐな矢印アイコン（画像と同じ見た目）
        Icon(
          Icons.arrow_forward,
          size: 20,
          color: Color(0xFF57606A), // 画像に合わせて少し淡いダークグレー
        ),
      ],
    ),
  )
      ),
    ),
  ),
),
SizedBox(height: 30),
Text('ログインすると、プロフィール情報の共有に同意したことになります',
style: TextStyle(
  fontSize: 11,
  color: Colors.grey,
)
),
SizedBox(height: 50),

    // --------------------------------------------------
    // 1. 上部の区切り線（盾アイコン付き）
    // --------------------------------------------------


    // --------------------------------------------------
    // 2. 3つの特徴エリア（横並び）
    // --------------------------------------------------
    IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ================= 特徴 1 =================
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '安全・安心',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'GitHubの認証で\n安全にログイン',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 縦の区切り線 1
          const VerticalDivider(
            color: Colors.white24,
            thickness: 1,
            width: 24,
          ),

          // ================= 特徴 2 =================
          Expanded(
            child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'スピーディー',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'githubにログインするだけ',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 縦の区切り線 2
          const VerticalDivider(
            color: Colors.white24,
            thickness: 1,
            width: 24,
          ),

          // ================= 特徴 3 =================
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.sync,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'データ連携',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'GitHubの情報と\n自動で連携',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ],
)
            
          
        ),
      ),
      )
    );
  }
}
// ============================================================
// エントリーポイント
// ============================================================

Future<void> main() async {// Flutterの初期化とFirebaseの初期化を行う
  WidgetsFlutterBinding.ensureInitialized();// Flutterの初期化を行う
  await _initializeFirebase();
  await GitHubSession.restoreFromPrefs();

  // ログイン済みならFirestoreに保存済みのカスタム表示名を先読みしておく
  if (FirebaseAuth.instance.currentUser != null) {
    await GitHubSession.loadCustomDisplayName();
  }

  runApp(const SyncApp());
}

/// Firebase / Firestoreの初期化（オフラインキャッシュを有効化）//先に保存されてるからオフラインでもそのデータが出る
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(// Firebaseの初期化
      options: DefaultFirebaseOptions.currentPlatform,// Firebaseの初期化オプションを指定
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
  final List<String> participantIds;
  final List<Map<String, dynamic>> participantProfiles;

  const ProjectInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerInfo,
    required this.ownerId,
    required this.role,
    required this.currentMembers,
    required this.tags,
    required this.participantIds,
    required this.participantProfiles,
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
  final participantIds =
      (data['participantIds'] as List?)?.whereType<String>().toList() ??
      const <String>[];
  final participantProfiles = (data['participantProfiles'] as List?)
          ?.whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList() ??
      const <Map<String, dynamic>>[];

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
  participantIds: participantIds,
  participantProfiles: participantProfiles,
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
    label: '参加中',
    description: '現在参加しているもの、募集しているもの',
    icon: Icons.handshake_outlined,
    iconColor: Color(0xFF8B5CF6),
    index: 1,
  ),
  MenuItemInfo(
    label: '本気モード',
    description: '本気でやり成果を残す！',
    icon: Icons.local_fire_department_outlined,
    iconColor: Color(0xffEF4444),
    index: 2,
  ),
  MenuItemInfo(
    label: '初心者モード',
    description: '簡単なことから始めよう',
    icon: Icons.rocket_launch_outlined,
    iconColor: Color(0xffF59E0B),
    index: 3,
  ),

  MenuItemInfo(
        label: '勉強モード',
    description: 'みんなと一緒にがんばろう',
    icon: Icons.person_add_outlined,
    iconColor: Color(0xff3B82F6),
    index: 4,
  ),
  MenuItemInfo(
label: 'フレンド機能',
    description: 'つながりを作ろう',
    icon: Icons.groups_outlined,
    iconColor: Color(0xFF22C55E),
    index: 5,
  ),
    
];

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

Future<void> _handleDeleteProject(
  BuildContext context, {
  required ProjectInfo project,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GitHubログインしてください')),
    );
    return;
  }

  if (project.ownerId != user.uid) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('自分の募集だけ削除できます')),
    );
    return;
  }

  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF0B1022),
      title: const Text(
        '本当に消しますか',
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        'この募集カードを削除すると元に戻せません。',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text('消します'),
        ),
      ],
    ),
  );

  if (shouldDelete != true || !context.mounted) return;

  try {
    await FirebaseFirestore.instance.collection('projects').doc(project.id).delete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('募集を削除しました')),
    );
  } catch (e) {
    debugPrint('募集の削除に失敗しました: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('削除に失敗しました')),
    );
  }
}
Future<void> _confirmJoinAndOpenTask(
  BuildContext context, {
  required ProjectInfo project,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('参加するには先にGitHubログインしてください')),
    );
    return;
  }

  final isOwnProject = project.ownerId == user.uid;
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
    try {
      bool? joinedAfterUpdate;
      final projectRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(project.id);

      final joinResult = await FirebaseFirestore.instance.runTransaction<
          bool>((transaction) async {
        final snapshot = await transaction.get(projectRef);
        final data = snapshot.data();
        if (data == null) {
          throw StateError('プロジェクトが見つかりません');
        }

        final participantIds =
            (data['participantIds'] as List?)?.whereType<String>().toList() ??
            <String>[];
        final participantProfiles =
            (data['participantProfiles'] as List?)
                    ?.whereType<Map>()
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList() ??
                <Map<String, dynamic>>[];
        final alreadyJoined = participantIds.contains(user.uid);
        final currentMembers = data['currentMembers'] as int? ?? 1;
        final maxMembers = data['memberCount'] as int?;
        final gitHubName = GitHubSession.displayName ?? user.displayName;
        debugPrint('GitHub displayName: ${GitHubSession.displayName}');
debugPrint('Firebase displayName: ${user.displayName}');
debugPrint('hello world');
        final gitHubLogin = GitHubSession.currentLogin ?? user.email ?? user.uid;
        final myProfile = GitHubSession.currentMemberProfile(uid: user.uid) ??
            <String, dynamic>{
              'uid': user.uid,
              'githubLogin': gitHubLogin,
              'githubName': gitHubName ?? gitHubLogin,
              'avatarUrl': '',
              'isOwner': false,
            };

        if (!alreadyJoined &&
            maxMembers != null &&
            currentMembers >= maxMembers) {
          return false;
        }

        if (alreadyJoined) {
          final nextParticipantProfiles = participantProfiles
              .where((member) => member['uid']?.toString() != user.uid)
              .toList();
          transaction.update(projectRef, {
            'currentMembers': currentMembers > 1 ? currentMembers - 1 : 1,
            'participantIds':
                participantIds.where((id) => id != user.uid).toList(),
            'participantProfiles': nextParticipantProfiles,
          });
          joinedAfterUpdate = false;
          return true;
        }

        transaction.update(projectRef, {
          'currentMembers': currentMembers + 1,
          'participantIds': [...participantIds, user.uid],
          'participantProfiles': [...participantProfiles, myProfile],
        });
        joinedAfterUpdate = true;
        return true;
      });

      if (!joinResult) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('この募集はすでに上限に達しています')),
        );
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            joinedAfterUpdate == true ? '参加しました' : '退出しました',
          ),
        ),
      );
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
        projectdescription: project.description,
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

  const _InfoCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
  final VoidCallback? onDeletePressed;

  const _ProjectCard({
    required this.project,
    required this.accent,
    required this.onJoinPressed,
    this.onDeletePressed,
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
        // _buildContent() の中の該当箇所を置き換え
        const SizedBox(height: 10),

Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: project.tags
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
      ),
    ),

    const SizedBox(width: 12),

    _buildMemberCount(),

    const SizedBox(width: 10),

    _JoinButton(onPressed: onJoinPressed),
  ],
),
      ],
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
      onSelected: (value) {
        if (value == 'delete') {
          onDeletePressed?.call();
          return;
        }
        debugPrint('カードメニュー選択: $value');
      },
      itemBuilder: (context) {
        final user = FirebaseAuth.instance.currentUser;
        final isOwnProject = user != null && project.ownerId == user.uid;

        return [
          if (isOwnProject)
            const PopupMenuItem(value: 'delete', child: Text('削除')),

        ];
      },
    );
  }
}
/// 募集一覧（Firestoreから取得）
class ProjectList extends StatelessWidget {
  final String? roleFilter;
  final bool showOnlyJoined;

  const ProjectList({
    super.key,
    this.roleFilter,
    this.showOnlyJoined = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProjectInfo>>(
      stream: ProjectService.watchProjects(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('❌ Firestore読み込みエラー: ${snapshot.error}');
        }

        var projects = snapshot.data ?? [];

        final user = FirebaseAuth.instance.currentUser;

        // 自分が募集したもの、または参加しているものだけ表示
        if (showOnlyJoined && user != null) {
          projects = projects.where((project) {
            final isOwner = project.ownerId == user.uid;
            final isJoined = project.participantIds.contains(user.uid);

            return isOwner || isJoined;
          }).toList();
        }

        // モードで絞り込み
        if (roleFilter != null) {
          projects = projects
              .where((project) => project.role == roleFilter)
              .toList();
        }

        if (projects.isEmpty) {
          return Center(
            child: Text(
              showOnlyJoined
                  ? '参加中・募集中のプロジェクトはありません。'
                  : 'まだ募集がありません。右上の「投稿」から作ってみよう。',
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
          onDeletePressed: () => _handleDeleteProject(
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
            _buildSettingsRow(context),
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
  // 設定画面で保存したカスタム表示名を最優先で表示する
  final displayName =
      GitHubSession.customDisplayName ??
      GitHubSession.displayName ??
      GitHubSession.currentLogin ??
      'ユーザー';

  return StreamBuilder<List<ProjectInfo>>(
    stream: ProjectService.watchProjects(),
    builder: (context, snapshot) {
      final projects = snapshot.data ?? [];
      final user = FirebaseAuth.instance.currentUser;

      final joinedCount = user == null
          ? 0
          : projects
              .where((project) => project.participantIds.contains(user.uid))
              .length;

      final ownerCount = user == null
          ? 0
          : projects
              .where((project) => project.ownerId == user.uid)
              .length;

      const friendCount = 0;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${GitHubSession.currentLogin ?? ''}',
                        style: const TextStyle(
                          color: Color(0xff7B849D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  value: joinedCount.toString(),
                  label: '参加中',
                ),
                _buildStatItem(
                  value: ownerCount.toString(),
                  label: '募集',
                ),
                _buildStatItem(
                  value: friendCount.toString(),
                  label: 'Friend',
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
Widget _buildStatItem({
  required String value,
  required String label,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xff7B849D),
          fontSize: 12,
        ),
      ),
    ],
  );
}
  Widget _buildSettingsRow(BuildContext context) {
    return GestureDetector(
      onTap: () async {
  // 設定画面から戻ってきたら、カスタム表示名が変わっている可能性があるので
  // ホーム画面側でも再読み込みしてサイドバーへ反映する
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const SettingPage(),
    ),
  );

  final homeState = context.findAncestorStateOfType<_HomePageState>();
  await homeState?._loadCustomDisplayName();
},
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
  final VoidCallback? onMenuTap; // ★追加

  const _SearchAndPostBar({this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onMenuTap != null) // ★狭い画面だけメニューボタンを表示
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: onMenuTap,
          ),
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
  // _buildSearchField / _buildPostButton はそのまま


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




// ============================================================
// ウィジェット：右サイドバー
// ============================================================

class _RepoSwitchSidebar extends StatefulWidget {
  const _RepoSwitchSidebar();

  @override
  State<_RepoSwitchSidebar> createState() => _RepoSwitchSidebarState();
}

class _RepoSwitchSidebarState extends State<_RepoSwitchSidebar> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _repositories = [];
  Map<String, dynamic>? _selectedRepo;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedRepo = GitHubSession.selectedRepo;
    _loadRepositories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRepositories() async {
    if (GitHubSession.repositories.isNotEmpty) {
      final cached = GitHubSession.repositories;
      final resolvedSelected = _resolveSelectedRepository(cached);
      if (!mounted) return;
      setState(() {
        _repositories = cached;
        _selectedRepo = resolvedSelected;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    final token = GitHubSession.accessToken;
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'GitHubログイン後にリポジトリ一覧が表示されます';
      });
      return;
    }

    try {
      final repositories = await GitHubApi.getRepositories(token: token);
      final repoList = repositories
          .whereType<Map>()
          .map((repo) => Map<String, dynamic>.from(repo))
          .toList();
      GitHubSession.repositories = repoList;
      final resolvedSelected = _resolveSelectedRepository(repoList);
      GitHubSession.selectedRepo = resolvedSelected;
      await GitHubSession.saveToPrefs();

      if (!mounted) return;
      setState(() {
        _repositories = repoList;
        _selectedRepo = resolvedSelected;
        _isLoading = false;
        _errorMessage = repoList.isEmpty ? 'リポジトリが見つかりません' : null;
      });
    } catch (e) {
      debugPrint('リポジトリ一覧の取得に失敗しました: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'リポジトリ一覧の取得に失敗しました';
      });
    }
  }

  Map<String, dynamic>? _resolveSelectedRepository(
    List<Map<String, dynamic>> repoList,
  ) {
    final currentSelected = GitHubSession.selectedRepo;
    if (currentSelected != null) {
      final selectedFullName = currentSelected['full_name'] as String?;
      final selectedExists = repoList.any(
        (repo) => repo['full_name'] == selectedFullName,
      );
      if (selectedExists) {
        return currentSelected;
      }
    }

    return repoList.isNotEmpty ? repoList.first : null;
  }

  Future<void> _selectRepository(Map<String, dynamic> repo) async {
    setState(() {
      _selectedRepo = repo;
    });
    GitHubSession.selectedRepo = repo;
    await GitHubSession.saveToPrefs();
    debugPrint('GitHub selected repo changed: ${repo['full_name']}');
  }

  List<Map<String, dynamic>> get _filteredRepositories {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _repositories;

    return _repositories.where((repo) {
      final fullName = (repo['full_name'] as String? ?? '').toLowerCase();
      final name = (repo['name'] as String? ?? '').toLowerCase();
      final description = (repo['description'] as String? ?? '').toLowerCase();
      final language = (repo['language'] as String? ?? '').toLowerCase();
      return fullName.contains(query) ||
          name.contains(query) ||
          description.contains(query) ||
          language.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = MediaQuery.of(context).size.width * 0.24;
    final selectedRepo = _selectedRepo;
    final filteredRepos = _filteredRepositories;
    final selectedFullName = selectedRepo?['full_name'] as String?;

    return Container(
      width: sidebarWidth.clamp(300.0, 380.0).toDouble(),
      color: AppColors.backgroundBase,
      padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _InfoCard(
              title: 'GitHub リポジトリ',
              child: Text(
                'ここで選んだリポジトリが、タスク画面や関連情報の基準になります。',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.6,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xff0a1220),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.white54, size: 20),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                  hintText: '検索...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: '現在の選択',
              child: selectedRepo == null
                  ? Text(
                      _isLoading
                          ? '読み込み中...'
                          : _errorMessage ?? '選択中のリポジトリはありません',
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedRepo['name'] as String? ?? '-',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selectedRepo['full_name'] as String? ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedRepo['description'] as String? ??
                              '説明はまだ設定されていません',
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.5,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: '切り替え可能なリポジトリ',
              child: SizedBox(
                height: 420,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xff8F7CFF),
                        ),
                      )
                    : _errorMessage != null && _repositories.isEmpty
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.5,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : filteredRepos.isEmpty
                            ? const Center(
                                child: Text(
                                  '条件に合うリポジトリがありません',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    height: 1.5,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredRepos.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final repo = filteredRepos[index];
                                  final isSelected =
                                      repo['full_name'] == selectedFullName;
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _selectRepository(repo),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xff1a2140)
                                            : Colors.white.withValues(
                                                alpha: 0.03,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xff8F7CFF)
                                                  .withValues(alpha: 0.45)
                                              : Colors.white.withValues(
                                                  alpha: 0.08,
                                                ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xff7c5cff)
                                                      .withValues(alpha: 0.22),
                                                  const Color(0xff5c6bc0)
                                                      .withValues(alpha: 0.14),
                                                ],
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.folder_rounded,
                                              color: Color(0xffC8B9FF),
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  repo['name'] as String? ??
                                                      '-',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  repo['full_name'] as String? ??
                                                      '',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(
                                                      alpha: 0.55,
                                                    ),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                if ((repo['language']
                                                            as String? ??
                                                        '')
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    repo['language'] as String,
                                                    style: const TextStyle(
                                                      color: Color(0xff8F7CFF),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xff8F7CFF),
                                              size: 18,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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
 
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
 
    WidgetsBinding.instance.addObserver(this);
    // 起動時にも記録を試みる
    _recordTodayIfNeeded();
    // Firestoreに保存されたカスタム表示名を読み込み、サイドバーに反映する
    _loadCustomDisplayName();
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

  // 設定画面で保存されたカスタム表示名をFirestoreから読み込み、再描画する
  Future<void> _loadCustomDisplayName() async {
    await GitHubSession.loadCustomDisplayName();
    if (!mounted) return;
    setState(() {});
  }


Widget _buildBody() {
  switch (_selectedMenuIndex) {
    case 0:
      return const ProjectList();

case 1:
return const AppleModePage();

    case 2:
      return const SeriousModePage();


    case 3:
    return const BeginnerModePage();

    case 4:
    return const StudyModePage();
    
    case 5:
    return const FriendModePage();



    default:
      return const ProjectList();
  }
}

 @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showLeftSidebar = width >= 760;   // これ未満はDrawerへ
        final showRightSidebar = width >= 1100; // これ未満は非表示

        final leftSidebar = _HomeSidebarLeft(
          menuItems: _menuItems,
          selectedIndex: _selectedMenuIndex,
          onMenuSelected: (index) {
            setState(() => _selectedMenuIndex = index);
            if (!showLeftSidebar) Navigator.of(context).maybePop(); // Drawerを閉じる
          },
        );

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.mainBackground,
          drawer: showLeftSidebar ? null : Drawer(child: leftSidebar),
          body: Row(
            children: [
              if (showLeftSidebar) leftSidebar,
      Expanded(
  child: Container(
    color: AppColors.contentBackground,
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchAndPostBar(
          onMenuTap: showLeftSidebar
              ? null
              : () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
    
        ),
        const SizedBox(height: 25),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1250),
            child:  _buildBody(), // ←ここ
          ),
        ),
      ],
    ),
  ),
),
              if (showRightSidebar) const _RepoSwitchSidebar(),
            ],
          ),
        );
      },
    );
  }
}