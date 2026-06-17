import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const TheCarrierApp());
}

class TheCarrierApp extends StatelessWidget {
  const TheCarrierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GamePage(),
    );
  }
}

class Vehicle {
  final String name;
  final String icon;
  final int price;
  final int repairCost;
  final int reward;
  final int fuelMax;
  final int speedMs;
  final double size;

  const Vehicle(
    this.name,
    this.icon,
    this.price,
    this.repairCost,
    this.reward,
    this.fuelMax,
    this.speedMs,
    this.size,
  );
}

class Mission {
  final String title;
  final int target;
  final int reward;

  const Mission(this.title, this.target, this.reward);
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final vehicles = const [
    Vehicle('Bisiklet', '🚲', 0, 20, 25, 999, 380, 54),
    Vehicle('Scooter', '🛴', 500, 60, 45, 80, 340, 58),
    Vehicle('Motor', '🏍️', 2000, 150, 80, 100, 300, 62),
    Vehicle('Araba', '🚗', 7500, 400, 150, 120, 260, 66),
    Vehicle('Kamyonet', '🚚', 20000, 1000, 300, 150, 230, 72),
    Vehicle('Helikopter', '🚁', 75000, 3000, 700, 180, 210, 78),
    Vehicle('Kargo Uçağı', '✈️', 250000, 10000, 2000, 220, 190, 84),
  ];

  final missions = const [
    Mission('5 teslimat yap', 5, 300),
    Mission('15 teslimat yap', 15, 1000),
    Mission('30 teslimat yap', 30, 3000),
    Mission('60 teslimat yap', 60, 8000),
    Mission('100 teslimat yap', 100, 20000),
  ];

  int money = 0;
  int deliveries = 0;
  int level = 1;
  int xp = 0;
  int currentVehicle = 0;
  int lane = 1;
  int packageLane = 1;
  int obstacleLane = 0;
  int fuel = 999;
  int roadOffset = 0;
  int bestDeliveries = 0;
  int sessionEarned = 0;
  bool playing = false;

  Timer? timer;
  final random = Random();

  BannerAd? bannerAd;
  bool bannerReady = false;

  RewardedAd? rewardedAd;
  bool rewardedReady = false;

  @override
  void initState() {
    super.initState();
    loadGame();
    newRound();
    loadBanner();
    loadRewarded();
  }

