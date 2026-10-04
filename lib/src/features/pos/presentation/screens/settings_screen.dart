import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(LocalStorageService.loadDarkMode());

  void toggle(bool value) {
    state = value;
    LocalStorageService.saveDarkMode(value);
  }
}

final isDarkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del TPV'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Appearance
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Modo Oscuro'),
                  subtitle: const Text('Tema visual oscuro para el punto de venta'),
                  value: isDark,
                  onChanged: (val) {
                    ref.read(isDarkModeProvider.notifier).toggle(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // App Info
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'gPOS v1.0.0 • Sistema de Punto de Venta',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
