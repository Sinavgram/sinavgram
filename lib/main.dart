// main.dart

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math'; 

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:archive/archive_io.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

// FIREBASE GEREKSİNİMLERİ
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';

// --- BAŞARIM KONFİGÜRASYONU ---
class AchievementConfig {
  static const List<Map<String, dynamic>> categories = [
    {'id': 'divanu_lugati', 'name': 'Divanü Lügati\'t-Türk', 'courseIds': ['6', '7'], 'symbol': 'D'},
    {'id': 'pisagor', 'name': 'Pisagor', 'courseIds': ['3', '4'], 'symbol': 'P'},
    {'id': 'newton', 'name': 'Isaac Newton', 'courseIds': ['1'], 'symbol': 'I'},
    {'id': 'cabir', 'name': 'Cabir bin Hayyan', 'courseIds': ['2'], 'symbol': 'C'},
    {'id': 'aristoteles', 'name': 'Aristoteles', 'courseIds': ['5'], 'symbol': 'A'},
    {'id': 'heredotos', 'name': 'Heredotos', 'courseIds': ['9'], 'symbol': 'H'},
    {'id': 'eratosthenes', 'name': 'Eratosthenes', 'courseIds': ['8'], 'symbol': 'E'},
    {'id': 'sokrates', 'name': 'Sokrates', 'courseIds': ['10', '11'], 'symbol': 'S'},
  ];

  static const List<Map<String, dynamic>> levels = [
    {'id': 'bronz', 'name': 'Bronz', 'threshold': 50, 'color': Color(0xFFCD7F32)}, // Bronz Renk
    {'id': 'gumus', 'name': 'Gümüş', 'threshold': 100, 'color': Color(0xFFC0C0C0)}, // Gümüş Renk
    {'id': 'altin', 'name': 'Altın', 'threshold': 250, 'color': Color(0xFFFFD700)}, // Altın Renk
    {'id': 'elmas', 'name': 'Elmas', 'threshold': 500, 'color': Color(0xFF00E5FF)}, // Elmas Renk
  ];

  // Yeni Seriler ve Özel Rozetler
  static const List<Map<String, dynamic>> series = [
    {'id': 'ciraklik', 'name': 'Çıraklık Serisi', 'target': 15, 'desc': '15 gün boyunca günlük 10 doğru', 'icon': 'assets/icons/ciraklik.ico'},
    {'id': 'disiplin', 'name': 'Disiplin Serisi', 'target': 50, 'desc': '50 gün boyunca günlük 10 doğru', 'icon': 'assets/icons/disiplin.ico'},
    {'id': 'odak', 'name': 'Odaklanmış Zihin', 'target': 100, 'desc': '100 gün boyunca günlük 10 doğru', 'icon': 'assets/icons/odak.ico'},
    {'id': 'maraton', 'name': 'Maraton Koşucusu', 'target': 200, 'desc': '200 gün boyunca günlük 10 doğru', 'icon': 'assets/icons/maraton.ico'},
  ];
  
  static const Map<String, dynamic> librarian = {
    'id': 'kutuphaneci', 'name': 'Kütüphaneci', 'desc': 'Tüm PDF\'leri okuma', 'icon': 'assets/icons/kutuphane.ico'
  };

  // Yeni: Puana Dayalı Rütbeler
  static const List<Map<String, dynamic>> ranks = [
    {'id': 'caylak', 'name': 'Çaylak', 'threshold': 0, 'icon': 'assets/icons/caylak.ico'},
    {'id': 'odaklanmis', 'name': 'Odaklanmış', 'threshold': 100000, 'icon': 'assets/icons/odaklanmis.ico'},
    {'id': 'uzman', 'name': 'Uzman', 'threshold': 500000, 'icon': 'assets/icons/uzman.ico'},
    {'id': 'master', 'name': 'Master', 'threshold': 1000000, 'icon': 'assets/icons/master.ico'},
    {'id': 'efsane', 'name': 'Efsane', 'threshold': 2000000, 'icon': 'assets/icons/efsane.ico'},
    {'id': 'yenilmez', 'name': 'Yenilmez', 'threshold': 5000000, 'icon': 'assets/icons/yenilmez.ico'},
  ];
}

// --- YEREL OTURUM SERVİSİ (JSON KAYIT) ---
class LocalSessionService {
  static const String _sessionKey = 'user_local_session';

  static Map<String, dynamic> _sanitizeData(Map<dynamic, dynamic> data) {
    final sanitized = <String, dynamic>{};
    data.forEach((key, value) {
      final String strKey = key.toString(); 
      if (value is Timestamp) {
        sanitized[strKey] = value.toDate().toIso8601String();
      } else if (value is FieldValue) {
        sanitized[strKey] = DateTime.now().toIso8601String(); 
      } else if (value is Map) {
        sanitized[strKey] = _sanitizeData(value);
      } else if (value is List) {
        sanitized[strKey] = value.map((e) {
          if (e is Timestamp) return e.toDate().toIso8601String();
          if (e is FieldValue) return DateTime.now().toIso8601String();
          if (e is Map) return _sanitizeData(e);
          return e;
        }).toList();
      } else if (value is DateTime) {
        sanitized[strKey] = value.toIso8601String();
      } else {
        sanitized[strKey] = value;
      }
    });
    return sanitized;
  }

  static Future<void> saveSession(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleanData = _sanitizeData(userData); 
      await prefs.setString(_sessionKey, json.encode(cleanData));
    } catch (e) {
      debugPrint("Yerel oturum kayıt hatası: $e");
    }
  }

  static Future<Map<String, dynamic>?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_sessionKey);
      if (dataString != null && dataString.isNotEmpty) {
        return json.decode(dataString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("Yerel oturum okuma hatası (Veri sıfırlanıyor): $e");
      await clearSession(); 
    }
    return null;
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (e) {
      debugPrint("Oturum temizleme hatası: $e");
    }
  }
}

// --- REKLAM SERVİSİ ---
class AdService {
  InterstitialAd? _interstitialAd;
  static const String _quizExitCountKey = 'quiz_exit_count';

  static final String bannerAdUnitId = Platform.isAndroid
    ? 'ca-app-pub-3940256099942544/6300978111'
    : 'ca-app-pub-3940256099942544/2934735716';

  static final String interstitialAdUnitId = Platform.isAndroid
    ? 'ca-app-pub-3940256099942544/1033173712'
    : 'ca-app-pub-3940256099942544/4411468910'; 

  Future<bool> shouldShowAdOnQuizExit() async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(_quizExitCountKey) ?? 0;
    currentCount++;

    if (currentCount >= 3) {
      await prefs.setInt(_quizExitCountKey, 0); 
      return true; 
    } else {
      await prefs.setInt(_quizExitCountKey, currentCount); 
      return false; 
    }
  }

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (err) {
          debugPrint('InterstitialAd yüklenemedi: $err');
        },
      ),
    );
  }
  
  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          loadInterstitialAd();
        }
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
        loadInterstitialAd();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}

// --- BANNER REKLAM WIDGET'I ---
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isPremium = context.watch<UserProvider>().isPremium;
    if (!isPremium) {
      _loadAd();
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd yüklenemedi: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

// --- KULLANICI VERİ YÖNETİMİ (PROVIDER) ---
class UserProvider with ChangeNotifier {
  Map<String, dynamic> _userData = {};

  Map<String, dynamic> get userData => _userData;
  int get score => _userData['score'] ?? 0;
  String get username => _userData['username'] ?? 'Kullanıcı';
  Map<String, dynamic> get archivedScores => _userData['archived_scores'] as Map<String, dynamic>? ?? {};
  String? get avatarUrl => _userData['avatar_url'];
  
  int? get rank => _userData['rank'] ?? 'caylak';
  int? get totalUsers => _userData['total_users'];
  List<dynamic> get badges => _userData['badges'] as List<dynamic>? ?? [];
  
  Map<String, dynamic> get courseProgress => _userData['course_progress'] as Map<String, dynamic>? ?? {};
  List<dynamic> get solvedQuestions => _userData['solved_questions'] as List<dynamic>? ?? [];

  // YENİ: Seri ve PDF verileri
  int get currentStreak => _userData['current_streak'] ?? 0;
  List<dynamic> get readPdfs => _userData['read_pdfs'] as List<dynamic>? ?? [];

  // YENİ: Rütbeler
  List<dynamic> get earnedRanks => _userData['earned_ranks'] as List<dynamic>? ?? ['caylak'];

  bool get isPremium => false; 
  bool get isIncognito => _userData['is_incognito'] ?? false;

  void setUser(Map<String, dynamic> userData) {
    _userData = userData;
    notifyListeners();
  }

  void updateScore(int newScore) {
    _userData['score'] = newScore;
    notifyListeners();
  }
    
  void updateUserPartial(Map<String, dynamic> data) {
      _userData['username'] = data['username'] ?? _userData['username'];
      _userData['avatar_url'] = data['avatar_url'] ?? _userData['avatar_url'];
      notifyListeners();
  }
  
  void addSolvedQuestion(String questionId) {
    final list = List<dynamic>.from(_userData['solved_questions'] ?? []);
    if (!list.contains(questionId)) {
      list.add(questionId);
      _userData['solved_questions'] = list;
      notifyListeners();
    }
  }

  void incrementCourseProgress(String courseId) {
    if (courseId.isEmpty) return;
    final progress = Map<String, dynamic>.from(courseProgress);
    progress[courseId] = (progress[courseId] ?? 0) + 1;
    _userData['course_progress'] = progress;
    notifyListeners();
  }

  // YENİ: PDF Okundu Olarak Ekle
  void addReadPdf(String url) {
    final list = List<dynamic>.from(readPdfs);
    if (!list.contains(url)) {
      list.add(url);
      _userData['read_pdfs'] = list;
      notifyListeners();
    }
  }
}

// --- GÜNLÜK HEDEF SERVİSİ ---
class DailyGoalService {
  static const String _goalKey = 'daily_goal';
  static const String _countKey = 'daily_solved_count';
  static const String _dateKey = 'daily_count_date';

  static Future<void> setGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalKey, goal);
  }

  static Future<int> getGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_goalKey) ?? 100;
  }

  static Future<int> getSolvedCount() async {
    await _resetIfNewDay();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_countKey) ?? 0;
  }

  static Future<void> incrementSolvedCount() async {
    await _resetIfNewDay();
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(_countKey) ?? 0;
    await prefs.setInt(_countKey, currentCount + 1);
  }

  static Future<void> _resetIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString(_dateKey);

    if (lastDate != today) {
      await prefs.setInt(_countKey, 0);
      await prefs.setString(_dateKey, today);
    }
  }
}

// --- YEREL ANALİZ SERVİSİ ---
class LocalAnalyticsService {
  static const String _recordsKey = 'analytics_records';

  static Future<void> addAnswerRecord({
    required String courseId,
    required String courseName,
    required String subtopicName,
    String? subtopicId,
    String? pdfUrl,
    required bool isCorrect,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final newRecord = {
      'course_id': courseId.toString(), 
      'course_name': courseName.toString(),
      'subtopic_name': subtopicName.toString(),
      'subtopic_id': subtopicId?.toString(),
      'pdf_url': pdfUrl?.toString(),
      'is_correct': isCorrect,
      'timestamp': DateTime.now().toIso8601String(),
    };

    List<dynamic> records = await getRecords();
    records.add(newRecord);
    
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    records.removeWhere((r) => DateTime.parse(r['timestamp']).isBefore(thirtyDaysAgo));

    await prefs.setString(_recordsKey, json.encode(records));
  }

  static Future<List<dynamic>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsString = prefs.getString(_recordsKey);
    if (recordsString != null) {
      return json.decode(recordsString) as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>?> analyzeWeakestCourse() async {
    List<dynamic> records = await getRecords();
    if (records.isEmpty) return null;

    final incorrectCounts = <String, Map<String, dynamic>>{};
    
    for (var record in records) {
      if (record['is_correct'] == false) {
        final String courseId = record['course_id']?.toString() ?? '';
        
        if (courseId.isNotEmpty) {
          final String key = record['course_name']?.toString() ?? courseId;
          incorrectCounts[key] = {
            'count': (incorrectCounts[key]?['count'] ?? 0) + 1,
            'course_id': courseId,
            'course_name': key,
          };
        }
      }
    }

    if (incorrectCounts.isEmpty) return null;
    var weakest = incorrectCounts.values.reduce((a, b) => a['count'] > b['count'] ? a : b);

    if (weakest['course_name'] == weakest['course_id']) {
      weakest['course_name'] = await FirebaseService.getCourseNameById(weakest['course_id']);
    }

    return weakest;
  }

  static Future<Map<String, dynamic>?> analyzeWeakestSubtopicLast7Days() async {
    List<dynamic> records = await getRecords();
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final recentRecords = records.where((r) {
      final timestamp = DateTime.parse(r['timestamp']);
      return timestamp.isAfter(sevenDaysAgo);
    }).toList();

    if (recentRecords.isEmpty) return null;

    final incorrectCounts = <String, Map<String, dynamic>>{};
    for (var record in recentRecords) {
      if (record['is_correct'] == false && record['subtopic_name'] != null && record['pdf_url'] != null) {
        final subtopic = record['subtopic_name'] as String;
        incorrectCounts[subtopic] = {
          'count': (incorrectCounts[subtopic]?['count'] ?? 0) + 1,
          'pdf_url': record['pdf_url'],
          'subtopic_name': subtopic,
        };
      }
    }

    if (incorrectCounts.isEmpty) return null;

    final weakestSubtopic = incorrectCounts.values.reduce((a, b) => a['count'] > b['count'] ? a : b);
    return weakestSubtopic;
  }
}

// --- AYARLAR SERVİSİ ---
class SettingsService {
  static const String _themeColorKey = 'theme_color';
  static const String _darkModeKey = 'dark_mode';

  static Future<void> setThemeColor(String colorName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeColorKey, colorName);
  }

  static Future<String> getThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeColorKey) ?? 'Mor';
  }

  static Future<void> setDarkModeEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isEnabled);
  }

  static Future<bool> getDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }
}

// --- TEMA YÖNETİCİSİ (PROVIDER) ---
class ThemeNotifier with ChangeNotifier {
  ThemeData _themeData;
  ThemeData _darkThemeData; // YENİ
  bool _isDarkMode; // YENİ

  ThemeData get themeData => _themeData;
  ThemeData get darkThemeData => _darkThemeData; // YENİ
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light; // YENİ

  // Constructor güncellendi
  ThemeNotifier(this._themeData, this._darkThemeData, this._isDarkMode);

  static final Map<String, Color> themeColors = {
    'Mor': Colors.deepPurple,
    'Mavi': Colors.blue,
    'Yeşil': Colors.green,
  };
  
  // Metod güncellendi: isDark parametresi eklendi
  static ThemeData _createThemeData(Color primaryColor, {bool isDark = false}) {
     final brightness = isDark ? Brightness.dark : Brightness.light;
     return ThemeData(
        brightness: brightness,
        primarySwatch: primaryColor as MaterialColor,
        primaryColor: primaryColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: isDark ? Colors.grey[850] : primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
        cardTheme: CardThemeData(
          color: isDark ? Colors.grey[800] : Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16)
        )
      );
  }

  void setTheme(String colorName) async {
    final color = themeColors[colorName] ?? Colors.deepPurple;
    _themeData = _createThemeData(color, isDark: false);
    _darkThemeData = _createThemeData(color, isDark: true); // YENİ
    await SettingsService.setThemeColor(colorName);
    notifyListeners();
  }

  // YENİ METOD: Karanlık mod geçişini tetikler
  void toggleDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await SettingsService.setDarkModeEnabled(isDark);
    notifyListeners();
  }
}

