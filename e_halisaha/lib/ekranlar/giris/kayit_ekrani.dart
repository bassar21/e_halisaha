import 'package:flutter/material.dart';
import '../../cekirdek/servisler/api_servisi.dart';

class KayitEkrani extends StatefulWidget {
  const KayitEkrani({super.key});

  @override
  State<KayitEkrani> createState() => _KayitEkraniState();
}

class _KayitEkraniState extends State<KayitEkrani> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _adSoyadController;
  late TextEditingController _emailController;
  late TextEditingController _telefonController;
  late TextEditingController _sifreController;

  bool _sifreGizli = true;
  bool _yukleniyor = false;
  final ApiServisi _apiServisi = ApiServisi();

  @override
  void initState() {
    super.initState();
    _adSoyadController = TextEditingController();
    _emailController = TextEditingController();
    _telefonController = TextEditingController();
    _sifreController = TextEditingController();
  }

  @override
  void dispose() {
    _adSoyadController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _kayitOl() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _yukleniyor = true);

      try {
        // FIX: ApiServisi.kayitOl artık bool değil Map döndürdüğü için uygun şekilde karşıladık
        final Map<String, dynamic> sonuc = await _apiServisi.kayitOl(
          _adSoyadController.text.trim(),
          _emailController.text.trim(),
          _telefonController.text.trim(),
          _sifreController.text,
        );

        if (!mounted) return;
        setState(() => _yukleniyor = false);

        if (sonuc['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Kayıt başarılı! Doğrulama kodu e-postanıza gönderildi.",
              ),
              backgroundColor: Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // DOĞRULAMAYI ATLIP DİREKT POP YAPARAK LOGİNE DÖNDÜRÜYORUZ
          Navigator.pop(context);
        } else {
          _hataGoster(sonuc['error'] ?? "Kayıt işlemi başarısız.");
        }
      } catch (e) {
        if (mounted) setState(() => _yukleniyor = false);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
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
                      Icons.person_add_rounded,
                      size: 48,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Yeni Hesap Oluştur",
                    style: TextStyle(
                      fontSize: 28,
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
                            "Ad Soyad",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _adSoyadController,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: _inputDekorasyonu(
                              "Adınız ve Soyadınız",
                              Icons.person_outline,
                              isDark,
                            ),
                            validator: (val) =>
                                val!.isEmpty ? "Boş bırakılamaz" : null,
                          ),
                          const SizedBox(height: 16),

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
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: _inputDekorasyonu(
                              "mail@example.com",
                              Icons.email_outlined,
                              isDark,
                            ),
                            validator: (val) =>
                                val!.isEmpty || !val.contains("@")
                                ? "Geçerli e-posta girin"
                                : null,
                          ),
                          const SizedBox(height: 16),

                          Text(
                            "Telefon Numarası",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _telefonController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: _inputDekorasyonu(
                              "05XX XXX XX XX",
                              Icons.phone_android_outlined,
                              isDark,
                            ),
                            validator: (val) =>
                                val!.isEmpty ? "Telefon boş bırakılamaz" : null,
                          ),
                          const SizedBox(height: 16),

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
                            controller: _sifreController,
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
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                              ),
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
                            validator: (val) => val!.length < 6
                                ? "Şifre en az 6 karakter olmalı"
                                : null,
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _yukleniyor ? null : _kayitOl,
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
                                      "Kayıt Ol",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
                        "Zaten hesabınız var mı?",
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Giriş Yap",
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

  InputDecoration _inputDekorasyonu(String hint, IconData ikon, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
      filled: true,
      fillColor: isDark ? const Color(0xFF111827) : Colors.white,
      prefixIcon: Icon(
        ikon,
        color: isDark ? Colors.grey[500] : Colors.grey[400],
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[400]!,
        ),
      ),
    );
  }
}
