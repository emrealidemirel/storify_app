# Yayın hazırlığının durumu

Son durum: 26 Ekim 2026. Bu belge, 24 Ekim denetiminden sonra yapılan düzeltmeleri ve henüz tamamlanmamış yayın adımlarını kaydeder.

## Tamamlanan kod değişiklikleri

- Android compile/target SDK 36, AGP 8.11.1, Gradle 8.13, Kotlin 2.1.20 ve NDK 28.2 yapılandırıldı. Release artık debug anahtarı kullanmıyor. `android/key.properties` yoksa doğrulama paketi imzasız üretiliyor; örnek yapılandırma `android/key.properties.example` içinde.
- Kullanılmayan `StoryModel`, `ThemeButton`, preferences metotları ve bazı doğrudan bağımlılıklar temizlendi. `contants` klasörü `constants` olarak düzeltildi. Font dosyaları ve eski hikâye kaydı uyumluluğu korundu. Geliştirme araçları dev dependencies altına taşındı.
- Şifreler `.trim()` ile değiştirilmeden gönderiliyor. Profil güncelleme işlemi AuthRepository/Cubit üzerinden yürütülüyor.
- Hesap silmede önce yeniden kimlik doğrulaması, sonra profil fotoğrafı/bildirim dosyalarının temizliği, yerel verilerin temizliği ve Auth hesabının silinmesi var. Dosya temizliği başarısızsa Auth hesabı silinmiyor; işlem yeniden denenebiliyor. Bu servisler arasında bir veritabanı transaction'ı değildir: sonraki adım başarısız olduğunda önceki temizlik geri alınamaz.
- Fotoğraflarda istemci tarafında dosya imzası ve 5 MB sınırı, seçicide 2048 piksel boyut sınırı eklendi. Storage kuralları kullanıcı sahipliği, MIME türü ve boyutu denetliyor. MIME kontrolü tek başına sunucuda görüntü çözümleme değildir.
- Apple girişi, iOS entitlement ve Apple hesabı silinirken yeniden doğrulama/token iptali kodu eklendi. E-posta doğrulama bağlantısı gönderme ayarlarda mevcut.
- TR/EN gizlilik açıklaması, hesap bazlı AI paylaşım izni ve izin geri çekme akışı eklendi. Gerçek yayıncı/destek/web bilgileri sağlanmadığı için dış bağlantılar gösterilmiyor.
- Hikâye ekranına uygulamadan çıkmadan içerik bildirme eklendi. Başarılı dosya yüklemesi sonrasında başarı gösteriliyor; hata halinde tekrar denenebiliyor.
- Üretilen metin ve şıklar OpenAI moderasyon kontrolünden geçiyor; uygunsuz veya kontrol edilemeyen içerik kullanıcıya döndürülmüyor. Bu kontrol de AI çağrısıyla birlikte yayın öncesinde sunucuya taşınmalı.
- AI oturumuna 30 bölüm sınırı ve final bölümü talimatı eklendi; tamamlanan hikâye tekrar açılabiliyor. Misafir hikâyelerinin 5 devam akışı korundu.
- Hesap geçişlerinde bellek içindeki hikâye ve devam eden isteğin sonuçları geçersiz kılınıyor. Normal çıkışta aynı hesabın devam edebilmesi için yerel kayıt korunuyor.
- Başlangıç hataları için yeniden deneme ekranı, iOS privacy manifesti ve yeni güvenlik testleri eklendi.

## Doğrulama sonuçları

| Kontrol | Sonuç |
| --- | --- |
| Flutter testleri | 72 geçti |
| Flutter analyze | Sorun bulunmadı |
| Storage kuralları, yerel demo emülatörü | 18 kontrol geçti |
| Android release AAB | Başarılı, imzasız |
| iOS release cihaz derlemesi | Başarılı, codesign kapalı |
| JS kural testi bağımlılıkları `npm audit` | 0 açık (bu test araçlarıyla sınırlı) |

Storage testleri kullanıcılar arası erişimi, oturumsuz erişimi, fotoğraf/bildirim boyutlarını, yanlış MIME türünü, bildirim üzerine yazmayı ve hesap sahibinin silebilmesini kapsar. Gerçek Firebase projesinin kuralları bu çalışmada değiştirilmedi.

