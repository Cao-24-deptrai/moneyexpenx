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

  Future<UserModel?> signUp(String username, String email, String password) async {
    try {
      UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        String uid = credential.user!.uid;
        UserModel newUser = UserModel(
          uID: uid,
          username: username,
          email: email,
          createdAt: DateTime.now(),
        );
        
        // Use a Firestore Batch to create both the user doc and default categories atomically
        final batch = FirebaseFirestore.instance.batch();
        
        // 1. Create user document
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
        batch.set(userDocRef, newUser.toMap());
        
        // 2. Define and seed default categories
        final defaultCategories = [
          {'name': 'Lương', 'type': 'Thu', 'iconKey': 'work'},
          {'name': 'Đầu tư', 'type': 'Thu', 'iconKey': 'trending_up'},
          {'name': 'Ăn uống', 'type': 'Chi', 'iconKey': 'restaurant'},
          {'name': 'Di chuyển', 'type': 'Chi', 'iconKey': 'directions_car'},
          {'name': 'Mua sắm', 'type': 'Chi', 'iconKey': 'shopping_bag'},
          {'name': 'Giải trí', 'type': 'Chi', 'iconKey': 'sports_esports'},
          {'name': 'Y tế & Sức khỏe', 'type': 'Chi', 'iconKey': 'medical_services'},
          {'name': 'Giáo dục', 'type': 'Chi', 'iconKey': 'school'},
          {'name': 'Nhà cửa', 'type': 'Chi', 'iconKey': 'home'},
          {'name': 'Cà phê', 'type': 'Chi', 'iconKey': 'coffee'},
        ];
        
        for (var cat in defaultCategories) {
          final catDocRef = FirebaseFirestore.instance.collection('categories').doc();
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
      UserCredential credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        String uid = credential.user!.uid;
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        } else {
          // Fallback if user doc was not created, create a default one to prevent crash
          UserModel fallbackUser = UserModel(
            uID: uid,
            username: credential.user!.displayName ?? email.split('@').first,
            email: email,
            createdAt: DateTime.now(),
          );
          await FirebaseFirestore.instance.collection('users').doc(uid).set(fallbackUser.toMap());
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
        return UserModel.fromMap(snap.docs.first.data() as Map<String, dynamic>);
      }
      
      // Fallback lookup with lowercased email
      QuerySnapshot snapLower = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      if (snapLower.docs.isNotEmpty) {
        return UserModel.fromMap(snapLower.docs.first.data() as Map<String, dynamic>);
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
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
      return snap.docs.map((doc) => CategoryModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      return [];
    }
  }

  Future<CategoryModel> addCategory(CategoryModel category) async {
    String id = _uuid.v4();
    CategoryModel newCat = category.copyWith(ctgID: id);
    await FirebaseFirestore.instance.collection('categories').doc(id).set(newCat.toMap());
    return newCat;
  }

  Future<void> updateCategory(CategoryModel category) async {
    await FirebaseFirestore.instance.collection('categories').doc(category.ctgID).update(category.toMap());
  }

  Future<void> deleteCategory(String ctgID) async {
    await FirebaseFirestore.instance.collection('categories').doc(ctgID).delete();
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
      return snap.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
      return [];
    }
  }

  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    String id = _uuid.v4();
    TransactionModel newTx = transaction.copyWith(tsID: id);
    await FirebaseFirestore.instance.collection('transactions').doc(id).set(newTx.toMap());
    return newTx;
  }

  Future<void> deleteTransaction(String tsID) async {
    await FirebaseFirestore.instance.collection('transactions').doc(tsID).delete();
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
    await FirebaseFirestore.instance.collection('saving_jars').doc(id).set(newJar.toMap());
    return newJar;
  }

  Future<void> updateSavingJar(SavingJarModel jar) async {
    await FirebaseFirestore.instance.collection('saving_jars').doc(jar.jarID).update(jar.toMap());
  }

  Future<void> deleteSavingJar(String jarID) async {
    await FirebaseFirestore.instance.collection('saving_jars').doc(jarID).delete();
  }

  // ==========================================
  // BUDGET SERVICES
  // ==========================================

  Future<BudgetModel?> getBudget(String uID, DateTime date) async {
    try {
      DateTime startOfMonth = DateTime(date.year, date.month, 1);
      DateTime endOfMonth = DateTime(date.year, date.month + 1, 1).subtract(const Duration(seconds: 1));

      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('budgets')
          .where('uID', isEqualTo: uID)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return BudgetModel.fromMap(snap.docs.first.data() as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("Error fetching budget: $e");
    }
    return null;
  }

  Future<BudgetModel> setBudget(BudgetModel budget) async {
    String id = budget.bgID.isEmpty ? _uuid.v4() : budget.bgID;
    BudgetModel newBudget = budget.copyWith(bgID: id);
    await FirebaseFirestore.instance.collection('budgets').doc(id).set(newBudget.toMap());
    return newBudget;
  }
}
