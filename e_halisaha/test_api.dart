import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

void main() async {
  debugPrint("--- API TEST (LOGIN & GET USERS) ---");
  const String baseUrl = "http://185.157.46.167:3000/api";

  try {
    // 1. Giriş Yap
    final loginRes = await http
        .post(
          Uri.parse("$baseUrl/auth/login"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": "ahmet.ozkurkcu@ademceylantk.com.tr",
            "password":
                "password123", // Varsayılan test için, hata verecekse bile görelim
          }),
        )
        .timeout(const Duration(seconds: 10));

    debugPrint("LOGIN Status: ${loginRes.statusCode}");
    // debugPrint("LOGIN Body: ${loginRes.body}");

    if (loginRes.statusCode == 200) {
      final data = jsonDecode(loginRes.body);
      final token = data['token'];
      debugPrint("Token alındı.");

      // 2. Kullanıcıları Çek
      final usersRes = await http.get(
        Uri.parse("$baseUrl/users"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      debugPrint("GET USERS Status: ${usersRes.statusCode}");
      debugPrint("GET USERS Body: ${usersRes.body}");
    }
  } catch (e) {
    debugPrint("HATA: $e");
  }
}