Komutlar:

```sh
flutter pub get
flutter analyze
flutter test
cd tool/firebase_tests
npm ci
npm test
```

Kural testleri Node ve Firebase CLI gerektirir; yalnızca `demo-storify` yerel emülatörünü kullanır. Test paketindeki gRPC override'ı, transitif eski sürümün güvenlik açığını gidermek içindir.

## Yayın zamanına açıkça ertelenenler

Kullanıcının isteğiyle API anahtarı/backend geçişi ve yayıncı/destek/gizlilik/silme web bilgileri henüz yapılmadı. Bu nedenle mevcut paketler mağazaya gönderilmemeli veya genel dağıtıma açılmamalı.

1. AI ve moderasyon çağrılarını Firebase ID token doğrulayan sunucuya taşı. Kullanıcı kotası, rate limit, maliyet sınırı ve varsa premium yetkilerini sunucuda uygula. `.env` assetini kaldır; dağıtılmış geliştirme anahtarını yenile. Şu an anahtar hâlâ mobil pakettedir.
2. Yayıncı adı, destek e-postası, gerçek HTTPS gizlilik ve hesap silme sayfalarını belirle. `lib/constants/release_config.dart` bunları `PUBLISHER_NAME`, `SUPPORT_EMAIL`, `PRIVACY_URL`, `ACCOUNT_DELETION_URL` dart define değerlerinden alır. Gizli anahtarları dart define içine koyma. Uygulamadaki açıklama, yayımlanmış ve gerçek işletme/veri saklama bilgilerini içeren gizlilik politikasının yerine geçmez.
3. Kalıcı uygulama kimliklerini ve yayın imzalarını kararlaştır. Mevcut `com.example` kimlikleri Firebase girişini bozmamak için değiştirilmedi. Kimlik değişirse Firebase/OAuth kayıtları ve release SHA parmak izleri birlikte güncellenmeli.
4. Apple Developer'da Sign in with Apple capability ve Firebase'de Apple sağlayıcısını yapılandır. Kodun derlenmesi gerçek Apple girişinin çalıştığını kanıtlamaz.
5. Mevcut canlı Storage kurallarını yedekleyip karşılaştır; test edilen `storage.rules` dosyasını doğru Firebase projesine uygula. Profil yükleme, bildirim ve silmeyi gerçek hesaplarla doğrula. Yerel kurallar henüz sunucuya uygulanmadı.
6. Bildirim inceleme sürecini işlet: dosyalar `users/{uid}/reports/{id}.json` altında oluşur ve Firebase Console'dan yetkili geliştirici tarafından incelenebilir. Otomatik bildirim e-postası veya yönetim paneli eklenmedi. Kullanıcıların bildirimlerine düzenli bakılmalı; sonuçlar içerik filtrelerine yansıtılmalı. Hesap silinince ilişkili raporlar da silinir.
7. App Privacy/Data Safety, yaş derecelendirmesi, SDK veri envanteri, izin metinleri ve politika sayfalarını nihai veri akışıyla eşleştir. Manifest son imzalı archive içinde kontrol edilmeli. Reklam/analitik eklenirse bu envanter yeniden değerlendirilmeli.
8. Gerçek iPhone ve Android'de Google/Apple/e-posta giriş, fotoğraf izinleri, ağ kesintisi, parola/e-posta değişimi ve hesap silme testlerini yap. İmzalı archive/IPA ve AAB'yi mağaza doğrulamasından geçir. Bu çalışmada dağıtım veya mağaza yüklemesi yapılmadı.

Android derlemesi başarılı olsa da Flutter, Gradle 8.14+ ve Kotlin 2.2.20+ için yaklaşan destek uyarısı veriyor. Built-in Kotlin geçişi de sonraki toolchain yükseltmesinde ele alınmalı. Bugün geçen derleme, gelecekteki Flutter sürümleri için garanti değildir.

Premium/reklam bu işin parçası olarak eklenmedi. Eklenirken satın alma doğrulama, restore, iptal/iade ve gerekli reklam izinleri ayrıca geliştirilip test edilmeli.
