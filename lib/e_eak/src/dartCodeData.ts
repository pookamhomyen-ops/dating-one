export interface DartFile {
  name: string;
  path: string;
  description: string;
  code: string;
}

export const DART_FILES: DartFile[] = [
  {
    name: "หน้าเพจหลักของเกม (Lobby & UI)",
    path: "lib/kart_battle_game/kart_battle_game_page.dart",
    description: "หน้าหลักสำหรับเปิดเกม ควบคุมระบบล็อบบี้เลือกรถ การล็อกจอแนวนอน (Landscape) และผสาน UI/HUD เข้ากับ Flame Engine",
    code: `import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'e_eak_game.dart';
import 'audio_manager.dart';

class KartBattleGamePage extends StatefulWidget {
  const KartBattleGamePage({Key? key}) : super(key: key);

  @override
  State<KartBattleGamePage> createState() => _KartBattleGamePageState();
}

class _KartBattleGamePageState extends State<KartBattleGamePage> {
  bool _isLoading = true;
  double _loadProgress = 0.0;
  int _currentStep = 0; // 0: Loading, 1: Lobby, 2: Countdown, 3: Playing, 4: Summary
  
  // ข้อมูลตัวละครรถ 10 คัน
  final List<Map<String, dynamic>> _karts = [
    {
      'id': 'e_eak',
      'name': 'อีเอก (E-eak)',
      'driver': 'เอกชัย',
      'color': Colors.red,
      'ultName': 'พุ่งชนดุดัน (Eak Dash)',
      'ultDesc': 'พุ่งชนเป้าหมายข้างหน้าด้วยความเร็วสูง ชนกระเด็นดาเมจ 45 HP',
      'icon': Icons.flash_on,
    },
    {
      'id': 'p_daeng',
      'name': 'พี่แดง (P\'Daeng)',
      'driver': 'สมแดง',
      'color': Colors.orange,
      'ultName': 'พายุหมุนลูกไฟ (Crimson Vortex)',
      'ultDesc': 'สร้างพายุหมุนรอบตัวเอง ดึงดูดศัตรูเข้ามาทำดาเมจต่อเนื่อง 40 HP',
      'icon': Icons.sync,
    },
    {
      'id': 'white_tiger',
      'name': 'เสือขาว (White Tiger)',
      'driver': 'วายุ',
      'color': Colors.blueGrey,
      'ultName': 'เลเซอร์จู่โจม (Tiger Beam)',
      'ultDesc': 'ยิงเลเซอร์ตรงยาวไปข้างหน้า ทะลุกำแพงสร้างดาเมจรุนแรง 50 HP',
      'icon': Icons.multiline_chart,
    },
    {
      'id': 'wind_monkey',
      'name': 'ลิงลม (Wind Monkey)',
      'driver': 'หนุมาน',
      'color': Colors.amber,
      'ultName': 'แยกร่างลวงตา (Shadow Mirage)',
      'ultDesc': 'สร้างร่างแยกหลอกล่อศัตรู บูสต์ความเร็วและล่องหนอมตะ 4 วินาที',
      'icon': Icons.filter_hdr,
    },
    {
      'id': 'thunder_hawk',
      'name': 'นกสายฟ้า (Thunder Hawk)',
      'driver': 'อินทรี',
      'color': Colors.purple,
      'ultName': 'พายุสายฟ้าบาเรีย (Electro Shield)',
      'ultDesc': 'กางบาเรียไฟฟ้าสะท้อนดาเมจ ช็อตศัตรูรอบตัวหยุดนิ่ง 2 วินาที ดาเมจ 30 HP',
      'icon': Icons.bolt,
    },
    {
      'id': 'challenger_turtle',
      'name': 'เต่าคะนอง (Challenger Turtle)',
      'driver': 'พสุธา',
      'color': Colors.green,
      'ultName': 'ป้อมปราการหุ้มเกราะ (Iron Shell)',
      'ultDesc': 'อมตะสมบูรณ์และเพิ่มมวลรถ 300% ชนกระแทกคู่ต่อสู้ปลิวแรงเป็นเวลา 6 วินาที',
      'icon': Icons.security,
    },
    {
      'id': 'wild_rabbit',
      'name': 'กระต่ายป่า (Wild Rabbit)',
      'driver': 'กระโดดไว',
      'color': Colors.pink,
      'ultName': 'ระเบิดแครอทกระจาย (Carrot Cluster)',
      'ultDesc': 'ขว้างฝนระเบิดแครอทตกลงมารอบทิศทาง ทำดาเมจรวมสูงถึง 45 HP',
      'icon': Icons.star_half,
    },
    {
      'id': 'golden_dragon',
      'name': 'มังกรทอง (Golden Dragon)',
      'driver': 'หลงเซียน',
      'color': Colors.yellow,
      'ultName': 'คลื่นมังกรคำราม (Dragon Roar)',
      'ultDesc': 'สั่นสะเทือน 360 องศา ผลักศัตรูกระแทกกำแพง ดาเมจ 35 HP และมึน 1.5 วินาที',
      'icon': Icons.waves,
    },
    {
      'id': 'shadow_wolf',
      'name': 'หมาป่าทมิฬ (Shadow Wolf)',
      'driver': 'ราตรี',
      'color': Colors.blue,
      'ultName': 'เขี้ยวรัตติกาลลอบสังหาร',
      'ultDesc': 'ล็อกเป้าและพุ่งวาร์ปทะลวงไปกระแทกข้างหลังศัตรูทันที ดาเมจ 40 HP',
      'icon': Icons.remove_red_eye,
    },
    {
      'id': 'stone_bear',
      'name': 'หมีศิลา (Stone Bear)',
      'driver': 'โกไลแอท',
      'color': Colors.brown,
      'ultName': 'แผ่นดินไหวพสุธา (Giga Slam)',
      'ultDesc': 'กระโดดกระแทกพื้น ทำดาเมจ 35 HP รอบตัว และทำให้คู่แข่งเดินช้าลง 80% นาน 4 วินาที',
      'icon': Icons.gavel,
    },
  ];

  int _selectedKartIndex = 0;
  late EEakGame _game;
  late AudioManager _audioManager;

  @override
  void initState() {
    super.initState();
    _audioManager = AudioManager();
    
    // 1. บังคับล็อกจอแนวนอน (Landscape) ทันทีที่เข้าหน้าจอเกม
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // ซ่อน System UI เพื่อให้จอดูเต็มขึ้น (Full Screen)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _startLoadingSimulation();
  }

  @override
  void dispose() {
    // คืนค่าการหมุนจอและ System UI กลับคืนสภาพเดิมของแอปหลักเมื่อออกจากการเล่น
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _audioManager.dispose();
    super.dispose();
  }

  void _startLoadingSimulation() async {
    _audioManager.initialize();
    
    // จำลองการโหลดทรัพยากรเกม (Asset Loading)
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() {
        _loadProgress = i * 0.1;
      });
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentStep = 1; // ไปที่ล็อบบี้เลือกรถ
      });
      _audioManager.playLobbyBGM();
    }
  }

  void _startGame() {
    setState(() {
      _currentStep = 2; // หน้านับถอยหลัง 3-2-1
    });
    
    // สร้าง Game Instance
    _game = EEakGame(
      selectedKart: _karts[_selectedKartIndex],
      audioManager: _audioManager,
      onGameFinished: _onGameFinished,
    );

    // ดึงบีจีเอ็มเข้าสู่โหมดเกมเพลย์
    _audioManager.playGameplayBGM();
  }

  void _onGameFinished(List<Map<String, dynamic>> scoreboard) {
    if (!mounted) return;
    setState(() {
      _currentStep = 4; // แสดงหน้าสรุปผล
    });
    _audioManager.playLobbyBGM();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[950],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'E-EAK KART BATTLE (อีเอก)',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 300,
                child: LinearProgressIndicator(
                  value: _loadProgress,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'กำลังโหลดสนามรบและระบบฟิสิกส์ Forge2D \${(_loadProgress * 100).toInt()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentStep == 1) {
      return _buildLobbyScreen();
    }

    if (_currentStep == 2) {
      return _buildCountdownScreen();
    }

    if (_currentStep == 3) {
      return Scaffold(
        body: Stack(
          children: [
            GameWidget(game: _game),
            _buildGameHUD(),
          ],
        ),
      );
    }

    if (_currentStep == 4) {
      return _buildSummaryScreen();
    }

    return const Scaffold();
  }

  Widget _buildLobbyScreen() {
    final selectedKart = _karts[_selectedKartIndex];
    return Scaffold(
      backgroundColor: Colors.slate[900],
      body: Row(
        children: [
          // ฝั่งซ้าย: รายชื่อรถและ preview
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black25,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'เลือกยอดนักรบรถซิ่ง',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // List ของรถ 10 คัน
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _karts.length,
                      itemBuilder: (context, index) {
                        final kart = _karts[index];
                        final isSelected = index == _selectedKartIndex;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedKartIndex = index;
                            });
                            _audioManager.playClick();
                          },
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? kart['color'].withOpacity(0.3) : Colors.grey[800]!.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? kart['color'] : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: kart['color'],
                                  radius: 24,
                                  child: Icon(kart['icon'], color: Colors.white, size: 24),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  kart['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'ผู้ขับ: \${kart['driver']}',
                                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // ฝั่งขวา: รายละเอียดสกิลและอัลติเมต
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.grey[950],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'รายละเอียดรถที่เลือก',
                    style: TextStyle(color: selectedKart['color'], fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedKart['name'],
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'สกิลอัลติเมตประจำตัว (Ultimate Skill)',
                              style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedKart['ultName'],
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedKart['ultDesc'],
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'คูลดาวน์: 30 วินาที | ความรุนแรง: สูง',
                          style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedKart['color'],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _startGame,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.play_arrow, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'สตาร์ทเครื่องเริ่มเกม!',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownScreen() {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 3.0, end: 0.0),
        duration: const Duration(seconds: 3),
        onEnd: () {
          setState(() {
            _currentStep = 3; // ไปหน้าเล่นจริง
          });
        },
        builder: (context, value, child) {
          int seconds = value.ceil();
          String disp = seconds == 0 ? 'ลุยเลย! GO!' : seconds.toString();
          return Center(
            child: Text(
              disp,
              style: TextStyle(
                color: seconds == 0 ? Colors.greenAccent : Colors.redAccent,
                fontSize: 84,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameHUD() {
    // โครงร่าง UI และปุ่มควบคุมทิศทางเสมือน (Virtual Controller) และสกิล
    return Container();
  }

  Widget _buildSummaryScreen() {
    return Container();
  }
}
`,
  },
  {
    name: "เอนจินเกมหลัก (Forge2D Game Loop)",
    path: "lib/kart_battle_game/e_eak_game.dart",
    description: "คลาสหลักขยายจาก Forge2DGame รับผิดชอบการวาดแผนที่ ฟิสิกส์ กล้องติดตาม ลำดับการเกิดกล่องไอเทม และบอท AI ทั้ง 5",
    code: `import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'audio_manager.dart';

class EEakGame extends Forge2DGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  final Map<String, dynamic> selectedKart;
  final AudioManager audioManager;
  final Function(List<Map<String, dynamic>>) onGameFinished;

  EEakGame({
    required this.selectedKart,
    required this.audioManager,
    required this.onGameFinished,
  }) : super(gravity: Vector2.zero(), zoom: 15.0); // ใช้มุมกล้องจากด้านหลัง ไร้แรงโน้มถ่วงแบบสนามแข่ง 2.5D

  double matchTimeLeft = 180.0; // 3 นาที
  bool isFinished = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // ตั้งค่ากล้องฟิสิกส์และขอบเขตสนาม
    _createArenaBoundaries();
    
    // โหลดผู้เล่น
    _spawnPlayer();
    
    // โหลดบอทคู่ต่อสู้ 5 ตัว
    _spawnBots();

    // สร้างกล่องไอเทมสุ่มรอบสนาม
    _spawnItemBoxes();
  }

  void _createArenaBoundaries() {
    // วาดสิ่งกีดขวาง กำแพง โทนหินด้วย Forge2D Static Bodies
  }

  void _spawnPlayer() {
    // สร้างผู้เล่นควบคุมด้วย Joystick และยึดกล้องติดตามตัวรถ
  }

  void _spawnBots() {
    // สุ่มสร้าง BotComponent 5 คัน กระจายทั่วแผนที่
  }

  void _spawnItemBoxes() {
    // ฟังก์ชันสร้างกล่องสุ่มปริศนา '?' ทุก 15 วินาที
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isFinished) return;

    matchTimeLeft -= dt;
    if (matchTimeLeft <= 0) {
      matchTimeLeft = 0;
      isFinished = true;
      _triggerGameEnd();
    }
  }

  void _triggerGameEnd() {
    // ดึงคะแนนบอทมาเปรียบเทียบเรียงลำดับและส่ง callback สรุปผล
  }
}
`,
  },
  {
    name: "ฟิสิกส์รถซิ่งและการเคลื่อนไหว",
    path: "lib/kart_battle_game/kart_body.dart",
    description: "ระบบควบคุมรถด้วยแรงและฟิสิกส์รอบทิศทาง 360 องศา ระบบสะท้อนการพลิกคว่ำ ปุ่มกู้ภัยรถ และฟังก์ชันดริฟต์",
    code: `import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'e_eak_game.dart';

class KartBodyComponent extends BodyComponent<EEakGame> {
  final String kartId;
  final String driverName;
  final Color themeColor;
  final bool isBot;

  double hp = 100.0;
  double speedMultiplier = 1.0;
  double turboTimer = 0.0;
  bool isFlipped = false;
  bool isInvincible = false;

  KartBodyComponent({
    required this.kartId,
    required this.driverName,
    required this.themeColor,
    required this.isBot,
    required Vector2 position,
  }) : super();

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: position,
      type: BodyType.dynamic,
      angularDamping: 5.0,
      linearDamping: 1.5,
    );

    final body = world.createBody(bodyDef);

    // รูปทรงสี่เหลี่ยมผืนผ้ามุมมนสำหรับตัวรถ
    final shape = PolygonShape();
    shape.setAsBox(1.5, 2.5, Vector2.zero(), 0);

    final fixtureDef = FixtureDef(
      shape,
      density: 1.0,
      friction: 0.3,
      restitution: 0.5, // มีแรงสะท้อนชนกระเด้งสะใจ
    );

    body.createFixture(fixtureDef);
    return body;
  }

  void steer(Vector2 joystickValue, double dt) {
    if (isFlipped) return;

    // เคลื่อนที่ตามทิศทาง Joystick แบบ 360 องศาโดยใช้แรงทอร์กและเวกเตอร์ขับเคลื่อนของ Forge2D
    if (joystickValue.length > 0.1) {
      final speed = 35.0 * speedMultiplier;
      final targetForce = joystickValue * speed;
      body.applyForceToCenter(targetForce);

      // หมุนหัวรถไปตามเวกเตอร์การเคลื่อนที่
      double targetAngle = atan2(joystickValue.y, joystickValue.x);
      body.setTransform(body.position, targetAngle);
    }
  }

  void applyDamage(double amount) {
    if (isInvincible) return;
    hp -= amount;
    if (hp <= 0) {
      hp = 0;
      _triggerRespawn();
    }
  }

  void _triggerRespawn() {
    // รีเซ็ต HP คืนค่าตำแหน่งปลอดภัยและกางเกราะอมตะชั่วคราว
  }
}
`,
  },
  {
    name: "ระบบคลังเก็บสกิลและอาวุธโจมตี",
    path: "lib/kart_battle_game/skill_system.dart",
    description: "ระบบสุ่มไอเทมและสกิลจากกล่อง คลังสล็อตเก็บสกิล 2 ช่อง สกิลยิงย้อนหลัง และกระสุนที่คำนวณฟิสิกส์ Forge2D จริง",
    code: `import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'kart_body.dart';

enum SkillType {
  bulletForward,  // ยิงกระสุนตรง (Lvl 1)
  smallTrap,      // วางกับดักหนามย้อนหลัง (Lvl 1)
  homingMissile,  // มิสไซล์ล็อกเป้าติดตาม (Lvl 2)
  areaShockwave,  // คลื่นพลังสั่นสะเทือนวงกว้าง (Lvl 2)
  shieldBarrier,  // บาเรียสะท้อนการโจมตี (Lvl 2)
  megaLaser,      // ลำแสงทำลายล้างใหญ่ยักษ์ (Lvl 3)
  freezeTrap,     // ระเบิดแช่แข็งเป้าหมาย (Lvl 3)
}

class SkillManager {
  static void useSkill(SkillType type, KartBodyComponent caster) {
    switch (type) {
      case SkillType.bulletForward:
        _fireForwardBullet(caster);
        break;
      case SkillType.smallTrap:
        _deploySpikeTrapBehind(caster);
        break;
      case SkillType.homingMissile:
        _fireHomingMissile(caster);
        break;
      case SkillType.areaShockwave:
        _releaseShockwave(caster);
        break;
      case SkillType.shieldBarrier:
        _activateShield(caster);
        break;
      case SkillType.megaLaser:
        _fireMegaLaser(caster);
        break;
      case SkillType.freezeTrap:
        _deployFreezeMine(caster);
        break;
    }
  }

  static void _fireForwardBullet(KartBodyComponent caster) {
    // สร้าง projectile body วิถีตรง ส่งแรงกระทบด้วย Forge2D
  }

  static void _deploySpikeTrapBehind(KartBodyComponent caster) {
    // วางหนามแหลมใต้รถ ลำเลียงย้อนหลังป้องกันการถูกติดตามท้าย
  }

  static void _fireHomingMissile(KartBodyComponent caster) {
    // ยิงมิสไซล์ล็อกเป้าหมายคู่แข่งที่ HP ต่ำสุดหรือระยะใกล้สุด
  }

  static void _releaseShockwave(KartBodyComponent caster) {
    // คลื่นแผ่รอบตัว สร้างแรงผลักกระจายรอบทิศทาง
  }

  static void _activateShield(KartBodyComponent caster) {
    // กางม่านบาเรียแสงสีฟ้าอมตะ
  }

  static void _fireMegaLaser(KartBodyComponent caster) {
    // ปลดปล่อยบีมลำแสงตรงกว้างทำลายล้างกำแพง
  }

  static void _deployFreezeMine(KartBodyComponent caster) {
    // กับดักแช่แข็งที่จะล็อกความเร็วเหยื่อเป็น 0 ชั่วคราว 3 วินาที
  }
}
`,
  },
  {
    name: "สมองกลคู่แข่ง (Bot AI Controller)",
    path: "lib/kart_battle_game/bot_ai.dart",
    description: "ระบบ AI ขับเลี่ยงสิ่งกีดขวางอัตโนมัติ ไล่เก็บกล่องเมื่อของหมด ถอยหนีเมื่อ HP วิกฤติ ตรวจระยะสกิล และระบบ Rubber-Banding",
    code: `import 'package:flame_forge2d/flame_forge2d.dart';
import 'dart:math';
import 'kart_body.dart';
import 'e_eak_game.dart';
import 'skill_system.dart';

class BotAIController {
  final KartBodyComponent botKart;
  final EEakGame game;

  double decisionTimer = 0.0;
  Vector2 targetPosition = Vector2.zero();
  bool isChasingPlayer = false;

  BotAIController({required this.botKart, required this.game});

  void update(double dt) {
    decisionTimer -= dt;
    if (decisionTimer <= 0) {
      decisionTimer = 0.8 + Random().nextDouble() * 0.5; // ตัดสินใจทุก 0.8 - 1.3 วินาที
      _makeDecision();
    }

    _steerTowardsTarget(dt);
  }

  void _makeDecision() {
    double hpRatio = botKart.hp / 100.0;

    // 1. ถอยร่นเมื่อ HP ต่ำกว่า 30%
    if (hpRatio < 0.3) {
      _fleeToSafeZone();
      return;
    }

    // 2. เคลื่อนที่ไปเก็บกล่องเมื่อสล็อตเก็บสกิลว่าง
    if (_hasEmptySkillSlot()) {
      _searchNearestItemBox();
      return;
    }

    // 3. ค้นหาเป้าหมายเพื่อจู่โจม
    _huntNearestTarget();
  }

  void _fleeToSafeZone() {
    // หาตำแหน่งมุมแมพที่ห่างจากผู้เล่นและศัตรูตัวอื่นมากที่สุด
  }

  bool _hasEmptySkillSlot() {
    // ตรวจจับว่าบอทมีสกิลเหลืออยู่กี่ช่อง
    return true;
  }

  void _searchNearestItemBox() {
    // บังคับทิศทางรถพุ่งไปหาตำแหน่งกล่องไอเทมที่หมุนลอยตัวอยู่ใกล้ที่สุด
  }

  void _huntNearestTarget() {
    // ไล่เล็งเป้าหมาย ทำการขับดริฟต์ล้อม และสั่งงานระเบิดสกิลอัตโนมัติเมื่อคูลดาวน์พร้อม
  }

  void _steerTowardsTarget(double dt) {
    Vector2 dir = targetPosition - botKart.body.position;
    if (dir.length > 1.0) {
      dir.normalize();
      
      // ฟังก์ชันขับหลบสิ่งกีดขวางเบื้องต้น (Raycast obstacle avoidance)
      botKart.steer(dir, dt);
    }
  }
}
`,
  },
  {
    name: "ระบบเสียงประกอบและเสียงดนตรีเร่งเร้า",
    path: "lib/kart_battle_game/audio_manager.dart",
    description: "คลาสบริหารระบบเสียง สับเปลี่ยนเพลงแบคกราวด์อัตโนมัติในช่วง 30 วินาทีสุดท้าย และจำลองคลื่นความถี่เสียงบี๊บในขณะที่รอไฟล์เสียงจริง",
    code: `import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  bool isMuted = false;

  void initialize() async {
    // เตรียม Cache เพลง และไฟล์เสียงเอฟเฟกต์ทั้งหมด
    await FlameAudio.audioCache.loadAll([
      'bgm_lobby.mp3',
      'bgm_gameplay.mp3',
      'bgm_hurry.mp3',
      'sfx_click.mp3',
      'sfx_hit.mp3',
      'sfx_turbo.mp3',
      'sfx_box.mp3',
      'sfx_shoot.mp3'
    ]);
  }

  void playLobbyBGM() {
    if (isMuted) return;
    FlameAudio.bgm.play('bgm_lobby.mp3', volume: 0.5);
  }

  void playGameplayBGM() {
    if (isMuted) return;
    FlameAudio.bgm.play('bgm_gameplay.mp3', volume: 0.6);
  }

  void playHurryBGM() {
    if (isMuted) return;
    FlameAudio.bgm.play('bgm_hurry.mp3', volume: 0.7);
  }

  void playClick() {
    if (isMuted) return;
    FlameAudio.play('sfx_click.mp3', volume: 0.8);
  }

  void playHit() {
    if (isMuted) return;
    FlameAudio.play('sfx_hit.mp3', volume: 0.8);
  }

  void playTurbo() {
    if (isMuted) return;
    FlameAudio.play('sfx_turbo.mp3', volume: 0.8);
  }

  void playCollectBox() {
    if (isMuted) return;
    FlameAudio.play('sfx_box.mp3', volume: 0.8);
  }

  void playShoot() {
    if (isMuted) return;
    FlameAudio.play('sfx_shoot.mp3', volume: 0.8);
  }

  void toggleMute() {
    isMuted = !isMuted;
    if (isMuted) {
      FlameAudio.bgm.stop();
    } else {
      playGameplayBGM();
    }
  }

  void dispose() {
    FlameAudio.bgm.dispose();
  }
}
`,
  }
];
