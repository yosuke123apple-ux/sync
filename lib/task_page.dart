import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'github_api.dart';

// ============================================================
// カラーパレット
// ============================================================
class _AppColors {
  static const background = Color(0xFF030303);
  static const panel = Color(0xFF050B14);
  static const accentPurple = Color(0xFF7C5CFF);
  static const accentBlue = Color(0xFF3B82F6);
  static const accentPink = Color(0xFFEC4899);
  static const accentTeal = Color(0xFF14B8A6);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9CA3AF); // グレー系の補助テキスト

  // ── 装飾用トークン（枠線・区切り線・影のトーンを統一するため追加） ──
  static const cardBorder = Color(0x14FFFFFF); // 白8%
  static const cardBorderSoft = Color(0x0DFFFFFF); // 白5%
  static const divider = Color(0x0AFFFFFF); // 白4%
  static const shadow = Color(0x66000000); // 黒40%
}
Color _getLanguageColor(String language) {
  switch (language) {
    case 'Dart':
      return const Color(0xFF02569B);

    case 'C':
      return const Color(0xFF555555);

    case 'C++':
      return const Color(0xFFF34B7D);

    case 'C#':
      return const Color(0xFF178600);

    case 'Java':
      return const Color(0xFFB07219);

    case 'Kotlin':
      return const Color(0xFFA97BFF);

    case 'Swift':
      return const Color(0xFFF05138);

    case 'Objective-C':
      return const Color(0xFF438EFF);

    case 'Objective-C++':
      return const Color(0xFF6866FB);

    case 'JavaScript':
    case 'JS':
      return const Color(0xFFF1E05A);

    case 'TypeScript':
    case 'TS':
      return const Color(0xFF3178C6);

    case 'Python':
      return const Color(0xFF3572A5);

    case 'Go':
    case 'Golang':
      return const Color(0xFF00ADD8);

    case 'Rust':
      return const Color(0xFFDEA584);

    case 'Ruby':
      return const Color(0xFF701516);

    case 'PHP':
      return const Color(0xFF4F5D95);

    case 'R':
      return const Color(0xFF198CE7);

    case 'Scala':
      return const Color(0xFFC22D40);

    case 'Shell':
    case 'Bash':
      return const Color(0xFF89E051);

    case 'PowerShell':
      return const Color(0xFF012456);

    case 'HTML':
      return const Color(0xFFE34C26);

    case 'CSS':
      return const Color(0xFF563D7C);

    case 'SCSS':
      return const Color(0xFFC6538C);

    case 'Vue':
      return const Color(0xFF41B883);

    case 'React':
      return const Color(0xFF61DAFB);

    case 'Svelte':
      return const Color(0xFFFF3E00);

    case 'SQL':
      return const Color(0xFFE38C00);

    case 'Lua':
      return const Color(0xFF000080);

    case 'Perl':
      return const Color(0xFF0298C3);

    case 'Haskell':
      return const Color(0xFF5E5086);

    case 'Elixir':
      return const Color(0xFF6E4A7E);

    case 'Erlang':
      return const Color(0xFFB83998);

    case 'D':
      return const Color(0xFFBA595E);

    case 'F#':
      return const Color(0xFFB845FC);

    case 'Groovy':
      return const Color(0xFF4298B8);

    case 'MATLAB':
      return const Color(0xFFE16737);

    case 'Assembly':
      return const Color(0xFF6E4C13);

    case 'Jupyter Notebook':
      return const Color(0xFFDA5B0B);

    case 'Dockerfile':
      return const Color(0xFF384D54);

    case 'JSON':
      return const Color(0xFF292929);

    case 'YAML':
      return const Color(0xFFCB171E);

    case 'Markdown':
      return const Color(0xFF083FA1);

    case 'Visual Basic':
      return const Color(0xFF945DB7);

    default:
      return const Color(0xFF8B949E);
  }
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
// プルリクエスト / イシュー用ステータスモデル
// ============================================================
class _StatusStat {
  final String count;
  final String title;
  final String subtitle;
  final Color accentColor;


  const _StatusStat({
    required this.count,
    required this.title,
    required this.subtitle,
    required this.accentColor,

  });
}

// ============================================================
// チャットメッセージモデル
// ============================================================
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });
  //firebaseから届いたデータを画面に届けるための変換機
  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> data) {
    final rawTimestamp = data['timestamp'];
    return ChatMessage(
      id: id, //各メッセージを世界で一つだけに
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '名無し',
      text: data['text'] as String? ?? '',
      // サーバー側でタイムスタンプが確定するまでの一瞬は null になるため、
      // その間は「送信中」の暫定表示として現在時刻を使う。
      timestamp: rawTimestamp is Timestamp
          ? rawTimestamp.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(), //googleが管理するサーバーの時刻
    };
  }
}

