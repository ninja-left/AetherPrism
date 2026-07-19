import 'package:flutter/material.dart';

import 'prism_home_page.dart';

class PrismApp extends StatelessWidget {
  const PrismApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aether Prism',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E7CF7),
          brightness: Brightness.dark,
        ),
      ),
      home: const PrismHomePage(),
    );
  }
}
