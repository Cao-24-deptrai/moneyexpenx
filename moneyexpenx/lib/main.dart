import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/data/services/firebase_service.dart';
import 'package:moneyexpenx/data/services/local_storage_service.dart';
import 'package:moneyexpenx/viewmodels/auth_viewmodel.dart';
import 'package:moneyexpenx/viewmodels/finance_viewmodel.dart';
import 'package:moneyexpenx/views/auth/login_screen.dart';
import 'package:moneyexpenx/views/dashboard/dashboard_screen.dart';

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
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadUserData();
      _initialized = true;
    }
  }

  Future<void> _loadUserData() async {
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final financeVm = Provider.of<FinanceViewModel>(context, listen: false);
    
    // If user is already authenticated from cache, load their finance data
    if (authVm.isAuthenticated) {
      await financeVm.loadData(authVm.currentUser!.uID);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context);

    // Show loading spinner if auth VM is booting
    if (authVm.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryYellow),
          ),
        ),
      );
    }

    // Direct routing based on Auth state
    if (authVm.isAuthenticated) {
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}
