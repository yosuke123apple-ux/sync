import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // ← 追加
import 'firebase_options.dart'; // ←

// ==================== カラー定義 ====================
class AppColors {
  static const Color backgroundBase = Color(0xFF060A18);
  static const Color bgGradientTop = Color(0xFF0F142D);
  static const Color bgGradientMiddle = Color(0xFF090D22);
  static const Color bgGradientBottom = Color(0xFF040611);
  static const Color cardGradientStart = Color(0xFF322990);
  static const Color cardGradientEnd = Color(0xFF151A5B);
}

// ==================== 統計アイテム ====================
class StatItem extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const StatItem({
    super.key,
    required this.title,
    required this.value,
    this.valueColor,
  });

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

// ==================== メニュー情報クラス ====================
class MenuItemInfo {
  final String label;
  final String description;
  final IconData icon;
  final Color iconColor;
  final int index;

  MenuItemInfo({
    required this.label,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.index,
  });
}

class ProjectInfo {
  final String title;
  final String description;
  final String ownerInfo;
  final IconData icon;
  final Color color;
  final int currentMembers;
  final int maxMembers;
  final List<String> tags;

  const ProjectInfo({
    required this.title,
    required this.description,
    required this.ownerInfo,
    required this.icon,
    required this.color,
    required this.currentMembers,
    required this.maxMembers,
    required this.tags,
  });
}

final projects = [
  ProjectInfo(
    title: 'Sync',
    description: 'プログラミング共同開発者募集アプリ',
    ownerInfo: '高校2年・Flutter歴2年',
    icon: Icons.auto_awesome,
    color: Colors.purple,
    currentMembers: 2,
    maxMembers: 3,
    tags: ['Flutter', 'Firebase', 'Riverpod'],
  ),
  ProjectInfo(
    title: 'Sync',
    description: 'プログラミング共同開発者募集アプリ',
    ownerInfo: '高校2年・Flutter歴2年',
    icon: Icons.auto_awesome,
    color: Colors.purple,
    currentMembers: 2,
    maxMembers: 3,
    tags: ['Flutter', 'Firebase', 'Riverpod'],
  ),
  ProjectInfo(
    title: 'Sync',
    description: 'プログラミング共同開発者募集アプリ',
    ownerInfo: '高校2年・Flutter歴2年',
    icon: Icons.auto_awesome,
    color: Colors.purple,
    currentMembers: 2,
    maxMembers: 3,
    tags: ['Flutter', 'Firebase', 'Riverpod'],
  ),
  ProjectInfo(
    title: 'Sync',
    description: 'プログラミング共同開発者募集アプリ',
    ownerInfo: '高校2年・Flutter歴2年',
    icon: Icons.auto_awesome,
    color: Colors.purple,
    currentMembers: 2,
    maxMembers: 3,
    tags: ['Flutter', 'Firebase', 'Riverpod'],
  ),
  ProjectInfo(
    title: 'Sync',
    description: 'プログラミング共同開発者募集アプリ',
    ownerInfo: '高校2年・Flutter歴2年',
    icon: Icons.auto_awesome,
    color: Colors.purple,
    currentMembers: 2,
    maxMembers: 3,
    tags: ['Flutter', 'Firebase', 'Riverpod'],
  ),
  ProjectInfo(
    title: 'Sync',
    description: 'プログラミング共同開発者募集アプリ',
    ownerInfo: '高校2年・Flutter歴2年',
    icon: Icons.auto_awesome,
    color: Colors.purple,
    currentMembers: 2,
    maxMembers: 3,
    tags: ['Flutter', 'Firebase', 'Riverpod'],
  ),
];

// ==================== メイン ====================
void main() async {
  // Flutterのバインディングを確実に初期化する
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebaseの初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SyncApp());
}

class SyncApp extends StatelessWidget {
  const SyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SyncCrew',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

// ==================== ホームページ ====================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedMenuIndex = 0;

