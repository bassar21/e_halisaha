import 'package:flutter/material.dart';
import '../../cekirdek/servisler/api_servisi.dart';

class DestekTalepleriEkrani extends StatefulWidget {
  const DestekTalepleriEkrani({super.key});

  @override
  State<DestekTalepleriEkrani> createState() => _DestekTalepleriEkraniState();
}

class _DestekTalepleriEkraniState extends State<DestekTalepleriEkrani> {
  final ApiServisi _apiServisi = ApiServisi();
  List<dynamic> _talepler = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _talepleriGetir();
  }

  Future<void> _talepleriGetir() async {
    if (!mounted) return;
    setState(() => _yukleniyor = true);
    final liste = await _apiServisi.destekTalepleriniGetir();
    if (mounted) {
      setState(() {
        _talepler = liste;
        _yukleniyor = false;
      });
    }
  }

  Future<void> _durumDegistir(int id, String yeniDurum) async {
    bool basarili = await _apiServisi.ticketDurumGuncelle(id, yeniDurum);
    if (basarili && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(yeniDurum == 'closed' ? "İşlem Gördü olarak işaretlendi!" : "Bekliyor olarak işaretlendi!"), 
          backgroundColor: yeniDurum == 'closed' ? Colors.green : Colors.orange
        ),
      );
      _talepleriGetir();
    }
  }

  void _silmeOnayiGoster(int id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        title: Text("Talebi Sil", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text("Bu destek talebini kalıcı olarak silmek istediğinize emin misiniz?", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              bool basarili = await _apiServisi.ticketSil(id);
              if (basarili && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Talep silindi."), backgroundColor: Colors.red));
                _talepleriGetir();
              }
            },
            child: const Text("SİL", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resmiGoster(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Image.network("http://185.157.46.167:3000/$url", fit: BoxFit.contain),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Destek Talepleri", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : const Color(0xFF111827),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
          : RefreshIndicator(
              onRefresh: _talepleriGetir,
              color: const Color(0xFF16A34A),
              child: _talepler.isEmpty
                  ? Center(child: Text("Henüz hiç destek talebi yok.", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _talepler.length,
                      itemBuilder: (context, index) {
                        final t = _talepler[index];
                        final int id = t['id'];
                        final String ad = t['full_name'] ?? 'Bilinmeyen Kullanıcı';
                        final String mesaj = t['message'] ?? '';
                        final String cihaz = t['device_info'] ?? 'Bilinmiyor';
                        final String? resimUrl = t['image_url'];
                        final String status = t['status'] ?? 'open';
                        
                        final bool isClosed = status == 'closed';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isClosed ? Colors.green.withValues(alpha: 0.5) : Colors.transparent, width: 1.5),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 10)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isClosed ? Colors.green.withValues(alpha: 0.1) : const Color(0xFF16A34A).withValues(alpha: 0.1),
                                      child: Icon(isClosed ? Icons.check_circle : Icons.person, color: isClosed ? Colors.green : const Color(0xFF16A34A)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(ad, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                                          Text(cihaz, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                    if (resimUrl != null)
                                      IconButton(
                                        icon: const Icon(Icons.image, color: Colors.blue),
                                        onPressed: () => _resmiGoster(resimUrl),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(mesaj, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                              ),
                              const Divider(height: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black12 : Colors.grey[50],
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // DURUM ROZETİ
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isClosed ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isClosed ? Colors.green : Colors.orange),
                                      ),
                                      child: Text(
                                        isClosed ? "İşlem Gördü" : "Bekliyor",
                                        style: TextStyle(color: isClosed ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        // DURUM DEĞİŞTİRME BUTONU
                                        TextButton.icon(
                                          onPressed: () => _durumDegistir(id, isClosed ? 'open' : 'closed'),
                                          icon: Icon(isClosed ? Icons.refresh : Icons.check, size: 18, color: isClosed ? Colors.orange : Colors.green),
                                          label: Text(isClosed ? "Geri Al" : "Çözüldü", style: TextStyle(color: isClosed ? Colors.orange : Colors.green)),
                                        ),
                                        // SİLME BUTONU
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => _silmeOnayiGoster(id),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}