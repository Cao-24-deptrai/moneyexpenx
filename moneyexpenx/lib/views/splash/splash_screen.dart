import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.blackBg,
      body: Stack(
        children: [
          // Ambient blurred background glows (Matching login_screen.dart)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellow.withValues(alpha: 0.14),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellow.withValues(alpha: 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.4,
            left: size.width * 0.7,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withValues(alpha: 0.06),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Center Logo & Title Content (100% IDENTICAL to login_screen.dart & home_view.dart)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Hero(
                  tag: 'app_logo',
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: AppTheme.primaryYellow,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MoneyExpenx',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppTheme.primaryYellow,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quản lý chi tiêu thông minh',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        letterSpacing: 0.5,
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 48),

                // Smooth Progress Indicator
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
