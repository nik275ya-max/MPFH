import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/settings_service.dart';

class MagnetCalibrationScreen extends StatefulWidget {
  const MagnetCalibrationScreen({super.key});

  @override
  State<MagnetCalibrationScreen> createState() => _MagnetCalibrationScreenState();
}

class _MagnetCalibrationScreenState extends State<MagnetCalibrationScreen> {
  StreamSubscription<MagnetometerEvent>? _sub;
  Timer? _timer;

  final List<double> _samples = [];
  bool _sampling = false;
  bool _ready = false;
  String? _error;
  double _currentMagnitude = 0;
  int _sampleCount = 0;
  int _secondsLeft = 3;
  double _baseline = 0;
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _samples.clear();
    _sampling = true;
    _ready = false;
    _error = null;
    _currentMagnitude = 0;
    _sampleCount = 0;
    _secondsLeft = 3;

    _sub?.cancel();
    _sub = magnetometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((e) {
      final magnitude =
          math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      _samples.add(magnitude);
      setState(() {
        _currentMagnitude = magnitude;
        _sampleCount = _samples.length;
      });
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        _finish();
      }
    });
  }

  Future<void> _finish() async {
    _timer?.cancel();
    _sub?.cancel();
    final count = _samples.length;
    if (count < 10) {
      setState(() {
        _sampling = false;
        _error = 'Недостаточно данных. Повторите калибровку.';
      });
      return;
    }

    final mean = _samples.reduce((a, b) => a + b) / count;
    final variance = _samples
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        count;
    final stddev = math.sqrt(variance);

    _baseline = mean;
    _offset = math.min(math.max(stddev * 8, 25.0), 120.0).toDouble();
    await SettingsService.instance.setMagnetCalibration(
      baseline: mean,
      offset: _offset,
    );
    if (!mounted) return;
    setState(() {
      _sampling = false;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Калибровка магнитометра')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Уберите магниты и металлические предметы от телефона. '
                'Держите его неподвижно (в том же положении, в котором '
                'будете записывать реплики).',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              _buildPanel(),
              const SizedBox(height: 24),
              if (!_sampling)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _start,
                        icon: const Icon(Icons.replay),
                        label: const Text('Повторить'),
                      ),
                    ),
                    if (_ready) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Готово'),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_sampling) ...[
              Text(
                'Измерение... Осталось $_secondsLeft с',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('Текущее поле: ${_currentMagnitude.round()} µT'),
              Text('Отсчётов: $_sampleCount'),
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ] else if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ] else if (_ready) ...[
              const Text(
                'Калибровка завершена',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('Фоновое поле: ${_baseline.round()} µT'),
              Text(
                'Порог срабатывания: '
                '${(_baseline + _offset).round()} µT',
              ),
            ],
          ],
        ),
      ),
    );
  }
}