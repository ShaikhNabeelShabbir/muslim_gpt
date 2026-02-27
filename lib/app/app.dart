import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../shared/constants/app_strings.dart';
import 'router.dart';

class MuslimGptApp extends StatelessWidget {
  const MuslimGptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
