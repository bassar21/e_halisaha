import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../cekirdek/servisler/api_servisi.dart';
import '../anasayfa/anasayfa_ekrani.dart';
import '../isletme/isletme_ana_sayfa.dart';
import '../web/web_ana_sayfa.dart';
import '../admin/admin_ana_sayfa.dart';
import 'kayit_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _girisEmailController;
  late TextEditingController _girisSifreController;

  bool _sifreGizli = true;
  bool _yukleniyor = false;
  final ApiServisi _apiServisi = ApiServisi();

  @override
  void initState() {
    super.initState();
    // Controller'ları burada başlatıyoruz
    _girisEmailController = TextEditingController();
    _girisSifreController = TextEditingController();
  }

  // İŞTE HAYALET ÇİZGİ SORUNUNU ÇÖZEN EN KRİTİK KISIM
  @override
  void dispose() {
    // Sayfa kapandığında klavye bağlantısını ve belleği tamamen temizle
    _girisEmailController.dispose();
    _girisSifreController.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    // Klavyeyi zorla kapat ve kelime tamamlama (IME) hafızasını sıfırla
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _yukleniyor = true);

      try {
        print(
          "Giriş isteği gönderiliyor: ${_girisEmailController.text.trim()}",
        );

        var sonuc = await _apiServisi.girisYap(
          _girisEmailController.text.trim(),
          _girisSifreController.text,
        );

        if (!mounted) return;
        setState(() => _yukleniyor = false);

        if (sonuc != null) {
          if (sonuc['success'] == true && sonuc['user'] != null) {
            print("Giriş başarılı! Kullanıcı verisi: ${sonuc['user']}");

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Giriş başarılı!"),
                backgroundColor: Color(0xFF22C55E),
                behavior: SnackBarBehavior.floating,
              ),
            );

            final user = sonuc['user'];

            if (kIsWeb) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => WebAnaSayfa(kullanici: user),
                ),
              );
            } else {
              String rol = (user['role'] ?? "customer")
                  .toString()
                  .toLowerCase();

              if (rol == "admin") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminAnaSayfa(),
                  ),
                );
              } else if (rol == "sahasahibi" ||
                  rol == "owner" ||
                  rol == "isletme") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IsletmeAnaSayfa(kullanici: user),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnasayfaEkrani(),
                  ),
                );
              }
            }
          } else {
            debugPrint("Giriş başarısız: ${sonuc['error']}");
            _hataGoster(
              sonuc['error'] ?? "Şifre veya E-posta adresiniz hatalı!",
            );
          }
        } else {
          debugPrint("Giriş başarısız: API null döndü (Bağlantı sorunu)");
          _hataGoster("Şifre veya E-posta adresiniz hatalı!");
        }
      } catch (e) {
        debugPrint("--- KRİTİK GİRİŞ HATASI ---");
        debugPrint(e.toString());
        debugPrint("---------------------------");

        setState(() => _yukleniyor = false);
        _hataGoster("Bağlantı hatası: $e");
      }
    }
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1F2937)
                          : const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.login_rounded,
                      size: 48,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Giriş Yap",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.05,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "E-posta",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _girisEmailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: "mail@example.com",
                              hintStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF111827)
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[400]!,
                                ),
                              ),
                            ),
                            validator: (val) =>
                                val!.isEmpty ? "Boş bırakılamaz" : null,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Şifre",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _girisSifreController,
                            obscureText: _sifreGizli,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: "••••••••",
                              hintStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF111827)
                                  : Colors.white,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _sifreGizli
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                onPressed: () =>
                                    setState(() => _sifreGizli = !_sifreGizli),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[400]!,
                                ),
                              ),
                            ),
                            validator: (val) =>
                                val!.length < 6 ? "Şifre çok kısa" : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _yukleniyor ? null : _girisYap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _yukleniyor
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Giriş Yap",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Hesabınız yok mu?",
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Kayıt ekranına geçerken de klavyeyi sıfırlayalım
                          FocusScope.of(context).unfocus();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KayitEkrani(),
                            ),
                          );
                        },
                        child: const Text(
                          "Kayıt Ol",
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
