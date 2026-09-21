import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/license_service.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key, this.onLicensed});

  final VoidCallback? onLicensed;

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.text = '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _formatAndValidate() {
    final raw = _controller.text.toUpperCase().trim();
    int cut = 0;
    final digits = StringBuffer();
    for (final ch in raw.split('')) {
      if ('0123456789'.contains(ch)) {
        digits.write(ch);
        cut++;
        if (digits.length == 8) break;
      }
    }
    final datePart = digits.toString();
    final prefix = 'MPFH-';
    String formatted = prefix;
    if (datePart.isNotEmpty) {
      formatted += datePart;
      if (datePart.length == 8) {
        final rest = raw.substring(cut).replaceAll(RegExp(r'[^0-9A-Z]'), '');
        if (rest.isNotEmpty) {
          formatted += '-${rest.substring(0, rest.length.clamp(0, 4))}';
          if (rest.length > 4) {
            formatted += '-${rest.substring(4, rest.length.clamp(4, 8))}';
          }
        }
      }
    }
    _controller.text = formatted;
    _controller.selection = TextSelection.collapsed(offset: formatted.length);
  }

  Future<void> _activate() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await LicenseService.instance.save(_controller.text);
    if (!mounted) return;
    if (ok) {
      widget.onLicensed?.call();
    } else {
      setState(() {
        _saving = false;
        _error = 'Ключ недействителен. Проверьте формат и контрольную сумму.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C2BD9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.visibility, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'MPFH',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Мастер предсказаний — Свободная рука',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Для работы приложения необходим лицензионный ключ. '
                    'Введите его, чтобы активировать запись реплик.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    onChanged: (_) {
                      if (mounted && _error != null) {
                        setState(() => _error = null);
                      }
                    },
                    onEditingComplete: _formatAndValidate,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z\-]')),
                      LengthLimitingTextInputFormatter(26),
                    ],
                    style: const TextStyle(letterSpacing: 1.2),
                    decoration: InputDecoration(
                      labelText: 'Лицензионный ключ',
                      hintText: 'MPFH-ГГГГММДД-XXXX-XXXX',
                      errorText: _error,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _activate,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6C2BD9),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Активировать',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}