import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:fft/fft.dart';
import 'package:vibration/vibration.dart';
import 'affective_state_estimator.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MaterialApp(home: BiosignalPage(), debugShowCheckedModeBanner: false));
}

class BiosignalPage extends StatefulWidget {
  const BiosignalPage({super.key});
  @override State<BiosignalPage> createState() => _BiosignalPageState();
}

class _BiosignalPageState extends State<BiosignalPage> {
  final estimator = AffectiveStateEstimator();
  CameraController? controller;
  final ppg = PPGProcessor();
  final audio = AudioFeatures();
  double stillness = 0.5;
  double touch = 0.0;

  @override void initState() {
    super.initState();
    _initCam();
    audio.start();
    accelerometerEvents.listen((e) {
      stillness = math.exp(-e.toVector().length * 5).clamp(0.0, 1.0);
      _tick();
    });
  }

  Future<void> _initCam() async {
    controller = CameraController(cameras.first, ResolutionPreset.medium);
    await controller!.initialize();
    controller!.startImageStream(ppg.processFrame);
    setState(() {});
  }

  void _tick() {
    estimator.update(
      hrvRmssd: ppg.hrvRmssd,
      spectralCentroid: audio.centroid,
      spectralFlux: audio.flux,
      stillness: stillness,
      touchIntensity: touch,
    );
    if (estimator.coherence > 0.94) Vibration.vibrate(duration: 30);
    setState(() {});
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        if (controller != null) CameraPreview(controller!),
        GestureDetector(
          onPanUpdate: (d) { touch = d.delta.distance / 100; _tick(); },
          child: Container(color: Colors.transparent),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('HRV: ${ppg.hrvRmssd.toStringAsFixed(1)} ms', style: const TextStyle(color: Colors.cyan)),
                Text('Centroid: ${audio.centroid.toStringAsFixed(0)} Hz', style: const TextStyle(color: Colors.orange)),
                const SizedBox(height: 16),
                Text('Valence ${estimator.valence.toStringAsFixed(2)}', style: const TextStyle(color: Colors.amber, fontSize: 24)),
                Text('Arousal ${estimator.arousal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontSize: 24)),
                Text('Coherence ${(estimator.coherence*100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.green, fontSize: 36)),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  @override void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
