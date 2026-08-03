import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:moneyexpenx/data/models/user_model.dart';
import 'package:moneyexpenx/data/models/category_model.dart';
import 'package:moneyexpenx/data/models/transaction_model.dart';
import 'package:moneyexpenx/data/models/saving_jar_model.dart';
import 'package:moneyexpenx/data/models/budget_model.dart';
import 'package:moneyexpenx/data/models/loan_model.dart';
import 'package:moneyexpenx/firebase_options.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseService._init();

  String? initializationError;
  final _uuid = const Uuid();
  final Map<String, UserModel> _userCache = {};

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      initializationError = null;
      debugPrint("Firebase successfully initialized.");
    } catch (e) {
      initializationError = e.toString();
      debugPrint("Firebase initialization failed: $e");
    }
  }

  // ==========================================
  // AUTHENTICATION SERVICES
  // ==========================================

  Future<UserModel?> signUp(
    String username,
    String email,
    String password,
  ) async {
    try {
      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        String uid = credential.user!.uid;
        bool isAdminEmail = email.trim().toLowerCase() == 'rocon@gmail.com';
        UserModel newUser = UserModel(
          uID: uid,
          username: username,
          email: email,
          createdAt: DateTime.now(),
          role: isAdminEmail ? 'admin' : 'user',
        );

        // Use a Firestore Batch to create both the user doc and default categories atomically
        final batch = FirebaseFirestore.instance.batch();

        // 1. Create user document
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid);
        batch.set(userDocRef, newUser.toMap());

        // 2. Define and seed default categories
        final defaultCategories = [
          {'name': 'Lương', 'type': 'Thu', 'iconKey': 'work'},
          {'name': 'Đầu tư', 'type': 'Thu', 'iconKey': 'trending_up'},
          {'name': 'Ăn uống', 'type': 'Chi', 'iconKey': 'restaurant'},
          {'name': 'Di chuyển', 'type': 'Chi', 'iconKey': 'directions_car'},
          {'name': 'Mua sắm', 'type': 'Chi', 'iconKey': 'shopping_bag'},
          {'name': 'Giải trí', 'type': 'Chi', 'iconKey': 'sports_esports'},
          {
            'name': 'Y tế & Sức khỏe',
            'type': 'Chi',
            'iconKey': 'medical_services',
          },
          {'name': 'Giáo dục', 'type': 'Chi', 'iconKey': 'school'},
          {'name': 'Nhà cửa', 'type': 'Chi', 'iconKey': 'home'},
          {'name': 'Cà phê', 'type': 'Chi', 'iconKey': 'coffee'},
        ];

        for (var cat in defaultCategories) {
          final catDocRef = FirebaseFirestore.instance
              .collection('categories')
              .doc();
          final categoryModel = CategoryModel(
            ctgID: catDocRef.id,
            uID: uid,
            name: cat['name']!,
            type: cat['type']!,
            iconKey: cat['iconKey']!,
          );
          batch.set(catDocRef, categoryModel.toMap());
        }

        // Commit all writes
        await batch.commit();

        return newUser;
      }
    } catch (e) {
      debugPrint("Firebase Sign Up Error: $e");
      rethrow;
    }
    return null;
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        String uid = credential.user!.uid;
        bool isAdminEmail = email.trim().toLowerCase() == 'rocon@gmail.com';
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists) {
          UserModel user = UserModel.fromMap(
            doc.data() as Map<String, dynamic>,
          );
          if (isAdminEmail && user.role != 'admin') {
            user = user.copyWith(role: 'admin');
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'role': 'admin'});
          }
          return user;
        } else {
          // Fallback if user doc was not created, create a default one to prevent crash
          UserModel fallbackUser = UserModel(
            uID: uid,
            username: credential.user!.displayName ?? email.split('@').first,
            email: email,
            createdAt: DateTime.now(),
            role: isAdminEmail ? 'admin' : 'user',
          );
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set(fallbackUser.toMap());
          return fallbackUser;
        }
      }
    } catch (e) {
      debugPrint("Firebase Sign In Error: $e");
      rethrow;
    }
    return null;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint("Firebase Password Reset Error: $e");
      rethrow;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      // Direct lookup by email
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return UserModel.fromMap(
          snap.docs.first.data() as Map<String, dynamic>,
        );
      }

      // Fallback lookup with lowercased email
      QuerySnapshot snapLower = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      if (snapLower.docs.isNotEmpty) {
        return UserModel.fromMap(
          snapLower.docs.first.data() as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint("Error fetching user by email: $e");
    }
    return null;
  }

  Future<UserModel?> getUserByID(String uid) async {
    if (_userCache.containsKey(uid)) {
      return _userCache[uid];
    }
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        _userCache[uid] = user;
        return user;
      }
    } catch (e) {
      debugPrint("Error fetching user by ID: $e");
    }
    return null;
  }

  Future<void> updateUsername(String uid, String newUsername) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'username': newUsername,
      });
      _userCache.remove(uid);
    } catch (e) {
      debugPrint("Error updating username: $e");
      rethrow;
    }
  }

  // ==========================================
  // CATEGORIES SERVICES
  // ==========================================

  Future<List<CategoryModel>> getCategories(String uID) async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('categories')
          .where('uID', isEqualTo: uID)
          .get();
      return snap.docs
          .map(
            (doc) => CategoryModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      return [];
    }
  }

  Future<CategoryModel> addCategory(CategoryModel category) async {
    String id = _uuid.v4();
    CategoryModel newCat = category.copyWith(ctgID: id);
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(id)
        .set(newCat.toMap());
    return newCat;
  }

  Future<void> updateCategory(CategoryModel category) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(category.ctgID)
        .update(category.toMap());
  }

  Future<void> deleteCategory(String ctgID) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(ctgID)
        .delete();
  }

  // ==========================================
  // TRANSACTION SERVICES
  // ==========================================

  Future<List<TransactionModel>> getTransactions(String uID) async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('transactions')
          .where('uID', isEqualTo: uID)
          .orderBy('ts_date', descending: true)
          .get();
      return snap.docs
          .map(
            (doc) =>
                TransactionModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
      return [];
    }
  }

  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    String id = _uuid.v4();
    TransactionModel newTx = transaction.copyWith(tsID: id);
    await FirebaseFirestore.instance
        .collection('transactions')
        .doc(id)
        .set(newTx.toMap());
    return newTx;
  }

  Future<void> deleteTransaction(String tsID) async {
    await FirebaseFirestore.instance
        .collection('transactions')
        .doc(tsID)
        .delete();
  }

  // ==========================================
  // SAVING JAR SERVICES
  // ==========================================

  Future<List<SavingJarModel>> getSavingJars(String uID) async {
    try {
      // Fetch jars owned by user
      QuerySnapshot snap1 = await FirebaseFirestore.instance
          .collection('saving_jars')
          .where('uID', isEqualTo: uID)
          .get();

      // Fetch jars where user is a shared member
      QuerySnapshot snap2 = await FirebaseFirestore.instance
          .collection('saving_jars')
          .where('members', arrayContains: uID)
          .get();

      final Map<String, SavingJarModel> combinedJars = {};
      for (var doc in snap1.docs) {
        final jar = SavingJarModel.fromMap(doc.data() as Map<String, dynamic>);
        combinedJars[jar.jarID] = jar;
      }
      for (var doc in snap2.docs) {
        final jar = SavingJarModel.fromMap(doc.data() as Map<String, dynamic>);
        combinedJars[jar.jarID] = jar;
      }

      return combinedJars.values.toList();
    } catch (e) {
      debugPrint("Error fetching saving jars: $e");
      return [];
    }
  }

  Future<SavingJarModel> addSavingJar(SavingJarModel jar) async {
    String id = _uuid.v4();
    SavingJarModel newJar = jar.copyWith(jarID: id);
    await FirebaseFirestore.instance
        .collection('saving_jars')
        .doc(id)
        .set(newJar.toMap());
    return newJar;
  }

  Future<void> updateSavingJar(SavingJarModel jar) async {
    await FirebaseFirestore.instance
        .collection('saving_jars')
        .doc(jar.jarID)
        .update(jar.toMap());
  }

  Future<void> deleteSavingJar(String jarID) async {
    await FirebaseFirestore.instance
        .collection('saving_jars')
        .doc(jarID)
        .delete();
  }

  // ==========================================
  // BUDGET SERVICES
  // ==========================================

  Future<BudgetModel?> getBudget(String uID, DateTime date) async {
    try {
      DateTime startOfMonth = DateTime(date.year, date.month, 1);
      DateTime endOfMonth = DateTime(
        date.year,
        date.month + 1,
        1,
      ).subtract(const Duration(seconds: 1));

      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('budgets')
          .where('uID', isEqualTo: uID)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return BudgetModel.fromMap(
          snap.docs.first.data() as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint("Error fetching budget: $e");
    }
    return null;
  }

  Future<BudgetModel> setBudget(BudgetModel budget) async {
    String id = budget.bgID.isEmpty ? _uuid.v4() : budget.bgID;
    BudgetModel newBudget = budget.copyWith(bgID: id);
    await FirebaseFirestore.instance
        .collection('budgets')
        .doc(id)
        .set(newBudget.toMap());
    return newBudget;
  }

  // ==========================================
  // LOANS AND DEBTS SERVICES
  // ==========================================

  Future<List<LoanModel>> getLoans(String uID) async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('loans')
          .where('uID', isEqualTo: uID)
          .get();
      final loans = snap.docs
          .map((doc) => LoanModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      loans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return loans;
    } catch (e) {
      debugPrint("Error fetching loans: $e");
      return [];
    }
  }

  Future<LoanModel> addLoan(LoanModel loan) async {
    String id = _uuid.v4();
    LoanModel newLoan = loan.copyWith(loanID: id);
    await FirebaseFirestore.instance
        .collection('loans')
        .doc(id)
        .set(newLoan.toMap());
    return newLoan;
  }

  Future<void> updateLoan(LoanModel loan) async {
    await FirebaseFirestore.instance
        .collection('loans')
        .doc(loan.loanID)
        .update(loan.toMap());
  }

  Future<void> deleteLoan(String loanID) async {
    await FirebaseFirestore.instance.collection('loans').doc(loanID).delete();
  }

  // ==========================================
  // ADMIN SERVICES
  // ==========================================

  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('users')
          .get();
      final users = snap.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    } catch (e) {
      debugPrint("Error fetching all users: $e");
      return [];
    }
  }

  Future<void> updateUserRole(String targetUid, String newRole) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .update({'role': newRole});
      _userCache.remove(targetUid);
    } catch (e) {
      debugPrint("Error updating user role: $e");
      rethrow;
    }
  }

  Future<void> deleteUser(String targetUid) async {
    try {
      // 1. Delete user document from 'users'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .delete();

      // 2. Clean up user's categories
      final categoriesSnap = await FirebaseFirestore.instance
          .collection('categories')
          .where('uID', isEqualTo: targetUid)
          .get();
      for (var doc in categoriesSnap.docs) {
        await doc.reference.delete();
      }

      // 3. Clean up user's transactions
      final txSnap = await FirebaseFirestore.instance
          .collection('transactions')
          .where('uID', isEqualTo: targetUid)
          .get();
      for (var doc in txSnap.docs) {
        await doc.reference.delete();
      }

      // 4. Clean up user's saving jars
      final jarsSnap = await FirebaseFirestore.instance
          .collection('saving_jars')
          .where('uID', isEqualTo: targetUid)
          .get();
      for (var doc in jarsSnap.docs) {
        await doc.reference.delete();
      }

      // 5. Clean up user's budgets
      final budgetsSnap = await FirebaseFirestore.instance
          .collection('budgets')
          .where('uID', isEqualTo: targetUid)
          .get();
      for (var doc in budgetsSnap.docs) {
        await doc.reference.delete();
      }

      // 6. Clean up user's loans
      final loansSnap = await FirebaseFirestore.instance
          .collection('loans')
          .where('uID', isEqualTo: targetUid)
          .get();
      for (var doc in loansSnap.docs) {
        await doc.reference.delete();
      }

      _userCache.remove(targetUid);
    } catch (e) {
      debugPrint("Error deleting user and associated data: $e");
      rethrow;
    }
  }

  Future<Map<String, int>> getSystemStats() async {
    try {
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .get();
      final txSnap = await FirebaseFirestore.instance
          .collection('transactions')
          .get();
      final jarsSnap = await FirebaseFirestore.instance
          .collection('saving_jars')
          .get();
      final loansSnap = await FirebaseFirestore.instance
          .collection('loans')
          .get();

      return {
        'totalUsers': usersSnap.docs.length,
        'totalTransactions': txSnap.docs.length,
        'totalJars': jarsSnap.docs.length,
        'totalLoans': loansSnap.docs.length,
      };
    } catch (e) {
      debugPrint("Error fetching system stats: $e");
      return {
        'totalUsers': 0,
        'totalTransactions': 0,
        'totalJars': 0,
        'totalLoans': 0,
      };
    }
  }
}
