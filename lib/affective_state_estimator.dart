import 'dart:math' as math;

class AffectiveStateEstimator {
  double _valence = 0.0;
  double _arousal = 0.0;
  double _coherence = 0.5;

  double get valence => _valence;
  double get arousal => _arousal;
  double get coherence => _coherence;

  void update({
    required double hrvRmssd,
    required double spectralCentroid,
    required double spectralFlux,
    double handVelocity = 0.0,
    double stillness = 0.5,
    double touchIntensity = 0.0,
  }) {
    final breath = (math.log1p(hrvRmssd) / 5.0).clamp(0.0, 1.0);
    final bright = (spectralCentroid / 4000).clamp(0.0, 1.0);

    _valence = breath * 0.6 + bright * 0.3 - handVelocity * 0.3 + touchIntensity * 0.4;
    _arousal = spectralFlux * 0.7 + handVelocity * 0.6 - breath * 0.3;
    _coherence = _coherence * 0.99 + (stillness * 0.6 + breath * 0.4) * 0.01;

    _valence = _valence.clamp(-1.0, 1.0);
    _arousal = _arousal.clamp(-1.0, 1.0);
    _coherence = _coherence.clamp(0.0, 1.0);
  }
}
