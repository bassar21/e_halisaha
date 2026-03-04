import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:async';
import '../../modeller/saha_modeli.dart';
import '../../cekirdek/servisler/api_servisi.dart';
import '../../cekirdek/servisler/kimlik_servisi.dart'; // userId için gerekli

class OdemeEkrani extends StatefulWidget {
  final SahaModeli saha;
  final DateTime tarih;
  final String saat;
  final double sonTutar;

  const OdemeEkrani({
    super.key,
    required this.saha,
    required this.tarih,
    required this.saat,
    required this.sonTutar,
  });

  @override
  State<OdemeEkrani> createState() => _OdemeEkraniState();
}

class _OdemeEkraniState extends State<OdemeEkrani> {
  final ApiServisi _apiServisi = ApiServisi();

  bool _yukleniyor = false;
  int _secilenYontem = 0;
  List<dynamic> _kayitliKartlar = [];
  bool _kartlarYuklendi = false;

  // Form Kontrolcüleri
  final _kartNoController = TextEditingController();
  final _kartAdController = TextEditingController();
  final _sktController = TextEditingController();
  final _cvvController = TextEditingController();

  // --- KART MASKELERİ ---
  var kartMaskesi = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // AY KONTROLÜ İÇİN ÖZEL FORMATTER (12'den büyük yazılamaz)
  final tarihFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    if (newValue.text.isNotEmpty) {
      if (newValue.text.length > 4) return oldValue; // MMYY (4 hane)

      // İlk iki hane (AY) kontrolü
      if (newValue.text.length >= 2) {
        int? ay = int.tryParse(newValue.text.substring(0, 2));
        if (ay == null || ay > 12 || ay == 0) {
          return oldValue; // Hatalı aysa yazma
        }
      }
    }
    return newValue;
  });

  @override
  void initState() {
    super.initState();
    _kartlariGetir();
  }

  void _kartlariGetir() async {
    int userId = KimlikServisi.aktifKullanici?['id'] ?? 0;
    var kartlar = await _apiServisi.kartlariGetir(userId);
    if (mounted) {
      setState(() {
        _kayitliKartlar = kartlar;
        _kartlarYuklendi = true;
      });
    }
  }

  void _kartSil(int kartId) async {
    setState(() => _yukleniyor = true);
    // API'den sil
    bool sonuc = await _apiServisi.kartSil(kartId);
    if (sonuc) {
      // Başarılıysa listeyi yenile
      _kartlariGetir();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Kart silindi.")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Silinemedi.")));
    }
    setState(() => _yukleniyor = false);
  }

  void _kartKaydet() async {
    if (_kartNoController.text.length < 19 || _sktController.text.length < 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Kart bilgileri eksik.")));
      return;
    }

    setState(() => _yukleniyor = true);
    int userId = KimlikServisi.aktifKullanici?['id'] ?? 0;

    bool sonuc = await _apiServisi.kartEkle(
      userId,
      _kartAdController.text.isEmpty ? "Kartım" : _kartAdController.text,
      _kartNoController.text,
    );

    if (sonuc) {
      _kartNoController.clear();
      _kartAdController.clear();
      _sktController.clear();
      _cvvController.clear();
      _kartlariGetir(); // Listeyi güncelle
      Navigator.pop(context); // Dialogu kapat
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Kart eklendi!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kart eklenirken hata oluştu.")),
      );
    }
    setState(() => _yukleniyor = false);
  }

  void _odemeYap() async {
    setState(() => _yukleniyor = true);

    // Rezervasyon İşlemi
    int userId = KimlikServisi.aktifKullanici?['id'] ?? 0;

    // Tarih birleştirme (String saat "19:00" -> int 19)
    int saatInt = int.parse(widget.saat.split(":")[0]);

    bool sonuc = await _apiServisi.rezervasyonYap(
      int.parse(widget.saha.id),
      userId,
      widget.tarih,
      saatInt,
      "Ödeme Yapıldı - Mobil Uygulama",
    );

    setState(() => _yukleniyor = false);

    if (sonuc) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: const Text(
            "Ödeme Başarılı! Rezervasyonunuz oluşturuldu.",
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text("TAMAM"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ödeme başarısız oldu."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Yeni Kart Ekleme Penceresi
  void _kartEkleDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Yeni Kart Ekle",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _kartAdController,
              decoration: const InputDecoration(
                labelText: "Kart Başlığı (Örn: İş Kartım)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _kartNoController,
              inputFormatters: [kartMaskesi],
              decoration: const InputDecoration(
                labelText: "Kart Numarası",
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sktController,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      tarihFormatter,
                    ],
                    decoration: const InputDecoration(
                      labelText: "AA/YY",
                      hintText: "1225",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    inputFormatters: [LengthLimitingTextInputFormatter(3)],
                    decoration: const InputDecoration(
                      labelText: "CVV",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _kartKaydet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "KAYDET",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool koyuMod = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Ödeme Yap")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: koyuMod ? Colors.grey[800] : Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ödenecek Tutar",
                        style: TextStyle(
                          color: koyuMod ? Colors.white70 : Colors.green[800],
                        ),
                      ),
                      Text(
                        "${widget.sonTutar.toStringAsFixed(0)} ₺",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.verified_user,
                    color: Colors.green,
                    size: 40,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Kayıtlı Kartlarım",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Kart Listesi
            if (!_kartlarYuklendi)
              const Center(child: CircularProgressIndicator())
            else if (_kayitliKartlar.isEmpty)
              const Text(
                "Kayıtlı kartınız yok. Aşağıdan ekleyebilirsiniz.",
                style: TextStyle(color: Colors.grey),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _kayitliKartlar.length,
                itemBuilder: (context, index) {
                  var kart = _kayitliKartlar[index];
                  bool secili = _secilenYontem == index;
                  return Card(
                    color: secili ? Colors.green.withOpacity(0.1) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: secili ? Colors.green : Colors.transparent,
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.credit_card),
                      title: Text(kart['cardAlias'] ?? "Kart"),
                      subtitle: Text(
                        "**** **** **** ${kart['cardNumber'].toString().substring(kart['cardNumber'].toString().length - 4)}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _kartSil(kart['id']), // ARTIK ÇÖKMEZ
                      ),
                      onTap: () => setState(() => _secilenYontem = index),
                    ),
                  );
                },
              ),

            TextButton.icon(
              onPressed: _kartEkleDialog,
              icon: const Icon(Icons.add_circle),
              label: const Text("Yeni Kart Ekle"),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _odemeYap,
                child: _yukleniyor
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "ÖDEMEYİ ONAYLA",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
