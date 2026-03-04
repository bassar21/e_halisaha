import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart'; // GERÇEK CİHAZ KONUMU İÇİN (Geolocator eklentisi pubspec'te mevcut)

class HavaDurumuServisi {
  static const String _baseUrl = "https://api.open-meteo.com/v1/forecast";

  /// 1. Cihazın Gerçek GPS Konumunu Alır
  static Future<Position?> _gercekKonumuAl() async {
    try {
      bool servisAcikMi = await Geolocator.isLocationServiceEnabled();
      if (!servisAcikMi) {
        debugPrint("Konum servisleri kapalı.");
        return null;
      }

      LocationPermission izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
        if (izin == LocationPermission.denied) {
          debugPrint("Konum izni reddedildi.");
          return null;
        }
      }
      
      if (izin == LocationPermission.deniedForever) {
        debugPrint("Konum izni kalıcı olarak reddedildi.");
        return null;
      }

      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      debugPrint("Gerçek Konum alınırken hata oluştu: $e");
      return null;
    }
  }

  /// 2. Cihazın Gerçek Konumu Üzerinden Seçili Tarihteki Saatlik Hava Durumunu Getirir
  static Future<Map<int, Map<String, dynamic>>?> cihazKonumundanHavaDurumuGetir(DateTime tarih) async {
    Position? pos = await _gercekKonumuAl();
    
    double lat;
    double lon;

    if (pos != null) {
      // TELEFONUN KENDİ GERÇEK KONUMU (GPS)
      lat = pos.latitude;
      lon = pos.longitude;
      debugPrint("📡 GERÇEK CİHAZ KONUMU ALINDI: $lat, $lon");
    } else {
      // İzin verilmezse vb. durumlarda fallback olarak İstanbul merkezKoordinatları alınır.
      lat = 41.0082;
      lon = 28.9784;
      debugPrint("⚠️ Gerçek konum alınamadı. Varsayılan (İstanbul) konumu kullanılıyor.");
    }

    return await _gunlukSaatlikHavaDurumuGetir(lat, lon, tarih);
  }

  /// 3. Open-Meteo API'sine Gerçek Koordinatları Gönderir
  static Future<Map<int, Map<String, dynamic>>?> _gunlukSaatlikHavaDurumuGetir(double lat, double lon, DateTime tarih) async {
    try {
      String tarihStr = tarih.toIso8601String().split('T')[0];

      final url = Uri.parse(
        "$_baseUrl?latitude=$lat&longitude=$lon"
        "&hourly=temperature_2m,weathercode"
        "&timezone=Europe%2FIstanbul"
        "&start_date=$tarihStr&end_date=$tarihStr"
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final veriler = jsonDecode(response.body);
        final hourly = veriler['hourly'];

        List<dynamic> saatler = hourly['time']; // "2024-03-03T00:00" formatında
        List<dynamic> sicakliklar = hourly['temperature_2m'];
        List<dynamic> kodlar = hourly['weathercode'];

        Map<int, Map<String, dynamic>> saatlikHavaDurumu = {};

        for (int i = 0; i < saatler.length; i++) {
          String zaman = saatler[i];
          int saatStr = int.parse(zaman.split('T')[1].split(':')[0]);
          
          double derece = double.tryParse(sicakliklar[i].toString()) ?? 0.0;
          int wmoKodu = int.tryParse(kodlar[i].toString()) ?? 0;

          saatlikHavaDurumu[saatStr] = {
            "derece": derece,
            "ikon": _wmoKodunuIkonaCevir(wmoKodu, saatStr)
          };
        }

        return saatlikHavaDurumu;
      } else {
        debugPrint("Hava durumu API Hatası: ${response.statusCode}");
        return null; 
      }
    } catch (e) {
      debugPrint("Hava durumu servisi hatası: $e");
      return null;
    }
  }

  /// WMO Hava Durumu Kodlarını Emoji İkonlarına Çevirir
  static String _wmoKodunuIkonaCevir(int kod, int saat) {
    bool geceMi = saat < 6 || saat > 18;
    if (kod == 0) return geceMi ? "🌙" : "☀️"; // Açık
    if (kod == 1 || kod == 2 || kod == 3) return geceMi ? "☁️" : "⛅"; // Parçalı Bulutlu
    if (kod == 45 || kod == 48) return "🌫️"; // Sisli
    if (kod >= 51 && kod <= 55) return "🌧️"; // Çisenti
    if (kod >= 61 && kod <= 65) return "🌧️"; // Yağmurlu
    if (kod >= 71 && kod <= 77) return "❄️"; // Kar
    if (kod >= 80 && kod <= 82) return "🌦️"; // Sağanak
    if (kod >= 95 && kod <= 99) return "⛈️"; // Fırtına

    return geceMi ? "🌙" : "☀️";
  }
}
