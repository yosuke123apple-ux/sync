import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'post_page.dart';
import 'task_page.dart';

// ============================================================
// エントリーポイント
// ============================================================

Future<void> main() async {// Flutterの初期化とFirebaseの初期化を行う
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const SyncApp());
}

/// Firebase / Firestoreの初期化（オフラインキャッシュを有効化）
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(// Firebaseの初期化
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
      theme: ThemeData.dark(),// ダークテーマを使用
      home: const HomePage(),
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
  final String title;
  final String description;
  final String ownerInfo;
  final int currentMembers;
  final int? maxMembers; // Firestoreの投稿には定員の概念がないためnull許容
  final List<String> tags;

  const ProjectInfo({
    required this.title,
    required this.description,
    required this.ownerInfo,
    required this.currentMembers,
    required this.tags,
    this.maxMembers,
  });

  /// Firestoreのドキュメントデータから生成する
  factory ProjectInfo.fromFirestore(Map<String, dynamic> data) {
    final role = data['role'] as String? ?? '役割未設定';
    final level = data['level'] as String? ?? 'レベル未設定';
    final languages =
        (data['languages'] as List?)?.whereType<String>().toList() ??
        const <String>[];

    return ProjectInfo(
      title: _textOrFallback(data['title'] as String?, '無題の募集'),
      description: _textOrFallback(data['description'] as String?, '説明がありません'),
      ownerInfo: _textOrFallback(data['ownerInfo'] as String?, '投稿者情報なし'),
      currentMembers: data['memberCount'] as int? ?? 1,
      tags: [role, level, ...languages.take(3)],
    );
  }

  /// 人数表示用ラベル（例: 定員ありなら"2/3人"、なしなら"2人"）
  String get memberLabel =>
      maxMembers != null ? '$currentMembers/$maxMembers人' : '$currentMembers人';
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


/// 現在ログイン中のユーザー（自分の募集への参加をブロックする判定に使用）
const String _currentUserOwnerInfo = 'やまた_Dev';

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
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProjectInfo.fromFirestore(doc.data()))
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

Future<void> _handleJoinPressed(
  BuildContext context, {
  required String currentUserOwnerInfo,
  required ProjectInfo project,
}) async {
  await _confirmJoinAndOpenTask(
    context,
    project: project,
    currentUserOwnerInfo: currentUserOwnerInfo,
  );
}

Future<void> _confirmJoinAndOpenTask(
  BuildContext context, {
  required ProjectInfo project,
  required String currentUserOwnerInfo,
}) async {
  final isOwnProject = project.ownerInfo.trim() == currentUserOwnerInfo.trim();
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

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TaskPage(
        projectTitle: project.title,
        ownerInfo: project.ownerInfo,
        isOwnProject: isOwnProject,
      ),
    ),
  );
}

// ============================================================
// ウィジェット：小さな部品
// ============================================================

/// 数値＋ラベルの統計表示（例: "7日" / "連続記録"）
class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _StatItem({required this.title, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF7C5CFF),
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF7B849D),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

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
  final String currentUserOwnerInfo;

  const _ProjectList({required this.currentUserOwnerInfo});

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
        final accent =
            AppColors.projectAccentPalette[index %
                AppColors.projectAccentPalette.length];
        return _ProjectCard(
          project: project,
          accent: accent,
          onJoinPressed: () => _handleJoinPressed(
            context,
            currentUserOwnerInfo: currentUserOwnerInfo,
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
            _buildProfileCard(),
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

  Widget _buildProfileCard() {
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(title: '連続記録', value: '7日', valueColor: Colors.white),
            ],
          ),
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

class _HomePageState extends State<HomePage> {
  int _selectedMenuIndex = 0;

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
                      child: const _ProjectList(
                        currentUserOwnerInfo: _currentUserOwnerInfo,
                      ),
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
