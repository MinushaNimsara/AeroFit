import 'package:aerofit/core/router/app_router.dart';
import 'package:aerofit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single stable [MaterialApp.router] shell — never swap app widgets on auth changes.
class AeroFitApp extends ConsumerWidget {
  const AeroFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'AeroFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