  final List<MenuItemInfo> menuItems = [
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
      iconColor: const Color(0xffEF4444),
      index: 1,
    ),
    MenuItemInfo(
      label: '初心者モード',
      description: '簡単なことから始めよう',
      icon: Icons.rocket_launch_outlined,
      iconColor: const Color(0xffF59E0B),
      index: 2,
    ),
    MenuItemInfo(
      label: '学生組',
      description: 'みんなで協力',
      icon: Icons.people_outline,
      iconColor: const Color(0xff10B981),
      index: 3,
    ),
    MenuItemInfo(
      label: 'フレンド機能',
      description: 'つながりを作ろう',
      icon: Icons.person_add_outlined,
      iconColor: const Color(0xff3B82F6),
      index: 4,
    ),
    MenuItemInfo(
      label: '勉強モード',
      description: 'みんなと一緒にがんばろう',
      icon: Icons.music_note_outlined,
      iconColor: const Color(0xffEC4899),
      index: 5,
    ),
  ];

  // ==================== メニューカード ====================
  Widget menuCard(MenuItemInfo item) {
    final isSelected = selectedMenuIndex == item.index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMenuIndex = item.index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 220,
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    item.iconColor.withOpacity(0.25),
                    item.iconColor.withOpacity(0.1),
                  ],
                )
              : null,
          color: isSelected ? null : const Color(0xFF0A1020),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? item.iconColor.withOpacity(0.5)
                : const Color(0xFF1D2742),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: item.iconColor.withOpacity(0.2),
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
                color: item.iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: item.iconColor,
                size: 24,
              ),
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
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff020710),
      body: Row(
        children: [
          // ==================== 左側メニュー ====================
          Container(
            width: 260,
            color: AppColors.backgroundBase,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 16, bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xff7c4dff),
                                Color(0xff5c6bc0),
                              ],
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
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          ...menuItems.map((item) => menuCard(item)).toList(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    width: 220,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1020),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1D2742),
                        width: 1,
                      ),
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
                                    const Color(0xff7c4dff).withOpacity(0.25),
                                    const Color(0xff5c6bc0).withOpacity(0.15),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xff7c4dff).withOpacity(0.25),
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
                                children: const [
                                  Text(
                                    "やまた_Dev",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "@yama_dev",
                                    style: TextStyle(
                                      color: Color(0xff7B849D),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xff7c4dff),
                                Color(0xff5c6bc0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "はじめの一歩",
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

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            StatItem(
                              title: "連続記録",
                              value: "7日",
                              valueColor: Color.fromARGB(255, 255, 255, 255),
                            ),
                        
                          ],
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      print('設定をタップしました');
                    },
                    child: Container(
                      width: 220,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            color: Colors.white.withOpacity(0.4),
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '設定',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white.withOpacity(0.15),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==================== 右側メインコンテンツ ====================
          Expanded(
            child: Container(
              color: const Color(0xff050b14),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  SizedBox(
                    width: 1000,
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        color: const Color(0xff0a1220),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: TextField(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white54,
                            size: 20,
                          ),
                          hintText: 'プロジェクトを検索...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                      
                    ),
                    
                  ),
    Spacer(),
            IconButton(
    icon: const Icon(Icons.notifications),
      color: Colors.white,
      onPressed: () {
        // アイコンがタップされたときの処理
        print('アイコンが押されました');
      },
    ),
    SizedBox(width: 10),
    ElevatedButton(
  onPressed: () {
    // ボタンが押されたときの処理
    print('投稿ボタンが押されました');
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xff2f80ed), // ボタンの背景色（鮮やかな青）
    foregroundColor: Colors.white,            // 文字やアイコンの色
    elevation: 0,                             // 影を消してフラットにする
    padding: const EdgeInsets.symmetric(
      horizontal: 20, // 横の余白
      vertical: 12,   // 縦の余白
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10), // 角丸の具合（検索バーに合わせるなら14でもOK）
    ),
  ),
  child: const Row(
    mainAxisSize: MainAxisSize.min, // ボタンの横幅を中身に合わせる
    children: [
      Icon(Icons.send, size: 18), // 送信（投稿）アイコン
      SizedBox(width: 8),         // アイコンと文字の間の隙間
      Text(
        '投稿',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold, // 太字
        ),
      ),
    ],
  ),
)

                    ],
                  ),
                  const SizedBox(height: 24),
              Container(
  height: 229,
  width: 1250,
  padding: const EdgeInsets.all(28),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xff17103a),
        Color(0xff0d1028),
      ],
    ),
    border: Border.all(
      color: Colors.white10,
    ),
  ),
  child: Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '一緒に、',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'アイデアをカタチにしよう。',
                    style: TextStyle(
                      color: Color(0xff7c5cff),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '少人数で、本気で、最高のプロダクトを。',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 統計情報1: 100時間
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              color: const Color(0xFF7C5CFF),
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '100時間',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '今週の総作業時間',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9EA3B0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 統計情報2: 92%
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up_outlined,
                              color: const Color(0xFF3B82F6),
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '92%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'また組みたい率',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9EA3B0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 統計情報3: 3件
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              color: const Color(0xFFEC4899),
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '3件',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '応募中のプロジェクト',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9EA3B0),
                            fontWeight: FontWeight.w600,
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
      SizedBox(
        width: 320,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff7c5cff).withOpacity(0.08),
              ),
            ),
            const Icon(
              Icons.code_rounded,
              size: 90,
              color: Color(0xff7c5cff),
            ),
          ],
        ),
      ),
    ],
  ),
),
                  const SizedBox(height: 25),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1250,
                      ),
                      child: ListView.builder(
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];

                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xff0a1220),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: project.color.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: project.color.withOpacity(0.1),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            project.color.withOpacity(0.25),
                                            project.color.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: project.color.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: project.color.withOpacity(0.15),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        project.icon,
                                        color: project.color,
                                        size: 38,
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                              Row(
                                                children: [
                                                
                                                Transform.translate(
  offset: const Offset(-30.0, 0.0), // 元の位置から左に6ピクセルずらす
  child: Row(
    mainAxisSize: MainAxisSize.min, // 囲んでいるRowの幅を最小限にする
    children: [
      const Icon(
        Icons.person_outline,
        size: 14,
        color: Color(0xff9f7aea),
      ),
      const SizedBox(width: 4),
      Text(
        project.ownerInfo,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 12,
        ),
      ),
    ],
  ),
)
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            project.description,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Wrap(
                                                  spacing: 8,
                                                  children: project.tags
                                                      .map(
                                                        (tag) => Container(
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .black26,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        999),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .white10,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            tag,
                                                            style: const TextStyle(
                                                              color: Colors
                                                                  .white70,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: const Color(
                                                        0xff8b5cf6),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.group,
                                                      color: Color(
                                                          0xffa78bfa),
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '${project.currentMembers}/${project.maxMembers}人',
                                                      style: const TextStyle(
                                                        color: Color(
                                                            0xffa78bfa),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Container(
                                                height: 44,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                    colors: [
                                                      Color(0xff8b5cf6),
                                                      Color(0xff7c3aed),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                              0xff8b5cf6)
                                                          .withOpacity(0.5),
                                                      blurRadius: 16,
                                                    ),
                                                  ],
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.group_add,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      '参加する',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
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
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'share') {
                                      print('共有');
                                    } else if (value == 'save') {
                                      print('保存');
                                    } else if (value == 'report') {
                                      print('通報');
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'share',
                                      child: Text('共有'),
                                    ),
                                    PopupMenuItem(
                                      value: 'save',
                                      child: Text('保存'),
                                    ),
                                    PopupMenuItem(
                                      value: 'report',
                                      child: Text('通報'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  )
                  
                ],
                
              ),
              
            ),
          ),
          
