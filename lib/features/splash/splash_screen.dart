import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/constants/app_assets.dart';
import '../../shared/constants/app_strings.dart';
import '../../theme/app_colors.dart';
import 'providers/model_ready_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modelReady = ref.watch(modelReadyProvider);
    final progress = ref.watch(extractionProgressProvider);

    // Navigate to home when model is ready
    ref.listen(modelReadyProvider, (previous, next) {
      next.whenData((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.go('/');
        });
      });
    });

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppAssets.logo,
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.appTagline,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 48),
              modelReady.when(
                loading: () => _buildProgressSection(progress),
                error: (e, _) => _buildErrorSection(),
                data: (_) => const Icon(
                  Icons.check_circle,
                  color: AppColors.textOnPrimary,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(double progress) {
    final showBar = progress >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          if (showBar) ...[
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.textOnPrimary.withValues(alpha: 0.3),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.textOnPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Preparing AI model... ${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ] else
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.textOnPrimary),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Column(
      children: [
        Text(
          'Setup failed. Please try again.',
          style: TextStyle(
            color: AppColors.textOnPrimary.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => ref.invalidate(modelReadyProvider),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
