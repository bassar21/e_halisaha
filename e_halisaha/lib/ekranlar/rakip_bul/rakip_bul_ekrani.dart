import 'package:flutter/material.dart';
import '../../modeller/takim_modeli.dart';

class RakipBulEkrani extends StatefulWidget {
  const RakipBulEkrani({super.key});

  @override
  State<RakipBulEkrani> createState() => _RakipBulEkraniState();
}

class _RakipBulEkraniState extends State<RakipBulEkrani> {
  // Varsayılan Takımlar
  final List<TakimModeli> takimlar = [
    TakimModeli(
      id: "1",
      isim: "Yıldırım Spor",
      seviye: "Dişli",
      yildiz: 4.5,
      kaptanId: "101",
    ),
    TakimModeli(
      id: "2",
      isim: "Kuzey Gücü",
      seviye: "Amatör",
      yildiz: 3.0,
      kaptanId: "102",
    ),
    TakimModeli(
      id: "3",
      isim: "Atalanta FC",
      seviye: "Pro",
      yildiz: 5.0,
      kaptanId: "103",
    ),
  ];

  // Yeni takım ekleme penceresi
  void _takimEkleDialog() {
    TextEditingController isimController = TextEditingController();
    String secilenSeviye = "Amatör";
    double seviyePuani = 3.0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Takımını Oluştur"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: isimController,
                    decoration: const InputDecoration(
                      labelText: "Takım Adı",
                      icon: Icon(Icons.group),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: secilenSeviye,
                    items: ["Amatör", "Orta", "Dişli", "Pro"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) =>
                        setStateDialog(() => secilenSeviye = val!),
                    decoration: const InputDecoration(labelText: "Seviye"),
                  ),
                  const SizedBox(height: 15),
                  const Text("Takım Gücü (Yıldız)"),
                  Slider(
                    value: seviyePuani,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: seviyePuani.toString(),
                    activeColor: const Color(0xFF22C55E),
                    onChanged: (val) => setStateDialog(() => seviyePuani = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                  ),
                  onPressed: () {
                    if (isimController.text.isNotEmpty) {
                      setState(() {
                        takimlar.add(
                          TakimModeli(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            isim: isimController.text,
                            seviye: secilenSeviye,
                            yildiz: seviyePuani,
                            kaptanId: "999",
                          ),
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "OLUŞTUR",
                    style: TextStyle(color: Colors.white),
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
    bool koyuMod = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Rakip Bul"), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _takimEkleDialog,
        backgroundColor: const Color(0xFF22C55E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Takım Ekle", style: TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: takimlar.length,
        itemBuilder: (context, index) {
          final takim = takimlar[index];
          return Card(
            color: koyuMod ? Colors.grey[800] : Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Text(
                  takim.isim[0],
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                takim.isim,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: koyuMod ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                "Seviye: ${takim.seviye} | ⭐ ${takim.yildiz}",
                style: TextStyle(
                  color: koyuMod ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "${takim.isim} takımına maç isteği gönderildi!",
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Maç Yap",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
