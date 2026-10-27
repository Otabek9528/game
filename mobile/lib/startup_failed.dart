import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shown instead of the app when it couldn't start: what failed, in words
/// one can send to the developer.
class StartupFailed extends StatelessWidget {
  const StartupFailed({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Ilova ochilmadi\nПриложение не открылось\nThe app couldn’t start',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text('Ilovani qayta oching. Takrorlansa, shu sahifaning skrinshotini yuboring.'),
              const SizedBox(height: 20),
              SelectableText('$error', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(onPressed: SystemNavigator.pop, child: const Text('OK')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
