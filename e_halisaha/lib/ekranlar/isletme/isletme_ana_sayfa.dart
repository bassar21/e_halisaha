import 'package:flutter/material.dart';
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
  // Artık Map değil, SahaModeli kullanıyoruz
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

      // Kullanıcının idsini string veya int olarak al
      String myId = (widget.kullanici['userId'] ?? widget.kullanici['id'])
          .toString();

      // Sahalar arasında ownerId'si kullanıcınınkiyle eşleşeni bul
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("İşletme Paneli"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Ekstra Fiyatları Ayarla",
            onPressed: () {
              if (_benimSaham != null) {
                _fiyatAyarlariniGoster();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Önce bir saha eklemelisiniz.")),
                );
              }
            },
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
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _benimSaham == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stadium_outlined,
                        size: 80,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Henüz Bir Sahanız Yok",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "İşletmeniz için müşteri kabul etmeye ve rezervasyon almaya başlamak için hemen yeni bir saha oluşturun.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _sahaEklemeDialogGoster,
                      icon: const Icon(Icons.add_business, size: 24),
                      label: const Text(
                        "Yeni Saha Oluştur",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Saha Bilgi Kartı
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.stadium,
                              size: 40,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Map [] operatörü yerine obje dot notation (.) kullanıyoruz
                                Text(
                                  _benimSaham!.isim,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _benimSaham!.ilce,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${_benimSaham!.fiyat.toInt()} ₺ / Saat",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "📅 Gelen Randevular",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Randevu Listesi
                  Expanded(
                    child: _randevular.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 50,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Henüz randevu yok.",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _randevular.length,
                            itemBuilder: (context, index) {
                              var randevu = _randevular[index];
                              String tarih = randevu['rezDate']
                                  .toString()
                                  .split('T')[0];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text("Saat: ${randevu['rezHour']}:00"),
                                  subtitle: Text(
                                    "Tarih: $tarih\nNot: ${randevu['note'] ?? 'Not yok'}",
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
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
          title: const Text("Saha ve Ekstra Fiyatları (₺)"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fiyatController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Saatlik Saha Ücreti (₺)",
                    prefixIcon: Icon(Icons.sports_soccer, color: Colors.green),
                  ),
                ),
                const Divider(height: 30),
                const Text(
                  "Ekstra Ürünler:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: suController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "1 Koli Soğuk Su Fiyatı",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: kramponController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Kiralık Krampon Fiyatı",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: eldivenController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Kiralık Eldiven Fiyatı",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
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
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      basarili
                          ? "Fiyatlar başarıyla güncellendi."
                          : "Ekstra Fiyatları güncellendi ama Saatlik Saha Ücreti backend'e yansımamış olabilir.",
                    ),
                    backgroundColor: basarili ? Colors.green : Colors.orange,
                  ),
                );

                if (basarili) {
                  _sahaBilgileriniGetir(); // Veriyi tazelemek için
                }
              },
              child: const Text("Kaydet"),
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
          title: const Row(
            children: [
              Icon(Icons.add_business, color: Colors.orange),
              SizedBox(width: 8),
              Text("Yeni Saha Oluştur"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: isimController,
                  decoration: const InputDecoration(
                    labelText: "Saha Adı (Örn: Merkez Spor Tesisleri)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fiyatController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Saatlik Ücret (₺)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ilceController,
                  decoration: const InputDecoration(
                    labelText: "İlçe (Örn: Kadıköy)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adresController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Tam Adres",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
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

                if (eklendiMi) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Saha başarıyla oluşturuldu! 🎉"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _sahaBilgileriniGetir(); // Listeyi güncelle
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
