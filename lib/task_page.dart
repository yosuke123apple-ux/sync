import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ============================================================
// カラーパレット
// ============================================================
class _AppColors {
  static const background = Color(0xFF030303);
  static const panel = Color(0xFF050B14);
  static const accentPurple = Color(0xFF7C5CFF);
  static const accentBlue = Color(0xFF3B82F6);
  static const accentPink = Color(0xFFEC4899);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9CA3AF); // グレー系の補助テキスト
}

// ============================================================
// メンバーデータ（ダミー・実データとは連携していない）
// ============================================================
class _MemberData {
  final String name;
  final String role;
  final Color roleColor;
  final Color avatarColor;
  final String status;
  final bool isOnline;
  final bool isSelf; // 自分自身のカードかどうか

  const _MemberData({
    required this.name,
    required this.role,
    required this.roleColor,
    required this.avatarColor,
    required this.status,
    this.isOnline = false,
    this.isSelf = false,
  });
}

// ============================================================
// TaskPage（画面全体）
// ============================================================
class TaskPage extends StatelessWidget {
  final String projectTitle;
  final String ownerInfo;
  final bool isOwnProject;

  const TaskPage({
    super.key,
    this.projectTitle = 'タスク',
    this.ownerInfo = '',
    this.isOwnProject = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: AppBar(
        backgroundColor: _AppColors.panel,
        elevation: 0, // フラットにして、よりモダンな印象に
        toolbarHeight: 52, // 高さを少し低くして、よりコンパクトに
        title: const Text('ホームに戻る'),
        iconTheme: const IconThemeData(color: Colors.white), // アイコンの色を白に設定
      ),
      body: _TaskPageBody(
        projectTitle: projectTitle,
        ownerInfo: ownerInfo,
        isOwnProject: isOwnProject,
      ),
    );
  }
}

// ============================================================
// _TaskPageBody（本体レイアウト・カード・各セクションをまとめて管理）
// ============================================================
class _TaskPageBody extends StatelessWidget {
  final String projectTitle;
  final String ownerInfo;
  final bool isOwnProject;

  const _TaskPageBody({
    required this.projectTitle,
    required this.ownerInfo,
    required this.isOwnProject,
  });

  // ── メンバー上限（この人数に達したら新規募集を締め切る） ──
  static const int _maxMembers = 3;

