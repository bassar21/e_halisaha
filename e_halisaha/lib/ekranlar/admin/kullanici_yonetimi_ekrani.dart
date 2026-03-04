import 'package:flutter/material.dart';
import '../../cekirdek/servisler/api_servisi.dart';

class KullaniciYonetimiEkrani extends StatefulWidget {
  const KullaniciYonetimiEkrani({super.key});

  @override
  State<KullaniciYonetimiEkrani> createState() =>
      _KullaniciYonetimiEkraniState();
}

class _KullaniciYonetimiEkraniState extends State<KullaniciYonetimiEkrani> {
  final ApiServisi _apiServisi = ApiServisi();
  final TextEditingController _aramaController = TextEditingController();

  List<dynamic> _tumKullanicilar = [];
  List<dynamic> _filtrelenmisKullanicilar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final veriler = await _apiServisi.tumKullanicilariGetir();
    if (mounted) {
      setState(() {
        _tumKullanicilar = veriler;
        _filtrelenmisKullanicilar = veriler;
        _yukleniyor = false;
      });
    }
  }

  void _kullanicilariFiltrele(String sorgu) {
    setState(() {
      _filtrelenmisKullanicilar = _tumKullanicilar.where((k) {
        final ad = (k['fullName'] ?? k['full_name'] ?? k['name'] ?? "")
            .toString()
            .toLowerCase();
        final email = (k['email'] ?? "").toString().toLowerCase();
        final tel = (k['phoneNumber'] ?? k['phone_number'] ?? k['phone'] ?? "")
            .toString()
            .toLowerCase();
        final rol = (k['role'] ?? "").toString().toLowerCase();
        final s = sorgu.toLowerCase();

        return ad.contains(s) ||
            email.contains(s) ||
            tel.contains(s) ||
            rol.contains(s);
      }).toList();
    });
  }

  // --- ROL DÜZENLEME (HIZLI SEÇİM) ---
  void _rolDuzenle(dynamic kullanici) async {
    String mevcutRol = (kullanici['role'] ?? "oyuncu").toString().toLowerCase();
    int kullaniciId = kullanici['id'];

    // Normalize role for initial selection
    String baslangicRolu = 'oyuncu';
    if (mevcutRol == 'admin')
      baslangicRolu = 'admin';
    else if (mevcutRol == 'isletme' || mevcutRol == 'sahasahibi')
      baslangicRolu = 'isletme';
    else
      baslangicRolu = 'oyuncu';

    String secilenRol = baslangicRolu;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
              title: Text(
                "${kullanici['fullName'] ?? 'Kullanıcı'} - Rol Düzenle",
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lütfen atamak istediğiniz rolü seçin:",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: secilenRol,
                    dropdownColor: isDark
                        ? const Color(0xFF374151)
                        : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.security,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'oyuncu',
                        child: Text("Oyuncu / Müşteri"),
                      ),
                      DropdownMenuItem(
                        value: 'isletme',
                        child: Text("İşletme / Saha Sahibi"),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text("Admin / Yönetici"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          secilenRol = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    "İptal",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Güncelleniyor..."),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    final sonuc = await _apiServisi.kullaniciRoluGuncelle(
                      kullaniciId,
                      secilenRol,
                    );

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          sonuc
                              ? "Rol başarıyla '${secilenRol.toUpperCase()}' yapıldı!"
                              : "Rol güncellenirken bir hata oluştu.",
                        ),
                        backgroundColor: sonuc ? Colors.green : Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );

                    if (sonuc) {
                      _verileriYukle();
                    }
                  },
                  child: const Text(
                    "Kaydet",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Kullanıcı Yönetimi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _aramaController,
                onChanged: _kullanicilariFiltrele,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: "İsim, Email, Tel veya Rol ara...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF16A34A),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          Expanded(
            child: _yukleniyor
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                  )
                : _filtrelenmisKullanicilar.isEmpty
                ? Center(
                    child: Text(
                      "Kullanıcı bulunamadı.",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtrelenmisKullanicilar.length,
                    itemBuilder: (context, index) {
                      return _kullaniciKarti(
                        _filtrelenmisKullanicilar[index],
                        isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _kullaniciKarti(dynamic k, bool isDark) {
    String rol = (k['role'] ?? 'Yok').toString();
    String rolKucuk = rol.toLowerCase();

    Color rolRengi = Colors.grey;
    Color rolArkaPlan = Colors.grey.withValues(alpha: isDark ? 0.2 : 0.1);

    if (rolKucuk == 'admin') {
      rolRengi = Colors.red;
      rolArkaPlan = Colors.red.withValues(alpha: isDark ? 0.2 : 0.1);
    } else if (rolKucuk == 'isletme' || rolKucuk == 'sahasahibi') {
      rolRengi = Colors.orange;
      rolArkaPlan = Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1);
    } else if (rolKucuk == 'oyuncu' ||
        rolKucuk == 'user' ||
        rolKucuk == 'customer') {
      rolRengi = Colors.blue;
      rolArkaPlan = Colors.blue.withValues(alpha: isDark ? 0.2 : 0.1);
    }

    String fullName =
        (k['fullName'] ?? k['full_name'] ?? k['name'] ?? "İsimsiz").toString();
    String firstLetter = fullName.isNotEmpty ? fullName[0].toUpperCase() : "?";
    String phone =
        (k['phoneNumber'] ?? k['phone_number'] ?? k['phone'] ?? "Telefon Yok")
            .toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 5,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
          child: Text(
            firstLetter,
            style: const TextStyle(
              color: Color(0xFF16A34A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          fullName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "${k['email']}",
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.black54,
              ),
            ),
            Text(
              phone,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: rolArkaPlan,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: rolRengi.withValues(alpha: 0.3)),
              ),
              child: Text(
                rol.toUpperCase(),
                style: TextStyle(
                  color: rolRengi,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.edit_note, color: Color(0xFF16A34A), size: 28),
          onPressed: () => _rolDuzenle(k),
        ),
        onTap: () => _rolDuzenle(k),
      ),
    );
  }
}
