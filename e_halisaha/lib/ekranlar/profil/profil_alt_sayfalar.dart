import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../cekirdek/servisler/api_servisi.dart';
import '../../cekirdek/servisler/kimlik_servisi.dart';

// --- TEMA YÖNETİCİSİ ---
class TemaAyari {
  static ValueNotifier<ThemeMode> temaModu = ValueNotifier(ThemeMode.light);

  static Future<void> temaYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isDark = prefs.getBool('koyu_tema_acik') ?? false; 
    temaModu.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> temaDegistir(bool karanlikMi) async {
    temaModu.value = karanlikMi ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('koyu_tema_acik', karanlikMi);
  }
}

// --- GİZLİ VİDEO TETİKLEYİCİ WIDGET ---
class GizliVideoTetikleyici extends StatefulWidget {
  final Widget child;
  final String videoYolu;

  const GizliVideoTetikleyici({
    super.key,
    required this.child,
    required this.videoYolu,
  });

  @override
  State<GizliVideoTetikleyici> createState() => _GizliVideoTetikleyiciState();
}

class _GizliVideoTetikleyiciState extends State<GizliVideoTetikleyici> {
  Timer? _zamanlayici;

  void _sayaciBaslat() {
    _zamanlayici = Timer(const Duration(milliseconds: 5200), _videoyuAc);
  }

  void _sayaciIptal() {
    if (_zamanlayici?.isActive ?? false) {
      _zamanlayici?.cancel();
    }
  }

  void _videoyuAc() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _GizliVideoPenceresi(videoYolu: widget.videoYolu),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _sayaciBaslat(),
      onTapUp: (_) => _sayaciIptal(),
      onTapCancel: _sayaciIptal,
      child: widget.child,
    );
  }
}

class _GizliVideoPenceresi extends StatefulWidget {
  final String videoYolu;
  const _GizliVideoPenceresi({required this.videoYolu});

  @override
  State<_GizliVideoPenceresi> createState() => _GizliVideoPenceresiState();
}

class _GizliVideoPenceresiState extends State<_GizliVideoPenceresi> {
  late VideoPlayerController _controller;
  bool _hazir = false;
  bool _hataVar = false;

  @override
  void initState() {
    super.initState();
    _videoHazirla();
  }