Container(
  
  width: MediaQuery.of(context).size.width * 0.2,
  // ❌ color: AppColors.backgroundBase はここに書くとエラーになるので消去！
  padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16), 
  
    color: AppColors.backgroundBase,
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    
    // ─── 1. おすすめカテゴリのカード ───
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.2), 
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "おすすめカテゴリ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              Chip(
                label: Text("Flutter"),
                backgroundColor: Colors.transparent,
                side: BorderSide(color: Colors.white24),
                labelStyle: TextStyle(color: Colors.white),
              ),
              Chip(
                label: Text("Web"),
                backgroundColor: Colors.transparent,
                side: BorderSide(color: Colors.white24),
                labelStyle: TextStyle(color: Colors.white),
              ),
              Chip(
                label: Text("AI"),
                backgroundColor: Colors.transparent,
                side: BorderSide(color: Colors.white24),
                labelStyle: TextStyle(color: Colors.white),
              ),
              Chip(
                label: Text("Unity"),
                backgroundColor: Colors.transparent,
                side: BorderSide(color: Colors.white24),
                labelStyle: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    ),

    const SizedBox(height: 16), // カード同士のすき間

    // ─── 2. トレンドタグのカード ───
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.2), 
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "トレンドタグ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16, // サイズを統一
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "#Flutter\n#個人開発\n#AI\n#Python",
            style: TextStyle(
              color: Colors.white70,
              height: 1.8,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),

    const SizedBox(height: 20), // カード同士のすき間

    // ─── 3. 最近の投稿のカード ───
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.2), 
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "最近の投稿",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16, // サイズを統一
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8), // ListTileの余白があるので少し狭めに
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "Flutter仲間募集",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Text(
              "3分前",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "AIアプリ開発中",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Text(
              "12分前",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
              const SizedBox(height: 25), // ListTileの余白があるので少し狭めに
    Container(
  width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.2), 
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "リアルタイムアクティビティ",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 12),

      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(
          Icons.flash_on,
          color: Color(0xFF6C5CE7),
        ),
        title: Text(
          "Flutter開発者が参加しました",
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          "2分前",
          style: TextStyle(color: Colors.white54),
        ),
        
      ),
      SizedBox(height: 6),
        ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(
          Icons.flash_on,
          color: Color(0xFF6C5CE7),
        ),
        title: Text(
          "Flutter開発者が参加しました",
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          "2分前",
          style: TextStyle(color: Colors.white54),
        ),
        
      ),
      SizedBox(height: 6),
        ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(
          Icons.flash_on,
          color: Color(0xFF6C5CE7),
        ),
        title: Text(
          "Flutter開発者が参加しました",
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          "2分前",
          style: TextStyle(color: Colors.white54),
        ),
        
      ),
        SizedBox(height: 6),
        ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(
          Icons.flash_on,
          color: Color(0xFF6C5CE7),
        ),
        title: Text(
          "Flutter開発者が参加しました",
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          "2分前",
          style: TextStyle(color: Colors.white54),
        ),
        
      ),
  
    
    ],
  ),




    ),
  ],
)
  
)
        ],
      ),
    );
  }
}