import 'package:flutter/material.dart';
import '../../cekirdek/servisler/api_servisi.dart';
import '../../modeller/saha_modeli.dart';
import '../../cekirdek/servisler/kimlik_servisi.dart';
import '../saha_detay/saha_detay_ekrani.dart';
import '../profil/profil_ekrani.dart';
import '../profil/profil_alt_sayfalar.dart';
import '../giris/giris_ekrani.dart';
import '../admin/admin_ana_sayfa.dart';
import '../isletme/isletme_ana_sayfa.dart';

class AnasayfaEkrani extends StatefulWidget {
  const AnasayfaEkrani({super.key});

  @override
  State<AnasayfaEkrani> createState() => _AnasayfaEkraniState();
}

class _AnasayfaEkraniState extends State<AnasayfaEkrani> {
  final ApiServisi _apiServisi = ApiServisi();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<SahaModeli> _sahalar = [];
  bool _yukleniyor = true;
  
  Map<String, dynamic>? _kullanici;
  String? _kullaniciAdi;
  String? _kullaniciEmail;
  String? _kullaniciRol;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  // --- SAATE GÖRE SELAMLAMA MESAJI ---
  String _selamlamaMesajiGetir() {
    final saat = DateTime.now().hour;
    if (saat >= 5 && saat < 12) {
      return "Günaydın! ☀️";
    } else if (saat >= 12 && saat < 18) {
      return "İyi Günler! 😊";
    } else if (saat >= 18 && saat < 22) {
      return "İyi Akşamlar! 🌙";
    } else {
      return "İyi Geceler! ⚽";
    }
  }

  Future<void> _verileriYukle() async {
    try {
      final user = await KimlikServisi.kullaniciGetir();
      final veriler = await _apiServisi.tumSahalariGetir();
      
      if (mounted) {
        setState(() {
          _kullanici = user;
          _kullaniciAdi = user?['fullName'] ?? user?['name'] ?? "Futbolsever";
          _kullaniciEmail = user?['email'] ?? "";
          _kullaniciRol = user?['role']?.toString().toLowerCase() ?? "oyuncu";
          _sahalar = veriler;
          _yukleniyor = false;
        });
      }
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _cikisYap() async {
    await KimlikServisi.cikisYap();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const GirisEkrani()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _yanMenuOlustur(), 
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _verileriYukle,
          color: const Color(0xFF16A34A),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _scaffoldKey.currentState?.openDrawer(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), 
                                    blurRadius: 15, 
                                    offset: const Offset(0, 5)
                                  ),
                                ],
                              ),
                              child: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF111827), size: 28),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Merhaba, ${_kullaniciAdi ?? "Futbolsever"} 👋", 
                                style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : const Color(0xFF4B5563))),
                              // ARTIK BURASI DİNAMİK:
                              Text(_selamlamaMesajiGetir(), 
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF111827))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: TextField(
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: "Saha adı veya konum ara...",
                            hintStyle: TextStyle(color: isDark ? Colors.grey : const Color(0xFF9CA3AF)),
                            border: InputBorder.none,
                            icon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _yukleniyor
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF16A34A))))
                  : _sahalar.isEmpty
                      ? SliverFillRemaining(child: Center(child: Text("Henüz saha bulunamadı.", style: TextStyle(color: isDark ? Colors.white : Colors.black))))
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _sahaKartiniOlustur(_sahalar[index]),
                              childCount: _sahalar.length,
                            ),
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _yanMenuOlustur() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String basHarf = _kullaniciAdi != null && _kullaniciAdi!.isNotEmpty ? _kullaniciAdi![0].toUpperCase() : "?";

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF111827) : Colors.white, shape: BoxShape.circle),
                  child: Center(child: Text(basHarf, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)))),
                ),
                const SizedBox(height: 16),
                Text(_kullaniciAdi ?? "Misafir", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(_kullaniciEmail ?? "Giriş yapılmadı", style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                const SizedBox(height: 10),
                _drawerListTile(Icons.person_outline, "Profilim", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilEkrani())).then((_) => _verileriYukle());
                }),
                _drawerListTile(Icons.calendar_month_outlined, "Rezervasyonlarım", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RandevularimSayfasi()));
                }),
                _drawerListTile(Icons.settings_outlined, "Ayarlar", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AyarlarSayfasi())).then((_) => _verileriYukle());
                }),
                if (_kullaniciRol == 'admin') ...[
                  Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
                  _drawerListTile(Icons.security, "Yönetim Paneli", () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnaSayfa()));
                  }, ikonRengi: Colors.red),
                ] else if (_kullaniciRol == 'isletme' || _kullaniciRol == 'sahasahibi') ...[
                  Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
                  _drawerListTile(Icons.stadium, "İşletme Paneli", () {
                    Navigator.pop(context);
                    if (_kullanici != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => IsletmeAnaSayfa(kullanici: _kullanici!)));
                    }
                  }, ikonRengi: Colors.orange),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2),
                foregroundColor: const Color(0xFFEF4444),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Çıkış Yap"),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                    title: Text("Çıkış Yap", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                    content: Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx), 
                        child: const Text("İptal", style: TextStyle(color: Colors.grey))
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _cikisYap();
                        },
                        child: const Text("Çıkış Yap", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerListTile(IconData ikon, String baslik, VoidCallback onTap, {Color ikonRengi = const Color(0xFF6B7280)}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(ikon, color: ikonRengi),
      title: Text(baslik, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827))),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFD1D5DB)),
      onTap: onTap,
    );
  }

  Widget _sahaKartiniOlustur(SahaModeli saha) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => SahaDetayEkrani(saha: saha))
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: saha.resimYolu.isNotEmpty 
                ? Image.network(
                    saha.resimYolu,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180, 
                      color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6), 
                      child: const Center(child: Icon(Icons.sports_soccer, size: 48, color: Color(0xFFD1D5DB)))
                    ),
                  )
                : Container(
                    height: 180, 
                    color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6), 
                    child: const Center(child: Icon(Icons.sports_soccer, size: 48, color: Color(0xFFD1D5DB)))
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(saha.isim, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black), overflow: TextOverflow.ellipsis)),
                      Text("${saha.fiyat.toInt()} ₺", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                  Text(saha.ilce, style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF6B7280))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}