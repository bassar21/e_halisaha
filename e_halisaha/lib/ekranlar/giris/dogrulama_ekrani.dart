import 'package:flutter/material.dart';
import '../../cekirdek/servisler/api_servisi.dart';
import 'giris_ekrani.dart';

class DogrulamaEkrani extends StatefulWidget {
  final String email;

  const DogrulamaEkrani({super.key, required this.email});

  @override
  State<DogrulamaEkrani> createState() => _DogrulamaEkraniState();
}

class _DogrulamaEkraniState extends State<DogrulamaEkrani> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _yukleniyor = false;
  final ApiServisi _apiServisi = ApiServisi();

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _koduDogrula() async {
    String kod = _controllers.map((e) => e.text).join();
    if (kod.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen 6 haneli kodu eksiksiz girin.")),
      );
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      // Backend'deki verify-otp endpoint'ini çağıracağız
      final sonuc = await _apiServisi.otpDogrula(widget.email, kod);

      if (mounted) {
        if (sonuc['success']) {
          _basariMesajiGoster();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(sonuc['error'] ?? "Hatalı kod!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bir hata oluştu: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _basariMesajiGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Hesabınız başarıyla doğrulandı! Şimdi giriş yapabilirsiniz.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const GirisEkrani()),
                (route) => false,
              );
            },
            child: const Text("Giriş Yap"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("E-posta Doğrulama")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 80, color: Color(0xFF16A34A)),
            const SizedBox(height: 24),
            Text(
              "Doğrulama Kodu",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              "${widget.email} adresine gönderilen 6 haneli kodu giriniz.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _otpKutusu(index)),
            ),
            const SizedBox(height: 40),
            _yukleniyor
                ? const CircularProgressIndicator(color: Color(0xFF16A34A))
                : ElevatedButton(
                    onPressed: _koduDogrula,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Doğrula ve Kaydı Tamamla", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _otpKutusu(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}