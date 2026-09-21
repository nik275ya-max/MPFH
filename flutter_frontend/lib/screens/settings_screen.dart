import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/license_service.dart';
import '../services/settings_service.dart';

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
    if (!mounted) return;
    Navigator.of(context).pop();
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