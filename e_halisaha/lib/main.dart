import 'package:flutter/material.dart';
import 'ekranlar/anasayfa/anasayfa_ekrani.dart';
import 'ekranlar/giris/giris_ekrani.dart';
import 'cekirdek/servisler/kimlik_servisi.dart';
import 'ekranlar/profil/profil_alt_sayfalar.dart'; // TemaAyari sınıfı burada olduğu için import ettik

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. ADIM: UYGULAMA AÇILMADAN ÖNCE KAYITLI TEMAYI HAFIZADAN ÇEK
  await TemaAyari.temaYukle();

  // 2. ADIM: Uygulama açılırken giriş yapılıp yapılmadığını kontrol et
  bool girisYapildi = await KimlikServisi.girisYapildiMi();

  runApp(
    MyApp(
      baslangicEkrani: girisYapildi
          ? const AnasayfaEkrani()
          : const GirisEkrani(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget baslangicEkrani;
  const MyApp({super.key, required this.baslangicEkrani});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder sayesinde Ayarlar sayfasındaki switch değişince burası tetiklenir
    // Ve tüm MaterialApp baştan aşağı yeni temayla çizilir.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: TemaAyari.temaModu,
      builder: (context, guncelMod, child) {
        return MaterialApp(
          navigatorKey: globalNavigatorKey,
          title: 'e-HalıSaha',
          debugShowCheckedModeBanner: false,

          // --- AYDINLIK TEMA AYARLARI ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: Colors.green,
            scaffoldBackgroundColor: const Color(0xFFF9FAFB), // bg-gray-50
            // Kartların varsayılan rengi
            cardColor: Colors.white,

            // AppBar Ayarları
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF111827),
              elevation: 0,
              centerTitle: true,
            ),

            // Yazı Renkleri
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF111827)),
              bodyMedium: TextStyle(color: Color(0xFF374151)),
            ),

            // Bölücü çizgiler
            dividerColor: const Color(0xFFE5E7EB),
          ),

          // --- KOYU TEMA AYARLARI ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.green,

            // Koyu mod arka plan rengi
            scaffoldBackgroundColor: const Color(
              0xFF111827,
            ), // Çok koyu lacivert/siyah
            // Koyu mod kart rengi
            cardColor: const Color(0xFF1F2937), // Gri-mavi koyu ton
            // Koyu mod AppBar
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F2937),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),

            // Koyu mod Yazı Renkleri
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Color(0xFFD1D5DB)),
            ),

            // Koyu mod bölücü çizgiler
            dividerColor: Colors.white10,
          ),

          // Şu anki tema modu (ThemeMode.light veya ThemeMode.dark)
          themeMode: guncelMod,

          // Başlangıç ekranı
          home: baslangicEkrani,

          // Rotalar
          routes: {
            '/login': (context) => const GirisEkrani(),
            '/home': (context) => const AnasayfaEkrani(),
          },
        );
      },
    );
  }
}