// --- FIREBASE SERVİSİ ---
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _googleSignInInitialized = false;
  static String? get _uid => _auth.currentUser?.uid;

  // YENİ (google_sign_in v7+): Artık initialize() bir kere çağrılmadan
  // GoogleSignIn.instance üzerinde başka hiçbir metod kullanılamıyor.
  static Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize(
      // Firebase ile giriş için Firebase konsolundaki Web İstemci Kimliğini
      // (Web client ID) buraya girin. Bu, Firebase'in idToken'ı doğrulayabilmesi için gereklidir.
      // serverClientId: 'FIREBASE_WEB_CLIENT_ID.apps.googleusercontent.com',
    );
    _googleSignInInitialized = true;
  }

  static String getFullUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) {
      return 'https://placehold.co/100x100/663399/FFFFFF?text=SG'; 
    }
    return relativeUrl;
  }

  static String _translateAuthError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email': return 'Geçersiz bir e-posta adresi girdiniz.';
      case 'weak-password': return 'Şifre çok zayıf (En az 6 karakter olmalı).';
      case 'user-not-found': return 'Bu e-posta adresine ait bir hesap bulunamadı.';
      case 'wrong-password': return 'Hatalı şifre girdiniz.';
      case 'invalid-credential': return 'E-posta adresiniz veya şifreniz hatalı.';
      case 'network-request-failed': return 'İnternet bağlantınızı kontrol edip tekrar deneyin.';
      case 'too-many-requests': return 'Çok fazla başarısız deneme yaptınız. Lütfen daha sonra tekrar deneyin.';
      default: return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  // --- AUTHENTICATION ---
  static Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      if (userCredential.user != null) {
        try {
          await userCredential.user!.sendEmailVerification();
        } catch (e) {
          debugPrint("Doğrulama maili gönderilemedi: $e");
        }

        final userData = {
          'id': userCredential.user!.uid,
          'username': username,
          'email': email,
          'avatar_url': null,
          'score': 0,
          'archived_scores': {},
          'created_at': FieldValue.serverTimestamp(),
          'liked_questions': [],
          'saved_questions': [],
          'solved_questions': [], 
          'course_progress': {}, 
          'total_answered': 0,
          'correct_answered': 0,
          'wrong_answered': 0,
          // Seriler ve Yeni Başarımlar İçin Yeni Alanlar
          'last_active_date': '',
          'last_goal_met_date': '',
          'today_correct_count': 0,
          'current_streak': 0,
          'read_pdfs': [],
          'earned_ranks': ['caylak'],
        };
        
        await _db.collection('users').doc(userCredential.user!.uid).set(userData);

        try {
          await _db.collection('mail').add({
            'to': email,
            'message': {
              'subject': 'Sınavgram\'a Hoş Geldin, $username! 🎉',
              'html': '''
                <div style="font-family: Arial, sans-serif; text-align: center; color: #333;">
                  <h1 style="color: #673AB7;">Sınavgram'a Hoş Geldin!</h1>
                  <p>Sınav yolculuğunda sana eşlik edeceğimiz için çok heyecanlıyız.</p>
                  <p>Sisteme giriş yaptıktan sonra ilk testini çözerek puan kazanmaya başlayabilirsin.</p>
                  <br>
                  <p>Başarılar dileriz,<br><strong>Sınavgram Ekibi</strong></p>
                </div>
              '''
            }
          });
        } catch (e) {
          debugPrint("Hoş geldin maili sıraya alınamadı: $e");
        }

        return {'requires_verification': true, 'email': email};
      }
      throw Exception("Kullanıcı oluşturulamadı.");
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateAuthError(e.code));
    } catch (e) {
      throw Exception("Beklenmeyen bir hata oluştu: $e");
    }
  }

  static void _logError(String title, dynamic e, StackTrace stack) {
    debugPrint('🔥 [FIREBASE ERROR - $title] 🔥');
    debugPrint('Mesaj: $e');
    if (e is FirebaseAuthException) {
      debugPrint('Kod: ${e.code}');
      debugPrint('Detay: ${e.message}');
    }
    debugPrint('Stacktrace: $stack');
    debugPrint('--------------------------');
  }

  static List<String> _calculateRanksBasedOnScore(int score) {
    List<String> earned = ['caylak']; // 0 Puan ve üstü
    
    if (score >= 100000) earned.add('odaklanmis');
    if (score >= 500000) earned.add('uzman');
    if (score >= 1000000) earned.add('master');
    if (score >= 2000000) earned.add('efsane');
    if (score >= 5000000) earned.add('yenilmez');
    
    return earned;
  }

  static Future<void> _ensureDocumentIsUpToDate(String uid, Map<String, dynamic> currentData) async {
    Map<String, dynamic> updates = {};
    
    // 1. Kullanıcının MEVCUT puanını al (Eğer puanı yoksa 0 kabul et)
    int currentScore = currentData['score'] ?? 0;
    
    // 2. Puanına uygun rütbe listesini hesapla
    List<String> calculatedRanks = _calculateRanksBasedOnScore(currentScore);

    // 3. Eksik alanları kontrol et ve doldur
    if (!currentData.containsKey('archived_scores')) updates['archived_scores'] = {};
    if (!currentData.containsKey('course_progress')) updates['course_progress'] = {};
    if (!currentData.containsKey('last_active_date')) updates['last_active_date'] = '';
    if (!currentData.containsKey('last_goal_met_date')) updates['last_goal_met_date'] = '';
    if (!currentData.containsKey('today_correct_count')) updates['today_correct_count'] = 0;
    if (!currentData.containsKey('current_streak')) updates['current_streak'] = 0;
    if (!currentData.containsKey('read_pdfs')) updates['read_pdfs'] = [];
    if (!currentData.containsKey('is_incognito')) updates['is_incognito'] = false;
    
    // 4. Rütbeler kısmı eksikse hak ettiği rütbeleri ver
    if (!currentData.containsKey('earned_ranks')) {
      updates['earned_ranks'] = calculatedRanks;
    }

    // 5. Eğer güncellenecek eksik bir alan bulunduysa veritabanına yaz
    if (updates.isNotEmpty) {
      try {
        await _db.collection('users').doc(uid).update(updates);
        debugPrint("Kullanıcı güncellendi ($uid). Verilen rütbeler: $calculatedRanks");
      } catch (e) {
        debugPrint("Migrasyon hatası: $e");
      }
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      if (userCredential.user != null) {
        if (!userCredential.user!.emailVerified) {
          return {'email_not_verified': true, 'email': email};
        }

        final doc = await _db.collection('users').doc(userCredential.user!.uid).get().timeout(const Duration(seconds: 10));
        final userData = {'id': doc.id, ...?doc.data()};
        
        await LocalSessionService.saveSession(userData);
        
        return {'user': userData, 'token': 'firebase_handles_token'};
      }
      throw Exception("Giriş yapılamadı.");
    } on TimeoutException {
      throw Exception("Bağlantı zaman aşımına uğradı. İnternetinizi kontrol edin.");
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateAuthError(e.code));
    } catch (e) {
      throw Exception("Beklenmeyen bir hata oluştu.");
    }
  }

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      // YENİ (google_sign_in v7+): signIn() kaldırıldı, yerine authenticate() geldi.
      // Kullanıcı girişi iptal ederse artık null dönmüyor, GoogleSignInException fırlatıyor
      // (code: GoogleSignInExceptionCode.canceled) — bu yüzden aşağıdaki catch bloğunda ele alınıyor.
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // YENİ: authentication artık senkron ve sadece idToken içeriyor
      // (accessToken ayrı bir yetkilendirme adımına taşındı). Firebase girişi
      // için idToken tek başına yeterli.
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final doc = await _db.collection('users').doc(uid).get().timeout(const Duration(seconds: 10));
        final userEmail = userCredential.user!.email;

        if (!doc.exists) {
          final userData = {
            'id': uid,
            'username': userCredential.user!.displayName ?? 'Kullanıcı',
            'email': userCredential.user!.email,
            'avatar_url': userCredential.user!.photoURL,
            'score': 0,
            'archived_scores': {},
            'created_at': FieldValue.serverTimestamp(),
            'liked_questions': [],
            'saved_questions': [],
            'solved_questions': [], 
            'course_progress': {}, 
            'total_answered': 0,
            'correct_answered': 0,
            'wrong_answered': 0,
            'is_subscribed': true,
            'last_active_date': '',
            'last_goal_met_date': '',
            'today_correct_count': 0,
            'current_streak': 0,
            'read_pdfs': [],
            'earned_ranks': ['caylak'],
          };
          
          await _db.collection('users').doc(uid).set(userData);
          await LocalSessionService.saveSession(userData);

          if (userEmail != null) {
            try { await subscribeToNewsletter(userEmail); } catch(e){}
          }
          
          return {'user': userData, 'isNewUser': true};
        } else {
          final existingData = {'id': doc.id, ...?doc.data()};
          await LocalSessionService.saveSession(existingData);
          return {'user': existingData, 'isNewUser': false};
        }
      }
      throw Exception("Giriş yapılamadı.");
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception("Google ile giriş iptal edildi.");
      }
      throw Exception("Google ile giriş yapılamadı: ${e.description ?? e.code}");
    } on TimeoutException {
      throw Exception("Bağlantı zaman aşımına uğradı. İnternetinizi kontrol edin.");
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateAuthError(e.code));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- APPLE SIGN-IN METODU ---
  static String _generateNonce([int length = 32]) {
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static Future<Map<String, dynamic>> signInWithApple() async {
    try {
      final String rawNonce = _generateNonce();
      final String hashNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      if (Platform.isIOS) {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashNonce,
        );

        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
          rawNonce: rawNonce,
        );
        return await _handleAppleCredential(oauthCredential, appleCredential);

      } else {
        final provider = OAuthProvider('apple.com')
          ..addScope('email')
          ..addScope('name');

        final userCredential = await _auth.signInWithProvider(provider);

        if (userCredential.user != null) {
          final uid = userCredential.user!.uid;
          final doc = await _db
              .collection('users')
              .doc(uid)
              .get()
              .timeout(const Duration(seconds: 10));

          if (!doc.exists) {
            final userData = {
              'id': uid,
              'username': userCredential.user!.displayName ?? 'Kullanıcı',
              'email': userCredential.user!.email,
              'avatar_url': userCredential.user!.photoURL,
              'score': 0,
              'archived_scores': {},
              'created_at': FieldValue.serverTimestamp(),
              'liked_questions': [],
              'saved_questions': [],
              'solved_questions': [],
              'course_progress': {},
              'total_answered': 0,
              'correct_answered': 0,
              'wrong_answered': 0,
              'is_subscribed': true,
              'last_active_date': '',
              'last_goal_met_date': '',
              'today_correct_count': 0,
              'current_streak': 0,
              'read_pdfs': [],
              'earned_ranks': ['caylak'],
            };
            await _db.collection('users').doc(uid).set(userData);
            await LocalSessionService.saveSession(userData);
            return {'user': userData, 'isNewUser': true};
          } else {
            final existingData = {'id': doc.id, ...?doc.data()};
            await LocalSessionService.saveSession(existingData);
            return {'user': existingData, 'isNewUser': false};
          }
        }
        throw Exception("Apple ile giriş yapılamadı.");
      }
    } on TimeoutException {
      throw Exception("Bağlantı zaman aşımına uğradı.");
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateAuthError(e.code));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> _handleAppleCredential(
    OAuthCredential oauthCredential,
    AuthorizationCredentialAppleID appleCredential,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final doc = await _db
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 10));

        if (!doc.exists) {
        String username = 'Kullanıcı';
        if (appleCredential.givenName != null || appleCredential.familyName != null) {
          username = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        } else if (userCredential.user!.displayName != null) {
          username = userCredential.user!.displayName!;
        }

        final userData = {
          'id': uid,
          'username': username,
          'email': userCredential.user!.email,
          'avatar_url': userCredential.user!.photoURL,
          'score': 0,
          'archived_scores': {},
          'created_at': FieldValue.serverTimestamp(),
          'liked_questions': [],
          'saved_questions': [],
          'solved_questions': [],
          'course_progress': {},
          'total_answered': 0,
          'correct_answered': 0,
          'wrong_answered': 0,
          'is_subscribed': true,
          'last_active_date': '',
          'last_goal_met_date': '',
          'today_correct_count': 0,
          'current_streak': 0,
          'read_pdfs': [],
          'earned_ranks': ['caylak'],
        };
          await _db.collection('users').doc(uid).set(userData);
          return {'user': userData, 'isNewUser': true};
        } else {
          final existingData = {'id': doc.id, ...?doc.data()};
          return {'user': existingData, 'isNewUser': false};
        }
      }
      throw Exception("User null döndü.");
    } catch (e, stack) {
      _logError('Apple_Sign_In_Flow', e, stack);
      rethrow;
    }
  }

  static Future<void> updateNewsletterSubscription(bool isSubscribed) async {
    if (_uid == null || _auth.currentUser?.email == null) return;
    String email = _auth.currentUser!.email!;

    if (isSubscribed) {
      await subscribeToNewsletter(email);
    } else {
      final query = await _db.collection('newsletter_subscribers')
          .where('email', isEqualTo: email)
          .get();
      for (var doc in query.docs) {
        await doc.reference.delete();
      }
    }
    await _db.collection('users').doc(_uid).update({'is_subscribed': isSubscribed});
  }

  static Future<void> updateIncognitoStatus(bool isIncognito) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({'is_incognito': isIncognito});
  }

  static Future<void> logout() async {
    try {
      await LocalSessionService.clearSession(); 
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Çıkış yaparken hata: $e");
    }
  }
  
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'message': 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi. Lütfen gelen kutunuzu kontrol edin.'};
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateAuthError(e.code));
    } catch (e) {
      throw Exception('Şifre sıfırlama maili gönderilirken beklenmeyen bir hata oluştu.');
    }
  }

  static Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    if (_auth.currentUser != null && !_auth.currentUser!.emailVerified) {
      await _auth.currentUser!.sendEmailVerification();
      return {'message': 'Doğrulama e-postası tekrar gönderildi. Lütfen Spam klasörünüzü de kontrol edin.'};
    }
    throw Exception('Kullanıcı bulunamadı veya e-posta zaten doğrulanmış.');
  }

  static Future<void> subscribeToNewsletter(String email) async {
    await _db.collection('newsletter_subscribers').add({
      'email': email,
      'subscribed_at': FieldValue.serverTimestamp()
    });
  }

  // --- KULLANICI İŞLEMLERİ ---
  static Future<Map<String, dynamic>> getMyProfile() async {
    if (_uid == null) throw Exception("Giriş yapılı değil.");
    final doc = await _db.collection('users').doc(_uid).get().timeout(const Duration(seconds: 10));
    
    if (doc.exists) {
      Map<String, dynamic> data = doc.data()!;
      
      // Veritabanı kontrolünü yap
      await _ensureDocumentIsUpToDate(doc.id, data);
      
      // Kullanıcının puanını al
      int score = data['score'] ?? 0;
      
      // Uygulama anında çökmesin diye state'i manuel toparla
      if (!data.containsKey('earned_ranks')) {
         data['earned_ranks'] = _calculateRanksBasedOnScore(score); // Hak ettiği rütbeyi burada da verdik
         data['course_progress'] = {};
         data['archived_scores'] = {};
         data['read_pdfs'] = [];
         data['current_streak'] = 0;
         data['is_incognito'] = false;
      }

      final userData = {'id': doc.id, ...data};
      await LocalSessionService.saveSession(userData); 
      return userData;
    }
    throw Exception("Profil bulunamadı.");
  }

  static Future<Map<String, dynamic>> updateUserProfile(String? username, XFile? avatarFile) async {
    if (_uid == null) throw Exception("Giriş yapılı değil.");
    Map<String, dynamic> updates = {};

    if (username != null && username.isNotEmpty) updates['username'] = username;

    if (avatarFile != null) {
      final storageRef = _storage.ref().child('avatars/$_uid.jpg');
      await storageRef.putFile(File(avatarFile.path));
      updates['avatar_url'] = await storageRef.getDownloadURL();
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(_uid).update(updates);
    }
    
    final updatedDoc = await _db.collection('users').doc(_uid).get();
    final userData = {'id': updatedDoc.id, ...?updatedDoc.data()};
    await LocalSessionService.saveSession(userData); 
    
    return {'user': userData};
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    if (_uid == null) throw Exception("Giriş yapılı değil.");
    try {
      await LocalSessionService.clearSession(); 
      await _auth.currentUser?.delete();
      return {'message': 'Hesabınız ve verileriniz kalıcı olarak silindi.'};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Güvenlik nedeniyle, hesabınızı silmeden önce çıkış yapıp tekrar giriş yapmanız gerekmektedir.');
      }
      throw Exception(_translateAuthError(e.code));
    } catch (e) {
      throw Exception('Hesap silinirken bir sorun oluştu.');
    }
  }

