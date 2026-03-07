import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'kimlik_servisi.dart';
import '../../modeller/saha_modeli.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class ApiServisi {
  static const String _baseUrl = "http://185.157.46.167:3000/api";
  static const String _imageBaseUrl = "http://185.157.46.167:3000";

  Future<Map<String, String>> _headers() async {
    String? token = await KimlikServisi.tokenGetir();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  void _yetkiKontrolu(int statusCode, {bool ignoreRedirect = false}) {
    if (statusCode == 401) {
      debugPrint("JWT Hatası: yetkisiz erişim/token yok.");
      KimlikServisi.tokenGetir().then((token) {
        if (token != null) {
          // Sadece daha önce token varsa ve süresi dolduysa çıkış yap.
          KimlikServisi.cikisYap().then((_) {
            if (!ignoreRedirect && globalNavigatorKey.currentContext != null) {
              Navigator.pushNamedAndRemoveUntil(
                globalNavigatorKey.currentContext!,
                '/login',
                (route) => false,
              );
            }
          });
        }
      });
    }
  }

  // --- KAYIT OL (GÜNCELLENDİ: ARTIK MAP DÖNÜYOR) ---
  Future<Map<String, dynamic>> kayitOl(
    String adSoyad,
    String email,
    String telefon,
    String sifre,
  ) async {
    try {
      final url = Uri.parse("$_baseUrl/auth/register");

      final bodyData = jsonEncode({
        "fullName": adSoyad,
        "email": email,
        "phone": telefon,
        "password": sifre,
      });

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: bodyData,
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message": decoded['message'],
          "userId": decoded['userId'],
        };
      }
      return {
        "success": false,
        "error": decoded['error'] ?? "Kayıt başarısız.",
      };
    } catch (e) {
      debugPrint("Kayıt fonksiyonunda hata: $e");
      return {"success": false, "error": "Bağlantı hatası oluştu."};
    }
  }

  // --- OTP / KOD DOĞRULAMA (YENİ EKLENDİ) ---
  Future<Map<String, dynamic>> otpDogrula(String email, String kod) async {
    try {
      final url = Uri.parse("$_baseUrl/auth/verify-otp");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "code": kod}),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": decoded['message']};
      }
      return {
        "success": false,
        "error": decoded['error'] ?? "Doğrulama başarısız.",
      };
    } catch (e) {
      return {"success": false, "error": "Sunucuya bağlanılamadı."};
    }
  }

  // --- GİRİŞ YAP ---
  Future<Map<String, dynamic>?> girisYap(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await KimlikServisi.girisYapveKaydet(data);
        return data;
      }
      // Eğer kullanıcı onaylı değilse backend 403 ve needVerify dönecek
      else if (response.statusCode == 403) {
        return {"success": false, "needVerify": true, "error": data['error']};
      }
      // DİĞER DURUMLAR (401 Hatalı Şifre, 404 Kullanıcı Bulunamadı vs.)
      else {
        return {
          "success": false,
          "error": data['error'] ?? "Giriş başarısız (${response.statusCode})",
        };
      }
    } catch (e) {
      return {"success": false, "error": "Sunucu bağlantı hatası: $e"};
    }
  }

  Future<List<dynamic>> tumKullanicilariGetir() async {
    try {
      final headers = await _headers();
      debugPrint("Kullanıcıları getirme isteği başlatıldı. Headers: $headers");
      final r = await http.get(Uri.parse('$_baseUrl/users'), headers: headers);
      _yetkiKontrolu(r.statusCode, ignoreRedirect: true);
      debugPrint("Kullanıcılar Yanıt Kodu: ${r.statusCode}");
      debugPrint("Kullanıcılar Yanıt İçeriği: ${r.body}");
      if (r.statusCode == 200) {
        final decoded = jsonDecode(r.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map<String, dynamic>) {
          return decoded['data'] ?? decoded['users'] ?? [];
        }
        return [];
      }
    } catch (e) {
      debugPrint("--- KRİTİK KULLANICI LİSTESİ HATASI ---");
      debugPrint(e.toString());
    }
    return [];
  }

  Future<bool> kullaniciBilgileriniGuncelle(
    int id,
    Map<String, dynamic> veriler,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/users/$id');
      final headers = await _headers();
      final body = jsonEncode(veriler);

      var r = await http.put(url, headers: headers, body: body);
      if (r.statusCode == 404) {
        r = await http.patch(url, headers: headers, body: body);
      }
      _yetkiKontrolu(r.statusCode);
      return r.statusCode == 200 || r.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> profilGuncelle(
    int kullaniciId,
    String ad,
    String email,
    String telefon,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/users/$kullaniciId');
      final headers = await _headers();

      final bodyData = jsonEncode({
        'fullName': ad,
        'name': ad,
        'email': email,
        'phone': telefon,
        'phoneNumber': telefon,
      });

      var response = await http.put(url, headers: headers, body: bodyData);

      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await http.patch(url, headers: headers, body: bodyData);
      }
      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> kullaniciRoluGuncelle(int id, String rol) async {
    try {
      final headers = await _headers();
      final body = jsonEncode({'role': rol});

      final urlRole = Uri.parse('$_baseUrl/users/$id/role');
      var r = await http.put(urlRole, headers: headers, body: body);

      if (r.statusCode == 404 || r.statusCode == 405) {
        final url = Uri.parse('$_baseUrl/users/$id');
        r = await http.put(url, headers: headers, body: body);
      }
      return r.statusCode == 200 || r.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> kullaniciSil(int id) async {
    try {
      final r = await http.delete(
        Uri.parse('$_baseUrl/users/$id'),
        headers: await _headers(),
      );
      return r.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<SahaModeli>> tumSahalariGetir() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pitches'));
      _yetkiKontrolu(response.statusCode, ignoreRedirect: true);
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        List<dynamic> sahalarJson = resData['data'] ?? [];
        return sahalarJson.map((json) {
          String imgUrl = json['image_url'] ?? "";
          if (imgUrl.isNotEmpty && !imgUrl.startsWith('http')) {
            imgUrl = "$_imageBaseUrl/$imgUrl";
          }

          String ilceBilgisi = json['district'] ?? "";
          if (ilceBilgisi.isEmpty && json['address'] != null) {
            ilceBilgisi = json['address']
                .toString()
                .split(',')[0]
                .split('/')[0]
                .trim();
          }
          if (ilceBilgisi.isEmpty) ilceBilgisi = "Konum Yok";

          return SahaModeli.fromMap({
            "id": json['id'].toString(),
            "isim": json['name'] ?? "İsimsiz Saha",
            "fiyat":
                double.tryParse(
                  (json['price'] ?? json['hourly_price'] ?? 0).toString(),
                ) ??
                0.0,
            "kapora": double.tryParse((json['deposit'] ?? 0).toString()) ?? 0.0,
            "tamKonum": json['address'] ?? "Adres yok",
            "ilce": ilceBilgisi,
            "puan": 4.5,
            "resimYolu": imgUrl,
            "ozellikler": ["Otopark", "Kantin"],
            "ownerId": json['owner_id']?.toString(),
            "acilisSaati": json['opening_hour'] ?? 8,
            "kapanisSaati": json['closing_hour'] ?? 23,
            "suFiyati": json['water_price'],
            "kramponFiyati": json['cleats_price'],
            "eldivenFiyati": json['gloves_price'],
          });
        }).toList();
      }
    } catch (e) {
      debugPrint("Saha hatası: $e");
    }
    return [];
  }

  Future<bool> sahaEkle(Map<String, dynamic> sahaVerisi) async {
    try {
      final r = await http.post(
        Uri.parse('$_baseUrl/pitches'),
        headers: await _headers(),
        body: jsonEncode(sahaVerisi),
      );
      return r.statusCode == 200 || r.statusCode == 201;
    } catch (e) {
      debugPrint("Saha ekleme hatası: $e");
      return false;
    }
  }

  Future<bool> sahaResimGuncelle(String pitchId, String resimYolu) async {
    try {
      var uri = Uri.parse('$_baseUrl/pitches/$pitchId/image');
      var request = http.MultipartRequest('POST', uri);

      String? token = await KimlikServisi.tokenGetir();
      if (token != null) {
        request.headers['Authorization'] = "Bearer $token";
      }

      if (resimYolu.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('image', resimYolu),
        );
      }

      var response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Saha resim yükleme hatası: $e");
      return false;
    }
  }

  Future<bool> sahaFiyatGuncelle(
    int id,
    double yeniFiyat,
    double suFiyati,
    double krampon,
    double eldiven,
  ) async {
    try {
      final r = await http.put(
        Uri.parse('$_baseUrl/pitches/$id'),
        headers: await _headers(),
        body: jsonEncode({
          "hourly_price": yeniFiyat,
          "price": yeniFiyat,
          "water_price": suFiyati,
          "cleats_price": krampon,
          "gloves_price": eldiven,
        }), // Her iki formatı da giden JSON'a ekliyoruz
      );
      return r.statusCode == 200 || r.statusCode == 201;
    } catch (e) {
      debugPrint("Fiyat güncelleme hatası: $e");
      return false;
    }
  }

  Future<bool> sahaSil(int id) async {
    try {
      final r = await http.delete(
        Uri.parse('$_baseUrl/pitches/$id'),
        headers: await _headers(),
      );
      return r.statusCode == 200 || r.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> sahaRandevulariniGetir(String id) async {
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/bookings/facility/$id'),
        headers: await _headers(),
      );
      if (r.statusCode == 200) {
        final decoded = jsonDecode(r.body);
        return decoded['data'] ?? [];
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<List<dynamic>> rezervasyonlarimiGetir() async {
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/bookings/my'),
        headers: await _headers(),
      );
      _yetkiKontrolu(r.statusCode);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is List) return data;
        return data['data'] ?? data['bookings'] ?? [];
      }
    } catch (e) {
      debugPrint("HATA: $e");
    }
    return [];
  }

  Future<List<int>> doluSaatleriGetir(int sahaId, DateTime tarih) async {
    try {
      String d = tarih.toIso8601String().split('T')[0];
      final r = await http.get(
        Uri.parse('$_baseUrl/bookings/check/$sahaId?date=$d'),
        headers: await _headers(),
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return List<int>.from(data['busyHours'] ?? []);
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<bool> rezervasyonYap(
    int sahaId,
    int userId,
    DateTime tarih,
    int saat,
    String notlar,
  ) async {
    try {
      String d = tarih.toIso8601String().split('T')[0];
      String start = "${d}T${saat.toString().padLeft(2, '0')}:00:00";
      String end = "${d}T${(saat + 1).toString().padLeft(2, '0')}:00:00";

      final bodyData = jsonEncode({
        "pitchId": sahaId,
        "userId": userId,
        "startTime": start,
        "endTime": end,
        "paymentMethod": "online",
        "notes": notlar,
      });

      final r = await http.post(
        Uri.parse('$_baseUrl/bookings'),
        headers: await _headers(),
        body: bodyData,
      );
      return r.statusCode == 200 || r.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> ticketOlustur(
    int userId,
    String cihazBilgisi,
    String mesaj,
    String? resimYolu,
  ) async {
    try {
      var uri = Uri.parse('$_baseUrl/tickets');
      var request = http.MultipartRequest('POST', uri);

      String? token = await KimlikServisi.tokenGetir();
      if (token != null) {
        request.headers['Authorization'] = "Bearer $token";
      }

      request.fields['userId'] = userId.toString();
      request.fields['deviceInfo'] = cihazBilgisi;
      request.fields['message'] = mesaj;

      if (resimYolu != null && resimYolu.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('image', resimYolu),
        );
      }

      var response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Ticket gönderme hatası: $e");
      return false;
    }
  }

  Future<List<dynamic>> destekTalepleriniGetir() async {
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/tickets'),
        headers: await _headers(),
      );
      _yetkiKontrolu(r.statusCode);
      if (r.statusCode == 200) {
        final decoded = jsonDecode(r.body);
        return decoded['data'] ?? [];
      }
    } catch (e) {
      debugPrint("💥 Ticket çekme hatası: $e");
    }
    return [];
  }

  Future<bool> ticketDurumGuncelle(int ticketId, String durum) async {
    try {
      final url = Uri.parse('$_baseUrl/tickets/$ticketId/status');
      final headers = await _headers();
      final body = jsonEncode({'status': durum});
      final r = await http.patch(url, headers: headers, body: body);
      return r.statusCode == 200;
    } catch (e) {
      debugPrint("💥 Durum güncelleme hatası: $e");
      return false;
    }
  }

  Future<bool> ticketSil(int ticketId) async {
    try {
      final r = await http.delete(
        Uri.parse('$_baseUrl/tickets/$ticketId'),
        headers: await _headers(),
      );
      return r.statusCode == 200;
    } catch (e) {
      debugPrint("💥 Silme hatası: $e");
      return false;
    }
  }

  Future<List<dynamic>> kartlariGetir(int id) async => [];
  Future<bool> kartSil(int id) async => true;
  Future<bool> kartEkle(int id, String a, String n) async => true;
}
