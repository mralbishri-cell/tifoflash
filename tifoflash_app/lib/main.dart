import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/tifo_theme.dart';
import 'features/stadium/presentation/sector_selector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: TifoFlashApp(),
    ),
  );
}

class TifoFlashApp extends StatelessWidget {
  const TifoFlashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TifoFlash Stadium',
      debugShowCheckedModeBanner: false,
      theme: TifoTheme.darkTheme,
      home: const SectorSelectorScreen(),
    );
  }
}