static Future<String> downloadMyData() async {
    if (_uid == null) throw Exception("Giriş yapılı değil.");

    // Verileri JSON formatına uygun hale getiren yardımcı fonksiyon
    Map<String, dynamic> exportSanitize(Map<dynamic, dynamic> data) {
      final sanitized = <String, dynamic>{};
      data.forEach((key, value) {
        final String strKey = key.toString();
        if (value is Timestamp) {
          sanitized[strKey] = DateFormat('dd.MM.yyyy HH:mm:ss').format(value.toDate());
        } else if (value is FieldValue) {
          sanitized[strKey] = DateFormat('dd.MM.yyyy HH:mm:ss').format(DateTime.now());
        } else if (value is Map) {
          sanitized[strKey] = exportSanitize(value);
        } else if (value is List) {
          sanitized[strKey] = value.map((e) {
            if (e is Timestamp) return DateFormat('dd.MM.yyyy HH:mm:ss').format(e.toDate());
            if (e is FieldValue) return DateFormat('dd.MM.yyyy HH:mm:ss').format(DateTime.now());
            if (e is Map) return exportSanitize(e);
            return e;
          }).toList();
        } else if (value is DocumentReference) {
          sanitized[strKey] = value.path;
        } else if (value is DateTime) {
          sanitized[strKey] = DateFormat('dd.MM.yyyy HH:mm:ss').format(value);
        } else {
          sanitized[strKey] = value;
        }
      });
      return sanitized;
    }

    // 1. Veri Çekme İşlemleri
    final userDoc = await _db.collection('users').doc(_uid).get();
    Map<String, dynamic> userProfile = userDoc.data() ?? {};
    final String? avatarUrl = userProfile['avatar_url'];
    userProfile.remove('id');

    final stats = await getUserStats();
    final liked = await getLikedQuestions();
    final saved = await getSavedQuestions();

    final submittedSnapshot = await _db.collection('questions').where('author_id', isEqualTo: _uid).get();
    List<Map<String, dynamic>> submittedQuestions = submittedSnapshot.docs.map((doc) {
      var data = doc.data();
      data.remove('author_id');
      return {'question_id': doc.id, ...data};
    }).toList();

    final reportsSnapshot = await _db.collection('reports').where('reporter_id', isEqualTo: _uid).get();
    List<Map<String, dynamic>> reportedQuestions = reportsSnapshot.docs.map((doc) {
      var data = doc.data();
      data.remove('reporter_id');
      return {'report_id': doc.id, ...data};
    }).toList();

    final aiRequestsSnapshot = await _db.collection('ai_requests').where('user_id', isEqualTo: _uid).get();
    List<Map<String, dynamic>> aiSolutions = aiRequestsSnapshot.docs.map((doc) {
      var data = doc.data();
      data.remove('user_id');
      return {'request_id': doc.id, ...data};
    }).toList();

    aiSolutions.sort((a, b) {
      int aTime = a['created_at'] is Timestamp ? (a['created_at'] as Timestamp).millisecondsSinceEpoch : 0;
      int bTime = b['created_at'] is Timestamp ? (b['created_at'] as Timestamp).millisecondsSinceEpoch : 0;
      return bTime.compareTo(aTime);
    });

    // 2. Resim Listesini Hazırlama
    Map<String, String> imageUrlToFilename = {};
    Set<String> urlsToDownload = {};

    void processImages(List<dynamic> questions) {
      for (var q in questions) {
        if (q is Map<String, dynamic> && q['image_url'] != null && q['image_url'].toString().isNotEmpty) {
          String url = q['image_url'];
          String qId = q['question_id'] ?? q['id'] ?? url.hashCode.toString();
          String filename = 'resim_$qId.jpg';
          urlsToDownload.add(url);
          imageUrlToFilename[url] = filename;
          q['local_image_path'] = 'images/$filename';
        }
      }
    }

    processImages(liked);
    processImages(saved);
    processImages(submittedQuestions);

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      urlsToDownload.add(avatarUrl);
      imageUrlToFilename[avatarUrl] = 'profil_fotografi.jpg';
      userProfile['local_avatar_path'] = 'images/profil_fotografi.jpg';
    }

    // 3. JSON Hazırlama ve Yazma
    final Map<String, dynamic> rawData = {
      "user_profile": userProfile,
      "statistics": {
        ...stats,
        "total_solved_unique_questions": (userProfile['solved_questions'] as List? ?? []).length,
      },
      "ai_solutions": aiSolutions,
      "liked_questions": liked,
      "saved_questions": saved,
      "submitted_questions": submittedQuestions,
      "reported_questions": reportedQuestions,
      "export_date": DateTime.now().toIso8601String(),
    };

    final cleanExport = exportSanitize(rawData);
    String jsonString = const JsonEncoder.withIndent('  ').convert(cleanExport);

    final tempDir = await Directory.systemTemp.createTemp('export_');
    final bundleDir = Directory('${tempDir.path}/sinavgram_verilerim');
    await bundleDir.create(recursive: true);

    final jsonFile = File('${bundleDir.path}/verilerim.json');
    await jsonFile.writeAsString(jsonString, flush: true);

    // 4. Resimlerin İndirilmesi (Garantili Yöntem)
    if (urlsToDownload.isNotEmpty) {
      final imagesDir = Directory('${bundleDir.path}/images');
      await imagesDir.create(recursive: true);

      final httpClient = HttpClient();
      for (String url in urlsToDownload) {
        try {
          final filename = imageUrlToFilename[url];
          final request = await httpClient.getUrl(Uri.parse(getFullUrl(url)));
          final response = await request.close();
          
          // pipe yerine bytes olarak alıp yazıyoruz ki dosya tamamlansın
          final bytes = await response.fold<List<int>>([], (p, e) => p..addAll(e));
          final file = File('${imagesDir.path}/$filename');
          await file.writeAsBytes(bytes, flush: true); 
        } catch (e) {
          debugPrint("İndirme hatası: $url -> $e");
        }
      }
      httpClient.close();
    }

  // 5. ZIP Oluşturma - GÜVENLİ YÖNTEM
  final zipPath = '${tempDir.path}/sinavgram_verilerim.zip';
  final archive = Archive();

  Future<void> addDirToArchive(Directory dir, String basePath) async {
    final entities = dir.listSync(recursive: false);
    for (var entity in entities) {
      if (entity is File) {
        final bytes = await entity.readAsBytes();
        if (bytes.isNotEmpty) {
          final relativeName = entity.path.substring(basePath.length + 1);
          archive.addFile(ArchiveFile(relativeName, bytes.length, bytes));
        }
      } else if (entity is Directory) {
        await addDirToArchive(entity, basePath);
      }
    }
  }

  // bundleDir'in parent'ını base path olarak kullan
  await addDirToArchive(bundleDir, tempDir.path);

  final zipData = ZipEncoder().encode(archive);
  if (zipData == null || zipData.isEmpty) {
    throw Exception("ZIP oluşturulamadı, veri boş.");
  }
  final zipFile = File(zipPath);
  await zipFile.writeAsBytes(zipData, flush: true);

  return zipPath;
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    if (_uid == null) throw Exception("Giriş yapılı değil.");
    final doc = await _db.collection('users').doc(_uid).get();
    final data = doc.data() ?? {};
    
    int total = data['total_answered'] ?? 0;
    int correct = data['correct_answered'] ?? 0;
    int wrong = data['wrong_answered'] ?? 0;
    double accuracy = total > 0 ? (correct / total) * 100 : 0.0;

    return {
      'total_answered_questions': total,
      'correctly_answered_questions': correct,
      'incorrectly_answered_questions': wrong,
      'rates': {'true': accuracy.toStringAsFixed(1)},
      'accuracy_rate_excluding_blanks': accuracy.toStringAsFixed(1),
    };
  }

  static Future<Map<String, dynamic>> getUserRank() async {
    if (_uid == null) return {'rank': 0, 'total_users': 0};
    
    try {
      final userDoc = await _db.collection('users').doc(_uid).get();
      int myScore = userDoc.data()?['score'] ?? 0;

      final totalSnapshot = await _db.collection('users').count().get();
      int totalUsers = totalSnapshot.count ?? 1;

      final rankSnapshot = await _db.collection('users')
          .where('score', isGreaterThan: myScore)
          .count()
          .get();
          
      int rank = (rankSnapshot.count ?? 0) + 1;

      // SIRALAMA ROZETLERİNİ KALICI OLARAK KAYDET (Puan Düşse Bile Kalır)
      String badgeToUnlock = '';
      if (rank > 0 && rank <= 100) badgeToUnlock = 'gold';
      else if (rank > 100 && rank <= 1000) badgeToUnlock = 'silver';
      else if (rank > 1000 && rank <= 10000) badgeToUnlock = 'bronze';

      if (badgeToUnlock.isNotEmpty) {
        List currentBadges = userDoc.data()?['badges'] ?? [];
        if (!currentBadges.contains(badgeToUnlock)) {
          await _db.collection('users').doc(_uid).update({
            'badges': FieldValue.arrayUnion([badgeToUnlock])
          });
        }
      }

      return {'rank': rank, 'total_users': totalUsers};
    } catch (e) {
      return {'rank': 0, 'total_users': 0};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId, {int page = 1}) async {
    final doc = await _db.collection('users').doc(userId).get();
    final data = doc.data() ?? {};
    
    int userScore = data['score'] ?? 0;
    int rank = 0;
    int totalUsers = 1;

    try {
      final totalUsersSnapshot = await _db.collection('users').count().get();
      totalUsers = totalUsersSnapshot.count ?? 1;
      
      final rankSnapshot = await _db.collection('users').where('score', isGreaterThan: userScore).count().get();
      rank = (rankSnapshot.count ?? 0) + 1;
    } catch (e) {
      debugPrint("Public profil sıralaması hesaplanamadı: $e");
    }
    
    final qs = await _db.collection('questions')
        .where('author_id', isEqualTo: userId)
        .where('status', isEqualTo: 'approved')
        .limit(20)
        .get();

    final questions = qs.docs.map((q) => {'id': q.id, ...q.data()}).toList();

    return {
      'id': doc.id,
      'username': data['username'] ?? 'Bilinmeyen',
      'avatar_url': data['avatar_url'],
      'score': userScore,
      'rank': rank,
      'total_users': totalUsers,
      
      'archived_scores': data['archived_scores'] is Map 
        ? Map<String, dynamic>.from(data['archived_scores'] as Map) 
        : <String, dynamic>{},
        
      // TİP GÜVENLİGİ İÇİN GÜNCELLENEN KISIMLAR:
      'badges': data['badges'] is List 
          ? List<dynamic>.from(data['badges'] as List) 
          : <dynamic>[],
          
      'course_progress': data['course_progress'] is Map 
          ? Map<String, dynamic>.from(data['course_progress'] as Map) 
          : <String, dynamic>{}, // Boş sözlüğün tipini kesin olarak belirttik
          
      'earned_ranks': data['earned_ranks'] is List 
          ? List<dynamic>.from(data['earned_ranks'] as List) 
          : <dynamic>['caylak'],
          
      'approved_questions': {
        'items': questions,
        'page': page,
        'has_next': false, 
      }
    };
  }

  static Future<List<dynamic>> getCourses() async {
    final snapshot = await _db.collection('dersler').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  static Future<List<dynamic>> getSubtopics(String courseId) async {
    final snapshot = await _db.collection('dersler')
        .doc(courseId)
        .collection('konular')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  static Future<String> getCourseNameById(String courseId) async {
    try {
      final doc = await _db.collection('dersler').doc(courseId).get();
      if (doc.exists) {
        return doc.data()?['name'] ?? 'Bilinmeyen Ders';
      }
    } catch (e) {
      debugPrint("Ders adı çekilemedi: $e");
    }
    return 'Bilinmeyen Ders';
  }

  static Future<List<Map<String, dynamic>>> getQuestions(String courseId, {String? subtopicId, List<dynamic> solvedIds = const []}) async {
    try {
      Query query = _db.collection('questions')
          .where('course_id', isEqualTo: courseId)
          .where('status', isEqualTo: 'approved');

      if (subtopicId != null) {
        query = query.where('subtopic_id', isEqualTo: subtopicId);
      }

      final snapshot = await query.limit(100).get();

      List<Map<String, dynamic>> filteredQuestions = [];
      
      for (var doc in snapshot.docs) {
        if (!solvedIds.contains(doc.id)) {
          final data = doc.data() as Map<String, dynamic>;
          filteredQuestions.add({'id': doc.id, ...data});
        }
        if (filteredQuestions.length >= 20) break; 
      }

      return filteredQuestions;
    } catch (e) {
      return [];
    }
  }

  static Future<String> getUsernameById(String? userId) async {
    if (userId == null || userId.isEmpty) return 'Anonim';
      try {
        final doc = await _db.collection('users').doc(userId).get();
        if (doc.exists) {
          return doc.data()?['username'] ?? 'Anonim';
        }
      } catch (e) {
        debugPrint("Kullanıcı adı çekilemedi: $e");
      }
    return 'Anonim';
  }

  static Future<Map<String, dynamic>> getQuestionByLinkId(String linkId) async {
    final snapshot = await _db.collection('questions')
        .where('link_id', isEqualTo: linkId)
        .limit(1)
        .get();
        
    if (snapshot.docs.isNotEmpty) {
      return {'id': snapshot.docs.first.id, ...snapshot.docs.first.data()};
    }
    throw Exception("Soru bulunamadı.");
  }

  static List<String> _generateSearchKeywords(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^\w\s\ğ\ü\ş\i\ö\ç]'), '').split(' ');
  }

  static Future<Map<String, dynamic>> submitQuestion(Map<String, String> fields, XFile? imageFile) async {
    if (_uid == null) throw Exception("Giriş yapılı değil.");
    String? imageUrl;

    if (imageFile != null) {
      final storageRef = _storage.ref().child('question_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(File(imageFile.path));
      imageUrl = await storageRef.getDownloadURL();
    }
    
    List<String> keywords = _generateSearchKeywords(fields['text'] ?? '');

    Map<String, String> options = {
      'A': fields['option_a'] ?? '',
      'B': fields['option_b'] ?? '',
      'C': fields['option_c'] ?? '',
      'D': fields['option_d'] ?? '',
      'E': fields['option_e'] ?? '',
    };

    await _db.collection('questions').add({
      'course_id': fields['course_id'],
      'subtopic_id': fields['subtopic_id'],
      'text': fields['text'],
      'options': options,
      'correct_option': fields['correct_option'],
      'image_url': imageUrl,
      'author_id': _uid,
      'status': 'pending',
      'reward_claimed': false, // YENİ EKLENEN ALAN
      'created_at': FieldValue.serverTimestamp(),
      'likes_count': 0,
      'search_keywords': keywords,
      'link_id': DateTime.now().millisecondsSinceEpoch.toString(), 
    });

    return {'message': 'Sorunuz onaya gönderildi. Onaylandığında 10.000 puan kazanacaksınız!'}; // MESAJ GÜNCELLENDİ
  }

  static Future<void> checkAndRewardApprovedQuestions(BuildContext context) async {
    if (_uid == null) return;
    
    try {
      final snapshot = await _db.collection('questions')
          .where('author_id', isEqualTo: _uid)
          .where('status', isEqualTo: 'approved')
          .where('reward_claimed', isEqualTo: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        int totalPoints = 0;

        for (var doc in snapshot.docs) {
          totalPoints += 10000;
          await doc.reference.update({'reward_claimed': true});
        }

        await addExtraScore(totalPoints);

        // Arayüzü (Puanı) anında güncelle
        if (context.mounted) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.updateScore(userProvider.score + totalPoints);
        }
      }
    } catch (e) {
      debugPrint("Onaylanan soruları kontrol ederken hata: $e");
    }
  }

  // 🔥 YENİ: Başarımlar ve Seri İlerlemesini de Barındıran Güncellenmiş Submit Fonksiyonu
  static Future<Map<String, dynamic>> submitAnswer(String questionId, String selectedOption) async {
    if (_uid == null) throw Exception("Giriş yapılı değil.");
    
    final userRef = _db.collection('users').doc(_uid);
    final userDocSnap = await userRef.get();
    Map<String, dynamic> data = userDocSnap.data() ?? {};
    
    List solvedList = data['solved_questions'] ?? [];

    final qDoc = await _db.collection('questions').doc(questionId).get();
    final correctOption = qDoc.data()?['correct_option'];
    final bool isCorrect = (selectedOption == correctOption);
    final String courseId = qDoc.data()?['course_id'] ?? '';

    if (solvedList.contains(questionId)) {
      return {
        'is_correct': isCorrect,
        'correct_option': correctOption,
        'new_score': data['score'] ?? 0,
        'already_solved': true, 
        'course_id': courseId,
      };
    }

    int scoreChange = isCorrect ? 1000 : -250;
    int currentScore = data['score'] ?? 0;
    int newScore = currentScore + scoreChange;
    
    Map<String, dynamic> updates = {
      'score': FieldValue.increment(scoreChange),
      'total_answered': FieldValue.increment(1),
      'correct_answered': FieldValue.increment(isCorrect ? 1 : 0),
      'wrong_answered': FieldValue.increment(isCorrect ? 0 : 1),
    };

    // RÜTBELERİ KALICI OLARAK AÇ
    List earnedRanks = data['earned_ranks'] ?? ['caylak'];
    List ranksToUnlock = [];
    for (var r in AchievementConfig.ranks) {
      if (newScore >= r['threshold'] && !earnedRanks.contains(r['id'])) {
        ranksToUnlock.add(r['id']);
      }
    }
    if (ranksToUnlock.isNotEmpty) {
       updates['earned_ranks'] = FieldValue.arrayUnion(ranksToUnlock);
    }

    if (isCorrect) {
      updates['solved_questions'] = FieldValue.arrayUnion([questionId]);
      if (courseId.isNotEmpty) {
        updates['course_progress.$courseId'] = FieldValue.increment(1);
      }

      // --- SERİ (STREAK) YÖNETİMİ ---
      String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String lastActive = data['last_active_date'] ?? '';
      int todayCount = data['today_correct_count'] ?? 0;
      int streak = data['current_streak'] ?? 0;
      String lastGoalMet = data['last_goal_met_date'] ?? '';

      // Yeni bir güne geçildiyse sayacı sıfırla
      if (lastActive != todayStr) {
        todayCount = 0;
        lastActive = todayStr;
        
        // Eğer kullanıcı önceki gün hedefini gerçekleştirmeden yeni güne girdiyse serisi bozulur
        if (lastGoalMet.isNotEmpty) {
          DateTime lastGoalDate = DateFormat('yyyy-MM-dd').parse(lastGoalMet);
          DateTime todayDateParsed = DateFormat('yyyy-MM-dd').parse(todayStr);
          if (todayDateParsed.difference(lastGoalDate).inDays > 1) {
            streak = 0;
          }
        }
      }

      todayCount++;
      updates['today_correct_count'] = todayCount;
      updates['last_active_date'] = todayStr;

      // 10'a Ulaştığında Seriyi Tetikle
      if (todayCount == 10) {
        if (lastGoalMet != todayStr) { // Bugün zaten hedefini karşılamamışsa
          streak++;
          updates['current_streak'] = streak;
          updates['last_goal_met_date'] = todayStr;
        }
      } else if (todayCount < 10) {
        updates['current_streak'] = streak; // Olası sıfırlanmaları kaydet
      }
    } else {
      // Yanlış cevaplarda sadece gün kontrolü (seri bozma ihtimali için)
      String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String lastActive = data['last_active_date'] ?? '';
      if (lastActive != todayStr) {
        updates['today_correct_count'] = 0;
        updates['last_active_date'] = todayStr;
        
        String lastGoalMet = data['last_goal_met_date'] ?? '';
        if (lastGoalMet.isNotEmpty) {
          DateTime lastGoalDate = DateFormat('yyyy-MM-dd').parse(lastGoalMet);
          DateTime todayDateParsed = DateFormat('yyyy-MM-dd').parse(todayStr);
          if (todayDateParsed.difference(lastGoalDate).inDays > 1) {
            updates['current_streak'] = 0;
          }
        }
      }
    }

    await userRef.update(updates);
    final updatedUserDoc = await userRef.get();

    return {
      'is_correct': isCorrect,
      'correct_option': correctOption,
      'new_score': updatedUserDoc.data()?['score'] ?? 0,
      'already_solved': false,
      'course_id': courseId,
    };
  }

  // --- KÜTÜPHANECİ (PDF OKUMA) İZLEYİCİSİ ---
  static Future<void> markPdfAsRead(String pdfUrl) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({
      'read_pdfs': FieldValue.arrayUnion([pdfUrl])
    });
  }

  static Future<void> addExtraScore(int points) async {
    if (_uid == null || points <= 0) return;
    await _db.collection('users').doc(_uid).update({
      'score': FieldValue.increment(points),
    });
  }

  static Future<void> addQuestionScore() async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({
      'score': FieldValue.increment(10000),
    });
  }

  static Future<Map<String, dynamic>> toggleLike(String questionId) async {
    if (_uid == null) throw Exception("Giriş yapılı değil.");
    
    final userRef = _db.collection('users').doc(_uid);
    final userDoc = await userRef.get();
    List likes = userDoc.data()?['liked_questions'] ?? [];

    bool isNowLiked = false;
    if (likes.contains(questionId)) {
      await userRef.update({'liked_questions': FieldValue.arrayRemove([questionId])});
      await _db.collection('questions').doc(questionId).update({'likes_count': FieldValue.increment(-1)});
    } else {
      await userRef.update({'liked_questions': FieldValue.arrayUnion([questionId])});
      await _db.collection('questions').doc(questionId).update({'likes_count': FieldValue.increment(1)});
      isNowLiked = true;
    }
    return {'liked': isNowLiked};
  }

  static Future<Map<String, dynamic>> toggleSave(String questionId) async {
    if (_uid == null) throw Exception("Giriş yapılı değil.");
    
    final userRef = _db.collection('users').doc(_uid);
    final userDoc = await userRef.get();
    List saved = userDoc.data()?['saved_questions'] ?? [];

    bool isNowSaved = false;
    if (saved.contains(questionId)) {
      await userRef.update({'saved_questions': FieldValue.arrayRemove([questionId])});
    } else {
      await userRef.update({'saved_questions': FieldValue.arrayUnion([questionId])});
      isNowSaved = true;
    }
    return {'saved': isNowSaved};
  }

  static Future<Map<String, dynamic>> reportQuestion(String questionId, String reason) async {
    await _db.collection('reports').add({
      'question_id': questionId,
      'reporter_id': _uid,
      'reason': reason,
      'created_at': FieldValue.serverTimestamp(),
    });
    await _db.collection('questions').doc(questionId).update({
    'status': 'reported'
    });
    return {'message': 'Soru bildirildi.'};
  }

  static Future<List<dynamic>> getLikedQuestions() async {
    if (_uid == null) return [];
    final userDoc = await _db.collection('users').doc(_uid).get();
    List likedIds = userDoc.data()?['liked_questions'] ?? [];
    if (likedIds.isEmpty) return [];

    List limitedIds = likedIds.take(10).toList();
    final snapshot = await _db.collection('questions')
        .where(FieldPath.documentId, whereIn: limitedIds)
        .get();

    List<Map<String, dynamic>> enrichedQuestions = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data();
      String courseId = data['course_id'] ?? '';
      
      if (data['course_name'] == null && courseId.isNotEmpty) {
        final courseDoc = await _db.collection('dersler').doc(courseId).get();
        data['course_name'] = courseDoc.data()?['name'] ?? 'Bilinmeyen Ders';
      }
      
      enrichedQuestions.add({'id': doc.id, ...data});
    }

    return enrichedQuestions;
  }

  static Future<List<dynamic>> getSavedQuestions() async {
    if (_uid == null) return [];
    final userDoc = await _db.collection('users').doc(_uid).get();
    List savedIds = userDoc.data()?['saved_questions'] ?? [];
    if (savedIds.isEmpty) return [];

    List limitedIds = savedIds.take(10).toList();
    final snapshot = await _db.collection('questions')
        .where(FieldPath.documentId, whereIn: limitedIds)
        .get();

    List<Map<String, dynamic>> enrichedQuestions = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data();
      String courseId = data['course_id'] ?? '';
      
      if (data['course_name'] == null && courseId.isNotEmpty) {
        final courseDoc = await _db.collection('dersler').doc(courseId).get();
        data['course_name'] = courseDoc.data()?['name'] ?? 'Bilinmeyen Ders';
      }
      
      enrichedQuestions.add({'id': doc.id, ...data});
    }

    return enrichedQuestions;
  }

  static Future<List<dynamic>> getSubmittedQuestions() async {
    if (_uid == null) return [];
    final snapshot = await _db.collection('questions')
        .where('author_id', isEqualTo: _uid)
        .where('status', isEqualTo: 'approved')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  static Future<List<dynamic>> searchQuestions(String query) async {
    final searchWord = query.toLowerCase().trim();
    if (searchWord.isEmpty) return [];

    final snapshot = await _db.collection('questions')
        .where('search_keywords', arrayContains: searchWord)
        .where('status', isEqualTo: 'approved')
        .limit(20)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    final searchWord = query.trim();
    if (searchWord.isEmpty) return [];

    final snapshot = await _db.collection('users')
        .where('username', isGreaterThanOrEqualTo: searchWord)
        .where('username', isLessThanOrEqualTo: '$searchWord\uf8ff')
        .limit(20)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // --- LİDERLİK TABLOSU ---
  static Future<Map<String, List<dynamic>>> getLeaderboardData(int myScore, String myId) async {
    try {
      // Limit 100 yerine 150 çekiyoruz ki gizli olanları filtrelediğimizde elimizde yeterli kişi kalsın
      final topSnapshot = await _db.collection('users')
          .orderBy('score', descending: true)
          .limit(150)
          .get();
          
      List<dynamic> top100 = [];
      for (var doc in topSnapshot.docs) {
        final data = doc.data();
        // Eğer kullanıcı gizliyse VE bu kullanıcı ben değilsem, onu atla
        if (data['is_incognito'] == true && doc.id != myId) continue; 
        
        top100.add({'id': doc.id, ...data});
        if (top100.length >= 100) break; // İlk 100'e ulaştığımızda dur
      }

      List<dynamic> surrounding = [];
      if (myId.isNotEmpty) {
        final aboveSnap = await _db.collection('users')
            .where('score', isGreaterThanOrEqualTo: myScore)
            .orderBy('score', descending: false)
            .limit(20) 
            .get();
            
        final belowSnap = await _db.collection('users')
            .where('score', isLessThan: myScore)
            .orderBy('score', descending: true)
            .limit(20)
            .get();

        final Map<String, dynamic> combined = {};
        for(var d in aboveSnap.docs) {
          if (d.data()['is_incognito'] == true && d.id != myId) continue;
          combined[d.id] = {'id': d.id, ...d.data()};
        }
        for(var d in belowSnap.docs) {
          if (d.data()['is_incognito'] == true && d.id != myId) continue;
          combined[d.id] = {'id': d.id, ...d.data()};
        }

        surrounding = combined.values.toList();
        surrounding.sort((a, b) => ((b['score'] ?? 0) as num).compareTo((a['score'] ?? 0) as num));
        
        // Sadece kendi etrafındaki makul bir sayıyı bırak (Örn: üstteki 10, alttaki 10)
        int myIndex = surrounding.indexWhere((u) => u['id'] == myId);
        if (myIndex != -1) {
          int start = max(0, myIndex - 10);
          int end = min(surrounding.length, myIndex + 11);
          surrounding = surrounding.sublist(start, end);
        }
      }

      return {
        'top100': top100,
        'surrounding': surrounding
      };
    } catch (e) {
      debugPrint("Leaderboard hatası: $e");
      return {'top100': [], 'surrounding': []};
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AudioPlayer.global.setAudioContext(AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const {
        
      },
    ),
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await MobileAds.instance.initialize();
  
  final String savedTheme = await SettingsService.getThemeColor();
  final bool isDarkMode = await SettingsService.getDarkModeEnabled(); // YENİ
  final Color primaryColor = ThemeNotifier.themeColors[savedTheme] ?? Colors.deepPurple;
  final initialTheme = ThemeNotifier._createThemeData(primaryColor);
  final initialDarkTheme = ThemeNotifier._createThemeData(primaryColor, isDark: true); // isDark: true eklendi

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ThemeNotifier(initialTheme, initialDarkTheme, isDarkMode)),
        Provider<AdService>(create: (_) => AdService(), dispose: (_, adService) => adService.dispose()),
      ],
      child: const SinavgramApp(),
    ),
  );
}

class SinavgramApp extends StatefulWidget {
  const SinavgramApp({super.key});

  @override
  State<SinavgramApp> createState() => _SinavgramAppState();
}

