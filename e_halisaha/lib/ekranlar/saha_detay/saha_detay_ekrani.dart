import 'package:flutter/material.dart';
import '../../modeller/saha_modeli.dart';
import '../../cekirdek/servisler/api_servisi.dart';
import '../../cekirdek/servisler/hava_durumu_servisi.dart';
import '../odeme/odeme_ekrani.dart';

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

  // UPSELLING (Ekstra Siparişler) için state yönetimi
  bool _suEklendi = false;
  bool _kramponEklendi = false;
  bool _eldivenEklendi = false;

  late double suFiyati;
  late double kramponFiyati;
  late double eldivenFiyati;

  // Gerçek Hava Durumu Datası (Saat => {derece: 18.2, ikon: '☀️'})
  Map<int, Map<String, dynamic>>? _saatlikHava;

  // Gerçek Türkiye Saatini veren yardımcı fonksiyon
  DateTime get _turkiyeSaati {
    return DateTime.now().toUtc().add(const Duration(hours: 3));
  }

  @override
  void initState() {
    super.initState();
    // İşletme tarafından dinamik belirlenen fiyatlar alınır
    suFiyati = widget.saha.suFiyati;
    kramponFiyati = widget.saha.kramponFiyati;
    eldivenFiyati = widget.saha.eldivenFiyati;

    _seciliTarih = _turkiyeSaati;
    _musaitlikKontrolEt();
  }

  Future<void> _musaitlikKontrolEt() async {
    if (!mounted) return;
    setState(() => _saatlerYukleniyor = true);
    try {
      final dolu = await _apiServisi.doluSaatleriGetir(
        int.parse(widget.saha.id),
        _seciliTarih,
      );

      // Kullanıcının/Telefonun O Anki Gerçek GPS Konumu Üzerinden Hava Durumunu Çek
      final hava = await HavaDurumuServisi.cihazKonumundanHavaDurumuGetir(
        _seciliTarih,
      );

      if (mounted) {
        setState(() {
          _doluSaatler = dolu;
          _saatlikHava = hava;
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
                      child: Icon(
                        Icons.sports_soccer,
                        size: 80,
                        color: isDark ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
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
                            Text(
                              widget.saha.isim,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.saha.ilce,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${widget.saha.fiyat.toInt()} ₺",
                          style: const TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Özellikler",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ozelliklerListesi(),
                  const SizedBox(height: 32),
                  Text(
                    "Tarih Seçin",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _tarihSecici(),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Müsait Saatler",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (_saatlerYukleniyor)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF16A34A),
                          ),
                        ),
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
      children: widget.saha.ozellikler
          .map(
            (ozellik) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).cardColor,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ozellik,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
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
          bool seciliMi =
              gun.day == _seciliTarih.day &&
              gun.month == _seciliTarih.month &&
              gun.year == _seciliTarih.year;

          return GestureDetector(
            onTap: () {
              setState(() => _seciliTarih = gun);
              _musaitlikKontrolEt();
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: seciliMi
                    ? const Color(0xFF16A34A)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: seciliMi
                      ? const Color(0xFF16A34A)
                      : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    [
                      "Pzt",
                      "Sal",
                      "Çar",
                      "Per",
                      "Cum",
                      "Cmt",
                      "Paz",
                    ][gun.weekday - 1],
                    style: TextStyle(
                      color: seciliMi
                          ? Colors.white70
                          : (isDark ? Colors.grey[400] : Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gun.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: seciliMi
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
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
    final bool bugunMu =
        _seciliTarih.day == simdi.day &&
        _seciliTarih.month == simdi.month &&
        _seciliTarih.year == simdi.year;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 16, // 08:00 - 23:00 arası
      itemBuilder: (context, index) {
        int saat = index + 8;

        bool backendDolu = _doluSaatler.contains(saat);
        bool gecmisSaat = bugunMu && saat <= simdi.hour;
        bool kilitli = backendDolu || gecmisSaat;
        bool secili = _seciliSaat == saat;

        // API'den gelen Gerçek Hava Durumu (Yoksa basit mock falleback döner)
        String havaIkonu = _saatlikHava?[saat]?['ikon'] ?? "☁️";
        double dereceTop = _saatlikHava?[saat]?['derece'] ?? 15.0;
        int derece = dereceTop.round();

        Color kutuRengi;
        Color yaziRengi;
        Color cerceveRengi;

        if (kilitli) {
          kutuRengi = isDark
              ? const Color(0xFF1F2937)
              : const Color(0xFFF3F4F6);
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
          onTap: () {
            if (kilitli) {
              if (backendDolu && !gecmisSaat) {
                // BEKLEME LİSTESİ (Waitlist - Özellik 8)
                _beklemeListesiDialogGoster(saat);
              }
            } else {
              setState(() => _seciliSaat = saat);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: kutuRengi,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cerceveRengi, width: secili ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${saat.toString().padLeft(2, '0')}:00",
                      style: TextStyle(
                        color: yaziRengi,
                        fontWeight: secili
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    if (!kilitli) ...[
                      const SizedBox(width: 4),
                      Text(
                        "$havaIkonu $derece°",
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
                if (kilitli)
                  Text(
                    gecmisSaat ? "GEÇTİ" : "DOLU",
                    style: TextStyle(
                      color: gecmisSaat
                          ? (isDark ? Colors.grey[600] : Colors.grey[500])
                          : Colors.redAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    "Seç",
                    style: TextStyle(
                      color: secili ? Colors.white70 : Colors.transparent,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _beklemeListesiDialogGoster(int saat) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Bekleme Listesi"),
          content: Text(
            "Saat $saat:00 için rezervasyon iptal olursa size haber vermemizi ister misiniz?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "$saat:00 saati için bekleme listesine eklendiniz! İptal olduğunda bildirim alacaksınız. 🔔",
                    ),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Haber Ver"),
            ),
          ],
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
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: (_seciliSaat == null) ? null : _rezervasyonOnayiniGoster,
        child: Text(
          _seciliSaat == null ? "Saat Seçin" : "Rezervasyonu Tamamla",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _rezervasyonOnayiniGoster() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!mounted) return;

    // Her açılışta ekstra siparişleri sıfırla
    _suEklendi = false;
    _kramponEklendi = false;
    _eldivenEklendi = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            double ekstraToplam = 0;
            if (_suEklendi) ekstraToplam += suFiyati;
            if (_kramponEklendi) ekstraToplam += kramponFiyati;
            if (_eldivenEklendi) ekstraToplam += eldivenFiyati;

            double genelToplam = widget.saha.fiyat + ekstraToplam;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Rezervasyon Özeti",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ozetSatiri("Saha", widget.saha.isim, isDark),
                  _ozetSatiri(
                    "Tarih",
                    "${_seciliTarih.day}/${_seciliTarih.month}/${_seciliTarih.year}",
                    isDark,
                  ),
                  _ozetSatiri(
                    "Saat",
                    "${_seciliSaat?.toString().padLeft(2, '0')}:00",
                    isDark,
                  ),

                  const Divider(height: 30),
                  // UPSELLING BÖLÜMÜ (Özellik 5)
                  Text(
                    "Ekstra İstekler (İsteğe Bağlı)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text("1 Koli Soğuk Su (10 Adet)"),
                    subtitle: Text(
                      "+${suFiyati.toInt()} ₺",
                      style: const TextStyle(color: Color(0xFF16A34A)),
                    ),
                    value: _suEklendi,
                    activeColor: const Color(0xFF16A34A),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (bool? value) {
                      setModalState(() {
                        _suEklendi = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("Kiralık Krampon"),
                    subtitle: Text(
                      "+${kramponFiyati.toInt()} ₺",
                      style: const TextStyle(color: Color(0xFF16A34A)),
                    ),
                    value: _kramponEklendi,
                    activeColor: const Color(0xFF16A34A),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (bool? value) {
                      setModalState(() {
                        _kramponEklendi = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("Kiralık Kaleci Eldiveni"),
                    subtitle: Text(
                      "+${eldivenFiyati.toInt()} ₺",
                      style: const TextStyle(color: Color(0xFF16A34A)),
                    ),
                    value: _eldivenEklendi,
                    activeColor: const Color(0xFF16A34A),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (bool? value) {
                      setModalState(() {
                        _eldivenEklendi = value ?? false;
                      });
                    },
                  ),

                  const Divider(height: 30),
                  _ozetSatiri(
                    "Ana Tutar",
                    "${widget.saha.fiyat.toInt()} ₺",
                    isDark,
                  ),
                  if (ekstraToplam > 0)
                    _ozetSatiri(
                      "Ekstralar",
                      "+${ekstraToplam.toInt()} ₺",
                      isDark,
                    ),
                  _ozetSatiri(
                    "Genel Toplam",
                    "${genelToplam.toInt()} ₺",
                    isDark,
                    isTotal: true,
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Dialogu kapat
                      importOdemeSayfasi(genelToplam);
                    },
                    child: const Text(
                      "ÖDEME ADIMINA GEÇ",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Bu fonksiyon sayfanın en başına import eklemeden ödeme sayfasına geçmek için gecikmeli bir push yapar.
  // Oku ve test et.
  void importOdemeSayfasi(double sonGenelTutar) {
    odemeEkraninaGit(sonGenelTutar);
  }

  void odemeEkraninaGit(double gTutar) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OdemeEkrani(
          saha: widget.saha,
          tarih: _seciliTarih,
          saat: "${_seciliSaat.toString().padLeft(2, '0')}:00",
          sonTutar: gTutar,
        ),
      ),
    );
  }

  Widget _ozetSatiri(
    String baslik,
    String deger,
    bool isDark, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            baslik,
            style: TextStyle(
              color: isTotal
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? Colors.grey[400] : Colors.grey),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            deger,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isTotal
                  ? const Color(0xFF16A34A)
                  : (isDark ? Colors.white : Colors.black),
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