  // ── メンバー一覧（ダミーデータ） ──
  static const List<_MemberData> _members = [
    _MemberData(
      name: 'さくら',
      role: 'オーナー',
      roleColor: _AppColors.accentPurple,
      avatarColor: Color(0xFFEC4899),
      status: 'オンライン',
      isOnline: true,
      isSelf: true,
    ),
    _MemberData(
      name: 'ゆいな',
      role: 'コミッター',
      roleColor: _AppColors.accentBlue,
      avatarColor: Color(0xFF34D399),
      status: '6日前',
    ),
    _MemberData(
      name: 'りょうた',
      role: 'デザイナー',
      roleColor: _AppColors.accentPink,
      avatarColor: Color(0xFFFACC15),
      status: '15分前',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // スクロールさせず画面内に収めるため、Padding のまま返す
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        // 最大幅を設定して、カードが広がりすぎないようにする
        constraints: const BoxConstraints(
          maxWidth: 420,
        ),
        child: _buildHeaderCard(),
      ),
    );
  }

  // ── ヘッダーカード全体 ──
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(),
          const SizedBox(height: 16), // Fibonacci spacing
          _buildBadgeRow(),
          const SizedBox(height: 16),
          _buildDescription(),
          const SizedBox(height: 26),
          _buildInfoSection(),
          const SizedBox(height: 16),
          _buildRepoCard(),
          const SizedBox(height: 26), // Fibonacci spacing
          _buildMembersSection(),
        ],
      ),
    );
  }

  // ── アイコン + タイトル + サブテキスト ──
  Widget _buildTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _AppColors.accentPurple,
                Color(0xFF4834AA),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _AppColors.accentPurple.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.code,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 21), // Fibonacci spacing
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Syncating',
                style: TextStyle(
                  color: _AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'フリーランスで開発完了！',
                style: TextStyle(
                  color: _AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Flutter / Firebase バッジ列 ──
  Widget _buildBadgeRow() {
    return Wrap(
      spacing: 13,
      runSpacing: 13,
      children: [
        _buildBadge(
          label: 'Flutter',
          icon: Icons.flutter_dash,
          color: _AppColors.accentBlue,
        ),
        _buildBadge(
          label: 'Firebase',
          icon: Icons.local_fire_department,
          color: const Color(0xFFFFA000),
        ),
      ],
    );
  }

  // ── バッジ単体（ラベル・アイコン・色を引数で受け取る） ──
  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── プロジェクト説明文 ──
  Widget _buildDescription() {
    return const Text(
      'AIにつながる、開発を加速する交渉・コラボレーションプラットフォームです。',
      style: TextStyle(
        color: _AppColors.textSecondary,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  // ── プロジェクト情報セクション（見出し部分） ──
  Widget _buildInfoSection() {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                _AppColors.accentPurple,
                _AppColors.accentPink,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 13),
        const Text(
          'プロジェクト情報',
          style: TextStyle(
            color: _AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GitHubリポジトリカード（アイコン＋URL／Star・Fork・Issue／最新コミット）
  // ============================================================
  Widget _buildRepoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRepoHeader(),
          const SizedBox(height: 10), // Fibonacci spacing
          _buildRepoStatsRow(),
          const SizedBox(height: 10),
          _buildLastCommitRow(),
        ],
      ),
    );
  }

  // ── リポジトリ名 + URL（GitHubアイコン付き） ──
  Widget _buildRepoHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FaIcon(
          FontAwesomeIcons.github,
          color: Colors.white,
          size: 32,
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GitHubリポジトリ',
                style: TextStyle(
                  color: _AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'github.com/flutter/flutter',
                style: TextStyle(
                  color: _AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Star / Fork / Issue の統計行 ──
  // ※ ここの数値はダミー（実データとは連携していない）
  Widget _buildRepoStatsRow() {
    return Row(
      children: [
        _buildRepoStatItem(
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFFACC15),
          value: '128',
          label: 'Stars',
        ),
        const SizedBox(width: 34), // Fibonacci spacing
        _buildRepoStatItem(
          icon: Icons.call_split_rounded,
          iconColor: _AppColors.accentBlue,
          value: '24',
          label: 'Forks',
        ),
        const SizedBox(width: 34),
        _buildRepoStatItem(
          icon: Icons.error_outline_rounded,
          iconColor: _AppColors.accentPink,
          value: '3',
          label: 'Issues',
        ),
      ],
    );
  }

  // ── 統計項目単体（アイコン + 数値 + ラベル） ──
  Widget _buildRepoStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: _AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: _AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ── 最新コミット行（ハッシュ + メッセージ + 経過時間） ──
  // ※ ここも実データとは連携していないダミー表示
  Widget _buildLastCommitRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.commit_rounded,
            color: _AppColors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 13),
          Text(
            'a35b230',
            style: TextStyle(
              color: _AppColors.accentPurple,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              'test: add unit test coverage',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 13),
          const Text(
            '3時間前',
            style: TextStyle(
              color: _AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // メンバーセクション（見出し／一覧／招待ボタン）
  // ============================================================
  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMembersHeader(),
        const SizedBox(height: 16), // Fibonacci spacing
        ..._members
            .map(_buildMemberRow)
            .expand((row) => [row, const SizedBox(height: 14)]),
        const SizedBox(height: 20),
        _buildInviteButton(),
      ],
    );
  }

  // ── メンバー見出し（左：タイトルバー／右：人数バッジ） ──
  Widget _buildMembersHeader() {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                _AppColors.accentPurple,
                _AppColors.accentPink,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Text(
            'メンバー',
            style: TextStyle(
              color: _AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '${_members.length}/$_maxMembers人',
          style: const TextStyle(
            color: _AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ── メンバー1行（アバター＋名前＋役割バッジ／右：状態） ──
  // ※ isSelf の場合は縦の余白を詰めて、他メンバーと一目で区別できるようにする
  Widget _buildMemberRow(_MemberData member) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 13,
        vertical: member.isSelf ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: member.isSelf
            ? _AppColors.accentPurple.withOpacity(0.07)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: member.isSelf
              ? _AppColors.accentPurple.withOpacity(0.4)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          _buildMemberAvatar(member),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        color: _AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (member.isSelf) ...[
                      const SizedBox(width: 6),
                      _buildSelfTag(),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                _buildMemberRoleBadge(member),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Text(
            member.status,
            style: TextStyle(
              color: member.isOnline
                  ? const Color(0xFF34D399)
                  : _AppColors.textSecondary,
              fontSize: 12,
              fontWeight: member.isOnline ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ── 「自分」であることを示す小さなタグ ──
  Widget _buildSelfTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _AppColors.accentPurple,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '自分',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── メンバーアバター（頭文字＋オンライン状態ドット） ──
  // ※ isSelf は行の縦幅を詰めているぶん、アバターも少し小さくして馴染ませる
  Widget _buildMemberAvatar(_MemberData member) {
    final double size = member.isSelf ? 38 : 44;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: member.avatarColor.withOpacity(0.85),
            shape: BoxShape.circle,
          ),
          child: Text(
            member.name.substring(0, 1),
            style: TextStyle(
              color: Colors.white,
              fontSize: member.isSelf ? 12 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (member.isOnline)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFF34D399),
                shape: BoxShape.circle,
                border: Border.all(color: _AppColors.panel, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  // ── メンバーの役割バッジ ──
  Widget _buildMemberRoleBadge(_MemberData member) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: member.roleColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: member.roleColor.withOpacity(0.35),
        ),
      ),
      child: Text(
        member.role,
        style: TextStyle(
          color: member.roleColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── メンバー招待ボタン（Container + InkWell） ──
  // ※ 上限（_maxMembers）に達している場合はグレーアウトしてタップ不可にする
  Widget _buildInviteButton() {
    final bool isFull = _members.length >= _maxMembers;
    final Color themeColor =
        isFull ? _AppColors.textSecondary : _AppColors.accentPurple;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isFull ? null : () {}, // TODO: メンバー招待フローに接続
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: themeColor.withOpacity(0.4),
            ),
            color: themeColor.withOpacity(0.08),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isFull
                    ? Icons.lock_outline_rounded
                    : Icons.person_add_alt_1_rounded,
                color: themeColor,
                size: 18,
              ),
              const SizedBox(width: 13),
              
              Text(
                isFull ? '上限に達しました（$_maxMembers人）' : 'メンバーを招待する',
                style: TextStyle(
                  color: themeColor,
                  fontSize: 14,
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
