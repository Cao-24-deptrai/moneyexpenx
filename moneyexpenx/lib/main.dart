import 'package:moneyexpenx/views/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/data/services/firebase_service.dart';
import 'package:moneyexpenx/data/services/local_storage_service.dart';
import 'package:moneyexpenx/viewmodels/auth_viewmodel.dart';
import 'package:moneyexpenx/viewmodels/finance_viewmodel.dart';
import 'package:moneyexpenx/views/auth/login_screen.dart';
import 'package:moneyexpenx/views/dashboard/dashboard_screen.dart';
import 'package:moneyexpenx/views/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  // Initialize Local Storage Cache
  await LocalStorageService.init();
  
  // Initialize Firebase
  await FirebaseService.instance.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => FinanceViewModel()),
      ],
      child: const MoneyExpenxApp(),
    ),
  );
}

class MoneyExpenxApp extends StatelessWidget {
  const MoneyExpenxApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyExpenx',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _loadedUid;

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context);

    // Show glowing brand SplashScreen during initial app boot
    if (authVm.isInitialLoading) {
      return const SplashScreen();
    }

    // Direct routing based on Auth state
    if (authVm.isAuthenticated) {
      final uid = authVm.currentUser!.uID;
      if (_loadedUid != uid) {
        _loadedUid = uid;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final financeVm = Provider.of<FinanceViewModel>(context, listen: false);
          financeVm.loadData(uid);
        });
      }

      if (authVm.isAdmin) {
        return const AdminDashboardScreen();
      }
      return const DashboardScreen();
    } else {
      _loadedUid = null;
      return const LoginScreen();
    }
  }
}