  Future<void> _videoHazirla() async {
    _controller = VideoPlayerController.asset(widget.videoYolu);
    try {
      await _controller.initialize();
      await _controller.setVolume(1.0);
      await _controller.setLooping(true);
      if (mounted) {
        setState(() => _hazir = true);
        _controller.play();
      }
    } catch (e) {
      if (mounted) setState(() => _hataVar = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: _hazir
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 35),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- RANDEVULARIM SAYFASI ---
class RandevularimSayfasi extends StatefulWidget {
  const RandevularimSayfasi({super.key});

  @override
  State<RandevularimSayfasi> createState() => _RandevularimSayfasiState();
}

class _RandevularimSayfasiState extends State<RandevularimSayfasi> {
  final ApiServisi _apiServisi = ApiServisi();
  List<dynamic> _randevular = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    try {
      final veriler = await _apiServisi.rezervasyonlarimiGetir();
      if (mounted) {
        setState(() {
          _randevular = veriler;
          _yukleniyor = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Rezervasyonlarım", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF111827)),
        titleTextStyle: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827), fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
          : _randevular.isEmpty
              ? _bosEkranGoster()
              : RefreshIndicator(
                  onRefresh: _verileriYukle,
                  color: const Color(0xFF16A34A),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _randevular.length,
                    itemBuilder: (context, index) => _randevuKarti(_randevular[index]),
                  ),
                ),
    );
  }

  Widget _randevuKarti(dynamic randevu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String pitchName = (randevu['pitch_name'] ?? "Bilinmeyen Saha").toString();
    final String facilityName = (randevu['facility_name'] ?? "Tesis Bilgisi Yok").toString();
    final String status = (randevu['status'] ?? "pending").toString().toLowerCase();
    
    String formatliTarih = "Bilinmeyen Tarih";
    String saatString = "--:--";
    
    try {
      if (randevu['start_time'] != null) {
        DateTime tarih = DateTime.parse(randevu['start_time'].toString()).toLocal();
        List<String> aylar = ["", "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"];
        formatliTarih = "${tarih.day} ${aylar[tarih.month]} ${tarih.year}";
        saatString = "${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}";
      }
    } catch (e) { /**/ }

    Color durumKutuRengi = isDark ? Colors.amber.withOpacity(0.1) : const Color(0xFFFEF3C7);
    Color durumYaziRengi = Colors.amber;
    String durumMetni = "Beklemede";

    if (status == 'confirmed' || status == 'onaylandı') {
      durumKutuRengi = isDark ? Colors.blue.withOpacity(0.1) : const Color(0xFFDBEAFE);
      durumYaziRengi = Colors.blue;
      durumMetni = "Onaylandı";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF16A34A).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.sports_soccer, color: Color(0xFF16A34A), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pitchName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                Text(facilityName, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 8),
                Text("$formatliTarih | $saatString", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: durumKutuRengi, borderRadius: BorderRadius.circular(8)),
            child: Text(durumMetni, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: durumYaziRengi)),
          ),
        ],
      ),
    );
  }

  Widget _bosEkranGoster() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_soccer_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Henüz bir maçın yok!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            child: const Text("Saha Ara", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// --- AYARLAR SAYFASI (GERİ BİLDİRİM FAB EKLENDİ) ---
class AyarlarSayfasi extends StatefulWidget {
  const AyarlarSayfasi({super.key});

  @override
  State<AyarlarSayfasi> createState() => _AyarlarSayfasiState();
}

class _AyarlarSayfasiState extends State<AyarlarSayfasi> {
  bool _bildirimAcik = true;

  // --- CİHAZ BİLGİSİNİ ALAN FONKSİYON ---
  Future<String> _cihazBilgisiAl() async {
    if (kIsWeb) return "Web Tarayıcı";
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return "${androidInfo.brand} ${androidInfo.model} (Android ${androidInfo.version.release})";
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return "${iosInfo.name} ${iosInfo.systemName} ${iosInfo.systemVersion}";
      }
    } catch (e) {
      return "Cihaz bilgisi alınamadı";
    }
    return "Bilinmeyen Cihaz";
  }

  // --- GERİ BİLDİRİM / TICKET PENCERESİ ---
  void _geriBildirimPenceresiAc() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _GeriBildirimFormu(cihazBilgisiFonksiyonu: _cihazBilgisiAl);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Ayarlar", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF111827)),
      ),
      // YÜZEN TICKET BUTONU
      floatingActionButton: FloatingActionButton(
        onPressed: _geriBildirimPenceresiAc,
        backgroundColor: const Color(0xFF16A34A),
        tooltip: "Geri Bildirim / Destek",
        elevation: 4,
        child: const Icon(Icons.support_agent, color: Colors.white, size: 28),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ayarGrubu("Uygulama Ayarları", [
            _ayarSatiriSwitch(Icons.notifications_none_rounded, "Bildirimler", "Bildirimleri yönet", _bildirimAcik, (v) => setState(() => _bildirimAcik = v)),
            _ayarSatiriSwitch(Icons.dark_mode_outlined, "Koyu Tema", isDark ? "Karanlık Mod" : "Aydınlık Mod", isDark, (v) {
              TemaAyari.temaDegistir(v);
            }),
          ]),
          const SizedBox(height: 24),
          _ayarGrubu("Destek", [
            _ayarSatiri(Icons.help_outline_rounded, "Yardım Merkezi", "S.S.S.", () {}),
            GizliVideoTetikleyici(
              videoYolu: 'assets/video.mp4', 
              child: _ayarSatiri(Icons.info_outline_rounded, "Uygulama Hakkında", "Versiyon 1.0.0", () {}),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _ayarGrubu(String baslik, List<Widget> cocuklar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(baslik, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: cocuklar),
        ),
      ],
    );
  }

  Widget _ayarSatiri(IconData ikon, String baslik, String altBaslik, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(ikon, color: const Color(0xFF16A34A)),
      title: Text(baslik, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      subtitle: Text(altBaslik),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _ayarSatiriSwitch(IconData ikon, String baslik, String altBaslik, bool deger, Function(bool) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(ikon, color: const Color(0xFF16A34A)),
      title: Text(baslik, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      subtitle: Text(altBaslik),
      trailing: Switch(value: deger, onChanged: onChanged, activeColor: const Color(0xFF16A34A)),
    );
  }
}

// --- GERİ BİLDİRİM FORMU WIDGET'I ---
class _GeriBildirimFormu extends StatefulWidget {
  final Future<String> Function() cihazBilgisiFonksiyonu;
  const _GeriBildirimFormu({required this.cihazBilgisiFonksiyonu});

  @override
  State<_GeriBildirimFormu> createState() => _GeriBildirimFormuState();
}

class _GeriBildirimFormuState extends State<_GeriBildirimFormu> {
  final TextEditingController _mesajController = TextEditingController();
  final ApiServisi _apiServisi = ApiServisi();
  XFile? _secilenResim;
  bool _gonderiliyor = false;

  Future<void> _resimSec() async {
    final ImagePicker picker = ImagePicker();
    final XFile? resim = await picker.pickImage(source: ImageSource.gallery);
    if (resim != null) {
      setState(() => _secilenResim = resim);
    }
  }

  Future<void> _gonder() async {
    if (_mesajController.text.trim().isEmpty) return;

    setState(() => _gonderiliyor = true);
    
    // Kullanıcı ID'sini ve cihazı al
    final user = await KimlikServisi.kullaniciGetir();
    int userId = user?['id'] ?? user?['userId'] ?? 0;
    String cihazBilgisi = await widget.cihazBilgisiFonksiyonu();

    // Api'ye gönder
    bool basarili = await _apiServisi.ticketOlustur(
      userId,
      cihazBilgisi,
      _mesajController.text.trim(),
      _secilenResim?.path,
    );

    if (!mounted) return;
    setState(() => _gonderiliyor = false);

    if (basarili) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geri bildiriminiz ulaştı. Teşekkürler!"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gönderilirken bir hata oluştu."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Destek Talebi / Öneri", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Text("Yaşadığınız sorunu veya önerinizi detaylıca yazın.", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700])),
            const SizedBox(height: 12),
            TextField(
              controller: _mesajController,
              maxLines: 4,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Buraya yazın...",
                hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                filled: true,
                fillColor: isDark ? const Color(0xFF111827) : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _resimSec,
                  icon: const Icon(Icons.image, size: 18),
                  label: const Text("Ekran Görüntüsü Ekle"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 12),
                if (_secilenResim != null) 
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _gonderiliyor ? null : _gonder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _gonderiliyor 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Gönder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// --- PROFİL DÜZENLE SAYFASI ---
class ProfilDuzenleSayfasi extends StatefulWidget {
  const ProfilDuzenleSayfasi({super.key});

  @override
  State<ProfilDuzenleSayfasi> createState() => _ProfilDuzenleSayfasiState();
}

class _ProfilDuzenleSayfasiState extends State<ProfilDuzenleSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final ApiServisi _apiServisi = ApiServisi();
  late TextEditingController _adController;
  late TextEditingController _emailController;
  late TextEditingController _telefonController; 
  bool _yukleniyor = true;
  bool _kaydediliyor = false;

  Map<String, dynamic>? _mevcutKullanici;

  @override
  void initState() {
    super.initState();
    _adController = TextEditingController();
    _emailController = TextEditingController();
    _telefonController = TextEditingController(); 
    _verileriGetir();
  }

  Future<void> _verileriGetir() async {
    final user = await KimlikServisi.kullaniciGetir();
    if (user != null && mounted) {
      setState(() {
        _mevcutKullanici = user;
        _adController.text = user['fullName'] ?? user['name'] ?? "";
        _emailController.text = user['email'] ?? "";
        _telefonController.text = user['phone'] ?? user['phoneNumber'] ?? ""; 
        _yukleniyor = false;
      });
    } else {
      if(mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _bilgileriGuncelle() async {
    if (!_formKey.currentState!.validate()) return; 

    setState(() {
      _kaydediliyor = true; 
    });

    try {
      if (_mevcutKullanici != null) {
        int userId = _mevcutKullanici!['id'] ?? _mevcutKullanici!['userId'] ?? 0;

        bool backendBasarili = await _apiServisi.profilGuncelle(
          userId,
          _adController.text,
          _emailController.text,
          _telefonController.text,
        );

        if (!backendBasarili) {
          throw Exception("Sunucuya bağlanırken veya veriyi güncellerken hata oluştu.");
        }

        _mevcutKullanici!['name'] = _adController.text;
        _mevcutKullanici!['fullName'] = _adController.text;
        _mevcutKullanici!['email'] = _emailController.text;
        _mevcutKullanici!['phone'] = _telefonController.text;
        _mevcutKullanici!['phoneNumber'] = _telefonController.text;

        final prefs = await SharedPreferences.getInstance();
        
        String? userStr = prefs.getString('user');
        if (userStr != null) {
          await prefs.setString('user', jsonEncode(_mevcutKullanici));
        } else {
          await prefs.setString('kullanici', jsonEncode(_mevcutKullanici));
        }
        
        await prefs.setString('name', _adController.text);
        await prefs.setString('email', _emailController.text);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profil başarıyla kaydedildi!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); 
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _kaydediliyor = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _adController.dispose();
    _emailController.dispose();
    _telefonController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profili Düzenle", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF16A34A).withOpacity(0.1),
                      child: const Icon(Icons.person, size: 50, color: Color(0xFF16A34A)),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _adController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: _dekorasyon("Ad Soyad", Icons.person_outline, isDark),
                      validator: (value) => value == null || value.isEmpty ? "Ad Soyad boş olamaz" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: _dekorasyon("E-posta", Icons.email_outlined, isDark),
                      validator: (value) => value == null || !value.contains('@') ? "Geçerli bir e-posta girin" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefonController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: _dekorasyon("Telefon Numarası", Icons.phone_android_outlined, isDark),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: _kaydediliyor ? null : _bilgileriGuncelle,
                        child: _kaydediliyor 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("Kaydet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _dekorasyon(String etiket, IconData ikon, bool isDark) {
    return InputDecoration(
      labelText: etiket,
      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
      prefixIcon: Icon(ikon, color: const Color(0xFF16A34A)),
      filled: true,
      fillColor: isDark ? const Color(0xFF1F2937) : Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
      ),
    );
  }
}