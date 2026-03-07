import 'package:flutter/material.dart';

import '../../modeller/saha_modeli.dart';
import '../../cekirdek/servisler/api_servisi.dart';
import '../../cekirdek/servisler/kimlik_servisi.dart'; // userId için gerekli

class OdemeEkrani extends StatefulWidget {
  final SahaModeli saha;
  final DateTime tarih;
  final String saat;
  final double sonTutar;
  final String ekstraNotlar;

  const OdemeEkrani({
    super.key,
    required this.saha,
    required this.tarih,
    required this.saat,
    required this.sonTutar,
    this.ekstraNotlar = "",
  });

  @override
  State<OdemeEkrani> createState() => _OdemeEkraniState();
}

class _OdemeEkraniState extends State<OdemeEkrani> {
  final ApiServisi _apiServisi = ApiServisi();

  bool _yukleniyor = false;
  @override
  void initState() {
    super.initState();
    // Kart olayları kaldırıldı. Sadece özet gösterilecek.
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
      "Ödeme Test Aşaması. ${widget.ekstraNotlar}",
    );

    setState(() => _yukleniyor = false);

    if (sonuc) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: const Text(
            "Rezervasyonunuz başarıyla oluşturuldu!\n\n(Ödeme saha tesisinde alınacaktır.)",
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

            const SizedBox(height: 30),
            Center(
              child: Text(
                "Şu anlık test aşamasında olduğumuz için ödemeler saha girişinde peşin veya kart ile alınmaktadır.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: koyuMod ? Colors.white70 : Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
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
                        "RANDEVUYU ONAYLA",
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