class _SinavgramAppState extends State<SinavgramApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("İlk link alınamadı: $e");
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("Link dinleme hatası: $err");
    });
  }

  void _handleDeepLink(Uri uri) {
  if (uri.path.contains('questions') || uri.host == 'questions') {
      final linkId = uri.pathSegments.last;
      
      debugPrint("Yakalanan Link ID: $linkId");

      Future.delayed(const Duration(milliseconds: 500), () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => SingleQuestionViewer(linkId: linkId),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      navigatorKey: navigatorKey, 
      title: 'Sınavgram',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.themeData,
      darkTheme: themeNotifier.darkThemeData,
      themeMode: themeNotifier.themeMode,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<User?>? _authSubscription;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final localSession = await LocalSessionService.getSession();

    if (localSession != null) {
      if (!mounted) return;
      Provider.of<UserProvider>(context, listen: false).setUser(localSession);
      setState(() => _isChecking = false);
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
      
      _syncWithFirebase();
    } else {
      final User? currentUser = await FirebaseAuth.instance.authStateChanges().first;

      if (!mounted) return;

      if (currentUser != null) {
        if (!currentUser.emailVerified) {
          setState(() => _isChecking = false);
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: currentUser.email ?? '')));
        } else {
          _handleNavigation(currentUser);
        }
      } else {
        setState(() => _isChecking = false);
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        await LocalSessionService.clearSession(); 
        if (mounted && !_isChecking) {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
        }
      }
    });
  }

  Future<void> _syncWithFirebase() async {
    try {
      final profileData = await FirebaseService.getMyProfile().timeout(const Duration(seconds: 10)); 
      if (mounted) {
         Provider.of<UserProvider>(context, listen: false).setUser(profileData);
      }
    } catch (e) {
      debugPrint("Arka plan senkronizasyon hatası: $e");
    }
  }

  Future<void> _handleNavigation(User user) async {
    try {
      final profileData = await FirebaseService.getMyProfile().timeout(const Duration(seconds: 10));
      if (!mounted) return;
      Provider.of<UserProvider>(context, listen: false).setUser(profileData);
      setState(() => _isChecking = false);
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    } catch (e) {
      debugPrint("Navigasyon hatası: $e");
      try { await FirebaseService.logout(); } catch (_) {} 
      if (mounted) {
        setState(() => _isChecking = false);
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories, size: 100, color: Theme.of(context).primaryColor),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); 
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isGoogleLoading = false; 
  bool _isAppleLoading = false;

  final String googleSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>''';
  final String appleSvg = '''<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" width="814" height="1000"> <path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-155.5-127C46.7 790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z"/></svg>''';

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final result = await FirebaseService.login(_identifierController.text.trim(), _passwordController.text);
        if (mounted) {
          TextInput.finishAutofillContext();

          if (result['email_not_verified'] == true) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
               content: Text('Giriş yapmak için e-postanızı doğrulamanız gerekmektedir.'), 
               backgroundColor: Colors.orange,
             ));
             Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: _identifierController.text.trim())));
          } else if (result.containsKey('user')) {
            Provider.of<UserProvider>(context, listen: false).setUser(result['user']); 
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
          }
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final result = await FirebaseService.signInWithGoogle();
      if (mounted && result.containsKey('user')) {
        Provider.of<UserProvider>(context, listen: false).setUser(result['user']);
        
        if (result['isNewUser'] == true) {
           Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        } else {
           Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _loginWithApple() async {
    setState(() => _isAppleLoading = true);
    try {
      final result = await FirebaseService.signInWithApple();
      if (mounted && result.containsKey('user')) {
        Provider.of<UserProvider>(context, listen: false).setUser(result['user']);
        
        if (result['isNewUser'] == true) {
           Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        } else {
           Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bağlantı açılamadı: $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: AutofillGroup( 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Sınavgram\'a Hoş Geldiniz!', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  const SizedBox(height: 8),
                  Text('Giriş yaparak devam edin', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _identifierController,
                    autofillHints: const [AutofillHints.email], 
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: 'E-posta Adresi', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty ? 'Lütfen bu alanı doldurun' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    autofillHints: const [AutofillHints.password], 
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _login, 
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value!.isEmpty ? 'Lütfen şifrenizi girin' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: const Text('Şifremi Unuttum'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                             padding: const EdgeInsets.symmetric(vertical: 14),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Giriş Yap'),
                        ),
                  const SizedBox(height: 16),

                  const Row(
                    children: [
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("VEYA", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _isGoogleLoading
                      ? const Center(child: CircularProgressIndicator())
                      : OutlinedButton.icon(
                          icon: SvgPicture.string(googleSvg, width: 20, height: 20,),
                          label: const Text('Google ile Giriş Yap', style: TextStyle(color: Colors.black87, fontSize: 16)),
                          onPressed: _loginWithGoogle,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                  
                  const SizedBox(height: 12),
                  _isAppleLoading
                      ? const Center(child: CircularProgressIndicator())
                      : OutlinedButton.icon(
                          icon: SvgPicture.string(appleSvg, width: 20, height: 20,),
                          label: const Text('Apple ile Giriş Yap', style: TextStyle(color: Colors.black87, fontSize: 16)),
                          onPressed: _loginWithApple,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),

                  const SizedBox(height: 12),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        children: [
                          const TextSpan(text: 'Kayıt olurken ya da giriş yaparken, '),
                          TextSpan(
                            text: 'Kullanım Şartları',
                            style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()..onTap = () => _launchURL('https://sinavgram.com/terms-of-service'),
                          ),
                          const TextSpan(text: '\'nı ve '),
                          TextSpan(
                            text: 'Gizlilik Politikası',
                            style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()..onTap = () => _launchURL('https://sinavgram.com/privacy-policy'),
                          ),
                          const TextSpan(text: '\'nı kabul etmiş olursunuz.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: 'Hesabınız yok mu? ',
                        style: const TextStyle(color: Colors.black87, fontSize: 16),
                        children: [
                          TextSpan(
                            text: 'Kayıt Olun',
                            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()..onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isGoogleLoading = false; 
  bool _isAppleLoading = false;
  bool _isPasswordVisible = false;

  bool _agreedToTerms = false;
  bool _subscribeToNewsletter = false;

  final String googleSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>''';
  final String appleSvg = '''<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" width="814" height="1000"> <path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-155.5-127C46.7 790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z"/></svg>''';
  
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bağlantı açılamadı: $url')));
      }
    }
  }

  Future<void> _register() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Devam etmek için şartları kabul etmelisiniz.'), backgroundColor: Colors.red));
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final result = await FirebaseService.register(
            _usernameController.text.trim(), 
            _emailController.text.trim(), 
            _passwordController.text
        );
        
        if (mounted) {
          TextInput.finishAutofillContext();

          if (result['requires_verification'] == true) {
            if (_subscribeToNewsletter) {
              try {
                await FirebaseService.subscribeToNewsletter(_emailController.text.trim());
              } catch (e) {
                debugPrint("Bülten aboneliği sırasında hata: $e");
              }
            }

            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Kayıt başarılı! Lütfen e-postanızı kontrol edip hesabınızı doğrulayın.'), 
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ));
            
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: _emailController.text.trim())), 
              (route) => false
            );
          }
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerWithGoogle() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Devam etmek için şartları kabul etmelisiniz.'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isGoogleLoading = true);
    try {
      final result = await FirebaseService.signInWithGoogle();
      if (mounted && result.containsKey('user')) {
        Provider.of<UserProvider>(context, listen: false).setUser(result['user']);
        
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _registerWithApple() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Devam etmek için şartları kabul etmelisiniz.'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isAppleLoading = true);
    try {
      final result = await FirebaseService.signInWithApple();
      if (mounted && result.containsKey('user')) {
        Provider.of<UserProvider>(context, listen: false).setUser(result['user']);
        
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hesap Oluştur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: AutofillGroup( 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _usernameController, 
                  autofillHints: const [AutofillHints.newUsername],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: 'Kullanıcı Adı', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), 
                  validator: (value) => value!.isEmpty ? 'Kullanıcı adı gerekli' : null
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController, 
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: 'E-posta', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), 
                  keyboardType: TextInputType.emailAddress, 
                  validator: (value) => value!.isEmpty || !value.contains('@') ? 'Geçerli bir e-posta girin' : null
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _passwordController, 
                  obscureText: !_isPasswordVisible, 
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Şifre', 
                    prefixIcon: const Icon(Icons.lock), 
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                  ), 
                  validator: (value) => value!.length < 6 ? 'Şifre en az 6 karakter olmalı' : null
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Checkbox(
                      value: _subscribeToNewsletter,
                      onChanged: (bool? value) => setState(() => _subscribeToNewsletter = value ?? false),
                    ),
                    const Expanded(
                      child: Text("Gelişmelerden haberdar olmak için bültene abone ol.", style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
                /*CheckboxListTile(
                  title: const Text("Gelişmelerden haberdar olmak için bültene abone ol.", style: TextStyle(fontSize: 14)),
                  value: _subscribeToNewsletter,
                  onChanged: (bool? value) => setState(() => _subscribeToNewsletter = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
*/
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (bool? value) => setState(() => _agreedToTerms = value ?? false),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.grey[700], fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Kullanım Şartları',
                              style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()..onTap = () => _launchURL('https://sinavgram.com/terms-of-service'),
                            ),
                            const TextSpan(text: ' ve '),
                            TextSpan(
                              text: 'Gizlilik Politikası',
                              style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()..onTap = () => _launchURL('https://sinavgram.com/privacy-policy'),
                            ),
                            const TextSpan(text: '\'nı okudum ve kabul ediyorum.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _isLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _register, 
                      child: const Text('Kayıt Ol')
                    ),
                    
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("VEYA", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                const SizedBox(height: 16),

                _isGoogleLoading
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton.icon(
                        icon: SvgPicture.string(googleSvg, width: 20, height: 20,),
                        label: const Text('Google ile Kayıt Ol', style: TextStyle(color: Colors.black87, fontSize: 16)),
                        onPressed: _registerWithGoogle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                const SizedBox(height: 12),
                _isAppleLoading
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton.icon(
                        icon: SvgPicture.string(appleSvg, width: 20, height: 20,),
                        label: const Text('Apple ile Kayıt Ol', style: TextStyle(color: Colors.black87, fontSize: 16)),
                        onPressed: _registerWithApple,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Widget> _buildPages(BuildContext context) {
    final username = Provider.of<UserProvider>(context, listen: false).username;
    
    return [
      _buildPage(
        icon: Icons.waving_hand,
        title: 'Sınavgram\'a Hoş Geldin, $username!',
        content: 'Sınavlara hazırlık yolculuğunda yeni partnerin burada. Başlamak için kaydır!',
      ),
      _buildPage(
        icon: Icons.checklist,
        title: 'Uygulama Nasıl Çalışır?',
        content: '• Panelim ile gelişimini anlık takip et.\n• Ders ve konu seçerek binlerce soru çöz.\n• PDF notları ile konularını pekiştir.\n• Çözemediğin soruları kaydet, sonra tekrar dene.',
        isList: true,
      ),
      _buildPage(
        icon: Icons.star_rate,
        title: 'Puan Sistemi Nasıl Çalışır?',
        content: '• Her doğru cevap için +1000 Puan kazanırsın.\n• Her yanlış cevap için -250 Puan kaybedersin.\n• Haksızlığı önlemek için aynı soruya bir kez doğru cevap verebilirsin.\n\nPuanını yükselterek sıralamada üste çık!',
        isList: true,
      ),
      _buildPage(
        icon: Icons.add,
        title: 'Yeni Soru Gönder',
        content: '• Soru bankamızı birlikte büyütelim!\n• Çözdüğün sorularda eksik gördüğün noktaları bize bildir.\n• Kendi sorularını gönder, diğer kullanıcılarla paylaş ve bilginin yayılmasına katkıda bulun.\n• Unutma her onaylanan soru için 10.000 puan kazanırsın!',
      ),
      _buildPage(
        icon: Icons.emoji_events,
        title: 'Başarımlarını Kazan!',
        content: '• Türkçe-Edebiyat, Matematik, Fen ve Sosyal alanlarında uzmanlaş.\n• 500 soru çözerek alanın "Üstadı" ol.\n• Kazandığın her başarımla profilini taçlandır ve bilginin gücünü kanıtla!',
        isList: true,
      ),
      _buildPage(
        icon: Icons.leaderboard,
        title: 'Zirveye Oyna!',
        content: '• Liderlik tablosunda yerini al.\n• Seninle aynı seviyedeki rakiplerinle yarış.\n• "Çaylak"lıktan "Yenilmez"e giden bu yolda, en üst basamağa adını yazdır.',
        isList: true,
      ),
    ];
  }

  Widget _buildPage({required IconData icon, required String title, required String content, bool isList = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Theme.of(context).primaryColor),
          const SizedBox(height: 32),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            content,
            textAlign: isList ? TextAlign.start : TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: pages,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) => _buildDot(index: index)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == pages.length - 1) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                        (route) => false,
                      );
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(_currentPage == pages.length - 1 ? 'Hadi Başlayalım!' : 'İleri'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  late final AdService _adService;

  static const List<Widget> _widgetOptions = <Widget>[
    PanelimScreen(),
    CoursesScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _adService = Provider.of<AdService>(context, listen: false);
    _adService.loadInterstitialAd();
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      floatingActionButton: _selectedIndex == 3
        ? FloatingActionButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubmitQuestionScreen())), tooltip: 'Soru Gönder', child: const Icon(Icons.add))
        : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Panelim'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Dersler'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Ara'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class PanelimScreen extends StatefulWidget {
  const PanelimScreen({super.key});

  @override
  State<PanelimScreen> createState() => _PanelimScreenState();
}

class _PanelimScreenState extends State<PanelimScreen> {
  Map<String, dynamic>? _weakestCourse;
  Map<String, dynamic>? _weakestSubtopic;
  Map<String, dynamic>? _randomQuestion;
  int _dailyGoal = 100;
  int _dailySolvedCount = 0;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileFuture = FirebaseService.getMyProfile();
      final rankFuture = FirebaseService.getUserRank();
      final randomQuestionFuture = _fetchRandomInteractionQuestion();
      final dailyGoalFuture = DailyGoalService.getGoal();
      final dailySolvedFuture = DailyGoalService.getSolvedCount();
      final weakestCourseFuture = LocalAnalyticsService.analyzeWeakestCourse();
      final weakestSubtopicFuture = LocalAnalyticsService.analyzeWeakestSubtopicLast7Days();

      final results = await Future.wait([
        profileFuture,
        rankFuture,
        randomQuestionFuture,
        dailyGoalFuture,
        dailySolvedFuture,
        weakestCourseFuture,
        weakestSubtopicFuture,
      ]);

      if (mounted) {
        final profileData = results[0] as Map<String, dynamic>?;
        final rankData = results[1] as Map<String, dynamic>?;

        if (profileData != null && rankData != null) {
          profileData.addAll(rankData);
        }
        
        if (profileData != null) {
          Provider.of<UserProvider>(context, listen: false).setUser(profileData);
        }

        setState(() {
          _randomQuestion = results[2] as Map<String, dynamic>?;
          _dailyGoal = results[3] as int;
          _dailySolvedCount = results[4] as int;
          _weakestCourse = results[5] as Map<String, dynamic>?;
          _weakestSubtopic = results[6] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Veriler yüklenirken bir hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
    if (mounted) {
      await FirebaseService.checkAndRewardApprovedQuestions(context);
    }
  }

  Future<Map<String, dynamic>?> _fetchRandomInteractionQuestion() async {
    try {
      final likedFuture = FirebaseService.getLikedQuestions();
      final savedFuture = FirebaseService.getSavedQuestions();

      final results = await Future.wait([likedFuture, savedFuture]);

      final List<dynamic> liked = results[0];
      final List<dynamic> saved = results[1];

      final allQuestions = <String, dynamic>{};
      for (var q in liked) { allQuestions[q['id'].toString()] = q; }
      for (var q in saved) { allQuestions[q['id'].toString()] = q; }

      final uniqueQuestions = allQuestions.values.toList();

      if (uniqueQuestions.isNotEmpty) {
        final random = Random();
        return uniqueQuestions[random.nextInt(uniqueQuestions.length)];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _showEditGoalDialog() async {
    final goalController = TextEditingController(text: _dailyGoal.toString());
    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Günlük Hedefi Düzenle'),
          content: TextField(
            controller: goalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Günlük Soru Hedefi'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final goal = int.tryParse(goalController.text);
                if (goal != null && goal > 0) {
                  Navigator.of(context).pop(goal);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (newGoal != null && mounted) {
      await DailyGoalService.setGoal(newGoal);
      setState(() {
        _dailyGoal = newGoal;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panelim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!)))
                    : RefreshIndicator(
                        onRefresh: _loadDashboardData,
                        child: ListView(
                          padding: const EdgeInsets.all(8.0),
                          children: [
                            _buildWelcomeCard(user),
                            _buildQuickStatCards(user.score, user.rank),
                            _buildDailyGoalCard(_dailySolvedCount, _dailyGoal),
                            _openMathGameCard(),
                            _buildLeaderboardCard(), // <--- LİDERLİK TABLOSU BUTONU
                            if (_weakestCourse != null && _weakestCourse!['course_id'] != null)
                              _buildWeakestSubjectCard(_weakestCourse!),
                            if (_weakestSubtopic != null)
                              _buildWeakestSubtopicCard(_weakestSubtopic!),
                            if (_randomQuestion != null) _buildRandomQuestionCard(_randomQuestion!),
                            const SuccessTipsCard(),
                          ],
                        ),
                      ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(UserProvider user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? Colors.grey[800] : Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(FirebaseService.getFullUrl(user.avatarUrl)) : null,
              child: user.avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba, ${user.username}!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Bugün hedeflerine ulaşmak için harika bir gün.',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatCards(int score, int? rank) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    score.toString(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 4),
                  const Text('Puan', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    rank != null && rank > 0 ? '#$rank' : '-',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 4),
                  const Text('Sıralama', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoalCard(int solved, int goal) {
    final double progress = goal > 0 ? (solved / goal).clamp(0.0, 1.0) : 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Günün Hedefi', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                  onPressed: _showEditGoalDialog,
                  tooltip: 'Hedefi Düzenle',
                )
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$solved / $goal', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

Widget _openMathGameCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? Colors.green.withOpacity(0.2) : Colors.green[50],
      child: ListTile(
        leading: Icon(Icons.videogame_asset, color: isDark ? Colors.greenAccent : Colors.green),
        title: const Text('Soru Çözerek Eğlen!'),
        subtitle: const Text('Matematik oyunlarımızla hem eğlen hem öğren. Hadi dene!'),
        onTap: () async {
          // Oyundan dönen puanı bekliyoruz
          final score = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MathGameWidget())
          );
          if (score != null && score is int && score > 0) {
            try {
              await FirebaseService.addExtraScore(score);
              if (mounted) {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                userProvider.updateScore(userProvider.score + score);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Harika! Matematik oyunundan $score puan kazandın. 🥳'),
                    backgroundColor: Colors.green,
                  )
                );
              }
            } catch (e) {
              debugPrint("Puan kaydedilemedi: $e");
            }
          }
        },
      ),
    );
  }

  Widget _buildLeaderboardCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? Colors.indigo.withOpacity(0.2) : Colors.indigo.shade50,
      child: ListTile(
        leading: Icon(Icons.leaderboard, color: isDark ? Colors.indigoAccent : Colors.indigo, size: 36),
        title: const Text('Liderlik Tablosu', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Sıralamanı ve rakiplerini gör!'),
        trailing: Icon(Icons.arrow_forward_ios, color: isDark ? Colors.indigoAccent : Colors.indigo),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
        }
      ),
    );
  }

  Widget _buildWeakestSubjectCard(Map<String, dynamic> weakestCourse) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectName = weakestCourse['course_name'] ?? 'Bilinmeyen Ders';
    final courseId = weakestCourse['course_id'];
    return Card(
      color: isDark ? Colors.red.withOpacity(0.2) : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: isDark ? Colors.redAccent : Colors.red[700]),
                const SizedBox(width: 8),
                const Text("Bu Derse Yüklen", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'En çok yanlışın "$subjectName" dersinde görünüyor. Netlerini artırmak için harika bir fırsat!',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (courseId != null) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizScreen(courseId: courseId, courseName: subjectName)));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.redAccent : Colors.red[700]),
                child: Text('$subjectName Soruları Çöz'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakestSubtopicCard(Map<String, dynamic> weakestSubtopic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtopicName = weakestSubtopic['subtopic_name'] ?? 'Bilinmeyen Konu';
    final pdfUrl = weakestSubtopic['pdf_url'];

    return Card(
      color: isDark ? Colors.orange.withOpacity(0.2) : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: isDark ? Colors.orangeAccent : Colors.orange[800]),
                const SizedBox(width: 8),
                const Text("Konu Tekrarı Önerisi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Son 1 haftada en çok "$subtopicName" konusunda zorlandın. Konu anlatımına göz atmaya ne dersin?',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfViewerScreen(pdfUrl: FirebaseService.getFullUrl(pdfUrl), title: subtopicName)));
                },
                style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.orangeAccent : Colors.orange[800]),
                child: const Text('Konu Anlatımını Aç'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRandomQuestionCard(Map<String, dynamic> question) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => SingleQuestionViewer(linkId: question['link_id'])));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.replay_circle_filled, color: Colors.grey),
                  SizedBox(width: 8),
                  Text("Tekrar Göz At", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                question['text'] ?? 'Soru metni bulunamadı.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  question['course_name'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SuccessTipsCard extends StatefulWidget {
  const SuccessTipsCard({super.key});

  @override
  State<SuccessTipsCard> createState() => _SuccessTipsCardState();
}

class _SuccessTipsCardState extends State<SuccessTipsCard> {
  static const List<String> _tips = [
    "Her gün belirli bir saatte çalışmak, düzenli bir alışkanlık kazanmanıza yardımcı olur.",
    "Çözemediğiniz soruların üzerine gitmek, en kalıcı öğrenmeyi sağlar. Pes etmeyin!",
    "Konu tekrarı yaparken sadece okumak yerine, küçük notlar alarak veya özet çıkararak çalışın.",
    "Pomodoro tekniğini deneyin: 25 dakika ders, 5 dakika mola. Bu, odaklanmanızı artırır.",
    "Deneme sınavı sonuçlarınızı analiz ederek en çok yanlış yaptığınız konuları belirleyin ve onlara öncelik verin.",
    "Yeterli ve kaliteli uyku, öğrendiklerinizin kalıcı hale gelmesi için çok önemlidir.",
    "Farklı kaynaklardan soru çözmek, farklı soru tiplerine alışmanızı sağlar."
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = Random().nextInt(_tips.length);
  }

  void _nextTip() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _tips.length;
    });
  }

  void _previousTip() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _tips.length) % _tips.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? Colors.amber.withOpacity(0.15) : Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: isDark ? Colors.amberAccent : Colors.amber),
                const SizedBox(width: 8),
                const Text("Günün İpucu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _tips[_currentIndex],
              style: const TextStyle(fontSize: 15, height: 1.4),
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: _previousTip,
                  iconSize: 16,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: _nextTip,
                  iconSize: 16,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late Future<List<dynamic>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = FirebaseService.getCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dersler')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _coursesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}'));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Gösterilecek ders bulunamadı.'));
          
                final courses = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        title: Text(course['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).primaryColor),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SubtopicScreen(courseId: course['id'], courseName: course['name']))),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

class SubtopicScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const SubtopicScreen({super.key, required this.courseId, required this.courseName});

  @override
  State<SubtopicScreen> createState() => _SubtopicScreenState();
}

class _SubtopicScreenState extends State<SubtopicScreen> {
  late Future<List<dynamic>> _subtopicsFuture;

  @override
  void initState() {
    super.initState();
    _subtopicsFuture = FirebaseService.getSubtopics(widget.courseId);
  }

  void _onSubtopicTap(Map<String, dynamic> subtopic) {
    String? pdfUrl = subtopic['pdf_url'];
    
    if (pdfUrl != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(subtopic['name']),
          content: const Text('Ne yapmak istersiniz?'),
          actions: [
            TextButton(child: const Text('PDF Görüntüle'), onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfViewerScreen(pdfUrl: FirebaseService.getFullUrl(pdfUrl), title: subtopic['name'])));
            }),
            ElevatedButton(child: const Text('Sınavı Başlat'), onPressed: () {
              Navigator.of(ctx).pop();
              _startQuiz(subtopicId: subtopic['id'], pdfUrl: pdfUrl);
            }),
          ],
        ),
      );
    } else {
      _startQuiz(subtopicId: subtopic['id']);
    }
  }

  void _startQuiz({String? subtopicId, String? pdfUrl}) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizScreen(
        courseId: widget.courseId, 
        subtopicId: subtopicId, 
        courseName: widget.courseName,
        subtopicPdfUrl: pdfUrl,
      )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.courseName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shuffle),
                label: const Text('Tüm Konulardan Karışık Çöz'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
                onPressed: () => _startQuiz(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _subtopicsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}'));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Bu derse ait alt konu bulunamadı.'));
                
                final subtopics = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: subtopics.length,
                  itemBuilder: (context, index) {
                    final subtopic = subtopics[index];
                    final bool hasPdf = subtopic['pdf_url'] != null;
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: ListTile(
                        title: Text(subtopic['name']),
                        subtitle: Text(hasPdf ? "PDF mevcut. Görüntülemek için dokunun." : "Sınavı başlatmak için dokunun."),
                        trailing: hasPdf ? const Icon(Icons.picture_as_pdf, color: Colors.red) : const Icon(Icons.quiz),
                        onTap: () => _onSubtopicTap(subtopic),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final String courseId;
  final String? subtopicId;
  final String courseName;
  final String? subtopicPdfUrl;

  const QuizScreen({
    super.key, 
    required this.courseId, 
    this.subtopicId, 
    required this.courseName,
    this.subtopicPdfUrl,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Future<List<dynamic>> _questionsFuture;
  late Future<List<dynamic>> _randomizedQuestionsFuture;
  final PageController _pageController = PageController();

  bool _isVerticalScrollLocked = false;

  int _sessionCorrectCount = 0;
  int _sessionWrongCount = 0;
  int _sessionTotalCount = 0;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final solvedQuestionsIds = userProvider.solvedQuestions;
    _questionsFuture = FirebaseService.getQuestions(widget.courseId, subtopicId: widget.subtopicId, solvedIds: solvedQuestionsIds);
    _randomizedQuestionsFuture = _questionsFuture.then((questions) {
      final random = Random();
      questions.shuffle(random);
      return questions;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Context kapanmadan önce servisleri alıyoruz
    final adService = Provider.of<AdService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return PopScope(
      canPop: false, // ÖNEMLİ: Otomatik çıkışı engelle
      onPopInvoked: (didPop) async {
        if (didPop) return; // Zaten çıkıldıysa işlem yapma

        // Ekrandan çıkmadan hemen önce reklam kontrolü yap
        final bool shouldShowAd = await adService.shouldShowAdOnQuizExit();
        if (shouldShowAd && !userProvider.isPremium) {
          adService.showInterstitialAd();
        }
        
        // Reklam tetiklendikten veya reklam yoksa işlemi bitirdikten sonra manuel çıkış yap
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('${widget.courseName} Sınavı')),
        body: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _randomizedQuestionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Sorular yüklenemedi: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))));
                  if (!snapshot.hasData) return const Center(child: Text('Bu konuda gösterilecek soru bulunamadı.'));
          
                  final questions = snapshot.data!;
                  _sessionTotalCount = questions.length;
                  if (questions.isEmpty) {
                    return const QuizFinishedScreen( 
                      correctCount: 0, 
                      wrongCount: 0, 
                      totalCount: 0,
                    );
                  }

                  return PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    physics: _isVerticalScrollLocked ? const NeverScrollableScrollPhysics() : null,
                    itemCount: questions.length + 1,
                    itemBuilder: (context, index) {
                      if (index < questions.length) {
                        return QuestionCard(
                          key: ValueKey(questions[index]['id']), 
                          questionData: questions[index],
                          courseId: widget.courseId,
                          courseName: widget.courseName,
                          subtopicId: widget.subtopicId,
                          subtopicPdfUrl: widget.subtopicPdfUrl,
                          onAnswered: (isCorrect, isAlreadySolved) {
                            if (!isAlreadySolved) {
                              setState(() {
                                if (isCorrect) _sessionCorrectCount++;
                                else _sessionWrongCount++;
                              });
                            }
                          },
                          onLockChanged: (isLocked) {
                            setState(() {
                              _isVerticalScrollLocked = isLocked;
                            });
                          },
                        );
                      } else {
                        return QuizFinishedScreen(
                          correctCount: _sessionCorrectCount,
                          wrongCount: _sessionWrongCount,
                          totalCount: _sessionTotalCount,
                        );
                      }
                    },
                  );
                },
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

class QuizFinishedScreen extends StatelessWidget {
  final int correctCount;
  final int wrongCount;
  final int totalCount;

  const QuizFinishedScreen({
    super.key,
    required this.correctCount,
    required this.wrongCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    int unansweredCount = totalCount - (correctCount + wrongCount);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Beyaz yerine tema kart rengi
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle_outline, color: isDark ? Colors.greenAccent : Colors.green[600], size: 80),
          const SizedBox(height: 24),
          const Text(
            'Test Tamamlandı!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu oturumdaki sonuçlarınız aşağıdadır:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.grey[700]),
          ),
          const SizedBox(height: 32),
          
          // --- İSTATİSTİKLER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Doğru', correctCount, isDark ? Colors.greenAccent : Colors.green, context),
              _buildStatColumn('Yanlış', wrongCount, isDark ? Colors.redAccent : Colors.red, context),
              _buildStatColumn('Boş', unansweredCount, Colors.grey, context),
            ],
          ),
          
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Derslere Geri Dön'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count, Color color, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.grey[800]),
        ),
      ],
    );
  }
}

