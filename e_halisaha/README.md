# E-Halısaha

E-Halısaha, futbolseverlerin kolayca halı saha bulmasını, rezervasyon yapmasını ve kendilerine rakip veya takım arkadaşı bulmasını sağlayan kapsamlı bir Flutter mobil uygulamasıdır. Kullanıcıların yanı sıra işletmeler (halı saha sahipleri) ve sistem yöneticileri (admin) için de özel paneller barındırır.

## 🚀 Özellikler

- **Gelişmiş Profil ve Kimlik Yönetimi:** Güvenli giriş/kayıt sistemi ve detaylı profil ekranı (`giris`, `profil`).
- **Harita Desteği:** Konum tabanlı (`geolocator`, `latlong2`) harita `flutter_map` üzerinden erişilebilir halı sahaları görüntüleme (`harita`).
- **Saha Keşfi ve Rezervasyon:** Seçilen sahanın özelliklerini inceleme, saat seçimi ve ödeme adımlarıyla hızlı rezervasyon (`saha_detay`, `odeme`, `anasayfa`).
- **Rakip Bul (Matchmaking):** Kendi takımınıza uygun rakipler veya eksik oyuncu arama özelliği (`rakip_bul`).
- **İşletme ve Yöneticiler İçin Özel Paneller:** Saha sahiplerinin kendi sahalarını ve rezervasyonlarını yönetebileceği özellikler (`isletme`, `admin`).
- **Dinamik Tema Desteği:** Karanlık ve Aydınlık (Dark/Light) mod desteği.
- **Çoklu Platform Uyumluluğu:** Mobil cihazlar (Android/iOS) ve Web ortamı için hazır mimari.

## 🛠️ Kullanılan Teknolojiler ve Paketler

- **Framework:** Flutter (Material 3 Kullanımı)
- **Harita ve Konum:** `flutter_map`, `latlong2`, `geolocator`
- **Ağ İstekleri:** `http`
- **Veri Depolama:** `shared_preferences`, `flutter_secure_storage`
- **Medya Yönetimi:** `image_picker`, `video_player`
- **UX & Araçlar:** `cupertino_icons`, `mask_text_input_formatter`, `intl`, `device_info_plus`

## 📂 Proje Yapısı (lib/)

- `bilesenler/`: Tekrar kullanılabilir (reusable) özel widgetlar ve UI elemanları.
- `cekirdek/`: Servisler, ağ istekleri, temalar ve iş mantığı (business logic) sınıfları.
- `ekranlar/`: Kullanıcı arayüzünü oluşturan sayfalar (`anasayfa`, `admin`, `harita`, `rakip_bul`, vb.).
- `modeller/`: Veri modelleri (`saha_modeli.dart`, `oyuncu_modeli.dart`, `takim_modeli.dart`).

## ⚙️ Kurulum ve Çalıştırma

1. Projeyi bilgisayarınıza klonlayın:
   ```bash
   git clone <repo-url>
   ```

2. Proje dizinine gidin ve bağımlılıkları yükleyin:
   ```bash
   cd e_halisaha
   flutter pub get
   ```

3. Uygulamayı bağlı bir cihaza veya emülatöre yükleyin:
   ```bash
   flutter run
   ```

*(Android veya iOS cihazlar için gerekli platform kurulumlarını [Flutter Resmi Dokümantasyonu](https://docs.flutter.dev/get-started/install)'ndan takip edebilirsiniz.)*
