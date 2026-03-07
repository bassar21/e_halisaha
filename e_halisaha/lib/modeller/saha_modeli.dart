class SahaModeli {
  final String id;
  final String isim;
  final double fiyat;
  final double kapora;
  final String ilce;
  final String tamKonum;
  final double puan;
  final String resimYolu;
  final List<String> ozellikler;
  final String isletmeSahibiEmail;
  final String? ownerId;

  // Upselling Dinamik Fiyatları
  double suFiyati;
  double kramponFiyati;
  double eldivenFiyati;

  SahaModeli({
    required this.id,
    required this.isim,
    required this.fiyat,
    required this.kapora,
    required this.ilce,
    required this.tamKonum,
    required this.puan,
    required this.resimYolu,
    required this.ozellikler,
    required this.isletmeSahibiEmail,
    this.ownerId,
    this.suFiyati = 20.0,
    this.kramponFiyati = 70.0,
    this.eldivenFiyati = 40.0,
  });

  factory SahaModeli.fromMap(Map<String, dynamic> map) {
    return SahaModeli(
      id: map['id'].toString(),
      isim: map['isim'] ?? "İsimsiz Saha",
      fiyat: map['fiyat'] ?? 0.0,
      kapora: map['kapora'] ?? 0.0,
      ilce: map['ilce'] ?? "Merkez",
      tamKonum: map['tamKonum'] ?? "Konum belirtilmedi",
      puan: map['puan'] ?? 4.5,
      resimYolu: map['resimYolu'] ?? "assets/resimler/saha1.png",
      ozellikler: List<String>.from(map['ozellikler'] ?? []),
      isletmeSahibiEmail: map['isletmeSahibiEmail'] ?? "",
      ownerId: map['ownerId']?.toString(),
      suFiyati: map['suFiyati'] != null
          ? double.tryParse(map['suFiyati'].toString()) ?? 20.0
          : 20.0,
      kramponFiyati: map['kramponFiyati'] != null
          ? double.tryParse(map['kramponFiyati'].toString()) ?? 70.0
          : 70.0,
      eldivenFiyati: map['eldivenFiyati'] != null
          ? double.tryParse(map['eldivenFiyati'].toString()) ?? 40.0
          : 40.0,
    );
  }
}