class QuestionCard extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final String courseId;
  final String courseName;
  final String? subtopicId;
  final String? subtopicPdfUrl;
  final Function(bool isCorrect, bool isAlreadySolved)? onAnswered;
  final ValueChanged<bool>? onLockChanged;

  const QuestionCard({
    super.key, 
    required this.questionData,
    required this.courseId,
    required this.courseName,
    this.subtopicId,
    this.subtopicPdfUrl,
    this.onAnswered,
    this.onLockChanged,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}
// --- MARKDOWN MATEMATİK DESTEĞİ İÇİN ÖZEL SINIFLAR ---
class MathSyntax extends md.InlineSyntax {
  MathSyntax() : super(r'\$\$(.*?)\$\$|\$(.*?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final isDisplay = match[1] != null;
    final math = match[1] ?? match[2];
    final el = md.Element.text('math', math!);
    el.attributes['display'] = isDisplay.toString();
    parser.addNode(el);
    return true;
  }
}

class MathBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final isDisplay = element.attributes['display'] == 'true';
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: isDisplay ? Alignment.center : Alignment.centerLeft,
      child: Math.tex(
        element.textContent,
        mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
        textStyle: preferredStyle?.copyWith(fontSize: 16),
      ),
    );
  }
}
class _QuestionCardState extends State<QuestionCard> with AutomaticKeepAliveClientMixin{
  String? _selectedOption;
  bool? _isCorrect;
  String? _correctOption;
  bool _isAnswered = false;
  late bool _isLiked;
  late bool _isSaved;
  late bool _isAlreadySolved;
  bool _isDrawingPageLocked = false;
  List<Stroke> _imageStrokes = [];

  String _authorName = 'Yükleniyor...';
  final PageController _pageController = PageController(initialPage: 1);
  String? _aiSolution;
  bool _isAiLoading = false;
  String? _aiError;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  final List<String> _correctSounds = [
    'correct1.wav', 'correct2.wav', 'correct3.mp3', 'correct4.wav',
  ];
  final List<String> _wrongSounds = [
    'wrong1.mp3', 'wrong2.mp3', 'wrong3.mp3', 'wrong4.wav',
  ];

  void _playSound(bool isCorrect) {
    String soundFile = isCorrect
        ? _correctSounds[_random.nextInt(_correctSounds.length)]
        : _wrongSounds[_random.nextInt(_wrongSounds.length)];
    _audioPlayer.play(AssetSource('sounds/$soundFile'));
  }

  @override
  bool get wantKeepAlive => true;

  void initState() {
    super.initState();
    _isLiked = widget.questionData['liked'] ?? false;
    _isSaved = widget.questionData['saved'] ?? false;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _isAlreadySolved = userProvider.solvedQuestions.contains(widget.questionData['id']);

    if (_isAlreadySolved) {
      _isAnswered = true;
      _correctOption = widget.questionData['correct_option'];
      _selectedOption = _correctOption;
      _isCorrect = true;
    }

    _fetchAuthorName();
  }

  Future<void> _fetchAuthorName() async {
    final authorId = widget.questionData['author_id'];
    final name = await FirebaseService.getUsernameById(authorId);
    if (mounted) {
      setState(() {
        _authorName = name;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleAnswer(String option) async {
    if (_isAnswered || _isAlreadySolved) return;

    setState(() { _selectedOption = option; _isAnswered = true; });
    try {
      final result = await FirebaseService.submitAnswer(widget.questionData['id'], option);
      _playSound(result['is_correct'] == true);
      setState(() {
        _isCorrect = result['is_correct'];
        _correctOption = result['correct_option'];
        if(result['already_solved'] == true) {
           _isAlreadySolved = true;
        }
      });

      if (mounted && widget.onAnswered != null) {
        widget.onAnswered!(result['is_correct'] == true, result['already_solved'] == true);
      }

      if(mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.updateScore(result['new_score']);

        if (result['already_solved'] == true) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu soruyu daha önce doğru çözdünüz. Puan eklenmedi.'), backgroundColor: Colors.orange));
        } else {
          if (result['is_correct'] == true) {
             userProvider.addSolvedQuestion(widget.questionData['id']);
             userProvider.incrementCourseProgress(result['course_id'] ?? '');
          }

          await DailyGoalService.incrementSolvedCount();
          await LocalAnalyticsService.addAnswerRecord(
            courseId: widget.courseId,
            courseName: widget.courseName,
            subtopicName: widget.questionData['subtopic_name'] ?? 'Genel',
            subtopicId: widget.subtopicId,
            pdfUrl: widget.subtopicPdfUrl,
            isCorrect: result['is_correct'],
          );

          final updatedData = await FirebaseService.getMyProfile();
          if (mounted) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            updatedData['rank'] = userProvider.rank;
            updatedData['total_users'] = userProvider.totalUsers;
            userProvider.setUser(updatedData);
          }
        }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      setState(() => _isAnswered = false);
    }
  }

  Future<void> _toggleLike() async {
      try {
          final result = await FirebaseService.toggleLike(widget.questionData['id']);
          if(result.containsKey('liked')) setState(() => _isLiked = result['liked']);
      } catch (e) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      }
  }

  Future<void> _toggleSave() async {
      try {
          final result = await FirebaseService.toggleSave(widget.questionData['id']);
           if(result.containsKey('saved')) setState(() => _isSaved = result['saved']);
      } catch (e) {
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      }
  }

  Future<void> _reportQuestion() async {
    final reportReasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Soruyu Bildir'),
        content: TextField(controller: reportReasonController, decoration: const InputDecoration(hintText: 'Bildirme nedeniniz...')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (reportReasonController.text.isEmpty) return;
              try {
                await FirebaseService.reportQuestion(widget.questionData['id'], reportReasonController.text);
                if(mounted) {
                   Navigator.of(ctx).pop();
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Soru başarıyla bildirildi.'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _shareQuestion() {
    final linkId = widget.questionData['link_id'];
    if (linkId != null) {
      Share.share('Sınavgram\'daki bu soruya bir göz at: https://sinavgram.com/questions/share/$linkId');
    }
  }

  Future<void> _getAiSolution() async {
    if (!_isAnswered || _selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yapay zeka çözümü için önce bir cevap vermelisiniz.')),
      );
      _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }

    if (_aiSolution != null) return;

    setState(() {
      _isAiLoading = true;
      _aiError = null;
    });

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userData['id'] ?? 'anonim';
      final questionText = widget.questionData['text'];
      final correctOption = widget.questionData['correct_option'] ?? _correctOption;
      final options = widget.questionData['options'] as Map<String, dynamic>;
      final imageUrl = widget.questionData['image_url'];
      final hasImage = imageUrl != null && imageUrl.toString().isNotEmpty;

      String promptText = "Sen Sınavgram uygulamasının yapay zeka öğretmenisin. Aşağıdaki soruyu adım adım çöz ve öğrenciye motive edici bir dille açıkla.\n"
          "${hasImage ? "\nDİKKAT: Bu soruya ait bir görsel de sisteme yüklendi. Lütfen çözümü yaparken görseldeki verileri, şekilleri veya grafikleri de mutlaka analiz et ve çözümüne dahil et.\n" : ""}"
          "SORU METNİ:\n$questionText\n\nSEÇENEKLER:\n";

      options.forEach((key, value) {
        promptText += "${key.toUpperCase()}) $value\n";
      });

      promptText += "\nDOĞRU CEVAP: $correctOption\nÖĞRENCİNİN İŞARETLEDİĞİ CEVAP: $_selectedOption\n\n"
          "Lütfen aşağıdaki formata göre bir analiz yap:\n"
          "1. **Sorunun Analizi:** Sorunun ne istediğini kısaca özetle.\n"
          "2. **Adım Adım Çözüm:** Soruyu çözmek için gereken adımları mantıksal bir sırayla açıkla.\n"
          "3. **Doğru Cevabın Açıklaması:** Neden '$correctOption' seçeneğinin doğru olduğunu detaylandır.\n"
          "4. **Öğrencinin Cevabının Analizi:** Öğrencinin seçtiği '$_selectedOption' seçeneğinin neden yanlış olduğunu veya hangi yanılgıdan kaynaklanabileceğini açıkla.\n"
          "5. **Soru Değerlendirmesi:** Eğer sorunun kendisinde, seçeneklerde veya belirtilen doğru cevapta bir hata, belirsizlik veya mantıksızlık varsa, bunu \"SORU HATALI OLABİLİR\" başlığı altında net bir şekilde belirt ve nedenini açıkla.";

      Map<String, dynamic> requestPayload = {
        'prompt': promptText,
        'user_id': userId,
        'question_id': widget.questionData['id'],
        'created_at': FieldValue.serverTimestamp(),
      };

      if (hasImage) {
        requestPayload['image_url'] = FirebaseService.getFullUrl(imageUrl);
      }

      final docRef = await FirebaseFirestore.instance.collection('ai_requests').add(requestPayload);

      docRef.snapshots().listen((snapshot) {
        if (!snapshot.exists) return;
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('status')) {
          final state = data['status']['state'];
          if (state == 'COMPLETED') {
            if (mounted) {
              setState(() {
                _aiSolution = data['response'];
                _isAiLoading = false;
              });
            }
          } else if (state == 'ERRORED') {
            if (mounted) {
              setState(() {
                _aiError = "Yapay zeka bir hatayla karşılaştı: ${data['status']['error']}";
                _isAiLoading = false;
              });
            }
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiError = 'İstek gönderilemedi: $e';
          _isAiLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final options = widget.questionData['options'] as Map<String, dynamic>;
    final imageUrl = widget.questionData['image_url'];

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: PageView(
        controller: _pageController,
        physics: _isDrawingPageLocked ? const NeverScrollableScrollPhysics() : null,
        onPageChanged: (index) {
          if (index == 2) {
            _getAiSolution();
          }
        },
        children: [
          _buildDrawingPage(),
          _buildQuestionPage(imageUrl, options),
          _buildAiSolutionPage(),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(String? imageUrl, Map<String, dynamic> options) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isAlreadySolved)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.greenAccent.withOpacity(0.5) : Colors.green.shade300)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified, color: isDark ? Colors.greenAccent : Colors.green),
                          const SizedBox(width: 8),
                          Text('Çözüldü (Puan Alındı)', style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      )
                    ),
                  GestureDetector(
                    onTap: () {
                      final authorId = widget.questionData['author_id'];
                      if (authorId != null && authorId.isNotEmpty && _authorName != 'Anonim') {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: authorId)));
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Ekleyen: $_authorName',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                            decoration: _authorName != 'Anonim' && _authorName != 'Yükleniyor...' ? TextDecoration.underline : TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.questionData['text'] ?? 'Soru metni yüklenemedi.', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  if (imageUrl != null)
                    GestureDetector(
                      onTap: () async {
                        final updatedStrokes = await Navigator.of(context).push<List<Stroke>>(
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageScreen(
                              imageUrl: FirebaseService.getFullUrl(imageUrl),
                              initialStrokes: _imageStrokes,
                            ),
                          ),
                        );
                        if (updatedStrokes != null && mounted) {
                          setState(() {
                            _imageStrokes = updatedStrokes;
                          });
                        }
                      },
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: CachedNetworkImage(imageUrl: FirebaseService.getFullUrl(imageUrl), placeholder: (context, url) => const CircularProgressIndicator(), errorWidget: (context, url, error) => const Icon(Icons.error), height: 150, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ...options.entries.map((entry) {
                    final optionKey = entry.key;
                    Color? buttonColor;
                    Color? textColor = isDark ? Colors.white : Colors.black87;
                    if (_isAnswered) {
                      if (optionKey == _correctOption) {
                        buttonColor = Colors.green.withOpacity(0.3);
                        textColor = isDark ? Colors.greenAccent : Colors.green[900];
                      } else if (optionKey == _selectedOption) {
                        buttonColor = Colors.red.withOpacity(0.3);
                        textColor = isDark ? Colors.redAccent : Colors.red[900];
                      }
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _handleAnswer(optionKey),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: buttonColor,
                            side: BorderSide(color: buttonColor != null ? Colors.transparent : Theme.of(context).primaryColor)
                          ),
                          child: Align(alignment: Alignment.centerLeft, child: Text('$optionKey) ${entry.value}', style: TextStyle(color: textColor))),
                        ),
                      ),
                    );
                  }).toList(),
                  const Padding(
                    padding: EdgeInsets.only(top: 24.0),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
                              Text(" Çizim Ekranı", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          Row(
                            children: [
                              Text("Yapay Zeka Çözümü ", style: TextStyle(color: Colors.grey)),
                              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(onPressed: _toggleLike, icon: Icon(_isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined, color: _isLiked ? Colors.blue : Colors.grey), tooltip: 'Beğen'),
              IconButton(onPressed: _toggleSave, icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: _isSaved ? Colors.amber[700] : Colors.grey), tooltip: 'Kaydet'),
              IconButton(onPressed: _reportQuestion, icon: const Icon(Icons.flag_outlined, color: Colors.grey), tooltip: 'Soruyu Bildir'),
              IconButton(onPressed: _shareQuestion, icon: const Icon(Icons.share, color: Colors.grey), tooltip: 'Paylaş'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDrawingPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.brush, color: Colors.orange),
              SizedBox(width: 8),
              Text('Karalama & Çizim Ekranı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 20),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DrawingCanvasWidget(
                  isDarkTheme: Theme.of(context).brightness == Brightness.dark,
                  onLockChanged: (isLocked) {
                    setState(() {
                      _isDrawingPageLocked = isLocked;
                    });
                    if (widget.onLockChanged != null) {
                      widget.onLockChanged!(isLocked); 
                    }
                  },
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Soruya dönmek için ekranı sağa kaydırın", style: TextStyle(color: Colors.grey)),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSolutionPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.psychology_alt, color: Colors.blue),
              SizedBox(width: 8),
              Text('Yapay Zeka Çözümü', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 20),
          Expanded(
            child: _isAiLoading
                ? const Center(child: CircularProgressIndicator())
                : _aiError != null
                    ? Center(child: Text(_aiError!, style: const TextStyle(color: Colors.red)))
                    : _aiSolution != null
                        ? SingleChildScrollView(
                            child: MarkdownBody(
                              data: _aiSolution!,
                              selectable: true,
                              builders: {
                                'math': MathBuilder(),
                              },
                              extensionSet: md.ExtensionSet(
                                md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                                [
                                  MathSyntax(),
                                  ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                                ],
                              ),
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(fontSize: 16, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                                h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                                h3: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                                strong: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                              ),
                            ),
                          )
                        : const Center(child: Text("Çözüm yükleniyor...")),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
                  Text("Soruya dönmek için sola kaydırın", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _debounce;
  
  List<dynamic> _questionResults = [];
  List<dynamic> _userResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose(); _debounce?.cancel(); _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 750), () => _performSearch());
  }
  
  Future<void> _performSearch() async {
      if (_searchController.text.length < 3) {
          setState(() { _questionResults = []; _userResults = []; });
          return;
      }
      setState(() => _isLoading = true);
      try {
          final results = await Future.wait([FirebaseService.searchQuestions(_searchController.text), FirebaseService.searchUsers(_searchController.text)]);
          if(mounted) {
            setState(() { 
                _questionResults = results[0]; 
                _userResults = results[1]; 
            });
          }
      } catch (e) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      } finally {
          if(mounted) setState(() => _isLoading = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ara'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.question_answer), text: "Sorular"),
            Tab(icon: Icon(Icons.people), text: "Kullanıcılar")
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(8.0), child: TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Soru veya kullanıcı ara...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
          if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator())),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _questionResults.isEmpty && !_isLoading
                    ? const Center(child: Text('Arama sonucu bulunamadı.'))
                    : ListView.builder(itemCount: _questionResults.length, itemBuilder: (context, index) {
                        final question = _questionResults[index];
                        return ListTile(
                            title: Text(question['text']), 
                            subtitle: Text(question['course_name'] ?? ''),
                            onTap: () {
                              final linkId = question['link_id'];
                              if (linkId != null) {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => SingleQuestionViewer(linkId: linkId)));
                              }
                            }
                        );
                      }),
                _userResults.isEmpty && !_isLoading
                    ? const Center(child: Text('Arama sonucu bulunamadı.'))
                    : ListView.builder(itemCount: _userResults.length, itemBuilder: (context, index) {
                        final user = _userResults[index];
                        return ListTile(
                            leading: CircleAvatar(backgroundImage: user['avatar_url'] != null ? CachedNetworkImageProvider(FirebaseService.getFullUrl(user['avatar_url'])) : null), 
                            title: Text(user['username']),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: user['id']))),
                        );
                      }),
              ],
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  @override
  void initState() {
      super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshProfile());
  }

