import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const TheCarrierApp());

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

  const Vehicle(this.name, this.icon, this.price, this.repairCost, this.reward, this.fuelMax);
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final vehicles = const [
    Vehicle('Bisiklet', '🚲', 0, 20, 25, 999),
    Vehicle('Scooter', '🛴', 500, 60, 45, 80),
    Vehicle('Motor', '🏍️', 2000, 150, 80, 100),
    Vehicle('Araba', '🚗', 7500, 400, 150, 120),
    Vehicle('Kamyonet', '🚚', 20000, 1000, 300, 150),
    Vehicle('Helikopter', '🚁', 75000, 3000, 700, 180),
    Vehicle('Kargo Uçağı', '✈️', 250000, 10000, 2000, 220),
  ];

  int money = 0;
  int deliveries = 0;
  int currentVehicle = 0;
  int lane = 1;
  int packageLane = 1;
  int obstacleLane = 0;
  int fuel = 999;
  int roadOffset = 0;
  bool playing = false;

  Timer? timer;
  final random = Random();

  @override
  void initState() {
    super.initState();
    fuel = vehicles[currentVehicle].fuelMax;
    newRound();
  }

  void startGame() {
    setState(() => playing = true);

    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (!playing) return;
      setState(() => roadOffset = (roadOffset + 1) % 8);
    });
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
          showMessage('Yakıt bitti!', 'Yakıt almak için para harcamalısın.');
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

        showMessage(
          'Kaza yaptın!',
          'Tamir masrafı kesildi. Paran yetmezse bir alt araca düştün.\n\nMevcut araç: ${vehicles[currentVehicle].icon} ${vehicles[currentVehicle].name}',
        );
      } else {
        if (lane == packageLane) {
          money += vehicle.reward;
          deliveries++;
        } else {
          money += 5;
        }

        newRound();
      }
    });
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
    }
  }

  void refillFuel() {
    final cost = 100 + currentVehicle * 100;
    if (money >= cost || currentVehicle == 0) {
      setState(() {
        if (currentVehicle > 0) money -= cost;
        fuel = vehicles[currentVehicle].fuelMax;
      });
    }
  }

  void rewardBonus() {
    setState(() {
      money += 250;
      if (currentVehicle > 0) fuel = vehicles[currentVehicle].fuelMax;
    });

    showMessage('Ödül alındı!', '250 TL bonus kazandın.');
  }

  void showMessage(String title, String message) {
    Future.delayed(Duration.zero, () {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = vehicles[currentVehicle];
    final nextVehicle =
        currentVehicle < vehicles.length - 1 ? vehicles[currentVehicle + 1] : null;

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF020617),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('💰 $money TL', style: const TextStyle(color: Colors.white, fontSize: 17)),
                      Text('📦 $deliveries', style: const TextStyle(color: Colors.white, fontSize: 17)),
                      Text('${vehicle.icon} ${vehicle.name}', style: const TextStyle(color: Colors.white, fontSize: 17)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: vehicle.fuelMax == 999 ? 1 : fuel / vehicle.fuelMax,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vehicle.fuelMax == 999 ? 'Yakıt: ∞' : 'Yakıt: $fuel',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (nextVehicle != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sıradaki: ${nextVehicle.icon} ${nextVehicle.name} - ${nextVehicle.price} TL',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: money >= nextVehicle.price ? buyNextVehicle : null,
                          child: const Text('AL'),
                        ),
                      ],
                    )
                  else
                    const Text('Tüm araçları açtın kral 🔥', style: TextStyle(color: Colors.amber)),
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

                    return Stack(
                      children: [
                        Positioned.fill(child: Container(color: const Color(0xFF374151))),

                        for (int i = 0; i < 8; i++)
                          Positioned(
                            left: width / 2 - 3,
                            top: i * 120.0 + roadOffset * 15 - 120,
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
                          child: Text(
                            random.nextBool() ? '🚧' : '🚗',
                            style: const TextStyle(fontSize: 46),
                          ),
                        ),

                        Positioned(
                          left: laneX(lane, width) - 30,
                          bottom: 45,
                          child: Text(vehicle.icon, style: const TextStyle(fontSize: 58)),
                        ),

                        if (!playing)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black54,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'THE CARRIER',
                                      style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Taşı, kazan, aracını büyüt.',
                                      style: TextStyle(color: Colors.white70, fontSize: 18),
                                    ),
                                    const SizedBox(height: 25),
                                    ElevatedButton(
                                      onPressed: startGame,
                                      child: const Text('BAŞLA', style: TextStyle(fontSize: 24)),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: rewardBonus,
                                      child: const Text('ÖDÜL AL +250 TL'),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: refillFuel,
                                      child: const Text('YAKIT DOLDUR'),
                                    ),
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
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF020617),
              child: const Text(
                'Kaydır: Şerit değiştir | Dokun: İlerle | Paket topla, engelden kaç',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
