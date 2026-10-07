<div align="center">

# 📒 Hata Defteri

**Sınava hazırlanan öğrenciler için kişisel, istatistiksel yanlış soru analizi ve akıllı tekrar defteri.**

Yanlışlarını kaydet, aralıklı tekrar ile unutma, Genel Kültür Akademisi ile kendini sına — tamamen **offline**.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.8-0175C2?logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/State-Riverpod-00B4AB)
![Hive](https://img.shields.io/badge/DB-Hive-FFB300)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20macOS-lightgrey)
![Offline](https://img.shields.io/badge/100%25-Offline-success)

</div>

---

## ✨ Özellikler

### 📝 Hata Defteri
- Yanlış yaptığın soruları **fotoğrafıyla birlikte** kaydet (kamera / galeri)
- Ders, konu, zorluk (Kolay / Orta / Zor) ve **hata nedeni** etiketleme
  - Dikkat Hatası · Bilgi Eksikliği · İşlem Hatası · Yanlış Okuma · Süre Yetmedi · Diğer
- Soru görsellerini yakınlaştırarak inceleme
- Hataları düzenleme, silme ve paylaşma

### 🔁 Aralıklı Tekrar (Spaced Repetition)
- Her hata **1 → 3 → 7 → 15 → 30 gün** aralıklarıyla otomatik olarak tekrara düşer
- "Bugünün Tekrarları" ekranında *Doğru Çözdüm / Yanlış Çözdüm* ile ilerleme
- Günlük **hatırlatıcı bildirimler** (saat ayarlanabilir)
- 🔥 Günlük çalışma serisi (streak) takibi

### 🎓 Genel Kültür Akademisi
- **900+** Tarih, Coğrafya ve Vatandaşlık sorusu içeren soru bankası
- Günün soruları, konu bazlı test, serbest pratik testi
- **Hata Denemesi:** geçmişte yanlış yaptığın sorulardan özel deneme oluştur
- **Hap bilgi kartları (flashcard)** — sesli okuma (TTS) desteğiyle, kendi kartlarını ekleyebilme
- Ders notları görüntüleyici (Tarih · Coğrafya · Vatandaşlık)
- Konu takip ekranı ve akıllı **çalışma asistanı** önerileri
- ⏱️ Çalışma zamanlayıcısı ve çalışma süresi grafikleri

### 📊 Gelişim ve İstatistik
- En çok yanlış yapılan ders ve konular
- Hata nedenlerine göre dağılım grafikleri (`fl_chart`)
- Kişiselleştirilmiş gelişim önerileri

### ⚙️ Ayarlar
- 🌙 Açık / Koyu tema
- 💾 Verileri **JSON olarak dışa / içe aktarma** (yedekleme)
- Tüm verileri sıfırlama

---

## 🏗️ Mimari

Proje, **feature-first** klasör yapısı ve katmanlı (data / domain / presentation) mimari ile geliştirilmiştir.

```
lib/
├── core/
│   ├── constants/      # Sabitler, renkler, çeviriler
│   ├── providers/      # Repository provider'ları
│   ├── router/         # go_router yapılandırması
│   ├── services/       # Hive, dosya ve bildirim servisleri
│   └── theme/          # Açık / koyu tema
├── features/
│   ├── dashboard/      # Ana pano
│   ├── mistakes/       # Hata ekleme, listeleme, detay
│   ├── review/         # Aralıklı tekrar ekranı
│   ├── academy/        # Genel Kültür Akademisi (quiz, not, flashcard)
│   ├── lessons/        # Ders yönetimi
│   ├── statistics/     # Grafikler ve analizler
│   └── settings/       # Ayarlar, yedekleme
└── main.dart

assets/
├── questions/          # Soru bankası ve flashcard JSON'ları
└── notes/              # Ders notu sayfaları (tarih, cografya, vatandaslik)
```

### 🧰 Teknolojiler

| Alan | Paket |
|---|---|
| State Management | [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) |
| Navigasyon | [`go_router`](https://pub.dev/packages/go_router) |
| Yerel Veritabanı | [`hive`](https://pub.dev/packages/hive) + [`hive_flutter`](https://pub.dev/packages/hive_flutter) |
| Grafikler | [`fl_chart`](https://pub.dev/packages/fl_chart) |
| Bildirimler | [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) |
| Görsel Seçimi | [`image_picker`](https://pub.dev/packages/image_picker) |
| Sesli Okuma | [`flutter_tts`](https://pub.dev/packages/flutter_tts) |
| Yedekleme / Paylaşım | [`file_picker`](https://pub.dev/packages/file_picker), [`share_plus`](https://pub.dev/packages/share_plus) |
| Tipografi | [`google_fonts`](https://pub.dev/packages/google_fonts) |

---

## 🚀 Kurulum

### Gereksinimler
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.8.1`)
- Android Studio / Xcode

### Adımlar

```bash
# Repoyu klonla
git clone git@github.com:mteysr/Hata_defteri.git
cd Hata_defteri

# Bağımlılıkları yükle
flutter pub get

# (Opsiyonel) Hive adapter'larını yeniden üret
dart run build_runner build --delete-conflicting-outputs

# Uygulamayı çalıştır
flutter run
```

### Release Build

```bash
flutter build apk --release      # Android
flutter build ios --release      # iOS
```

---

## 🔒 Gizlilik

Hata Defteri **tamamen offline** çalışır. Tüm verilerin (hatalar, fotoğraflar, istatistikler) yalnızca cihazında, Hive veritabanında saklanır. Hiçbir veri sunucuya gönderilmez.

---

## 🤝 Katkı

1. Repoyu fork'la
2. Yeni bir branch oluştur: `git checkout -b feature/yeni-ozellik`
3. Değişikliklerini commit'le: `git commit -m "feat: yeni özellik"`
4. Branch'ini push'la: `git push origin feature/yeni-ozellik`
5. Pull Request aç 🎉

---

<div align="center">

Geliştiren: **[@mteysr](https://github.com/mteysr)**

⭐ Projeyi beğendiysen yıldız vermeyi unutma!

</div>