  Future<void> _refreshProfile() async {
      try {
          final results = await Future.wait([
            FirebaseService.getMyProfile(),
            FirebaseService.getUserRank(),
          ]);

          final profileData = results[0];
          final rankData = results[1];

          profileData.addAll(rankData);

          if(mounted) {
            Provider.of<UserProvider>(context, listen: false).setUser(profileData);
          }
      } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Profil bilgileri yenilenemedi: ${e.toString().replaceAll('Exception: ', '')}'))
            );
          }
      }
  }

  Widget _buildProfileButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) => ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 20)));
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilim'), actions: [IconButton(onPressed: () async { await FirebaseService.logout(); if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false); }, icon: const Icon(Icons.logout), tooltip: 'Çıkış Yap')]),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.username.isEmpty) return const Center(child: CircularProgressIndicator());
          
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () async { if (await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())) == true) _refreshProfile(); },
                            child: Stack(
                              children: [
                                CircleAvatar(radius: 50, backgroundImage: userProvider.avatarUrl != null ? CachedNetworkImageProvider(FirebaseService.getFullUrl(userProvider.avatarUrl)) : null, child: userProvider.avatarUrl == null ? const Icon(Icons.person, size: 50) : null),
                                Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.white, size: 16)))
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(child: Text(userProvider.username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                        const SizedBox(height: 8),
                        Center(child: Text('Güncel Sezon Puanı: ${userProvider.score}', style: TextStyle(fontSize: 20, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))),
                        const SizedBox(height: 4),
                        Center(child: Text('Puanlar YKS gününden sonra yeni sezon için sıfırlanır', style: TextStyle(fontSize: 10, color: Colors.grey[700]))),
                        const SizedBox(height: 12),
                        // --- GEÇMİŞ SEZON ARŞİVİ KARTI ---
                        if (userProvider.archivedScores.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                            child: Card(
                              color: Colors.amber.shade50,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.shade200)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.history, color: Colors.amber),
                                        SizedBox(width: 8),
                                        Text('Geçmiş Sezon Arşivi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                    const Divider(),
                                    ...userProvider.archivedScores.entries.map((e) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${e.key} Sezonu', style: const TextStyle(fontWeight: FontWeight.w500)),
                                          Text('${NumberFormat.decimalPattern().format(e.value)} Puan', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                        ],
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        RankAndBadges(
                          rank: userProvider.rank,
                          totalUsers: userProvider.totalUsers,
                          badges: userProvider.badges,
                          courseProgress: userProvider.courseProgress, 
                          earnedRanks: userProvider.earnedRanks,
                        ),
                
                        const SizedBox(height: 20),
                        _buildProfileButton(context, icon: Icons.bar_chart, label: "İstatistiklerim", onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsScreen()))),
                        const SizedBox(height: 12),
                        _buildProfileButton(context, icon: Icons.emoji_events, label: "Başarımlarım", onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AchievementsScreen(
                          username: userProvider.username,
                          courseProgress: userProvider.courseProgress,
                          currentStreak: userProvider.currentStreak,
                          readPdfsCount: userProvider.readPdfs.length,
                          earnedRanks: userProvider.earnedRanks,
                          badges: userProvider.badges,
                        )))),
                        const SizedBox(height: 12),
                        _buildProfileButton(context, icon: Icons.thumb_up, label: "Beğenilerim", onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuestionListScreen(title: "Beğenilen Sorular", questionsFuture: FirebaseService.getLikedQuestions())))),
                        const SizedBox(height: 12),
                        _buildProfileButton(context, icon: Icons.bookmark, label: "Kaydettiklerim", onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuestionListScreen(title: "Kaydedilen Sorular", questionsFuture: FirebaseService.getSavedQuestions())))),
                         const SizedBox(height: 12),
                        _buildProfileButton(context, icon: Icons.settings, label: "Ayarlar", onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        }),
                        const SizedBox(height: 24),
                        const Text("Onaylanan Sorularım", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        FutureBuilder<List<dynamic>>(
                          future: FirebaseService.getSubmittedQuestions(), 
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(child: Text("Onaylanmış sorunuz bulunmuyor."));
                            }
                            final questions = snapshot.data!;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: questions.length,
                              itemBuilder: (context, index) {
                                  final q = questions[index];
                                  return Card(
                                      child: ListTile(
                                          title: Text(q['text'], maxLines: 1, overflow: TextOverflow.ellipsis), 
                                          subtitle: Text(q['course_name'] ?? ''),
                                          onTap: () {
                                              final linkId = q['link_id'];
                                              if (linkId != null) {
                                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => SingleQuestionViewer(linkId: linkId)));
                                              }
                                          },
                                      ),
                                  );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AchievementsScreen extends StatelessWidget {
  final String username;
  final Map<String, dynamic> courseProgress;
  final int currentStreak;
  final int readPdfsCount;
  final List<dynamic> earnedRanks;
  final List<dynamic> badges;

  const AchievementsScreen({
    super.key,
    required this.username,
    required this.courseProgress,
    required this.currentStreak,
    required this.readPdfsCount,
    required this.earnedRanks,
    required this.badges,
  });

  Widget _buildRankingBadge(String id, String name, String desc, bool isUnlocked) {
    IconData icon = Icons.shield;
    Color color = Colors.grey;
    if (id == 'gold') { icon = Icons.emoji_events; color = Colors.amber; }
    else if (id == 'silver') { icon = Icons.emoji_events; color = Colors.grey.shade400; }
    else if (id == 'bronze') { icon = Icons.emoji_events; color = Colors.brown.shade400; }

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 50, color: isUnlocked ? color : Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isUnlocked ? Colors.black87 : Colors.grey)),
          Text(desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isUnlocked ? Colors.grey.shade700 : Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$username - Başarımlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Sıralama Rozetleri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRankingBadge('gold', 'Altın', 'İlk 100', badges.contains('gold')),
                  _buildRankingBadge('silver', 'Gümüş', 'İlk 1.000', badges.contains('silver')),
                  _buildRankingBadge('bronze', 'Bronz', 'İlk 10.000', badges.contains('bronze')),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(thickness: 2),
          const SizedBox(height: 16),

          const Text('Soru Çözüm Rozetleri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 12),
          ...AchievementConfig.categories.map((cat) {
            int total = 0;
            for (var cid in cat['courseIds']) {
              total += ((courseProgress[cid] ?? 0) as num).toInt();
            }

            Map<String, dynamic>? currentLevel;
            Map<String, dynamic>? nextLevel = AchievementConfig.levels.first;

            for (int i = 0; i < AchievementConfig.levels.length; i++) {
              final level = AchievementConfig.levels[i];
              if (total >= level['threshold']) {
                currentLevel = level;
                nextLevel = i + 1 < AchievementConfig.levels.length ? AchievementConfig.levels[i + 1] : null;
              }
            }

            final progressToNext = nextLevel != null
                ? (total / nextLevel['threshold']).clamp(0.0, 1.0)
                : 1.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentLevel != null ? currentLevel['color'] : Colors.grey.shade300,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat['symbol'].toUpperCase(),
                        style: TextStyle(
                          color: currentLevel != null ? Colors.white : Colors.grey.shade500,
                          fontSize: 28,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            currentLevel != null ? '${currentLevel['name']} Rozeti' : 'Henüz rozet kazanılmadı',
                            style: TextStyle(color: currentLevel != null ? Colors.black87 : Colors.grey, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          if (nextLevel != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$total', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('${nextLevel['threshold']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: progressToNext,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(nextLevel['color']),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 4),
                            Text('Sonraki: ${nextLevel['name']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ] else ...[
                            const Text('Maksimum seviyeye ulaşıldı!', style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          const Divider(thickness: 2),
          const SizedBox(height: 16),
          const Text('Seriler & Özel Başarımlar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 12),

          // Puana Dayalı Rütbeler
          const Text('Rütbeler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          ...AchievementConfig.ranks.map((rank) {
            bool isUnlocked = earnedRanks.contains(rank['id']);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: isUnlocked ? Colors.white : Colors.grey.shade100,
              child: ListTile(
                leading: Image.asset(
                  rank['icon'],
                  width: 40, height: 40,
                  color: isUnlocked ? null : Colors.grey.shade400,
                  colorBlendMode: isUnlocked ? null : BlendMode.srcIn,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: isUnlocked ? Colors.amber : Colors.grey.shade300),
                    child: const Icon(Icons.military_tech, color: Colors.white, size: 24),
                  ),
                ),
                title: Text(rank['name'], style: TextStyle(fontWeight: FontWeight.bold, color: isUnlocked ? Colors.black87 : Colors.grey)),
                subtitle: Text('${NumberFormat.decimalPattern().format(rank['threshold'])} Puan', style: TextStyle(color: isUnlocked ? Colors.deepPurple : Colors.grey)),
                trailing: isUnlocked ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.lock, color: Colors.grey),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Seriler (Streaks)
          ...AchievementConfig.series.map((serie) {
            double progress = (currentStreak / serie['target']).clamp(0.0, 1.0);
            bool isCompleted = currentStreak >= serie['target'];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Image.asset(
                      serie['icon'],
                      width: 50, height: 50,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: isCompleted ? Colors.amber : Colors.grey.shade300),
                        child: Icon(isCompleted ? Icons.star : Icons.star_border, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(serie['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(serie['desc'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$currentStreak Gün', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('${serie['target']} Gün', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.green : Colors.blue),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Kütüphaneci Başarımı
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Image.asset(
                    AchievementConfig.librarian['icon'],
                    width: 50, height: 50,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: readPdfsCount > 0 ? Colors.purple : Colors.grey.shade300),
                      child: Icon(readPdfsCount > 0 ? Icons.menu_book : Icons.menu_book_outlined, color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AchievementConfig.librarian['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(AchievementConfig.librarian['desc'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('Okunan PDF Sayısı: $readPdfsCount', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDownloading = false;
  bool _isDeleting = false;
  String _currentTheme = 'Mor';
  bool _isSubscribed = false;
  bool _isIncognito = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _isSubscribed = userProvider.userData['is_subscribed'] ?? false;
    _isIncognito = userProvider.isIncognito;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = await SettingsService.getThemeColor();
    if (mounted) {
      setState(() {
        _currentTheme = theme;
      });
    }
  }

  Future<void> _downloadData() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Verilerini İndir',
      content: 'Hesabınızla ilgili tüm verilerin (profil, istatistik, beğeniler) bir kopyasını hazırlamak istediğinizden emin misiniz?',
      confirmText: 'Evet, Hazırla',
    );

    if (confirmed != true) return;

    setState(() => _isDownloading = true);
    try {
      final filePath = await FirebaseService.downloadMyData();
      
      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;

        await Share.shareXFiles(
          [
            // Doğrudan dosya yolunu veriyoruz. share_plus paketi FileProvider iznini kendi halleder.
            XFile(
              filePath,
              mimeType: 'application/zip',
            )
          ],
          text: 'Sınavgram Verilerim',
          // iPad çökmelerini önlemek için:
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null, 
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veri dosyası başarıyla hazırlandı.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Hesabı Sil',
      content: 'Bu işlem geri alınamaz! Hesabınızı ve ilişkili tüm verileri kalıcı olarak silmek istediğinizden emin misiniz?',
      confirmText: 'Evet, Sil',
      isDestructive: true,
    );
    
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      final result = await FirebaseService.deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.green, duration: const Duration(seconds: 5)),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive ? Colors.red : Theme.of(context).primaryColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tema Seçin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeNotifier.themeColors.keys.map((colorName) {
              return RadioListTile<String>(
                title: Text(colorName),
                value: colorName,
                groupValue: _currentTheme,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currentTheme = value;
                    });
                    context.read<ThemeNotifier>().setTheme(value);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('Görünüm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                ),
                Card(
                child: Column( // Eğer tek bir listTile varsa Column içine alın
                  children: [
                    ListTile(
                      leading: const Icon(Icons.color_lens),
                      title: const Text('Uygulama Teması'),
                      subtitle: Text(_currentTheme),
                      onTap: _showThemeDialog,
                    ),
                    const Divider(height: 1), // YENİ
                    SwitchListTile(           // YENİ
                      secondary: const Icon(Icons.dark_mode),
                      title: const Text('Karanlık Mod'),
                      value: context.watch<ThemeNotifier>().themeMode == ThemeMode.dark,
                      onChanged: (bool value) {
                        context.read<ThemeNotifier>().toggleDarkMode(value);
                      },
                    ),
                  ],
                ),
              ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                ),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.visibility_off),
                        title: const Text('Liderlik Tablosunda Gizlen'),
                        subtitle: const Text('Açık olduğunda sıralamada başkalarına görünmezsiniz.'),
                        value: _isIncognito,
                        onChanged: (bool value) async {
                          try {
                            await FirebaseService.updateIncognitoStatus(value);
                            setState(() {
                              _isIncognito = value;
                            });
                            // Lokal State'i anında güncelliyoruz
                            if (mounted) {
                              Provider.of<UserProvider>(context, listen: false).userData['is_incognito'] = value;
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Hata: ${e.toString()}"))
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.mail_outline),
                        title: const Text('E-Bülten Aboneliği'),
                        subtitle: const Text('Yeni sorulardan e-posta ile haberdar ol.'),
                        value: _isSubscribed,
                        onChanged: (bool value) async {
                          try {
                            await FirebaseService.updateNewsletterSubscription(value);
                            setState(() {
                              _isSubscribed = value;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(value ? "Bültene abone olundu." : "Bültenden çıkıldı."))
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("İşlem başarısız: ${e.toString().replaceAll('Exception: ', '')}"))
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Text('Hesap Yönetimi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: _isDownloading ? const CircularProgressIndicator() : const Icon(Icons.download_for_offline),
                        title: const Text('Verilerimi İndir'),
                        subtitle: const Text('Hesap bilgilerinizi ve aktivitelerinizi indirin.'),
                        onTap: _isDownloading ? null : _downloadData,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: _isDeleting ? const CircularProgressIndicator() : const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text('Hesabımı Kalıcı Olarak Sil', style: TextStyle(color: Colors.red)),
                        subtitle: const Text('Bu işlem geri alınamaz.'),
                        onTap: _isDeleting ? null : _deleteAccount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = FirebaseService.getUserStats();
  }
  
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İstatistiklerim')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error.toString().replaceAll('Exception: ', '')}"));
                if (!snapshot.hasData || (snapshot.data!['rates'] == null)) return const Center(child: Text("İstatistik bulunamadı."));
          
                final stats = snapshot.data!;
                final rates = stats['rates'] as Map<String, dynamic>? ?? {};
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ListView(
                    children: [
                      const SizedBox(height: 12),
                      _buildStatCard("Toplam Cevap", (stats['total_answered_questions'] ?? 0).toString(), Icons.question_answer),
                      const SizedBox(height: 8),
                      _buildStatCard("Doğru Cevap", (stats['correctly_answered_questions'] ?? 0).toString(), Icons.check_circle_outline),
                      const SizedBox(height: 8),
                      _buildStatCard("Yanlış Cevap", (stats['incorrectly_answered_questions'] ?? 0).toString(), Icons.highlight_off),
                      const SizedBox(height: 8),
                      _buildStatCard("Doğruluk Oranı", "%${rates['true'] ?? 0.0}", Icons.pie_chart),
                       const SizedBox(height: 8),
                      _buildStatCard("Başarı Yüzdesi", "%${stats['accuracy_rate_excluding_blanks'] ?? 0.0}", Icons.trending_up),
                       const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

class QuestionListScreen extends StatefulWidget {
  final String title;
  final Future<List<dynamic>> questionsFuture;
  
  const QuestionListScreen({super.key, required this.title, required this.questionsFuture});

  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: widget.questionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error.toString().replaceAll('Exception: ', '')}"));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Gösterilecek soru bulunamadı."));
          
                final questions = snapshot.data!;
                return ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(question['text'], maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(question['course_name'] ?? 'Bilinmeyen Ders'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SingleQuestionViewer(linkId: question['link_id']))),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

class VerifyEmailScreen extends StatefulWidget {
    final String email;
    const VerifyEmailScreen({super.key, required this.email});

    @override
    State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
    bool _isLoading = false;

    Future<void> _resendEmail() async {
        setState(() => _isLoading = true);
        try {
            final result = await FirebaseService.resendVerificationEmail(widget.email);
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.green));
        } catch (e) {
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
        } finally {
            if(mounted) setState(() => _isLoading = false);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('E-posta Doğrulama')),
            body: Center(
                child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            const Icon(Icons.mark_email_unread_outlined, size: 100, color: Colors.deepPurple),
                            const SizedBox(height: 24),
                            const Text('Hesabınızı Doğrulayın', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            Text('Lütfen ${widget.email} adresine gönderilen doğrulama bağlantısına tıklayın. E-postayı görmüyorsanız, spam klasörünüzü kontrol edin.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 32),
                            _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _resendEmail, child: const Text('Doğrulama E-postasını Tekrar Gönder')),
                             const SizedBox(height: 16),
                             TextButton(
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut(); 
                                  if (context.mounted) {
                                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                                  }
                                }, 
                                child: const Text('Giriş Ekranına Dön')
                             )
                        ],
                    ),
                ),
            ),
        );
    }
}

class SubmitQuestionScreen extends StatefulWidget {
  const SubmitQuestionScreen({super.key});

  @override
  State<SubmitQuestionScreen> createState() => _SubmitQuestionScreenState();
}

class _SubmitQuestionScreenState extends State<SubmitQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _optionEController = TextEditingController();
  
  String? _selectedCourseId;
  String? _selectedSubtopicId;
  String _correctOption = 'A';
  XFile? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() => _imageFile = image);
  }

  // SubmitQuestionScreen içindeki _submit() metodunu bulun:
  Future<void> _submit() async {
      if (!_formKey.currentState!.validate() || _selectedSubtopicId == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tüm alanları doldurun ve bir alt konu seçin.')));
          return;
      }
      setState(() => _isLoading = true);
      final fields = {'course_id': _selectedCourseId.toString(), 'subtopic_id': _selectedSubtopicId.toString(), 'text': _textController.text, 'option_a': _optionAController.text, 'option_b': _optionBController.text, 'option_c': _optionCController.text, 'option_d': _optionDController.text, 'option_e': _optionEController.text, 'correct_option': _correctOption};
      try {
          final result = await FirebaseService.submitQuestion(fields, _imageFile);
          if (mounted) {
              if(!context.read<UserProvider>().isPremium) {
                context.read<AdService>().showInterstitialAd();
              }
              // await FirebaseService.addQuestionScore(); // BU SATIRI SİLİN (veya yorum satırı yapın)
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.green));
              Navigator.of(context).pop();
          }
      } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      } finally {
          if (mounted) setState(() => _isLoading = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Soru Gönder')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<List<dynamic>>(
                      future: FirebaseService.getCourses(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        return DropdownButtonFormField<String>(
                          value: _selectedCourseId,
                          hint: const Text("Ders Seçin"),
                          onChanged: (value) => setState(() { _selectedCourseId = value; _selectedSubtopicId = null; }),
                          items: snapshot.data!.map<DropdownMenuItem<String>>((course) => DropdownMenuItem<String>(value: course['id'], child: Text(course['name']))).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedCourseId != null)
                      FutureBuilder<List<dynamic>>(
                        future: FirebaseService.getSubtopics(_selectedCourseId!),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Text('Alt konular yükleniyor...');
                          return DropdownButtonFormField<String>(
                             value: _selectedSubtopicId,
                             hint: const Text("Alt Konu Seçin"),
                             onChanged: (value) => setState(() => _selectedSubtopicId = value),
                             items: snapshot.data!.map<DropdownMenuItem<String>>((subtopic) => DropdownMenuItem<String>(value: subtopic['id'], child: Text(subtopic['name']))).toList(),
                             validator: (v) => v == null ? 'Alt konu seçimi zorunludur' : null,
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _textController, decoration: const InputDecoration(labelText: 'Soru Metni'), maxLines: 5, validator: (v) => v!.isEmpty ? 'Soru metni boş olamaz' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _optionAController, decoration: const InputDecoration(labelText: 'A Seçeneği'), validator: (v) => v!.isEmpty ? 'Boş olamaz' : null),
                    TextFormField(controller: _optionBController, decoration: const InputDecoration(labelText: 'B Seçeneği'), validator: (v) => v!.isEmpty ? 'Boş olamaz' : null),
                    TextFormField(controller: _optionCController, decoration: const InputDecoration(labelText: 'C Seçeneği'), validator: (v) => v!.isEmpty ? 'Boş olamaz' : null),
                    TextFormField(controller: _optionDController, decoration: const InputDecoration(labelText: 'D Seçeneği'), validator: (v) => v!.isEmpty ? 'Boş olamaz' : null),
                    TextFormField(controller: _optionEController, decoration: const InputDecoration(labelText: 'E Seçeneği'), validator: (v) => v!.isEmpty ? 'Boş olamaz' : null),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _correctOption,
                      decoration: const InputDecoration(labelText: 'Doğru Seçenek'),
                      items: ['A', 'B', 'C', 'D', 'E'].map((label) => DropdownMenuItem(child: Text(label), value: label)).toList(),
                      onChanged: (value) => setState(() => _correctOption = value!),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('Resim Seç')),
                        const SizedBox(width: 10),
                        if (_imageFile != null) Expanded(child: Text(_imageFile!.name, overflow: TextOverflow.ellipsis))
                      ],
                    ),
                     const SizedBox(height: 24),
                     _isLoading ? const Center(child: CircularProgressIndicator()) : Center(child: ElevatedButton(onPressed: _submit, child: const Text('Onaya Gönder'))),
                  ],
                ),
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  XFile? _avatarFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = Provider.of<UserProvider>(context, listen: false).username;
  }

  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    setState(() => _avatarFile = image);
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
        final result = await FirebaseService.updateUserProfile(_usernameController.text, _avatarFile);
        if (mounted) {
            Provider.of<UserProvider>(context, listen: false).updateUserPartial(result['user']);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil başarıyla güncellendi."), backgroundColor: Colors.green));
            Navigator.of(context).pop(true);
        }
    } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
        if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(radius: 60, backgroundImage: _avatarFile != null ? FileImage(File(_avatarFile!.path)) : (context.watch<UserProvider>().avatarUrl != null ? CachedNetworkImageProvider(FirebaseService.getFullUrl(context.watch<UserProvider>().avatarUrl)) : null) as ImageProvider?),
                          Positioned(bottom: 0, right: 0, child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.deepPurple), onPressed: _pickAvatar))
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Kullanıcı Adı'), validator: (value) => value!.isEmpty ? 'Kullanıcı adı boş olamaz' : null),
                    const SizedBox(height: 32),
                    _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _updateProfile, child: const Text('Değişiklikleri Kaydet'))
                  ],
                ),
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await FirebaseService.requestPasswordReset(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(Icons.lock_reset, size: 80, color: Theme.of(context).primaryColor),
                const SizedBox(height: 24),
                const Text(
                  'Kayıtlı e-posta adresinizi girerek şifre sıfırlama talimatlarını alabilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-posta Adresi',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Lütfen e-posta adresinizi girin.';
                    if (!val.contains('@')) return 'Lütfen geçerli bir e-posta girin.';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _sendResetRequest,
                        child: const Text('Sıfırlama Linki Gönder', style: TextStyle(fontSize: 16)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;

  Stroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
  });
}

class StrokePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  StrokePainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // Silgi için saydamlık efekti (arkaplanın görünmesini sağlar)
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (var stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }

    canvas.restore();
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    final paint = Paint()
      ..color = stroke.isEraser ? Colors.transparent : stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class DrawingCanvasWidget extends StatefulWidget {
  final bool isDarkTheme;
  final ValueChanged<bool>? onLockChanged;

  const DrawingCanvasWidget({
    super.key, 
    this.isDarkTheme = false, 
    this.onLockChanged,
  });

  @override
  State<DrawingCanvasWidget> createState() => _DrawingCanvasWidgetState();
}

class _DrawingCanvasWidgetState extends State<DrawingCanvasWidget> with AutomaticKeepAliveClientMixin {
  List<Stroke> _strokes = [];
  Stroke? _currentStroke;
  bool _isEraser = false;
  bool _isLocked = false;
  int _pointerCount = 0; // Ekrana dokunan parmak sayısını takip edeceğiz

  Color _selectedColor = Colors.blue;
  double _strokeWidth = 4.0;
  final List<Color> _availableColors = [Colors.red, Colors.blue, Colors.green, Colors.black];

  @override
  bool get wantKeepAlive => true; 

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        InteractiveViewer(
          panEnabled: !_isLocked, // Kilitliyken tek parmakla kaydırma kapalı (Çizim için)
          scaleEnabled: true, // İki parmakla büyütme HER ZAMAN AÇIK
          minScale: 1.0,
          maxScale: 4.0,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              _pointerCount++;
              // Eğer kilit açık değilse VEYA birden fazla parmak dokunuyorsa çizim yapma
              if (!_isLocked || _pointerCount > 1) {
                _currentStroke = null;
                return;
              }
              setState(() {
                _currentStroke = Stroke(
                  points: [event.localPosition],
                  color: _selectedColor,
                  width: _isEraser ? 25.0 : _strokeWidth,
                  isEraser: _isEraser,
                );
              });
            },
            onPointerMove: (event) {
              // Sadece tek parmak dokunuyorsa çizgiyi çiz
              if (_currentStroke != null && _pointerCount == 1) {
                setState(() => _currentStroke!.points.add(event.localPosition));
              }
            },
            onPointerUp: (event) {
              _pointerCount--;
              if (_pointerCount < 0) _pointerCount = 0;
              
              if (_currentStroke != null) {
                setState(() => _strokes.add(_currentStroke!));
                _currentStroke = null;
              }
            },
            onPointerCancel: (event) {
              _pointerCount--;
              if (_pointerCount < 0) _pointerCount = 0;
              _currentStroke = null;
            },
            child: Container(
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: StrokePainter(strokes: _strokes, currentStroke: _currentStroke),
              ),
            ),
          ),
        ),
        // Kontrol Paneli (Güncellendi)
        Positioned(
          top: 10, right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_isLocked ? Icons.lock : Icons.lock_open, color: _isLocked ? Colors.orange : Colors.white),
                      onPressed: () {
                        setState(() => _isLocked = !_isLocked);
                        if (widget.onLockChanged != null) {
                          widget.onLockChanged!(_isLocked);
                        }
                      },
                      tooltip: "Çizim Kilidi",
                    ),
                    if (_isLocked) ...[
                      IconButton(icon: Icon(Icons.edit, color: !_isEraser ? Colors.blue : Colors.white), onPressed: () => setState(() => _isEraser = false)),
                      IconButton(icon: Icon(Icons.cleaning_services, color: _isEraser ? Colors.blue : Colors.white), onPressed: () => setState(() => _isEraser = true)),
                      IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.red), onPressed: () => setState(() => _strokes.clear())),
                    ]
                  ],
                ),
                // YENİ EKLENEN RENK VE KALINLIK PANELİ
                if (_isLocked && !_isEraser) ...[
                  SizedBox(
                    width: 150,
                    child: Slider(
                      value: _strokeWidth,
                      min: 2.0, max: 12.0,
                      activeColor: _selectedColor,
                      inactiveColor: Colors.grey,
                      onChanged: (val) => setState(() => _strokeWidth = val),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _availableColors.map((c) => GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: _selectedColor == c ? Colors.white : Colors.transparent, width: 2),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FullScreenImageScreen extends StatefulWidget {
  final String imageUrl;
  final List<Stroke> initialStrokes; // YENİ: Başlangıç çizimlerini almak için eklendi

  const FullScreenImageScreen({super.key, required this.imageUrl, required this.initialStrokes});

  @override
  State<FullScreenImageScreen> createState() => _FullScreenImageScreenState();
}

class _FullScreenImageScreenState extends State<FullScreenImageScreen> {
  late List<Stroke> _strokes;
  Stroke? _currentStroke;
  bool _isEraser = false;
  int _pointerCount = 0; // Parmak takibi (2 parmakla zoom, 1 parmakla çizim için)

  Color _selectedColor = Colors.redAccent;
  double _strokeWidth = 4.0;
  final List<Color> _availableColors = [Colors.red, Colors.blue, Colors.green, Colors.black];

  @override
  void initState() {
    super.initState();
    // YENİ: Önceki ekrandan gelen çizimleri kopyalayarak başla
    _strokes = List.from(widget.initialStrokes);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // YENİ: Android/iOS sistem geri tuşuna basıldığında çizimleri geriye döndür
        Navigator.of(context).pop(_strokes); 
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black, foregroundColor: Colors.white,
          title: const Text("Görsel Analiz"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            // YENİ: Uygulama içi geri tuşuna basıldığında çizimleri geriye döndür
            onPressed: () => Navigator.of(context).pop(_strokes),
          ),
          actions: [
            // Kilit mekanizması kaldırıldı
            IconButton(icon: Icon(Icons.edit, color: !_isEraser ? Colors.blue : Colors.white), onPressed: () => setState(() => _isEraser = false)),
            IconButton(icon: Icon(Icons.cleaning_services, color: _isEraser ? Colors.blue : Colors.white), onPressed: () => setState(() => _isEraser = true)),
            IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () {
              setState(() => _strokes.clear());
            }),
          ],
        ),
        body: Stack(
          children: [
            InteractiveViewer(
              panEnabled: false, // YENİ: 1 parmakla kaydırma iptal edildi, 2 parmakla (pinch to zoom/pan) otomatik çalışmaya devam eder
              scaleEnabled: true,
              minScale: 1.0,
              maxScale: 5.0,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  _pointerCount++;
                  // Birden fazla parmak dokunuyorsa çizim yapma, zoom/pan moduna bırak
                  if (_pointerCount > 1) {
                    _currentStroke = null;
                    return;
                  }
                  setState(() {
                    _currentStroke = Stroke(
                      points: [event.localPosition],
                      color: _isEraser ? Colors.transparent : _selectedColor,
                      width: _isEraser ? 30.0 : _strokeWidth,
                      isEraser: _isEraser,
                    );
                  });
                },
                onPointerMove: (event) {
                  if (_currentStroke != null && _pointerCount == 1) {
                    setState(() => _currentStroke!.points.add(event.localPosition));
                  }
                },
                onPointerUp: (event) {
                  _pointerCount--;
                  if (_pointerCount < 0) _pointerCount = 0;

                  if (_currentStroke != null) {
                    setState(() => _strokes.add(_currentStroke!));
                    _currentStroke = null;
                  }
                },
                onPointerCancel: (event) {
                  _pointerCount--;
                  if (_pointerCount < 0) _pointerCount = 0;
                  _currentStroke = null;
                },
                child: Stack(
                  children: [
                    Center(
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.contain, 
                        width: double.infinity, 
                        height: double.infinity,
                      ),
                    ),
                    CustomPaint(
                      painter: StrokePainter(strokes: _strokes, currentStroke: _currentStroke),
                      size: Size.infinite,
                    ),
                  ],
                ),
              ),
            ),
            if (!_isEraser)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _availableColors.map((c) => GestureDetector(
                          onTap: () => setState(() => _selectedColor = c),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: _selectedColor == c ? Colors.white : Colors.transparent, width: 3),
                            ),
                          ),
                        )).toList(),
                      ),
                      Slider(
                        value: _strokeWidth,
                        min: 2.0, max: 12.0,
                        activeColor: _selectedColor,
                        inactiveColor: Colors.grey,
                        onChanged: (val) => setState(() => _strokeWidth = val),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  const PdfViewerScreen({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  Timer? _timer;
  int _secondsSpent = 0;
  bool _isMarked = false;

  @override
  void initState() {
    super.initState();
    // 5 Dakika İzleme Sayacı (Kütüphaneci Başarımı)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsSpent++;
      if (_secondsSpent >= 300 && !_isMarked) { // 300 saniye = 5 dk
        _isMarked = true;
        _markAsRead();
        timer.cancel();
      }
    });
  }

  Future<void> _markAsRead() async {
    try {
      await FirebaseService.markPdfAsRead(widget.pdfUrl);
      if (mounted) {
        final userProv = Provider.of<UserProvider>(context, listen: false);
        userProv.addReadPdf(widget.pdfUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kütüphaneci başarımı için bu PDF okundu olarak işaretlendi!'),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
      debugPrint('PDF işaretleme hatası: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: PDF(
              enableSwipe: true,
              swipeHorizontal: false, 
              autoSpacing: false,
              pageFling: false,
            ).cachedFromUrl(
              widget.pdfUrl,
              placeholder: (double progress) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('PDF Yükleniyor... %${progress.toInt()}'),
                  ],
                ),
              ),
              errorWidget: (dynamic error) => Center(
                child: Text('PDF yüklenirken bir hata oluştu:\n$error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

class PublicProfileScreen extends StatefulWidget {
    final String userId;
    const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
    Map<String, dynamic>? _profileData;
    List<dynamic> _questions = [];
    int _currentPage = 1;
    bool _hasNextPage = true;
    bool _isLoading = false;
    final ScrollController _scrollController = ScrollController();

    @override
    void initState() {
        super.initState();
        _fetchProfileAndQuestions();
        _scrollController.addListener(() {
            if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasNextPage && !_isLoading) {
                _fetchProfileAndQuestions(page: _currentPage + 1);
            }
        });
    }

    @override
    void dispose() {
        _scrollController.dispose();
        super.dispose();
    }

    Future<void> _fetchProfileAndQuestions({int page = 1}) async {
        if (_isLoading) return;
        setState(() => _isLoading = true);
        try {
            final profileData = await FirebaseService.getUserProfile(widget.userId, page: page);
            if(mounted) {
              setState(() {
                  if (_profileData == null) {
                      _profileData = profileData;
                  }
                  final questionData = profileData['approved_questions'];
                  _questions.addAll(questionData['items']);
                  _currentPage = questionData['page'];
                  _hasNextPage = questionData['has_next'];
              });
            }
        } catch (e) {
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profil yüklenemedi: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red));
        } finally {
            if(mounted) setState(() => _isLoading = false);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text(_profileData?['username'] ?? 'Kullanıcı Profili'),
            ),
            body: Column(
              children: [
                Expanded(
                  child: _profileData == null
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                  CircleAvatar(
                                      radius: 50,
                                      backgroundImage: _profileData!['avatar_url'] != null ? CachedNetworkImageProvider(FirebaseService.getFullUrl(_profileData!['avatar_url'])) : null,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(_profileData!['username'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('Güncel Sezon Puanı: ${_profileData!['score']}', style: TextStyle(fontSize: 20, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                                  // --- GEÇMİŞ SEZON ARŞİVİ KARTI (BAŞKA KULLANICI) ---
                                  if (_profileData!['archived_scores'] != null && (_profileData!['archived_scores'] as Map).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                                      child: Card(
                                        color: Colors.amber.shade50,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.shade200)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            children: [
                                              const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.history, color: Colors.amber),
                                                  SizedBox(width: 8),
                                                  Text('Geçmiş Sezon Arşivi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                ],
                                              ),
                                              const Divider(),
                                              ...(_profileData!['archived_scores'] as Map<String, dynamic>).entries.map((e) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text('${e.key} Sezonu', style: const TextStyle(fontWeight: FontWeight.w500)),
                                                    Text('${NumberFormat.decimalPattern().format(e.value)} Puan', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                                  ],
                                                ),
                                              )),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  RankAndBadges(
                                    rank: _profileData!['rank'],
                                    totalUsers: _profileData!['total_users'],
                                    badges: _profileData!['badges'] as List<dynamic>? ?? [],
                                    courseProgress: _profileData!['course_progress'] as Map<String, dynamic>? ?? {},
                                    earnedRanks: _profileData!['earned_ranks'] as List<dynamic>? ?? ['caylak'],
                                  ),
                
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.emoji_events),
                                    label: const Text('Tüm Başarımları Gör'),
                                    onPressed: () {
                                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AchievementsScreen(
                                        username: _profileData!['username'] ?? 'Kullanıcı',
                                        courseProgress: _profileData!['course_progress'] ?? {},
                                        currentStreak: _profileData!['current_streak'] ?? 0,
                                        readPdfsCount: (_profileData!['read_pdfs'] as List?)?.length ?? 0,
                                        earnedRanks: _profileData!['earned_ranks'] ?? ['caylak'],
                                        badges: _profileData!['badges'] ?? [],
                                      )));
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  const Text("Onaylanan Soruları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                   ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _questions.length + (_hasNextPage ? 1 : 0),
                                      itemBuilder: (context, index) {
                                          if(index == _questions.length && _hasNextPage) {
                                              return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                                          }
                                          final q = _questions[index];
                                          return Card(
                                              child: ListTile(
                                                  title: Text(q['text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis), 
                                                  subtitle: Text(q['course_name'] ?? ''),
                                                  onTap: () {
                                                      final linkId = q['link_id'];
                                                      if (linkId != null) {
                                                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => SingleQuestionViewer(linkId: linkId)));
                                                      }
                                                  },
                                              ),
                                          );
                                      }
                                   )
                              ],
                          ),
                      ),
                ),
                const BannerAdWidget(),
              ],
            ),
        );
    }
}

