import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/android_home_screen.dart';
import 'screens/web_home_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i kontrollü başlat (duplicate app hatasını önle)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Firebase zaten initialize edilmiş, devam et
      print('Firebase already initialized');
    } else {
      // Başka bir hata varsa tekrar fırlat
      rethrow;
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call SMS Forwarder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: kIsWeb ? const WebHomeScreen() : const AndroidHomeScreen(),
    );
  }
}