  Future<void> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      money = prefs.getInt('money') ?? 0;
      deliveries = prefs.getInt('deliveries') ?? 0;
      level = prefs.getInt('level') ?? 1;
      xp = prefs.getInt('xp') ?? 0;
      currentVehicle = prefs.getInt('currentVehicle') ?? 0;
      bestDeliveries = prefs.getInt('bestDeliveries') ?? 0;
      fuel = prefs.getInt('fuel') ?? vehicles[currentVehicle].fuelMax;
    });
  }

  Future<void> saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('money', money);
    await prefs.setInt('deliveries', deliveries);
    await prefs.setInt('level', level);
    await prefs.setInt('xp', xp);
    await prefs.setInt('currentVehicle', currentVehicle);
    await prefs.setInt('bestDeliveries', bestDeliveries);
    await prefs.setInt('fuel', fuel);
  }

  void loadBanner() {
    bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => bannerReady = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    bannerAd!.load();
  }

  void loadRewarded() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
          rewardedReady = true;
        },
        onAdFailedToLoad: (error) {
          rewardedReady = false;
        },
      ),
    );
  }

  void showRewardAd() {
    if (rewardedAd == null || !rewardedReady) {
      rewardBonus(false);
      return;
    }

    rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewardBonus(true);
      },
    );

    rewardedAd = null;
    rewardedReady = false;
    loadRewarded();
  }

  void startGame() {
    setState(() {
      playing = true;
      sessionEarned = 0;
    });

    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: vehicles[currentVehicle].speedMs), (_) {
      if (!playing) return;
      setState(() => roadOffset = (roadOffset + 1) % 8);
    });
  }

  void pauseGame() {
    setState(() => playing = false);
    timer?.cancel();
  }

  void newRound() {
    packageLane = random.nextInt(3);
    obstacleLane = random.nextInt(3);
    while (obstacleLane == packageLane) {
      obstacleLane = random.nextInt(3);
    }
  }

  void moveLeft() {
    if (!playing) return;
    setState(() {
      if (lane > 0) lane--;
    });
  }

  void moveRight() {
    if (!playing) return;
    setState(() {
      if (lane < 2) lane++;
    });
  }

  void drive() {
    if (!playing) return;

    final vehicle = vehicles[currentVehicle];

    setState(() {
      if (currentVehicle > 0) {
        fuel -= 5;
        if (fuel <= 0) {
          playing = false;
          timer?.cancel();
          saveGame();
          showMessage('Yakıt bitti!', 'Yakıt doldur ve devam et.');
          return;
        }
      }

      if (lane == obstacleLane) {
        money = max(0, money - vehicle.repairCost);

        if (currentVehicle > 0 && money < vehicle.repairCost) {
          currentVehicle--;
          fuel = vehicles[currentVehicle].fuelMax;
        }

        playing = false;
        timer?.cancel();

        if (deliveries > bestDeliveries) {
          bestDeliveries = deliveries;
        }

        saveGame();
        showGameOver();
      } else {
        if (lane == packageLane) {
          money += vehicle.reward;
          sessionEarned += vehicle.reward;
          deliveries++;
          xp += 20;
          checkLevel();
          checkMission();
        } else {
          money += 5;
          sessionEarned += 5;
          xp += 5;
        }

        saveGame();
        newRound();
      }
    });
  }

  void checkLevel() {
    final need = level * 100;
    if (xp >= need) {
      xp -= need;
      level++;
      money += level * 100;
      sessionEarned += level * 100;
    }
  }

  void checkMission() {
    for (final mission in missions) {
      if (deliveries == mission.target) {
        money += mission.reward;
        sessionEarned += mission.reward;
        Future.delayed(Duration.zero, () {
          showMessage('Görev tamamlandı!', '${mission.title}\nÖdül: ${mission.reward} TL');
        });
        break;
      }
    }
  }

  void buyNextVehicle() {
    if (currentVehicle >= vehicles.length - 1) return;
    final next = vehicles[currentVehicle + 1];

    if (money >= next.price) {
      setState(() {
        money -= next.price;
        currentVehicle++;
        fuel = next.fuelMax;
      });
      saveGame();
      showMessage('Yeni araç!', '${next.icon} ${next.name} garaja eklendi.');
    }
  }

  void refillFuel() {
    if (currentVehicle == 0) return;
    final cost = 100 + currentVehicle * 100;

    if (money >= cost) {
      setState(() {
        money -= cost;
        fuel = vehicles[currentVehicle].fuelMax;
      });
      saveGame();
    } else {
      showMessage('Para yetersiz', 'Yakıt için $cost TL gerekiyor.');
    }
  }

  void rewardBonus(bool fromAd) {
    setState(() {
      money += fromAd ? 500 : 250;
      if (currentVehicle > 0) fuel = vehicles[currentVehicle].fuelMax;
    });
    saveGame();
    showMessage('Ödül alındı!', fromAd ? 'Reklam ödülü: 500 TL kazandın.' : '250 TL bonus kazandın.');
  }

  void showGarage() {
    pauseGame();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Garaj'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final v = vehicles[index];
              final unlocked = index <= currentVehicle;
              return ListTile(
                leading: Text(v.icon, style: const TextStyle(fontSize: 30)),
                title: Text(v.name),
                subtitle: Text(unlocked ? 'Açık' : '${v.price} TL'),
                trailing: unlocked ? const Icon(Icons.check_circle) : const Icon(Icons.lock),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              startGame();
            },
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void showGameOver() {
    final vehicle = vehicles[currentVehicle];
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Kaza yaptın!'),
          content: Text(
            'Seans kazancı: $sessionEarned TL\n'
            'Toplam teslimat: $deliveries\n'
            'En iyi teslimat: $bestDeliveries\n'
            'Mevcut araç: ${vehicle.icon} ${vehicle.name}\n\n'
            'Tamir masrafı kesildi. Paran yetmezse bir alt araca düştün.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                startGame();
              },
              child: const Text('Devam Et'),
            ),
          ],
        ),
      );
    });
  }

  void showMessage(String title, String message) {
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                startGame();
              },
              child: const Text('Devam Et'),
            ),
          ],
        ),
      );
    });
  }

  double laneX(int index, double width) {
    if (index == 0) return width * 0.18;
    if (index == 1) return width * 0.50;
    return width * 0.82;
  }

  @override
  void dispose() {
    timer?.cancel();
    bannerAd?.dispose();
    rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = vehicles[currentVehicle];
    final nextVehicle = currentVehicle < vehicles.length - 1 ? vehicles[currentVehicle + 1] : null;
    final currentMission = missions.firstWhere(
      (m) => deliveries < m.target,
      orElse: () => const Mission('Tüm görevler tamam', 999999, 0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFF020617),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('💰 $money TL', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      Text('⭐ Lv $level', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      Text('${vehicle.icon} ${vehicle.name}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(value: xp / max(100, level * 100), minHeight: 7),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: vehicle.fuelMax == 999 ? 1 : max(0, fuel) / vehicle.fuelMax,
                          minHeight: 7,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(vehicle.fuelMax == 999 ? 'Yakıt: ∞' : 'Yakıt: $fuel', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Görev: ${currentMission.title} (${min(deliveries, currentMission.target)}/${currentMission.target})',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nextVehicle == null
                              ? 'Tüm araçlar açık 🔥'
                              : 'Sıradaki: ${nextVehicle.icon} ${nextVehicle.name} - ${nextVehicle.price} TL',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      ElevatedButton(onPressed: showGarage, child: const Text('Garaj')),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: nextVehicle != null && money >= nextVehicle.price ? buyNextVehicle : null,
                        child: const Text('AL'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: drive,
                onHorizontalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) < 0) {
                    moveLeft();
                  } else {
                    moveRight();
                  }
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    final obstacleIcon = obstacleLane == 0 ? '🚧' : obstacleLane == 1 ? '🚗' : '🕳️';

                    return Stack(
                      children: [
                        Positioned.fill(child: Container(color: const Color(0xFF374151))),
                        for (int i = 0; i < 8; i++)
                          Positioned(
                            left: width / 2 - 3,
                            top: i * 120.0 + roadOffset * 18 - 120,
                            child: Container(width: 6, height: 70, color: Colors.white54),
                          ),
                        Positioned(left: width / 3, top: 0, bottom: 0, child: Container(width: 2, color: Colors.white24)),
                        Positioned(left: width * 2 / 3, top: 0, bottom: 0, child: Container(width: 2, color: Colors.white24)),
                        Positioned(
                          left: laneX(packageLane, width) - 24,
                          top: height * 0.22,
                          child: const Text('📦', style: TextStyle(fontSize: 46)),
                        ),
                        Positioned(
                          left: laneX(obstacleLane, width) - 24,
                          top: height * 0.46,
                          child: Text(obstacleIcon, style: const TextStyle(fontSize: 46)),
                        ),
                        Positioned(
                          left: laneX(lane, width) - vehicle.size / 2,
                          bottom: 45,
                          child: Text(vehicle.icon, style: TextStyle(fontSize: vehicle.size)),
                        ),
                        if (!playing)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black54,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('THE CARRIER', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    const Text('Taşı, kazan, imparatorluğunu kur.', style: TextStyle(color: Colors.white70, fontSize: 17)),
                                    const SizedBox(height: 10),
                                    Text('En iyi: $bestDeliveries teslimat', style: const TextStyle(color: Colors.amber, fontSize: 15)),
                                    const SizedBox(height: 22),
                                    ElevatedButton(onPressed: startGame, child: const Text('BAŞLA', style: TextStyle(fontSize: 24))),
                                    const SizedBox(height: 10),
                                    ElevatedButton(onPressed: showRewardAd, child: const Text('REKLAM İZLE +500 TL')),
                                    const SizedBox(height: 10),
                                    ElevatedButton(onPressed: refillFuel, child: const Text('YAKIT DOLDUR')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              color: const Color(0xFF020617),
              child: Text(
                '📦 $deliveries teslimat | Kaydır: şerit değiştir | Dokun: ilerle',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            if (bannerReady && bannerAd != null)
              SizedBox(
                height: bannerAd!.size.height.toDouble(),
                width: bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: bannerAd!),
              ),
          ],
        ),
      ),
    );
  }
}