// ============================================================
// ChatService（Firestore連携／モック切り替え用の抽象インターフェース）
// ============================================================
abstract class ChatService {
  Stream<List<ChatMessage>> watchMessages(String projectId);

  Future<void> sendMessage(
    String projectId, {
    required String senderId,
    required String senderName,
    required String text,
  });
}

// ── Firestore実装（本番用） ──
class FirestoreChatService implements ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _messagesRef(String projectId) {
    return _db.collection('projects').doc(projectId).collection('messages');
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String projectId) {
    return _messagesRef(projectId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  //チャットメッセージを作ってfirebaseに保存する
  @override
  Future<void> sendMessage(
    String projectId, {
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final message = ChatMessage(
      id: '', // Firestore側で自動採番されるため未使用
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    );
    await _messagesRef(projectId).add(message.toFirestore());
  }
}

// ── モック実装（Firebase未接続時の開発・プレビュー用） ──
class MockChatService implements ChatService {
  final StreamController<List<ChatMessage>> _controller =
      StreamController<List<ChatMessage>>.broadcast();
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'mock-1',
      senderId: 'self',
      senderName: 'やまだ',
      text: 'feat: add auth screen をコミットしました',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  MockChatService() {
    // StreamBuilder が listen した直後に初期データを流すため microtask で発火
    scheduleMicrotask(() => _controller.add(List.of(_messages)));
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String projectId) =>
      _controller.stream;

  @override
  Future<void> sendMessage(
    String projectId, {
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    _messages.add(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        senderId: senderId,
        senderName: senderName,
        text: text,
        timestamp: DateTime.now(),
      ),
    );
    _controller.add(List.of(_messages));
  }
}

// ============================================================
// ServiceLocator（Mock / Firestore の切り替え）
// ※ Firebase未接続の環境で動作確認したい場合は下の行を入れ替える
// ============================================================
class ServiceLocator {
  static ChatService chatService = FirestoreChatService();
  // static ChatService chatService = MockChatService();
}

// ============================================================
// TaskPage（画面全体）
// ============================================================
class TaskPage extends StatelessWidget {
  final String projectTitle;
  final String ownerInfo;
  final bool isOwnProject;
  final String projectId; // Firestore上のプロジェクトドキュメントID

  const TaskPage({
    super.key,
    this.projectTitle = 'タスク',
    this.ownerInfo = '',
    this.isOwnProject = false,
    this.projectId = 'demo-project',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: AppBar(
        backgroundColor: _AppColors.panel,
        elevation: 0,
        toolbarHeight: 56,
        title: Text('ホームに戻る'),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _TaskPageBody(
        projectTitle: projectTitle,
        ownerInfo: ownerInfo,
        isOwnProject: isOwnProject,
        projectId: projectId,
      ),
    );
  }
}

// ============================================================
// _TaskPageBody（本体レイアウト・カード・各セクションをまとめて管理）
// ※ チャットの送受信状態を持つため StatefulWidget
// ============================================================
class _TaskPageBody extends StatefulWidget {
  final String projectTitle;
  final String ownerInfo;
  final bool isOwnProject;
  final String projectId;

  const _TaskPageBody({
    required this.projectTitle,
    required this.ownerInfo,
    required this.isOwnProject,
    required this.projectId,
  });

  @override
  State<_TaskPageBody> createState() => _TaskPageBodyState();
}

class _TaskPageBodyState extends State<_TaskPageBody> {
    Map<String, dynamic>? repo;
    Map<String, dynamic>? languages;
    List<dynamic> pullRequests = [];
List<dynamic> issues = [];
int get openPulls =>
    pullRequests.where((pr) => pr['state'] == 'open').length;

int get mergedPulls =>
    pullRequests.where((pr) => pr['merged_at'] != null).length;

int get closedPulls =>
    pullRequests.where(
      (pr) => pr['state'] == 'closed' && pr['merged_at'] == null,
    ).length;

int get openIssues =>
    issues.where((issue) => issue['pull_request'] == null && issue['state'] == 'open').length;

int get closedIssues =>
    issues.where((issue) => issue['pull_request'] == null && issue['state'] == 'closed').length;
  // ── メンバー上限（この人数に達したら新規募集を締め切る） ──
  static const int _maxMembers = 3;

  // ── メンバー一覧（ダミーデータ） ──
  static const List<_MemberData> _members = [
    _MemberData(
      name: 'やまだ',
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

  // ── 現在のユーザー情報（仮の値。認証実装後は FirebaseAuth.currentUser 等に置き換える） ──
  static const String _currentUserId = 'self';
  static const String _currentUserName = 'やまだ';

  // ── 入力欄でよく使う絵文字（ここに好きな絵文字を追加してOK） ──
  static const List<String> _quickEmojis = [
    '😀',
    '😂',
    '😍',
    '👍',
    '🙏',
    '🎉',
    '🔥',
    '❤️',
    '😢',
    '😮',
    '✅',
    '🚀',
    '👀',
    '💡',
    '⚡',
    '🙌',
    '😅',
    '👏',
    '🤔',
    '😊',
    '😁',
    '🤣',
    '😭',
    '😎',
    '🥳',
    '😴',
    '🤯',
    '😡',
    '🥲',
    '💪',
    '✨',
    '⭐',
    '💯',
    '🎯',
    '📌',
    '📚',
    '💻',
    '⌨️',
    '🖥️',
    '📱',
    '🛠️',
    '🔧',
    '🧠',
    '📢',
    '📸',
    '🎵',
    '🎮',
    '🍕',
    '☕',
    '🍔',
    '🍩',
    '🍎',
    '🌸',
    '🌈',
    '☀️',
    '🌙',
    '⭐',
    '🎁',
    '🏆',
  ];

  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

@override
void initState() {
  super.initState();
  loadRepo();
}

Future<void> loadRepo() async {
  repo = await GitHubApi.getRepo(
    owner: 'yosuke123apple-ux',
    repo: 'sync',
  );

  languages = await GitHubApi.getLanguages(
    owner: 'yosuke123apple-ux',
    repo: 'sync',
  );

  pullRequests = await GitHubApi.getPullRequests(
    owner: 'yosuke123apple-ux',
    repo: 'sync',
  );

  issues = await GitHubApi.getIssues(
    owner: 'yosuke123apple-ux',
    repo: 'sync',
  );

  setState(() {});
}

  @override
  void dispose() {
    _messageController.dispose(); //ユーザーが打った文字を操作する
    _messageFocusNode.dispose(); //キーボードからの入力受け取り管理
    _scrollController.dispose(); //画面のスクロールコード
    super.dispose();
  }

  // ── メッセージ送信処理（Firestoreへ保存） ──
  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (_isSending) return;

    debugPrint('送信開始: $text');

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ServiceLocator.chatService.sendMessage(
        widget.projectId,
        senderId: _currentUserId,
        senderName: _currentUserName,
        text: text,
      );

      debugPrint('Firestore保存成功');

      _scrollToBottom();
    } catch (e, stackTrace) {
      debugPrint('Firestore保存失敗');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('メッセージの送信に失敗しました: $e')));
      }
    } finally {
      //止める
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  //メッセージがつかされた瞬間に一番下まで自動でスクロールさせる
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return; //つながってなかったら消せ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        //指定したところに行きます
        _scrollController.position.maxScrollExtent, //一番下まで
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut, //緩やかに
      );
    });
  }

  // ============================================================
  // 入力欄アイコン共通処理（絵文字・添付）
  // ============================================================
  // ── カーソル位置（選択範囲）にテキストを挿入する共通ヘルパー ──
  void _insertTextAtCursor(String insertText) {
    final text = _messageController.text; //今入力されてる文字全体
    final selection = _messageController.selection; //現在の選択範囲
    final start = selection.start >= 0
        ? selection.start
        : text.length; //選択されてるところの文字を得るためのコード
    final end = selection.end >= 0
        ? selection.end
        : text.length; //文字が打たれなかったら0だからそれでとめる

    final newText = text.replaceRange(
      start,
      end,
      insertText,
    ); //入れたい文字に置き換えて新しい文章ができる
    final newCursor = start + insertText.length; //挿入された分だけカーソルが右に行く

    _messageController.text = newText;
    _messageController.selection = TextSelection.collapsed(
      offset: newCursor,
    ); //荒らしいカーソルの位置を決定し実際に行動
  }

  // ── 絵文字ピッカーをボトムシートで表示し、選んだ絵文字を挿入 ──
  Future<void> _showEmojiPicker() async {
    final selected = await showModalBottomSheet<String>(
      //下から出てくるカード
      context: context, //引き渡し
      backgroundColor: const Color(0xFF12151F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _quickEmojis.map((emoji) {
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).pop(emoji),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      _insertTextAtCursor(selected);
      _messageFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF090A0F), // カード taskpageの背景色です
              Color(0xFF161B26), // 背景
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(21), // Fibonacci spacing
          child: LayoutBuilder(
            builder: (context, constraints) {
              //大きさを測定
              final isWide = constraints.maxWidth >= 1080; //pc画面か分割画面かの判断
              final leftCard = _buildHeaderCard();
              final leftPanel = SizedBox(
                //さっきの横幅の想定で比率を班d何
                width: isWide ? constraints.maxWidth * 0.25 : double.infinity,
                child: leftCard,
              );
              //こっちは真ん中のところかな
              final chatPanel = SizedBox(
                width: isWide ? constraints.maxWidth * 0.42 : double.infinity,
                height: isWide ? null : 500,
                child: Container(
                  padding: const EdgeInsets.all(21), // Fibonacci spacing
                  decoration: BoxDecoration(
                    color: _AppColors.panel,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: _AppColors.shadow,
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(child: _buildChatMessageList()),
                      const SizedBox(height: 13),
                      Container(height: 1, color: _AppColors.divider),
                      const SizedBox(height: 13),
                      _buildMessageInput(),
                    ],
                  ),
                ),
              );
              final rightPanel = SizedBox(
                width: isWide ? constraints.maxWidth * 0.30 : double.infinity,
                child: _buildRightCard(),
              );
              if (isWide) {
                return Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch, //横並びなら縦、縦並びなら横
                  children: [
                    leftPanel,
                    const SizedBox(width: 21),
                    chatPanel,
                    const SizedBox(width: 21),
                    rightPanel,
                  ],
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    leftPanel,
                    const SizedBox(height: 21),
                    chatPanel,
                    const SizedBox(height: 21),
                    rightPanel,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── ヘッダーカード全体 ──
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: _AppColors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 中身の高さに合わせて縮める（画面下まで伸びるのを防ぐ）
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(),
          const SizedBox(height: 16), // Fibonacci spacing
          _buildBadgeRow(),
          const SizedBox(height: 16),
          _buildDescription(),
          const SizedBox(height: 5),
          Container(height: 1, color: _AppColors.divider),
          const SizedBox(height: 21),
          _buildInfoSection(),
          const SizedBox(height: 13),
          _buildRepoCard(),
          const SizedBox(height: 5),
          Container(height: 1, color: _AppColors.divider),
          const SizedBox(height: 21),
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
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_AppColors.accentPurple, Color(0xFF4834AA)],
            ),
            boxShadow: [
              BoxShadow(
                color: _AppColors.accentPurple.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.code, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 21), // Fibonacci spacing
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.projectTitle,
                style: const TextStyle(
                  color: _AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.ownerInfo.isNotEmpty
                    ? widget.ownerInfo
                    : 'プロジェクトオーナー情報なし',
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
        border: Border.all(color: color.withOpacity(0.35)),
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
              colors: [_AppColors.accentPurple, _AppColors.accentPink],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 13),
        const Text(
          'ボイスチャット',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.cardBorder),
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
        const FaIcon(FontAwesomeIcons.github, color: Colors.white, size: 32),
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
          style: const TextStyle(color: _AppColors.textSecondary, fontSize: 13),
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
          Icon(Icons.commit_rounded, color: _AppColors.textSecondary, size: 16),
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
            style: TextStyle(color: _AppColors.textSecondary, fontSize: 12),
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
        const SizedBox(height: 13), // Fibonacci spacing
        ..._members
            .map(_buildMemberRow)
            .expand((row) => [row, const SizedBox(height: 10)]),
        const SizedBox(height: 13),
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
              colors: [_AppColors.accentPurple, _AppColors.accentPink],
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
          style: const TextStyle(color: _AppColors.textSecondary, fontSize: 12),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: member.isSelf
              ? _AppColors.accentPurple.withOpacity(0.4)
              : _AppColors.cardBorderSoft,
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
        border: Border.all(color: member.roleColor.withOpacity(0.35)),
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
    final Color themeColor = isFull
        ? _AppColors.textSecondary
        : _AppColors.accentPurple;

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
            border: Border.all(color: themeColor.withOpacity(0.4)),
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

  Widget _buildRightCard() {
    return Container(
      padding: const EdgeInsets.all(21), // Fibonacci spacing
      decoration: BoxDecoration(
        color: _AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: _AppColors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1つ目のパーツ：タイトルの行（横並び）
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_AppColors.accentPurple, _AppColors.accentPink],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 13),
              const Text(
                'Github情報',
                style: TextStyle(
                  color: _AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13), // 文字の下線とのスキマ
          // 2つ目のパーツ：区切り線
          Container(height: 1, color: _AppColors.divider),

          const SizedBox(height: 14), // 線と、新しく作るコンテンツのスキマを追加
          // 3つ目のパーツ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16), // 内側の余白
            decoration: BoxDecoration(
              color: const Color(0xFF161B22), // カードの背景色（暗いグレー）
              borderRadius: BorderRadius.circular(12), // カドを丸くする
              border: Border.all(
                color: Colors.white.withOpacity(0.05), // 微妙な白枠線で立体感を出す
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 中身を左寄せにする設定
              children: [
                const Text(
                  'リポジトリ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

            Row(
  children: [
    // Forks
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FaIcon(
          FontAwesomeIcons.codeFork,
          size: 14,
          color: Colors.white38,
        ),
        const SizedBox(width: 4),
        Text(
          repo == null ? '...' : repo!['forks_count'].toString(),
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
    const SizedBox(width: 16),

    // Stars
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star_border,
          size: 14,
          color: Colors.white38,
        ),
        const SizedBox(width: 4),
        Text(
          repo == null ? '...' : repo!['stargazers_count'].toString(),
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
    const SizedBox(width: 16),

    // Watchers
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.visibility_outlined,
          size: 14,
          color: Colors.white38,
        ),
        const SizedBox(width: 4),
        Text(
          repo == null ? '...' : repo!['subscribers_count'].toString(),
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
    const SizedBox(width: 16),

    // Size
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.insert_drive_file_outlined,
          size: 14,
          color: Colors.white38,
        ),
        const SizedBox(width: 4),
        Text(
          repo == null
              ? '...'
              : '${(repo!['size'] / 1024).toStringAsFixed(0)}MB',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
    const SizedBox(width: 16),

    // License
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.gavel,
          size: 14,
          color: Colors.white38,
        ),
        const SizedBox(width: 4),
        Text(
          (repo?['license'] as Map<String, dynamic>?)?['spdx_id'] ?? '-',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
    const SizedBox(width: 16),


    // Visibility
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.lock_outline,
          size: 14,
          color: Colors.white38,
        ),
        const SizedBox(width: 4),
        Text(
          repo == null ? '...' : repo!['visibility'],
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
    const SizedBox(width: 16),

    // Last Push
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.schedule,
          size: 14,
          color: Colors.white38,
        ),
        const SizedBox(width: 4),
        Text(
          repo == null ? '...' : repo!['updated_at'].substring(0, 10),
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
    const SizedBox(width: 16),

Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    const Icon(
      Icons.error_outline,
      size: 14,
      color: Colors.white38,
    ),
    const SizedBox(width: 4),
    Text(
      repo == null ? '...' : repo!['open_issues_count'].toString(),
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 11,
      ),
    ),
  ],
),
const SizedBox(width: 16),

Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    const Icon(
      Icons.folder_outlined,
      size: 14,
      color: Colors.white38,
    ),
    const SizedBox(width: 4),
    Text(
      repo == null ? '...' : repo!['name'],
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 11,
      ),
    ),
  ],
),
const SizedBox(width: 16),
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    const Icon(
      Icons.calendar_today_outlined,
      size: 14,
      color: Colors.white38,
    ),
    const SizedBox(width: 4),
    Text(
      repo == null
          ? '...'
          : repo!['created_at']
              .toString()
              .replaceFirst('T', ' ')
              .replaceFirst('Z', ''),
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 11,
      ),
    ),
  ],
),


  ],
)
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 8),
                const Text(
                  'ブランチ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.codeBranch,
                      color: Colors.deepPurpleAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 13),
                    const Text('main'),

                    const Spacer(),

                    const Text('7', style: TextStyle(color: Colors.white38)),
                    const SizedBox(width: 6),

                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white24,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildStatusSection(
            'プルリクエスト',
            [
              _StatusStat(
                count: openPulls.toString(),
                title: 'レビュー待ち',
                subtitle: 'Open',
                accentColor: const Color(0xFF58A6FF),
              ),
              _StatusStat(
                count: mergedPulls.toString(),
                title: 'マージ済み',
                subtitle: 'Merged',
                accentColor: const Color(0xFF22C55E),
              ),
              _StatusStat(
                count: closedPulls.toString(),
                title: 'クローズ',
                subtitle: 'Closed',
                accentColor: const Color(0xFFF97316),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStatusSection(
            'イシュー (Issue)',
            [
              _StatusStat(
                count: openIssues.toString(),
                title: '未対応',
                subtitle: 'Open',
                accentColor: const Color(0xFFEC4899),
              ),
              _StatusStat(
                count: closedIssues.toString(),
                title: '解決済み',
                subtitle: 'Closed',
                accentColor: const Color(0xFF22C55E),
              ),
              _StatusStat(
                count: '0',
                title: '下書き',
                subtitle: 'Draft',
                accentColor: const Color(0xFF9CA3AF),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 230,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '最新のコミット',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {},
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'a35b230',
                                      style: TextStyle(
                                        color: Color(0xFF8B98A5),
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF8B98A5),
                                      size: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'test: add unit test coverage',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {},
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'a35b230',
                                      style: TextStyle(
                                        color: Color(0xFF8B98A5),
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF8B98A5),
                                      size: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'test: add unit test coverage',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {},
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'a35b230',
                                      style: TextStyle(
                                        color: Color(0xFF8B98A5),
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF8B98A5),
                                      size: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'test: add unit test coverage',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 230,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'アクティビティ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.alt_route, color: Colors.blue, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('やまだ が', style: TextStyle(color: Colors.white, fontSize: 14)),
                                Text('4 commits をプッシュ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ),
                          const Text('2分前', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.adjust, color: Colors.green, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ゆいな が', style: TextStyle(color: Colors.white, fontSize: 14)),
                                Text('Issue #126 を作成', style: TextStyle(color: Colors.blue, fontSize: 13)),
                              ],
                            ),
                          ),
                          const Text('15分前', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_merge, color: Colors.amber, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('りょうた が', style: TextStyle(color: Colors.white, fontSize: 14)),
                                Text('PR #152 をマージ', style: TextStyle(color: Colors.blue, fontSize: 13)),
                              ],
                            ),
                          ),
                          const Text('1時間前', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildLanguageBar(),
        ],
      ),
    );
  }

  // ── 言語構成バー（割合バー＋凡例） ──
  // ※ 元コードでは Column の children リストの中に変数宣言(final totalBytes = ...)と
  //   return 文を直接書いていたためコンパイルエラーになっていた。
  //   ロジックをこのメソッドに切り出すことで、totalBytes の計算とreturnを
  //   正しく「メソッド本体」の中で行えるように修正。
  Widget _buildLanguageBar() {
    final langs = languages ?? {};//安全装置
    final totalBytes = langs.values.fold<int>(
      0,
      (sum, bytes) => sum + (bytes as int),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // --- 1. 左側：割合バー ---
          SizedBox(
            width: 120, // Expanded(flex: 2) をやめて固定幅にする
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (totalBytes > 0)
                      for (final entry in langs.entries) ...[
                        Expanded(
  flex: (((entry.value as int) / totalBytes) * 1000).round().clamp(1, 1000),
  child: Container(
    height: 8, // ★ ここで高さを明示！
    color: _getLanguageColor(entry.key),
  ),
),
                        const SizedBox(width: 1),
                      ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // --- 2. 右側：スクロール可能な凡例 ---
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (totalBytes > 0)
                    for (final language in langs.keys) ...[
                      Text(
                        // Textの文字列の中で直接パーセント計算を行う
                        '● $language ${((langs[language]! / totalBytes) * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getLanguageColor(language),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(String label, List<_StatusStat> items) {
    return Container(
      width: double.infinity,
      height: 109,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF141A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.cardBorderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              //...とはfor内で作った複数のuiパーツを広げて外側のリストの中に展開するという物
              for (var i = 0; i < items.length; i++) ...[
                Expanded(
                  child: _buildStatusCard(items[i]),
                ),
                if (i != items.length - 1)
                  const SizedBox(
                    height: 60,
                    child: VerticalDivider(
                      color: Color(0x33FFFFFF),
                      thickness: 1,
                      width: 12,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(_StatusStat item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Text(
            item.count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            item.title,
            style: TextStyle(
              color: item.accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.subtitle.isNotEmpty)
            Text(
              item.subtitle,
              style: TextStyle(
                color: item.accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // 複数のカードを表示する親
  Widget buildStatusBar(List<_StatusStat> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 0,
        children: items.map((item) => _buildStatusCard(item)).toList(),
      ),
    );
  }

  // ============================================================
  // 中央カラム：チャットメッセージ一覧（Firestoreをリアルタイム購読）
  // ※ カード状の背景は持たせず、テキストのみを縦に並べる
  // ============================================================
  Widget _buildChatMessageList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: ServiceLocator.chatService.watchMessages(widget.projectId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(21),
              child: Text(
                'メッセージの読み込みに失敗しました\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _AppColors.accentPurple),
          );
        }

        final messages = snapshot.data;
        if (messages == null || messages.isEmpty) {
          return const Center(
            child: Text(
              'まだメッセージがありません',
              style: TextStyle(color: _AppColors.textSecondary, fontSize: 13),
            ),
          );
        }

        // 新着メッセージが来たら自動で最下部へスクロール
        _scrollToBottom();

        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          itemCount: messages.length,
          separatorBuilder: (context, index) =>
              Container(height: 1, color: _AppColors.divider),
          itemBuilder: (context, index) =>
              _buildChatMessageItem(messages[index]),
        );
      },
    );
  }

  // ── チャットメッセージ1件分の表示 ──
  // ※ 吹き出し（カード）は使わず文字だけを表示する。
  // アイコン＋名前は固定幅の左カラムに置き、本文だけが Expanded で伸びる構成にすることで、
  // 本文がどれだけ長くなってもアイコン・名前の位置は左にぴったり固定されたままになる。
  Widget _buildChatMessageItem(ChatMessage message) {
    final bool isMe = message.senderId == _currentUserId;
    final Color nameColor = isMe
        ? _AppColors.accentPurple
        : _AppColors.textPrimary;
    final Color avatarColor = isMe
        ? _AppColors.accentPurple
        : const Color(0xFF3B4152);

    return Container(
      padding: const EdgeInsets.only(top: 13, bottom: 13, left: 13, right: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isMe
                ? _AppColors.accentPurple.withOpacity(0.5)
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── アバター（固定サイズ・左固定） ──
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarColor,
            child: Text(
              message.senderName.isNotEmpty
                  ? message.senderName.substring(0, 1)
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // ── 名前・時刻・本文（本文だけが可変幅で伸びる） ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.senderName,
                      style: TextStyle(
                        color: nameColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 時刻を HH:mm 形式に整形 ──
  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ============================================================
  // メッセージ入力欄（ピル型の入力バー）
  // ── テキスト入力 → 絵文字アイコン → 送信ボタン ──
  // ============================================================
  Widget _buildMessageInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _messageFocusNode,
          builder: (context, child) {
            final bool isFocused = _messageFocusNode.hasFocus;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isFocused
                      ? _AppColors.accentTeal.withOpacity(0.5)
                      : _AppColors.cardBorder,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: _AppColors.accentTeal.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: Row(
            children: [
              Expanded(
                child: Focus(
                  focusNode: _messageFocusNode,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        (HardwareKeyboard.instance.isControlPressed ||
                            HardwareKeyboard.instance.isMetaPressed)) {
                      _handleSendMessage();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isSending,
                    minLines: 1,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    onSubmitted: (_) => _handleSendMessage(),
                    decoration: InputDecoration(
                      hintText: 'メッセージを入力...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildInputIconButton(
                icon: Icons.emoji_emotions_outlined,
                onTap: _showEmojiPicker,
              ),
              const SizedBox(width: 8),
              _buildSendButton(),
            ],
          ),
        ),
      ],
    );
  }

  // ── 入力バー内の丸型アイコンボタン（クリップ・絵文字で共通利用） ──
  Widget _buildInputIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      ),
    );
  }

  // ── 送信ボタン（グラデーションの角丸スクエア） ──
  Widget _buildSendButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _isSending ? null : _handleSendMessage,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: _isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}