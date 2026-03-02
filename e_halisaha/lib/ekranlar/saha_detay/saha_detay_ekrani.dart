import 'package:flutter/material.dart';
import '../../modeller/saha_modeli.dart';
import '../../cekirdek/servisler/api_servisi.dart';
import '../../cekirdek/servisler/kimlik_servisi.dart';

class SahaDetayEkrani extends StatefulWidget {
  final SahaModeli saha;
  const SahaDetayEkrani({super.key, required this.saha});

  @override
  State<SahaDetayEkrani> createState() => _SahaDetayEkraniState();
}

class _SahaDetayEkraniState extends State<SahaDetayEkrani> {
  final ApiServisi _apiServisi = ApiServisi();
  
  // TÜRKİYE SAAT DİLİMİNE SABİTLENDİ (UTC +3)
  late DateTime _seciliTarih;
  
  int? _seciliSaat;
  List<int> _doluSaatler = [];
  bool _saatlerYukleniyor = true;

  // Gerçek Türkiye Saatini veren yardımcı fonksiyon
  DateTime get _turkiyeSaati {
    return DateTime.now().toUtc().add(const Duration(hours: 3));
  }

  @override
  void initState() {
    super.initState();
    _seciliTarih = _turkiyeSaati;
    _musaitlikKontrolEt();
  }

  Future<void> _musaitlikKontrolEt() async {
    if (!mounted) return;
    setState(() => _saatlerYukleniyor = true);
    try {
      final dolu = await _apiServisi.doluSaatleriGetir(int.parse(widget.saha.id), _seciliTarih);
      if (mounted) {
        setState(() {
          _doluSaatler = dolu;
          _saatlerYukleniyor = false;
          _seciliSaat = null; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _saatlerYukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF16A34A),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.saha.resimYolu,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: Icon(Icons.sports_soccer, size: 80, color: isDark ? Colors.grey[600] : Colors.grey),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, 
                        end: Alignment.bottomCenter, 
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.black.withOpacity(0.4)]
                      )
                    )
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.saha.isim, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(widget.saha.ilce, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF16A34A).withOpacity(0.1) : const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                        child: Text("${widget.saha.fiyat.toInt()} ₺", style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text("Özellikler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 12),
                  _ozelliklerListesi(),
                  const SizedBox(height: 32),
                  Text("Tarih Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 12),
                  _tarihSecici(),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Müsait Saatler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      if (_saatlerYukleniyor) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _saatSecici(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _rezervasyonButonu(),
    );
  }

  Widget _ozelliklerListesi() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: widget.saha.ozellikler.map((ozellik) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!), 
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF16A34A)),
            const SizedBox(width: 6),
            Text(ozellik, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.black87)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _tarihSecici() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, 
        itemBuilder: (context, index) {
          DateTime gun = _turkiyeSaati.add(Duration(days: index));
          bool seciliMi = gun.day == _seciliTarih.day && gun.month == _seciliTarih.month && gun.year == _seciliTarih.year;
          
          return GestureDetector(
            onTap: () {
              setState(() => _seciliTarih = gun);
              _musaitlikKontrolEt();
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: seciliMi ? const Color(0xFF16A34A) : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: seciliMi ? const Color(0xFF16A34A) : (isDark ? Colors.grey[800]! : Colors.grey[200]!)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"][gun.weekday - 1], 
                    style: TextStyle(color: seciliMi ? Colors.white70 : (isDark ? Colors.grey[400] : Colors.grey))
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gun.day.toString(), 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: seciliMi ? Colors.white : (isDark ? Colors.white : Colors.black87))
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _saatSecici() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime simdi = _turkiyeSaati;
    final bool bugunMu = _seciliTarih.day == simdi.day && 
                         _seciliTarih.month == simdi.month && 
                         _seciliTarih.year == simdi.year;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, 
        childAspectRatio: 1.8,
        crossAxisSpacing: 10, 
        mainAxisSpacing: 10
      ),
      itemCount: 16, // 08:00 - 23:00 arası
      itemBuilder: (context, index) {
        int saat = index + 8;
        
        bool backendDolu = _doluSaatler.contains(saat);
        bool gecmisSaat = bugunMu && saat <= simdi.hour;
        bool kilitli = backendDolu || gecmisSaat;
        bool secili = _seciliSaat == saat;

        Color kutuRengi;
        Color yaziRengi;
        Color cerceveRengi;

        if (kilitli) {
          kutuRengi = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);
          yaziRengi = isDark ? Colors.grey[600]! : Colors.grey[400]!;
          cerceveRengi = isDark ? Colors.grey[800]! : Colors.grey[200]!;
        } else if (secili) {
          kutuRengi = const Color(0xFF16A34A);
          yaziRengi = Colors.white;
          cerceveRengi = const Color(0xFF16A34A);
        } else {
          kutuRengi = Theme.of(context).cardColor;
          yaziRengi = isDark ? Colors.white70 : Colors.black87;
          cerceveRengi = isDark ? Colors.grey[700]! : Colors.grey[300]!;
        }

        return GestureDetector(
          onTap: kilitli ? null : () => setState(() => _seciliSaat = saat),
          child: Container(
            decoration: BoxDecoration(
              color: kutuRengi,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cerceveRengi, width: secili ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${saat.toString().padLeft(2, '0')}:00",
                  style: TextStyle(
                    color: yaziRengi,
                    fontWeight: secili ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (kilitli)
                  Text(
                    gecmisSaat ? "GEÇTİ" : "DOLU",
                    style: TextStyle(
                      color: gecmisSaat ? (isDark ? Colors.grey[600] : Colors.grey[500]) : Colors.redAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rezervasyonButonu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), 
            blurRadius: 10, 
            offset: const Offset(0, -4)
          )
        ]
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: (_seciliSaat == null) ? null : _rezervasyonOnayiniGoster,
        child: Text(_seciliSaat == null ? "Saat Seçin" : "Rezervasyonu Tamamla", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _rezervasyonOnayiniGoster() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = await KimlikServisi.kullaniciGetir();
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Rezervasyon Özeti", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 20),
            _ozetSatiri("Saha", widget.saha.isim, isDark),
            _ozetSatiri("Tarih", "${_seciliTarih.day}/${_seciliTarih.month}/${_seciliTarih.year}", isDark),
            _ozetSatiri("Saat", "${_seciliSaat?.toString().padLeft(2, '0')}:00", isDark),
            _ozetSatiri("Toplam Ücret", "${widget.saha.fiyat.toInt()} ₺", isDark),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A), 
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);

                int gonderilecekId = user?['userId'] ?? user?['id'] ?? 0;

                bool basarili = await _apiServisi.rezervasyonYap(
                  int.parse(widget.saha.id),
                  gonderilecekId, 
                  _seciliTarih, 
                  _seciliSaat!, 
                  ""
                );
                
                if (basarili) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("✅ Rezervasyon Başarılı!"), 
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    )
                  );
                  navigator.pop(); 
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("❌ Hata oluştu, tekrar deneyin."), 
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    )
                  );
                }
              },
              child: const Text("ONAYLIYORUM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ozetSatiri(String baslik, String deger, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Text(baslik, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey)), 
          Text(deger, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))
        ]
      ),
    );
  }
}