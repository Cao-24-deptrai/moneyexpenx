import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moneyexpenx/data/models/user_model.dart';
import 'package:moneyexpenx/data/services/firebase_service.dart';
import 'package:moneyexpenx/data/services/local_storage_service.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  AuthViewModel() {
    _loadSessionFromCache();
  }

  Future<void> _loadSessionFromCache() async {
    _isLoading = true;
    notifyListeners();

    String? cachedUid = LocalStorageService.getCachedUserId();
    String? cachedUsername = LocalStorageService.getCachedUsername();
    String? cachedRole = LocalStorageService.getCachedUserRole();

    if (cachedUid != null) {
      // Create session from cache for immediate UI responsiveness
      _currentUser = UserModel(
        uID: cachedUid,
        username: cachedUsername ?? 'User',
        email: '',
        createdAt: DateTime.now(),
        role: cachedRole ?? 'user',
      );

      // Refresh full profile in background from Firestore to get latest role
      _firebaseService.getUserByID(cachedUid).then((user) {
        if (user != null) {
          _currentUser = user;
          LocalStorageService.cacheUserRole(user.role);
          notifyListeners();
        }
      });
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserModel? user = await _firebaseService.signIn(email, password);
      if (user != null) {
        _currentUser = user;
        await LocalStorageService.cacheUserId(user.uID);
        await LocalStorageService.cacheUsername(user.username);
        await LocalStorageService.cacheUserRole(user.role);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Đăng nhập thất bại. Vui lòng thử lại.";
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "Đã xảy ra lỗi xác thực.";
      if (e.code == 'user-not-found') {
        _errorMessage = "Không tìm thấy tài khoản với email này.";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _errorMessage = "Mật khẩu hoặc thông tin đăng nhập không chính xác.";
      } else if (e.code == 'invalid-email') {
        _errorMessage = "Địa chỉ email không hợp lệ.";
      } else if (e.code == 'user-disabled') {
        _errorMessage = "Tài khoản này đã bị vô hiệu hóa.";
      } else if (e.code == 'operation-not-allowed') {
        _errorMessage =
            "Đăng nhập bằng Email/Password chưa được bật trên Firebase Console.";
      }
    } on FirebaseException catch (e) {
      _errorMessage = e.message ?? "Lỗi cơ sở dữ liệu Firebase.";
      if (e.code == 'permission-denied') {
        _errorMessage =
            "Quyền truy cập bị từ chối. Vui lòng kiểm tra Firestore Rules.";
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserModel? user = await _firebaseService.signUp(
        username,
        email,
        password,
      );
      if (user != null) {
        _currentUser = user;
        await LocalStorageService.cacheUserId(user.uID);
        await LocalStorageService.cacheUsername(user.username);
        await LocalStorageService.cacheUserRole(user.role);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Đăng ký thất bại. Vui lòng thử lại.";
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "Đã xảy ra lỗi khi tạo tài khoản.";
      if (e.code == 'email-already-in-use') {
        _errorMessage = "Email này đã được sử dụng bởi một tài khoản khác.";
      } else if (e.code == 'invalid-email') {
        _errorMessage = "Địa chỉ email không hợp lệ.";
      } else if (e.code == 'weak-password') {
        _errorMessage = "Mật khẩu quá yếu (tối thiểu 6 ký tự).";
      } else if (e.code == 'operation-not-allowed') {
        _errorMessage =
            "Đăng ký bằng Email/Password chưa được bật trên Firebase Console.";
      }
    } on FirebaseException catch (e) {
      _errorMessage = e.message ?? "Lỗi cơ sở dữ liệu Firebase.";
      if (e.code == 'permission-denied') {
        _errorMessage =
            "Quyền truy cập bị từ chối. Vui lòng kiểm tra Firestore Rules.";
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _firebaseService.signOut();
    await LocalStorageService.clearCachedUserId();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.sendPasswordResetEmail(email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage =
          e.message ?? "Đã xảy ra lỗi khi gửi yêu cầu khôi phục mật khẩu.";
      if (e.code == 'user-not-found') {
        _errorMessage = "Không tìm thấy tài khoản với email này.";
      } else if (e.code == 'invalid-email') {
        _errorMessage = "Địa chỉ email không hợp lệ.";
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateUsername(String newUsername) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.updateUsername(
        _currentUser!.uID,
        newUsername.trim(),
      );
      _currentUser = UserModel(
        uID: _currentUser!.uID,
        username: newUsername.trim(),
        email: _currentUser!.email,
        createdAt: _currentUser!.createdAt,
      );
      await LocalStorageService.cacheUsername(newUsername.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // ADMIN MANAGEMENT METHODS
  // ==========================================

  Future<List<UserModel>> fetchAllUsers() async {
    return await _firebaseService.getAllUsers();
  }

  Future<bool> updateUserRole(String targetUid, String newRole) async {
    try {
      await _firebaseService.updateUserRole(targetUid, newRole);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Không thể cập nhật quyền: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String targetUid) async {
    try {
      await _firebaseService.deleteUser(targetUid);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Không thể xóa người dùng: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, int>> fetchSystemStats() async {
    return await _firebaseService.getSystemStats();
  }
}
