import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
// TODO: プロジェクト内の実際のパスに合わせて修正してください
import 'github_session.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final TextEditingController _displayNameController =
      TextEditingController();
  int selectedIndex = 0;
  String _version = '読み込み中...';
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();

    _displayNameController.text =
        GitHubSession.customDisplayName ??
        GitHubSession.displayName ??
        GitHubSession.currentLogin ??
        '';

    _loadVersion();
    // Firestoreに保存済みのカスタム表示名を念のため読み直す
    _loadCustomDisplayName();
  }

  // Firestoreからカスタム表示名を読み込み、UIに反映する
  Future<void> _loadCustomDisplayName() async {
    await GitHubSession.loadCustomDisplayName();
    if (!mounted) return;
    setState(() {
      _displayNameController.text =
          GitHubSession.customDisplayName ??
          GitHubSession.displayName ??
          GitHubSession.currentLogin ??
          '';
    });
  }

  @override
  void dispose() {
    // コントローラーの破棄漏れを修正
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() {
        _version = '${info.version} (${info.buildNumber})';
      });
    } catch (e, stackTrace) {
      debugPrint('バージョン取得エラー: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _version = '取得できませんでした';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      body: SafeArea(
        child: Row(
          children: [
            // ==================== 左メニュー ====================
            SizedBox(
              width: 260,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 0, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'アプリの設定を管理',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: Column(
                        spacing: 2,
                        children: [
                          _buildMenuTile(
                            icon: Icons.person_outline,
                            title: 'アカウント',
                            index: 0,
                            isSelected: selectedIndex == 0,
                          ),
                          _buildMenuTile(
                            icon: Icons.lock_outline,
                            title: 'プライバシー',
                            index: 1,
                            isSelected: selectedIndex == 1,
                          ),
                          _buildMenuTile(
                            icon: Icons.info_outline,
                            title: 'その他',
                            index: 2,
                            isSelected: selectedIndex == 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 縦線
            Container(
              width: 1,
              color: Colors.white.withOpacity(0.08),
            ),

            // ==================== 右側コンテンツ ====================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
  children: [
    IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(
        Icons.arrow_back_rounded,
        color: Colors.white,
      ),
    ),
    const SizedBox(width: 8),
    Text(
      _getTitle(selectedIndex),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.w800,
      ),
    ),
  ],
),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _getContent(selectedIndex),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => selectedIndex = index),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B8CFF).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? const Border(
                  left: BorderSide(
                    color: Color(0xFF8B8CFF),
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF8B8CFF)
                  : Colors.white.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // メニューは3項目（アカウント/プライバシー/その他）なので配列を合わせる
  String _getTitle(int index) {
    const titles = ['アカウント', 'プライバシー', 'その他'];
    return titles[index];
  }

  Widget _getContent(int index) {
    final contents = [
      _buildAccountContent(),
      _buildPrivacyContent(),
      _buildOtherContent(),
    ];
    return contents[index];
  }

  Widget _buildAccountContent() {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingItem(
          title: '表示名',
          value: GitHubSession.customDisplayName ??
              GitHubSession.displayName ??
              '未設定',
        ),
        _buildSettingItem(
          title: 'GitHub',
          value: GitHubSession.currentLogin ?? '未ログイン',
        ),
        const SizedBox(height: 16),
        _buildButton(
          'プロフィール編集',
          Colors.white.withOpacity(0.1),
          onTap: _showEditProfileDialog,
        ),
      ],
    );
  }

  // 呼び出されていたが未実装だったダイアログを追加
  void _showEditProfileDialog() {
    _displayNameController.text =
        GitHubSession.customDisplayName ??
        GitHubSession.displayName ??
        GitHubSession.currentLogin ??
        '';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF111827),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'プロフィール編集',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: _displayNameController,
              autofocus: true,
              enabled: !_isSavingName,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '表示名を入力',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF8B8CFF)),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    _isSavingName ? null : () => Navigator.pop(dialogContext),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: _isSavingName
                    ? null
                    : () async {
                        final newName = _displayNameController.text.trim();

                        setDialogState(() => _isSavingName = true);
                        setState(() => _isSavingName = true);

                        // Firestoreに保存し、GitHubSession.customDisplayNameも更新する
                        await GitHubSession.saveCustomDisplayName(
                          newName.isEmpty ? null : newName,
                        );

                        if (!mounted) return;
                        setState(() => _isSavingName = false);

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                      },
                child: _isSavingName
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF8B8CFF),
                        ),
                      )
                    : const Text(
                        '保存',
                        style: TextStyle(color: Color(0xFF8B8CFF)),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingItem(
          title: 'データ共有',
          value: 'オン',
        ),
        _buildSettingItem(
          title: 'アナリティクス',
          value: 'オン',
        ),
        const SizedBox(height: 16),
        _buildButton(
          'プライバシーポリシー',
          Colors.white.withOpacity(0.1),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF111827),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'プライバシーポリシー',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: const SingleChildScrollView(
                  child: Text(
                    '''
Syncでは、サービス提供のために必要な範囲でユーザー情報を取得・利用します。

【取得する情報】
・GitHubアカウント情報
・プロフィール情報
・投稿内容
・参加プロジェクト情報

【利用目的】
・ログイン認証
・プロフィール表示
・チーム募集機能の提供
・サービス改善
・不正利用の防止

取得した情報は、法令に基づく場合を除き、ユーザーの同意なく第三者へ提供しません。

本ポリシーは必要に応じて変更される場合があります。
''',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('閉じる'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOtherContent() {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'バージョン',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        Text(
          _version,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 15,
          ),
        ),
        Switch(
          value: value,
          onChanged: (val) {},
          activeColor: const Color(0xFF8B8CFF),
        ),
      ],
    );
  }

  Widget _buildButton(
    String text,
    Color bgColor, {
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor ?? const Color(0xFF8B8CFF),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}