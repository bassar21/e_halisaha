import 'package:flutter/foundation.dart';

class OdemeServisi {
  static final List<Map<String, String>> _kayitliKartlar = [
    {'no': '**** **** **** 4242', 'isim': 'Varsayılan Test Kartı'},
  ];

  static List<Map<String, String>> get kartlar => _kayitliKartlar;

  static void kartEkle(String kartNo, String isim) {
    String sonDort = kartNo.length > 4
        ? kartNo.substring(kartNo.length - 4)
        : kartNo;

    bool zatenVar = _kayitliKartlar.any((k) => k['no']!.contains(sonDort));

    if (!zatenVar) {
      String maskeliNo = "**** **** **** $sonDort";
      _kayitliKartlar.add({'no': maskeliNo, 'isim': isim});
      debugPrint("Kart Eklendi: $isim - $maskeliNo");
    }
  }

  // Kart Silme
  static void kartSil(int index) {
    _kayitliKartlar.removeAt(index);
  }
}