class SingleQuestionViewer extends StatelessWidget {
    final String linkId;
    const SingleQuestionViewer({super.key, required this.linkId});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text("Soru Detayı")),
            body: Column(
              children: [
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                      future: FirebaseService.getQuestionByLinkId(linkId),
                      builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                              return Center(child: Text("Soru yüklenemedi: ${snapshot.error.toString().replaceAll('Exception: ', '')}"));
                          }
                          if (!snapshot.hasData) {
                              return const Center(child: Text("Soru bulunamadı."));
                          }
                          return QuestionCard(
                            questionData: snapshot.data!,
                            courseId: snapshot.data!['course_id'] ?? '',
                            courseName: snapshot.data!['course_name'] ?? '',
                          );
                      },
                  ),
                ),
                const BannerAdWidget(),
              ],
            ),
        );
    }
}

class RankAndBadges extends StatelessWidget {
  final int? rank;
  final int? totalUsers;
  final List<dynamic> badges;
  final Map<String, dynamic> courseProgress;
  final List<dynamic> earnedRanks;

  const RankAndBadges({
    super.key,
    required this.rank,
    required this.totalUsers,
    required this.badges,
    required this.courseProgress,
    required this.earnedRanks,
  });

  Widget _buildManualBadge(String badgeName) {
    IconData badgeIcon = Icons.shield;
    Color badgeColor = Colors.grey;
    String tooltip = "Rozet";

    switch (badgeName.toLowerCase()) {
      case 'gold':
        badgeIcon = Icons.emoji_events;
        badgeColor = Colors.amber;
        tooltip = "Altın Rozet (İlk 100)";
        break;
      case 'silver':
        badgeIcon = Icons.emoji_events;
        badgeColor = Colors.grey.shade400;
        tooltip = "Gümüş Rozet (İlk 1000)";
        break;
      case 'bronze':
        badgeIcon = Icons.emoji_events;
        badgeColor = Colors.brown.shade400;
        tooltip = "Bronz Rozet (İlk 10000)";
        break;
    }
    return Tooltip(message: tooltip, child: Icon(badgeIcon, color: badgeColor, size: 30));
  }

