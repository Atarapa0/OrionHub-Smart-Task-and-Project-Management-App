# OrionHub - Akıllı Görev ve Proje Yönetim Uygulaması

<div align="center">
  <img src="assets/OrionHub_logo.png" alt="OrionHub Logo" width="200"/>
  
  **Modern, kullanıcı dostu ve güçlü görev yönetim çözümü**
  
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![Supabase](https://img.shields.io/badge/Supabase-181818?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
</div>

## 📸 Ekran Görüntüleri

### Ana Sayfa
<img width="326" alt="Ekran Resmi 2025-06-12 20 46 13" src="https://github.com/user-attachments/assets/34d988b7-235e-4d53-940c-b0d150ab1699" />

### Proje Yönetimi
<img width="330" alt="Ekran Resmi 2025-06-12 20 46 25" src="https://github.com/user-attachments/assets/c5434191-386a-491c-92ea-150c28a07190" />

### Bildirimler
<img width="331" alt="Ekran Resmi 2025-06-12 20 46 38" src="https://github.com/user-attachments/assets/9f6552c3-ee09-4297-82a5-e26681503fc9" />

## 🚀 Özellikler

### 📝 Kişisel Görev Yönetimi
- **Akıllı Görev Oluşturma**: Başlık, açıklama, öncelik ve kategori desteği
- **Zaman Yönetimi**: Tarih ve saat ataması ile zamanında hatırlatma
- **Öncelik Sistemi**: Acil, Yüksek, Orta, Düşük öncelik seviyeleri
- **Akıllı Filtreleme**: Öncelik, durum ve tarihe göre filtreleme
- **İlerleme Takibi**: Tamamlanan görevlerin otomatik takibi

### 🤝 Takım ve Proje Yönetimi
- **Proje Oluşturma**: Takım projeleri için özel çalışma alanları
- **Üye Yönetimi**: Email ile kullanıcı arama ve davet sistemi
- **Rol Tabanlı Erişim**: Sahip, Yönetici ve Üye rolleri
- **Görev Atama**: Proje üyelerine görev atama ve takip
- **Gerçek Zamanlı Senkronizasyon**: Anlık güncellemeler

### 🔔 Akıllı Bildirim Sistemi
- **Kategorik Bildirimler**: 4 farklı bildirim kategorisi
  - Tümü
  - Proje Bildirimleri (Görev atamaları + Proje görevleri)
  - Kişisel Görevler
  - Davetler
- **Otomatik Hatırlatmalar**: Görev son tarihi yaklaştığında uyarı
- **Proje Davetleri**: Anında kabul/red seçenekleri
- **Görev Atama Bildirimleri**: Yeni atanan görevler için bildirim

### 🎨 Modern Kullanıcı Arayüzü
- **Material Design 3**: Modern ve tutarlı tasarım
- **Gradient Temalar**: Göz alıcı renk geçişleri
- **Responsive Tasarım**: Tüm ekran boyutlarında mükemmel uyum
- **Smooth Animasyonlar**: Akıcı geçişler ve etkileşimler

## 🛠️ Teknoloji Yığını

### Frontend
- **Flutter**: Cross-platform mobil uygulama geliştirme
- **Dart**: Modern programlama dili
- **Material Design 3**: Google'ın tasarım sistemi

### Backend
- **Supabase**: Backend-as-a-Service
- **PostgreSQL**: Güçlü ilişkisel veritabanı
- **Row Level Security (RLS)**: Güvenli veri erişimi
- **Real-time Subscriptions**: Anlık güncellemeler

### Önemli Paketler
```yaml
dependencies:
  flutter: sdk
  supabase_flutter: ^2.9.0
  shared_preferences: ^2.5.3
  cupertino_icons: ^1.0.8
  hexcolor: ^3.0.1
  http: ^1.4.0
  crypto: ^3.0.3
```

## 📱 Platform Desteği

- ✅ **iOS**: iPhone ve iPad
- ✅ **Android**: Tüm Android cihazlar
- ✅ **Web**: Modern web tarayıcılar
- ✅ **Windows**: Windows 10/11 masaüstü

## 🗄️ Veritabanı Yapısı

### Ana Tablolar
- `user_profiles`: Kullanıcı profil bilgileri
- `tasks`: Kişisel görevler
- `projects`: Proje bilgileri
- `project_members`: Proje üyelikleri
- `project_tasks`: Proje görevleri
- `project_invitations`: Proje davetleri
- `notifications`: Bildirim sistemi

### Güvenlik
- **Row Level Security (RLS)**: Her tablo için özel güvenlik kuralları
- **Email tabanlı kimlik doğrulama**: Güvenli giriş sistemi
- **Rol tabanlı erişim kontrolü**: Proje bazında yetki yönetimi

## 🚀 Kurulum

### Önkoşullar
- Flutter SDK (3.8.0+)
- Dart SDK
- Android Studio / VS Code
- Git

### Adımlar

1. **Projeyi klonlayın**
```bash
git clone https://github.com/kullaniciadi/orionhub.git
cd orionhub
```

2. **Bağımlılıkları yükleyin**
```bash
flutter pub get
```

3. **Supabase konfigürasyonu**
```bash
# Örnek config dosyasını kopyalayın
cp lib/core/config/supabase_config.example.dart lib/core/config/supabase_config.dart

# Supabase bilgilerinizi ekleyin (detaylar aşağıda)
```

4. **Uygulamayı çalıştırın**
```bash
flutter run
```

## ⚙️ Konfigürasyon

### Supabase Kurulumu
1. [Supabase](https://supabase.com) hesabı oluşturun
2. Yeni proje oluşturun
3. Settings > API kısmından Project URL ve Anon Key'i kopyalayın
4. `lib/core/config/supabase_config.dart` dosyasını oluşturun:
   ```bash
   cp lib/core/config/supabase_config.example.dart lib/core/config/supabase_config.dart
   ```
5. Gerçek Supabase bilgilerinizi dosyaya ekleyin

### Veritabanı Kurulumu
SQL dosyalarını Supabase SQL Editor'de çalıştırın:
1. Temel tablo yapıları
2. RLS politikaları
3. Trigger'lar ve fonksiyonlar

## 👥 Kullanım

### İlk Başlangıç
1. **Kayıt Olun**: Email ve şifre ile hesap oluşturun
2. **Profil Tamamlayın**: Ad, soyad bilgilerinizi ekleyin
3. **İlk Görevi Oluşturun**: + butonuna tıklayarak başlayın

### Proje Yönetimi
1. **Proje Oluşturun**: "Yeni Proje Oluştur" butonunu kullanın
2. **Üye Ekleyin**: Email ile kullanıcıları arayın ve davet edin
3. **Görev Atayın**: Proje görevlerini üyelere atayın
4. **İlerlemeyi Takip Edin**: İstatistikler sekmesinden kontrol edin

### Bildirimler
- **Bildirimler**: Sağ üst köşedeki zil ikonundan erişin
- **Kategoriler**: 4 farklı kategori ile organize bildirimler
- **Hızlı İşlemler**: Davetleri doğrudan kabul/red edin

## 🔐 Güvenlik

- **Veri Şifreleme**: Tüm veriler şifreli olarak saklanır
- **Güvenli API**: HTTPS ile korumalı veri iletişimi
- **Kullanıcı İzolasyonu**: Her kullanıcı sadece kendi verilerine erişir
- **Rol Tabanlı Erişim**: Proje bazında yetki kontrolü

## 🤝 Katkıda Bulunma

1. Bu repository'yi fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Branch'inizi push edin (`git push origin feature/AmazingFeature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 📞 İletişim

**Proje Sahibi**: [Furkan Erdoğan]
- Email: [furkaan.er@gmail.com]
- LinkedIn: [https://www.linkedin.com/in/furkan-erdogan/]

**Proje Linki**: [https://github.com/Atarapa0/orionhub](https://github.com/Atarapa0/orionhub)

## 🙏 Teşekkürler

- [Flutter Team](https://flutter.dev/community) - Harika framework için
- [Supabase](https://supabase.com) - Backend altyapısı için
- [Material Design](https://material.io) - Tasarım sistemi için

---

<div align="center">
  <b>OrionHub ile görevlerinizi organize edin, projelerinizi yönetin! 🚀</b>
</div>
