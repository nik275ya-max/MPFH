import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/sensor_mode.dart';
import '../services/api_service.dart';
import '../services/license_service.dart';
import '../services/settings_service.dart';
import '../services/vibration_service.dart';
import 'settings_screen.dart';

enum RecordState { idle, armed, recording }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onLicenseLost});

  final VoidCallback? onLicenseLost;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _speech = SpeechToText();
  final List<String> _replies = [];

  RecordState _state = RecordState.idle;
  bool _triggerActive = false;
  bool _speechReady = false;
  String? _statusText;
  int _targetReplies = 4;
  SensorMode _mode = SensorMode.accelerometer;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  double _tiltScore = 0;
  double _motionScore = 0;
  double _magnetScore = 0;

  static const double _magnetHysteresis = 12.0;

  @override
  void initState() {
    super.initState();
    _targetReplies = SettingsService.instance.repliesCount;
    _initSpeech();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onError: (e) => _setStatus('Ошибка распознавания'),
      onStatus: (s) {
        if (s == 'done' && !_triggerActive) {
          _stopRecording();
        }
      },
    );
    if (!_speechReady) {
      _setStatus('Распознавание речи недоступно');
    }
  }

  void _setStatus(String text) {
    if (!mounted) return;
    setState(() => _statusText = text);
  }

  Future<void> _vibrate() async {
    await VibrationService.vibrate();
  }

  void _startEngine() {
    if (!_speechReady) {
      _setStatus('Распознавание речи недоступно');
      return;
    }
    _mode = SettingsService.instance.sensorMode;
    if (_mode == SensorMode.magnetometer &&
        SettingsService.instance.magnetBaseline <= 0) {
      _setStatus('Сначала откалибруйте магнитометр (Настройки → Калибровать).');
      return;
    }
    setState(() => _state = RecordState.armed);
    _setStatus(_armedHint);
    _triggerActive = false;
    _tiltScore = 0;
    _motionScore = 0;
    _magnetScore = 0;
    _accelSub?.cancel();
    _magSub?.cancel();
    if (_mode == SensorMode.magnetometer) {
      _magSub = magnetometerEventStream().listen((e) {
        _onMagnetometer(e.x, e.y, e.z);
      });
    } else {
      _accelSub = accelerometerEventStream().listen((e) {
        _onAccelerometer(e.x, e.y, e.z);
      });
    }
  }

  String get _armedHint => switch (_mode) {
        SensorMode.accelerometer =>
          'Держите телефон вертикально. Наклоните горизонтально, чтобы записать реплику.',
        SensorMode.magnetometer =>
          'Держите телефон неподвижно. Поднесите магнит, чтобы записать реплику.',
      };

  String get _armedFallback => switch (_mode) {
        SensorMode.accelerometer => 'Следите за положением телефона',
        SensorMode.magnetometer => 'Следите за магнитным полем',
      };

  static const double _gravity = 9.81;

  void _onAccelerometer(double x, double y, double z) {
    if (_state != RecordState.armed && _state != RecordState.recording) return;

    final settings = SettingsService.instance;
    final magnitude = math.sqrt(x * x + y * y + z * z);

    // Normalized fast indicators: >1 means "too tilted" / "moving too much".
    final axisThreshold =
        _gravity * math.sin(settings.tiltAngle * math.pi / 180);
    final tiltNorm =
        axisThreshold <= 0 ? 0.0 : math.sqrt(x * x + z * z) / axisThreshold;
    final motionNorm =
        (magnitude - _gravity).abs() / _sensitivityToTolerance(settings.sensitivity);

    // Low-pass smoothing: brief shake spikes average out, a held tilt
    // accumulates and reliably crosses the threshold. Lower sensitivity =
    // more smoothing = shakes are ignored, but the tilt just needs be held.
    final alpha = _sensitivityToAlpha(settings.sensitivity);
    _tiltScore += alpha * (tiltNorm - _tiltScore);
    _motionScore += alpha * (motionNorm - _motionScore);

    final isVertical = _tiltScore < 1.0 && _motionScore < 1.0;
    _setTriggerActive(!isVertical);
  }

  void _onMagnetometer(double x, double y, double z) {
    if (_state != RecordState.armed && _state != RecordState.recording) return;

    final magnitude = math.sqrt(x * x + y * y + z * z);
    const alpha = 0.15;
    _magnetScore += alpha * (magnitude - _magnetScore);

    final threshold = SettingsService.instance.magnetThreshold;
    // Hysteresis: to start recording the field must rise above the threshold,
    // to stop it must drop back below the threshold minus a small gap.
    final active = _triggerActive
        ? _magnetScore >= threshold - _magnetHysteresis
        : _magnetScore >= threshold;
    _setTriggerActive(active);
  }

  void _setTriggerActive(bool active) {
    if (_triggerActive == active) return;
    _triggerActive = active;
    if (active) {
      _startRecording();
    } else {
      _stopRecording();
    }
  }

  static double _sensitivityToTolerance(double sensitivity) {
    // 0..100 -> tolerance from 3.0 (very tolerant) down to 0.3 (very strict).
    return 3.0 - (sensitivity / 100) * 2.7;
  }

  static double _sensitivityToAlpha(double sensitivity) {
    // 0..100 -> alpha from 0.05 (heavily smoothed, ignores shakes) to 0.30 (fast).
    return 0.05 + (sensitivity / 100) * 0.25;
  }

  String get _recordingHint => switch (_mode) {
        SensorMode.accelerometer =>
          'Идёт запись реплики ${_replies.length + 1}. Поставьте телефон вертикально для завершения.',
        SensorMode.magnetometer =>
          'Идёт запись реплики ${_replies.length + 1}. Уберите магнит для завершения.',
      };

  Future<void> _startRecording() async {
    if (_state == RecordState.recording) return;
    await _vibrate();
    setState(() => _state = RecordState.recording);
    _setStatus(_recordingHint);

    try {
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: 'ru_RU',
        ),
        onResult: (r) {
          if (r.finalResult) {
            final text = r.recognizedWords.trim();
            if (text.isNotEmpty) {
              setState(() {
                _replies.add(text);
              });
            }
            if (_replies.length >= _targetReplies) {
              _finishAll();
            }
          }
        },
      );
    } on Exception {
      if (!mounted) return;
      _setStatus('Не удалось начать запись');
      setState(() => _state = RecordState.armed);
    }
  }

  Future<void> _stopRecording() async {
    if (_state != RecordState.recording) return;
    await _vibrate();
    await _speech.stop();
    setState(() => _state = RecordState.armed);
    if (_replies.length >= _targetReplies) {
      _finishAll();
      return;
    }
    if (_replies.length < _targetReplies) {
      _setStatus('Запись завершена (${_replies.length}/$_targetReplies). '
          '$_stopHint');
    }
  }

  String get _stopHint => switch (_mode) {
        SensorMode.accelerometer =>
          'Наклоните телефон для следующей реплики.',
        SensorMode.magnetometer =>
          'Поднесите магнит для следующей реплики.',
      };

  void _finishAll() {
    if (!mounted) return;
    setState(() {
      _state = RecordState.idle;
      _statusText = 'Все реплики записаны. Отправка данных на сервер...';
    });
    _accelSub?.cancel();
    _magSub?.cancel();
    _sendData();
  }

  Future<void> _sendData() async {
    final url = await ApiService.instance.sendReplies(
      instruction: SettingsService.instance.instruction,
      replies: List<String>.from(_replies),
    );
    if (!mounted) return;
    if (url != null) {
      setState(() {
        _statusText = 'Данные отправлены. Страница результата:';
      });
      _showResultSheet(url);
    } else {
      _setStatus('Ошибка отправки данных. Попробуйте снова.');
    }
  }

  void _showResultSheet(String url) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Данные успешно отправлены!'),
            const SizedBox(height: 16),
            SelectableText(
              url,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: url)),
              child: const Text('Скопировать ссылку'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _reset();
              },
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _replies.clear();
      _state = RecordState.idle;
      _statusText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('MPFH — Предсказание'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _state == RecordState.idle
                ? () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                    if (!mounted) return;
                    setState(() {
                      _targetReplies = SettingsService.instance.repliesCount;
                    });
                    if (!LicenseService.instance.isValidStored()) {
                      widget.onLicenseLost?.call();
                    }
                  }
                : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildStartButton(),
            const SizedBox(height: 32),
            Expanded(
              child: _buildRecordingSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: FilledButton(
        onPressed: _state == RecordState.idle ? _startEngine : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6C2BD9),
          disabledBackgroundColor: const Color(0xFF3A2B5A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          'СТАРТ',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            color: _state == RecordState.idle ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingSection() {
    final Color indicatorColor;
    final String indicatorText;

    switch (_state) {
      case RecordState.idle:
        indicatorColor = Colors.grey;
        indicatorText = _statusText ?? 'Нажмите СТАРТ, чтобы начать';
        break;
      case RecordState.armed:
        indicatorColor = _triggerActive ? Colors.green : Colors.orange;
        indicatorText = _statusText ?? _armedFallback;
        break;
      case RecordState.recording:
        indicatorColor = Colors.red;
        indicatorText = _statusText ?? 'Запись...';
        break;
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          indicatorText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        Expanded(child: _buildRepliesList()),
      ],
    );
  }

  Widget _buildRepliesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Реплики (${_replies.length}/$_targetReplies):',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _replies.isEmpty
              ? const Center(
                  child: Text('Пока нет записанных реплик'),
                )
              : ListView.builder(
                  itemCount: _replies.length,
                  itemBuilder: (ctx, i) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${i + 1}'),
                      ),
                      title: Text(_replies[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}