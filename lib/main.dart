import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const TheCarrierApp());
}

class TheCarrierApp extends StatelessWidget {
  const TheCarrierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Carrier',
      theme: ThemeData(fontFamily: 'Arial'),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int money = 0;
  int deliveries = 0;
  int lane = 1;
  bool playing = false;

  final List<String> lanes = ['left', 'middle', 'right'];
  late int packageLane;
  late int obstacleLane;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final random = Random();
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

    setState(() {
      if (lane == obstacleLane) {
        money = max(0, money - 20);
        playing = false;
        _showCrashDialog();
      } else {
        if (lane == packageLane) {
          money += 50;
          deliveries++;
        } else {
          money += 10;
        }
        _newRound();
      }
    });
  }

  void _showCrashDialog() {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Kaza yaptın!'),
          content: const Text('Tamir için 20 TL harcadın. Devam etmek ister misin?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  playing = true;
                  _newRound();
                });
              },
              child: const Text('Devam Et'),
            ),
          ],
        ),
      );
    });
  }

  double laneX(int laneIndex, double width) {
    if (laneIndex == 0) return width * 0.25;
    if (laneIndex == 1) return width * 0.50;
    return width * 0.75;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0B1320),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Para: $money TL',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'Teslimat: $deliveries',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: drive,
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < 0) {
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
                        Positioned.fill(
                          child: Container(color: const Color(0xFF2F2F2F)),
                        ),
                        Positioned(
                          left: width / 3,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 2, color: Colors.white24),
                        ),
                        Positioned(
                          left: width * 2 / 3,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 2, color: Colors.white24),
                        ),
                        Positioned(
                          left: laneX(packageLane, width) - 25,
                          top: height * 0.25,
                          child: const Text('📦', style: TextStyle(fontSize: 44)),
                        ),
                        Positioned(
                          left: laneX(obstacleLane, width) - 25,
                          top: height * 0.45,
                          child: const Text('🚧', style: TextStyle(fontSize: 44)),
                        ),
                        Positioned(
                          left: laneX(lane, width) - 30,
                          bottom: 40,
                          child: const Text('🚲', style: TextStyle(fontSize: 56)),
                        ),
                        if (!playing)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black54,
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      playing = true;
                                      money = 0;
                                      deliveries = 0;
                                      lane = 1;
                                      _newRound();
                                    });
                                  },
                                  child: const Text(
                                    'BAŞLA',
                                    style: TextStyle(fontSize: 24),
                                  ),
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
              color: const Color(0xFF0B1320),
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Sağa/sola kaydır. Ekrana dokunup ilerle. Paketi topla, engelden kaç.',
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
