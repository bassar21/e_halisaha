import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../cekirdek/servisler/api_servisi.dart';
import '../../cekirdek/servisler/kimlik_servisi.dart';
import '../../modeller/saha_modeli.dart';
import '../giris/giris_ekrani.dart';

class IsletmeAnaSayfa extends StatefulWidget {
  final Map<String, dynamic> kullanici;

  const IsletmeAnaSayfa({super.key, required this.kullanici});

  @override
  State<IsletmeAnaSayfa> createState() => _IsletmeAnaSayfaState();
}

class _IsletmeAnaSayfaState extends State<IsletmeAnaSayfa> {
  final ApiServisi _apiServisi = ApiServisi();
  final ImagePicker _picker = ImagePicker();

  SahaModeli? _benimSaham;
  List<dynamic> _randevular = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _sahaBilgileriniGetir();
  }

  void _sahaBilgileriniGetir() async {
    try {
      var tumSahalar = await _apiServisi.tumSahalariGetir();

      String myId = (widget.kullanici['userId'] ?? widget.kullanici['id'])
          .toString();

      var saham = tumSahalar.where((saha) {
        bool emailEslesti =
            (saha.isletmeSahibiEmail.isNotEmpty &&
            saha.isletmeSahibiEmail == widget.kullanici['email']);
        bool idEslesti = (saha.ownerId != null && saha.ownerId == myId);
        return emailEslesti || idEslesti;
      }).firstOrNull;

      if (saham != null) {
        var randevular = await _apiServisi.sahaRandevulariniGetir(saham.id);

        if (mounted) {
          setState(() {
            _benimSaham = saham;
            _randevular = List.from(randevular.reversed);
            _yukleniyor = false;
          });
        }
      } else {
        if (mounted) setState(() => _yukleniyor = false);
      }
    } catch (e) {
      debugPrint("Saha Getirme Hatası: $e");
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _resimSecVeYukle() async {
    final XFile? resim = await _picker.pickImage(source: ImageSource.gallery);
    if (resim != null) {
      setState(() => _yukleniyor = true);
      bool basarili = await _apiServisi.sahaResimGuncelle(
        _benimSaham!.id,
        resim.path,
      );

      if (!mounted) return;
      if (basarili) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Saha görseli başarıyla güncellendi! 📸"),
            backgroundColor: Colors.green,
          ),
        );
        _sahaBilgileriniGetir();
      } else {
        setState(() => _yukleniyor = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Görsel yüklenemedi. Sunucu hatası."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "İşletme Paneli",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade800, Colors.orange.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (_benimSaham != null)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: "Fiyatları Ayarla",
              onPressed: _fiyatAyarlariniGoster,
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              KimlikServisi.cikisYap();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const GirisEkrani()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.grey.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _yukleniyor
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                )
              : _benimSaham == null
              ? _buildSahamYokEkrani()
              : _buildSahaVeRandevular(context),
        ),
      ),
    );
  }

  Widget _buildSahamYokEkrani() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0.5, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, val, child) {
                return Transform.scale(
                  scale: val,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade100, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.stadium_rounded,
                      size: 80,
                      color: Colors.orange.shade600,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              "Sahanız Henüz Yok",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "İşletmeniz için müşteri kabul etmeye başlamak adına ilk adımınızı atın ve sahanızı oluşturun.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _sahaEklemeDialogGoster,
              icon: const Icon(Icons.add_circle_outline, size: 28),
              label: const Text(
                "Yeni Saha Oluştur",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                shadowColor: Colors.orange.shade200,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSahaVeRandevular(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Glassmorphic tarzı saha bilgi kartı
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      _benimSaham!.resimYolu.isNotEmpty
                          ? Image.network(
                              _benimSaham!.resimYolu,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 180,
                                    color: Colors.grey.shade100,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                            )
                          : Container(
                              height: 180,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade300,
                                    Colors.orange.shade100,
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.sports_soccer,
                                  size: 80,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: ElevatedButton.icon(
                          onPressed: _resimSecVeYukle,
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text("Görseli Güncelle"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.stadium,
                          size: 36,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _benimSaham!.isim,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _benimSaham!.ilce,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${_benimSaham!.fiyat.toInt()} ₺ / Saat",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event_note_rounded,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Gelen Randevular",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Randevu Listesi
          Expanded(
            child: _randevular.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Henüz randevu bulunmuyor.",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _randevular.length,
                    itemBuilder: (context, index) {
                      var randevu = _randevular[index];
                      String tarih = randevu['rezDate'].toString().split(
                        'T',
                      )[0];
                      bool aktifMi = DateTime.parse(tarih).isAfter(
                        DateTime.now().subtract(const Duration(days: 1)),
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: aktifMi
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              aktifMi ? Icons.check_circle : Icons.history,
                              color: aktifMi ? Colors.green : Colors.grey,
                            ),
                          ),
                          title: Text(
                            "Saat: ${randevu['rezHour'].toString().padLeft(2, '0')}:00",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "Tarih: $tarih\nNot: ${randevu['note'] ?? 'Belirtilmedi'}",
                              style: TextStyle(
                                height: 1.4,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _fiyatAyarlariniGoster() {
    TextEditingController fiyatController = TextEditingController(
      text: _benimSaham!.fiyat.toInt().toString(),
    );
    TextEditingController suController = TextEditingController(
      text: _benimSaham!.suFiyati.toString(),
    );
    TextEditingController kramponController = TextEditingController(
      text: _benimSaham!.kramponFiyati.toString(),
    );
    TextEditingController eldivenController = TextEditingController(
      text: _benimSaham!.eldivenFiyati.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(Icons.settings_suggest, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text(
                "Fiyat Ayarları",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: fiyatController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Saatlik Saha Ücreti (₺)",
                    prefixIcon: Icon(
                      Icons.sports_soccer,
                      color: Colors.green.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Ekstra Ürünler:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: suController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Soğuk Su (Koli) ₺",
                    prefixIcon: const Icon(
                      Icons.water_drop,
                      color: Colors.lightBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kramponController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Kiralık Krampon ₺",
                    prefixIcon: const Icon(
                      Icons.skateboarding,
                      color: Colors.deepOrange,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: eldivenController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Kaleci Eldiveni ₺",
                    prefixIcon: const Icon(
                      Icons.back_hand,
                      color: Colors.pinkAccent,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "İptal",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                double yeniFiyat =
                    double.tryParse(fiyatController.text) ?? _benimSaham!.fiyat;

                bool basarili = await _apiServisi.sahaFiyatGuncelle(
                  int.parse(_benimSaham!.id),
                  yeniFiyat,
                );

                setState(() {
                  _benimSaham!.suFiyati =
                      double.tryParse(suController.text) ?? 20.0;
                  _benimSaham!.kramponFiyati =
                      double.tryParse(kramponController.text) ?? 70.0;
                  _benimSaham!.eldivenFiyati =
                      double.tryParse(eldivenController.text) ?? 40.0;
                });
                if (!context.mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      basarili
                          ? "Fiyatlar başarıyla güncellendi."
                          : "Ek fiyatlar kaydedildi, saha ücreti güncellenemedi.",
                    ),
                    backgroundColor: basarili ? Colors.green : Colors.orange,
                  ),
                );

                if (basarili) _sahaBilgileriniGetir();
              },
              child: const Text(
                "Kaydet",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _sahaEklemeDialogGoster() {
    TextEditingController isimController = TextEditingController();
    TextEditingController fiyatController = TextEditingController(text: "1500");
    TextEditingController ilceController = TextEditingController();
    TextEditingController adresController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(Icons.add_business, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text(
                "Yeni Saha Oluştur",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: isimController,
                  decoration: InputDecoration(
                    labelText: "Saha Adı",
                    hintText: "Örn: Merkez Spor Tesisleri",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fiyatController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Saatlik Ücret (₺)",
                    prefixIcon: const Icon(
                      Icons.monetization_on,
                      color: Colors.green,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ilceController,
                  decoration: InputDecoration(
                    labelText: "İlçe",
                    hintText: "Örn: Kadıköy",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adresController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Tam Adres",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "İptal",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                if (isimController.text.trim().isEmpty ||
                    ilceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lütfen zorunlu alanları doldurun."),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() => _yukleniyor = true);

                double saatlikFiyat =
                    double.tryParse(fiyatController.text) ?? 1500.0;
                String myId =
                    (widget.kullanici['userId'] ?? widget.kullanici['id'])
                        .toString();

                Map<String, dynamic> yeniSahaVerisi = {
                  "name": isimController.text.trim(),
                  "hourlyPrice": saatlikFiyat,
                  "type": "Açık",
                  "capacity": 14,
                  "depositPrice": 0,
                  "openingHour": 8,
                  "closingHour": 23,
                  "slotDuration": 60,
                  "district": ilceController.text.trim(),
                  "address": adresController.text.trim(),
                  "ownerId": myId,
                };

                bool eklendiMi = await _apiServisi.sahaEkle(yeniSahaVerisi);

                if (!context.mounted) return;

                if (eklendiMi) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Saha başarıyla oluşturuldu! 🎉"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _sahaBilgileriniGetir();
                } else {
                  if (mounted) setState(() => _yukleniyor = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Saha oluşturulamadı, backend rotasını kontrol edin.",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                "Oluştur",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