  @override
  Widget build(BuildContext context) {
    if (rank == null || totalUsers == null) {
      return const SizedBox.shrink(); 
    }

    List<Widget> manualBadges = badges.map((b) => _buildManualBadge(b.toString())).toList();

    // En yüksek rütbeyi bul
    Map<String, dynamic>? highestRank;
    for (var r in AchievementConfig.ranks) {
      if (earnedRanks.contains(r['id'])) {
        highestRank = r;
      }
    }

    List<Widget> achievementBadges = [];
    for (var cat in AchievementConfig.categories) {
      int total = 0;
      for (var cid in cat['courseIds']) {
        total += ((courseProgress[cid] ?? 0) as num).toInt();
      }
      Map<String, dynamic>? highestLevel;
      for (var level in AchievementConfig.levels) {
        if (total >= level['threshold']) {
          highestLevel = level;
        }
      }
      
      if (highestLevel != null) {
        achievementBadges.add(
          Tooltip(
            message: '${cat['name']}\n${highestLevel['name']} Rozeti ($total Soru)',
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: highestLevel['color'],
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)]
              ),
              alignment: Alignment.center,
              child: Text(
                cat['symbol'].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          )
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Text(
            'Sıralama: $rank / $totalUsers',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          if (highestRank != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    highestRank['icon'],
                    width: 24, height: 24,
                    errorBuilder: (ctx, err, trace) => const Icon(Icons.military_tech, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    highestRank['name'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                ],
              ),
            ),
          if (manualBadges.isNotEmpty || achievementBadges.isNotEmpty) const SizedBox(height: 12),
          
          if (manualBadges.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: manualBadges,
            ),
            
          if (achievementBadges.isNotEmpty) const SizedBox(height: 8),
          if (achievementBadges.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 8,
              children: achievementBadges,
            ),
        ],
      ),
    );
  }
}

enum Operation { addition, subtraction, multiplication, division, modulus, exponentiation, squareRoot }
enum GameState { setup, playing, result }

class MathGameWidget extends StatefulWidget {
  const MathGameWidget({super.key});

  @override
  State<MathGameWidget> createState() => _MathGameWidgetState();
}

class _MathGameWidgetState extends State<MathGameWidget> {
  // Oyun Konfigürasyonu
  Set<Operation> _activeOperations = {Operation.addition, Operation.subtraction};
  int _digitLimit = 2;
  bool _allowNegative = false;

  // Oyun Durumu
  GameState _gameState = GameState.setup;
  int _totalScore = 0;
  
  // Soru Durumu
  String _currentTex = "";
  num _currentAnswer = 0;
  num _lastX = 0, _lastY = 0;
  Operation? _lastOp;
  String _userAnswer = "";
  
  // Zamanlayıcı ve Ses Yönetimi
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  int _lastQuestionScore = 0;
  bool _isLastAnswerCorrect = false;

  final Random _random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  final List<String> _correctSounds = [
    'correct1.wav', 'correct2.wav', 'correct3.mp3', 'correct4.wav',
  ];
  final List<String> _wrongSounds = [
    'wrong1.mp3', 'wrong2.mp3', 'wrong3.mp3', 'wrong4.wav',
  ];

  // --- SES ÇALMA MOTORU ---
  void _playSound(String soundType) {
    String soundFile = '';

    switch (soundType) {
      case 'click': 
        soundFile = 'click.wav'; 
        break;
      case 'correct': 
        soundFile = _correctSounds[_random.nextInt(_correctSounds.length)]; 
        break;
      case 'wrong': 
        soundFile = _wrongSounds[_random.nextInt(_wrongSounds.length)]; 
        break;
    }

    if (soundFile.isNotEmpty) {
      _audioPlayer.play(AssetSource('sounds/$soundFile'));
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _stopwatch.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- MATEMATİK MOTORU VE SORU ÜRETİMİ ---
  void _startNewQuestion() {
    if (_activeOperations.isEmpty) {
      _activeOperations = {Operation.addition}; // Güvenlik önlemi
    }

    final op = _activeOperations.toList()[_random.nextInt(_activeOperations.length)];
    int maxVal = pow(10, _digitLimit).toInt();

    num x = 0, y = 0, answer = 0;
    String tex = "";

    switch (op) {
      case Operation.addition:
        x = _generateNumber(maxVal, _allowNegative);
        y = _generateNumber(maxVal, _allowNegative);
        answer = x + y;
        tex = "${_format(x)} + ${_format(y)}";
        break;
        
      case Operation.subtraction:
        x = _generateNumber(maxVal, _allowNegative);
        y = _generateNumber(maxVal, _allowNegative);
        answer = x - y;
        tex = "${_format(x)} - ${_format(y)}";
        break;
        
      case Operation.multiplication:
        // Çarpma için sayıları biraz daha küçük tutmak mantıklı
        x = _generateNumber(maxVal, _allowNegative);
        y = _generateNumber(pow(10, max(1, _digitLimit - 1)).toInt() + 5, _allowNegative); 
        answer = x * y;
        tex = "${_format(x)} \\times ${_format(y)}";
        break;
        
      case Operation.division:
        // Bölme işlemi için her zaman tam çıkacak şekilde ayarlandı
        y = _generateNumber(maxVal, _allowNegative);
        if (y == 0) y = 1; // Sıfıra bölme hatasını engelle
        answer = _generateNumber(maxVal, _allowNegative);
        x = y * answer;
        tex = "${_format(x)} \\div ${_format(y)}";
        break;
        
      case Operation.modulus:
        x = _generateNumber(maxVal, _allowNegative);
        y = (_random.nextInt(48) + 2) * (_random.nextBool() && _allowNegative ? -1 : 1);
        if (y == 0) y = 2;
        answer = x.toInt() % y.toInt();
        tex = "${_format(x)} \\pmod{${y.toInt()}}";
        break;
        
      case Operation.exponentiation:
        // Üs alma (Çok büyük sayılar çıkmaması için sınırlandırıldı)
        x = _generateNumber(maxVal > 10 ? 10 : maxVal, _allowNegative);
        y = _random.nextInt(3) + 2; // Sadece kare (2) veya küp (3)
        answer = pow(x, y);
        tex = "{${_format(x)}}^{${y.toInt()}}";
        break;
        
      case Operation.squareRoot:
        // Kök alma işlemi için tam kare sayılar üretilir (Kök içi negatif olamaz)
        answer = _generateNumber(maxVal * 2, false); // Kök sonucu her zaman pozitiftir
        if (answer < 0) answer *= -1; 
        x = answer * answer;
        tex = "\\sqrt{${_format(x)}}";
        break;
    }

    setState(() {
      _currentTex = tex;
      _currentAnswer = answer;
      _lastX = x;
      _lastY = y;
      _lastOp = op;
      _userAnswer = "";
      _gameState = GameState.playing;
    });

    _stopwatch.reset();
    _stopwatch.start();

    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _gameState == GameState.playing) {
        setState(() {}); // Sadece sürenin ekranda akmasını sağlar
      } else {
        timer.cancel();
      }
    });
  }

  num _generateNumber(int max, bool allowNeg) {
    num n = _random.nextInt(max);
    if (allowNeg && _random.nextBool()) n *= -1;
    return n;
  }

  // Orijinal gelişmiş matematik/sayı formatlayıcısı
  String _format(num number) {
    String formatted;
    if (number is int || number == number.roundToDouble()) {
      formatted = number.toInt().toString();
    } else {
      formatted = number.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    // Negatif sayıların etrafına daha okunaklı olması için parantez konur.
    return number < 0 ? "($formatted)" : formatted;
  }

  int _calculateScore(Operation op, num x, num y, int seconds) {
    int base = 2;
    if (op == Operation.multiplication || op == Operation.division) base = 4;
    if (op == Operation.exponentiation || op == Operation.squareRoot) base = 5;
    if (op == Operation.modulus) base = 3;

    int difficulty = (x.abs().toString().length + y.abs().toString().length);
    if (op == Operation.squareRoot) difficulty = x.abs().toString().length;

    int timeBonus = (seconds <= 5) ? 100 : (seconds <= 15 ? 50 : 10);
    return (base * difficulty) + timeBonus;
  }

  // --- KULLANICI GİRİŞİ KONTROLLERİ ---
  void _appendAnswer(String char) {
    _playSound('click');
    if (char == '-' && (_userAnswer.isNotEmpty && !_userAnswer.contains(','))) return;
    if (char == ',' && _userAnswer.contains(',')) return;
    if (char == '-' && _userAnswer.endsWith('-')) return;

    setState(() {
      _userAnswer += char;
    });
  }

  void _backspace() {
    _playSound('click');
    if (_userAnswer.isNotEmpty) {
      setState(() {
        _userAnswer = _userAnswer.substring(0, _userAnswer.length - 1);
      });
    }
  }

  void _checkAnswer() {
    _uiTimer?.cancel();
    _stopwatch.stop();
    num? val = num.tryParse(_userAnswer.replaceAll(',', '.'));
    
    if (val != null && (val - _currentAnswer).abs() < 0.0001) { // Tolerans düzeltildi
      _playSound('correct');
      _isLastAnswerCorrect = true;
      _lastQuestionScore = _calculateScore(_lastOp!, _lastX, _lastY, _stopwatch.elapsed.inSeconds);
      _totalScore += _lastQuestionScore;
    } else {
      _playSound('wrong');
      _isLastAnswerCorrect = false;
      _lastQuestionScore = 0;
    }

    setState(() {
      _gameState = GameState.result;
    });
  }

  // İşlem İsimleri Yardımcısı
  String _getOpName(Operation op) {
    switch (op) {
      case Operation.addition: return "Toplama";
      case Operation.subtraction: return "Çıkarma";
      case Operation.multiplication: return "Çarpma";
      case Operation.division: return "Bölme";
      case Operation.modulus: return "Mod Alma";
      case Operation.exponentiation: return "Üs Alma";
      case Operation.squareRoot: return "Kök Alma";
    }
  }

  // --- UI OLUŞTURUCULARI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Işık Hızında Düşün"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            final adService = Provider.of<AdService>(context, listen: false);
            final isPremium = Provider.of<UserProvider>(context, listen: false).isPremium;
            if (!isPremium) {
              adService.showInterstitialAd();
            }
            Navigator.pop(context, _totalScore);
          },
        ),
      ),
      body: _buildCurrentState(),
    );
  }

  Widget _buildCurrentState() {
    switch (_gameState) {
      case GameState.setup:
        return _buildSetupScreen();
      case GameState.playing:
        return _buildGameScreen();
      case GameState.result:
        return _buildResultScreen();
    }
  }

  // 1. Ayarlar (Setup) Ekranı
  Widget _buildSetupScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("İşlem Seçimi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          ...Operation.values.map((op) => CheckboxListTile(
            title: Text(_getOpName(op)),
            value: _activeOperations.contains(op),
            onChanged: (_) {
              setState(() {
                if (_activeOperations.contains(op) && _activeOperations.length > 1) {
                  _activeOperations.remove(op);
                } else {
                  _activeOperations.add(op);
                }
              });
            },
          )),
          const Divider(height: 40),
          const Text("Zorluk Ayarları", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ListTile(
            title: Text("Basamak Sayısı Sınırı: $_digitLimit"),
            subtitle: Slider(
              value: _digitLimit.toDouble(),
              min: 1, max: 4, divisions: 3,
              onChanged: (v) => setState(() => _digitLimit = v.toInt()),
            ),
          ),
          SwitchListTile(
            title: const Text("Negatif Sayılar Çıkabilir"),
            value: _allowNegative,
            onChanged: (v) => setState(() => _allowNegative = v),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
            onPressed: () {
              _totalScore = 0; // Yeni oyunda puanı sıfırla
              _startNewQuestion();
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text("OYUNA BAŞLA", style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 15),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  // 2. Oyun (Playing) Ekranı
  Widget _buildGameScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Toplam Puan: $_totalScore", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Süre: ${_stopwatch.elapsed.inSeconds}s", style: const TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  child: Math.tex(_currentTex, mathStyle: MathStyle.display, textStyle: const TextStyle(fontSize: 50)),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  child: Text(
                    _userAnswer.isEmpty ? "?" : _userAnswer,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildKeypad(),
      ],
    );
  }

  // 3. Sonuç (Result) Ekranı
  Widget _buildResultScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isLastAnswerCorrect ? Icons.check_circle : Icons.error,
              size: 100,
              color: _isLastAnswerCorrect ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              _isLastAnswerCorrect ? "DOĞRU CEVAP!" : "YANLIŞ CEVAP",
              style: TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.bold, 
                color: _isLastAnswerCorrect ? Colors.green : Colors.red
              ),
            ),
            if (!_isLastAnswerCorrect) ...[
              const SizedBox(height: 10),
              const Text("Doğru Cevap:", style: TextStyle(fontSize: 18)),
              Text(_format(_currentAnswer), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ] else ...[
              const SizedBox(height: 10),
              Text("+$_lastQuestionScore Puan Kazandın", style: const TextStyle(fontSize: 24)),
            ],
            const SizedBox(height: 30),
            Text("Mevcut Toplam Puan: $_totalScore", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              onPressed: _startNewQuestion,
              child: const Text("YENİ SORU GELSİN", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 15),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
              onPressed: () {
                final adService = Provider.of<AdService>(context, listen: false);
                final isPremium = Provider.of<UserProvider>(context, listen: false).isPremium;
                if (!isPremium) {
                  adService.showInterstitialAd();
                }
                Navigator.pop(context, _totalScore);
              },
              child: const Text("OYUNU BİTİR VE PUANI KAYDET", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 15),
            const BannerAdWidget(),
          ],
        ),
      )
    );
  }

  // --- KLAVYE (KEYPAD) ---
  Widget _buildKeypad() {
    final List<List<String>> rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['-', '0', ','] // Orijinal virgül desteği geri getirildi
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Column(
        children: [
          for (var row in rows)
            Row(
              children: row.map((key) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _appendAnswer(key),
                    child: Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ),
              )).toList(),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(15)
                  ),
                  onPressed: _userAnswer.isEmpty ? null : _checkAnswer,
                  child: const Text("CEVABI ONAYLA", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(15)
                  ),
                  onPressed: _backspace,
                  child: const Icon(Icons.backspace_outlined, size: 28),
                ),
              ),
            ],
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

// --- LİDERLİK TABLOSU EKRANI ---
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _top100 = [];
  List<dynamic> _surrounding = [];
  String _myId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _myId = userProvider.userData['id'] ?? '';
    final data = await FirebaseService.getLeaderboardData(userProvider.score, _myId);
    
    if (mounted) {
      setState(() {
        _top100 = data['top100']!;
        _surrounding = data['surrounding']!;
        _isLoading = false;
      });
    }
  }

  Widget _buildList(List<dynamic> users, {bool showRank = true}) {
    if (users.isEmpty) return const Center(child: Text("Kullanıcı bulunamadı."));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final u = users[index];
        final bool isMe = u['id'] == _myId;
        final rankText = showRank ? '#${index + 1}' : '';
        return Card(
          // YENİ: Card rengi temaya ve isMe durumuna göre ayarlandı
          color: isMe 
              ? (isDark ? Colors.deepPurple.withOpacity(0.3) : Colors.deepPurple.shade50) 
              : (isDark ? Colors.grey[800] : Colors.white),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showRank) ...[
                  Text(
                    rankText, 
                    // YENİ: Sıralama yazısı rengi temaya göre ayarlandı
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16, 
                      color: isMe 
                          ? (isDark ? Colors.purpleAccent.shade100 : Colors.deepPurple) 
                          : (isDark ? Colors.white70 : Colors.black87)
                    )
                  ),
                  const SizedBox(width: 8),
                ],
                CircleAvatar(
                  backgroundImage: u['avatar_url'] != null ? CachedNetworkImageProvider(FirebaseService.getFullUrl(u['avatar_url'])) : null,
                  child: u['avatar_url'] == null ? const Icon(Icons.person) : null,
                ),
              ],
            ),
            title: Text(u['username'] ?? 'Anonim', style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text(
              '${u['score'] ?? 0} Puan', 
              // YENİ: Kendi puan rengimiz karanlık modda daha okunaklı yapıldı
              style: TextStyle(color: isMe ? (isDark ? Colors.purpleAccent.shade100 : Colors.deepPurple) : Colors.grey)
            ),
            trailing: isMe ? const Icon(Icons.star, color: Colors.amber) : null,
            onTap: () {
              if (!isMe) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: u['id'])));
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liderlik Tablosu'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "İlk 100", icon: Icon(Icons.emoji_events)),
            Tab(text: "Etrafındakiler", icon: Icon(Icons.group)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_top100),
                _buildList(_surrounding, showRank: false), 
              ],
            ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}