Karşınızda 24 saatte 4 kişilik ekiple geliştirilen ve Hackathon da 10 proje içinden 3. seçilen projemiz.

CanBağı: Deprem Öncesi Kritik İletişim Protokolü 🛡️📍
"Deprem sarsıntısı ulaşmadan önceki 15 saniye, hayat kurtarmak için en büyük şansımızdır."

Türkiye gibi deprem riski yüksek bölgelerde, sarsıntıdan hemen sonra oluşan şebeke yoğunluğu (Network Congestion) nedeniyle "İletişim Körlüğü" yaşanmaktadır. OnBeş, şebekelerin çökmesini beklemez; şebeke henüz aktifken deprem erken uyarı sinyalini kullanarak kritik konum verilerini sevdiklerinize ulaştırır.

🚀 Proje Hakkında
Deprem dalgaları (P ve S dalgaları) arasındaki hız farkını kullanan OnBeş, Android Deprem Uyarıları Sistemi'nden gelen bildirimi bir otonom tetikleyici olarak kullanır.

Temel Problem
Deprem sonrası ilk 20 dakikada operatörlerin kapasiteyi korumak adına hatları kapatması veya aşırı yükten dolayı sistemin çökmesi, enkaz altındakilere veya yakınlarına ulaşmayı imkansız kılar.

Çözümümüz: "Altın Pencere" Protokolü
Sarsıntı bölgeye ulaşmadan önceki 10-20 saniyelik sürede, cihaz henüz internete bağlıyken ultra hafif (1-2 KB) bir konum paketini aile üyelerine gönderir ve alıcı cihazın yerel hafızasına mühürler. İnternet kopsa dahi haritadaki son konum silinmez.

✨ Özellikler
Otonom Aktivasyon: Sarsıntı bildirimi geldiği anda kullanıcı müdahalesi gerektirmeden arka planda uyanma.

Ultra Düşük Gecikme (Low-Latency): Firebase Realtime Database (WebSocket) ile milisaniyeler içinde veri senkronizasyonu.

Çevrimdışı Kalıcılık (Offline Caching): Şebeke tamamen kesilse bile sevdiklerinizin "Son Bilinen Konumu" cihazda kayıtlı kalır.

Minimal Veri Tüketimi: 2G/Edge hızında bile çalışabilen optimize edilmiş veri paketi mimarisi.

Gizlilik Odaklı: Konum verileri sadece acil durum anında ve sadece seçilen "Güvenlik Ağı" üyeleriyle paylaşılır.

🛠️ Teknik Altyapı
Framework: Flutter (Cross-platform performans için)

Backend: Firebase Realtime Database (Anlık veri akışı için)

Yerel Depolama: shared_preferences (Offline veri kalıcılığı için)

Konum Servisleri: geolocator (Yüksek hassasiyetli GPS takibi)

Mimari: Clean Architecture prensiplerine uygun, modüler ve sürdürülebilir kod yapısı.

📂 Dosya Yapısı
Plaintext
lib/
├── core/           # Sabitler, temalar ve genel yardımcı sınıflar
├── data/           # Firebase ve Local storage servisleri
├── models/         # User ve Location modelleri
├── logic/          # Tetikleme mekanizması ve konum hesaplama
└── screens/        # Harita ve ayarlar arayüzü
🏗️ Kurulum
Bu repoyu klonlayın:

Bash
git clone https://github.com/kullaniciadi/onbes.git
Gerekli paketleri indirin:

Bash
flutter pub get
Firebase projenizi oluşturun ve google-services.json (Android) veya GoogleService-Info.plist (iOS) dosyalarını ilgili dizinlere ekleyin.

Uygulamayı çalıştırın:

Bash
flutter run
🗺️ Gelecek Planı (Roadmap)
[ ] AI Tahliye Rehberi: Bina yoğunluğu ve toplanma alanlarına göre en güvenli rotayı çizme.

[ ] SMS Fallback: İnternet yoksa koordinatları otomatik SMS ile iletme.

[ ] Giyilebilir Entegrasyon: Akıllı saatlerden nabız ve hareket verisi çekme.

[ ] Onboarding: Uygulamayı indirmeyen aile üyeleri için otomatik davet sistemi.

🤝 Katkıda Bulunma
Bu proje bir sosyal sorumluluk ve yazılım mühendisliği girişimidir. Geliştirmelere katkı sağlamak isterseniz lütfen bir "Pull Request" gönderin veya bir "Issue" açın.
