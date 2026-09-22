import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sensor_mode.dart';
import '../services/license_service.dart';
import '../services/settings_service.dart';
import 'magnet_calibration_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _instructionController = TextEditingController();
  int _repliesCount = SettingsService.instance.repliesCount;
  double _sensitivity = SettingsService.instance.sensitivity;
  double _tiltAngle = SettingsService.instance.tiltAngle;
  SensorMode _sensorMode = SettingsService.instance.sensorMode;
  double _magnetBaseline = SettingsService.instance.magnetBaseline;
  double _magnetOffset = SettingsService.instance.magnetOffset;

  @override
  void initState() {
    super.initState();
    _instructionController.text = SettingsService.instance.instruction;
  }

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  String get _siteUrl {
    final s = SettingsService.instance;
    final base = s.apiUrl.endsWith('/')
        ? s.apiUrl.substring(0, s.apiUrl.length - 1)
        : s.apiUrl;
    return s.license.isEmpty
        ? '$base/'
        : '$base/?license=${Uri.encodeQueryComponent(s.license)}';
  }

  Future<void> _copySiteUrl() async {
    await Clipboard.setData(ClipboardData(text: _siteUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ссылка скопирована')),
    );
  }

  Future<void> _save() async {
    final settings = SettingsService.instance;
    await settings.setInstruction(_instructionController.text.trim().isEmpty
        ? 'Инструкция к фокусу:'
        : _instructionController.text.trim());
    await settings.setRepliesCount(_repliesCount);
    await settings.setSensitivity(_sensitivity);
    await settings.setTiltAngle(_tiltAngle);
    await settings.setSensorMode(_sensorMode);
    await settings.setMagnetOffset(_magnetOffset);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _calibrateMagnet() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MagnetCalibrationScreen()),
    );
    if (!mounted) return;
    final s = SettingsService.instance;
    setState(() {
      _magnetBaseline = s.magnetBaseline;
      _magnetOffset = s.magnetOffset;
    });
  }

  Future<void> _changeLicense() async {
    await LicenseService.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Адрес сайта',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            readOnly: true,
            controller: TextEditingController(text: _siteUrl),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _copySiteUrl,
                tooltip: 'Копировать',
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Инструкция',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _instructionController,
            minLines: 4,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Инструкция к фокусу:',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Количество реплик',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 2, label: Text('2')),
              ButtonSegment(value: 3, label: Text('3')),
              ButtonSegment(value: 4, label: Text('4')),
              ButtonSegment(value: 5, label: Text('5')),
              ButtonSegment(value: 6, label: Text('6')),
            ],
            selected: {_repliesCount},
            onSelectionChanged: (selection) {
              setState(() => _repliesCount = selection.first);
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Чувствительность',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _sensitivity,
            min: 0,
            max: 100,
            divisions: 100,
            label: '${_sensitivity.round()}',
            onChanged: (value) => setState(() => _sensitivity = value),
          ),
          Text(
            'Чем выше, тем быстрее реакция на движение. Чем ниже, тем дольше '
            'нужно удерживать наклон — тряска реже вызывает запись.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Угол поворота',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _tiltAngle,
            min: 5,
            max: 60,
            divisions: 55,
            label: '${_tiltAngle.round()}°',
            onChanged: (value) => setState(() => _tiltAngle = value),
          ),
          Text(
            'Отклонение телефона от вертикали, при котором начинается запись.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Датчик записи',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          RadioGroup<SensorMode>(
            groupValue: _sensorMode,
            onChanged: (v) => setState(() => _sensorMode = v!),
            child: Column(
              children: [
                RadioListTile<SensorMode>(
                  value: SensorMode.accelerometer,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Наклон телефона (акселерометр)'),
                ),
                RadioListTile<SensorMode>(
                  value: SensorMode.magnetometer,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Магнит (магнитометр)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Магнитометр',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _magnetBaseline > 0
                ? 'База: ${_magnetBaseline.round()} µT · Порог: '
                    '${(_magnetBaseline + _magnetOffset).round()} µT'
                : 'Калибровка не выполнена. Проведите калибровку для работы датчика.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _calibrateMagnet,
            icon: const Icon(Icons.tune),
            label: const Text('Калибровать'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Порог срабатывания',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _magnetOffset.clamp(10, 150).toDouble(),
            min: 10,
            max: 150,
            divisions: 140,
            label: '+${_magnetOffset.round()} µT',
            onChanged: (value) => setState(() => _magnetOffset = value),
          ),
          Text(
            'Превышение над фоновым полем, при котором начинается запись. '
            'Ниже — чувствительнее к слабому магниту, но возможны ложные '
            'срабатывания.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Сохранить'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _changeLicense,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Сменить лицензионный ключ'),
          ),
        ],
      ),
    );
  }
}