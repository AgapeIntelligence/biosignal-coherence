import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:fft/fft.dart';

class PPGProcessor {
  final List<double> red = [];
  final List<double> rr = [];
  DateTime? lastPeak;
  double hrvRmssd = 50.0;

  void processFrame(CameraImage img) {
    if (img.format.group != ImageFormatGroup.yuv420) return;
    int sum = 0, n = 0;
    final w = img.width, h = img.height;
    for (int dy = -20; dy < 20; dy++) for (int dx = -20; dx < 20; dx++) {
      final x = w~/2 + dx; final y = h~/2 + dy;
      if (x < 0 || x >= w || y < 0 || y >= h) continue;
      final yp = img.planes[0].bytes[y*w + x];
      final vp = img.planes[2].bytes[(y~/2)*img.planes[2].bytesPerRow + (x~/2)*2];
      sum += (yp + 1.402*(vp-128)).round();
      n++;
    }
    if (n == 0) return;
    final avg = sum / n;
    red.add(avg);
    if (red.length > 120) red.removeAt(0);

    if (red.length > 60) {
      final base = red.sublist(red.length-60).reduce(math.min);
      if (avg > base + 18 && (lastPeak == null || DateTime.now().difference(lastPeak!).inMilliseconds > 400)) {
        if (lastPeak != null) rr.add(DateTime.now().difference(lastPeak!).inMilliseconds/1000);
        lastPeak = DateTime.now();
        if (rr.length > 8) {
          double s = 0;
          for (int i=1; i<rr.length; i++) s += math.pow(rr[i]-rr[i-1],2);
          hrvRmssd = math.sqrt(s/(rr.length-1));
        }
      }
    }
  }
}

class AudioFeatures {
  final meter = NoiseMeter();
  final fft = FFT();
  double centroid = 432.0;
  double flux = 0.0;
  List<double> prev = [];

  void start() {
    meter.noiseStream.listen((n) {
      if (n.samples.length < 2048) return;
      final mag = fft.magnitude(n.samples.take(2048));
      centroid = _c(mag);
      flux = prev.isEmpty ? 0 : _f(mag, prev);
      prev = mag;
    });
  }
  double _c(List<double> m) {
    double s=0, w=0;
    for (int i=0; i<m.length; i++) { s += m[i]; w += m[i]*i; }
    return s>0 ? w/s * (22050/m.length) : 432;
  }
  double _f(List<double> a, List<double> b) {
    double f=0;
    final len = a.length.clamp(0, b.length);
    for (int i=0; i<len; i++) f += (a[i]-b[i]).abs();
    return f/len/100;
  }
}

extension on AccelerometerEvent {
  double toVector() => math.sqrt(x*x + y*y + z*z);
}
