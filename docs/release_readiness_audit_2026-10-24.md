# Storify yayın öncesi denetim — 24 Ekim 2026

Bu belge ilk denetimin tarihsel kaydıdır. Sonraki düzeltmeler ve güncel kalan işler için [yayın hazırlığı durumuna](release_preparation.md) bakın.

## Karar

Mevcut haliyle mağazaya gönderilmesi önerilmez. Test edilen uygulama akışları iyi durumda; ancak istemcideki AI anahtarı, eksik veri silme akışı ve yayın yapılandırması önce tamamlanmalı. Premium/reklam geliştirmesi yapılabilir, fakat güvenli sunucu altyapısından önce eklenmesi erişim ve maliyet kontrolünü çözmez.

Bu çalışma kaynak kodu, yerel testler, derleme denemeleri ve resmî mağaza kurallarının incelemesidir. Sızma testi, canlı Firebase yetki denetimi veya mağaza onayı değildir. Uygulama davranışını değiştiren bir düzeltme yapılmadı.

## Doğrulanan kontroller

- `flutter test`: **64 test geçti**. Hesap arayüzleri, responsive yerleşimler, loading, hata/tekrar akışları, hikâye bağlamı ve misafir hikâye verileri kapsanıyor.
- `flutter analyze`: **No issues found**.
- `dart format --output=none --set-exit-if-changed lib test`: 50 dosyadan 2'sinde format farkı var: `lib/blocs/theme/theme_state.dart`, `lib/services/firebase_storage_service.dart`. Bu komut dosyaları değiştirmedi.
- Canlı Firebase giriş/silme/Storage izinleri bu denetimde uçtan uca test edilmedi. Testlerdeki sahte repository sonuçları bunları doğrulamaz.
- Release derleme sonuçları aşağıdaki derleme bölümünde kayıtlıdır.

## Yayını engelleyen / yüksek öncelikli bulgular

### P0 — AI sağlayıcı anahtarı mobil pakette

Kanıt: `pubspec.yaml:71`, `lib/main.dart:32`, `lib/repositories/story_repository.dart:18`, `:86`.

Bu denetimde üretilen iOS release paketinde `Runner.app/Frameworks/App.framework/flutter_assets/.env` dosyasının varlığı ayrıca doğrulandı; gizli içeriği çıktıya alınmadı.

`.env` asset olarak paketleniyor; OpenAI isteği cihazdan doğrudan, bu dosyadaki anahtarla gidiyor. `.gitignore` veya obfuscation paket içindeki anahtarı korumaz. Anahtarı çıkaran kişi uygulama girişini atlayarak hesabın kotasını kullanabilir. `canUseAI` kontrolü istemcide olduğu için bir güvenlik sınırı değildir.

Çözüm: AI çağrılarını sunucuya taşı; Firebase ID token doğrulaması, kullanıcı başına kota, rate limit, istek boyutu ve maliyet sınırlarını sunucuda uygula. Premium yetkisini de orada doğrula. Anahtarı mobil assetlerden tamamen kaldır; dağıtılmış paketlerde kullanılmış anahtarı sunucu geçişinden sonra yenile. App Check ek savunma olabilir, kimlik doğrulamanın yerine geçmez.

Firebase `firebase_options.dart` içindeki istemci yapılandırma anahtarları, OpenAI gizli anahtarıyla aynı kategoride değildir. Firebase veri erişimini gerçek servis kuralları ve kimlik doğrulama belirler.

### P1 — Hesap silme, ilişkili veriyi temizlemiyor

Kanıt: `lib/pages/settings_page.dart:291` fotoğraf yükler; `lib/services/firebase_storage_service.dart:8` yolu `users/$userId/profile.jpg`; `lib/services/firebase_auth_service.dart:204` yalnızca `user.delete()` çağırır. `lib/pages/settings_page.dart:544` sonrasında yerel hikâye temizliği yoktur.

Sonuç: Kodda profil fotoğrafını veya yerel hikâye/owner kaydını silen hesap-silme adımı yok. Ayrı bir sunucu temizleme mekanizması varsa bu çalışma alanında görünmüyor. Auth hesabının silinmesini tüm verilerin silinmesi sayamayız.

Çözüm: Yetkili, yeniden denenebilir hesap/veri silme işlemi; Storage temizliği; yerel state ve preferences temizliği; kısmi başarısızlıkların takibi. Auth kaydı silindikten sonra istemcinin Storage silme yetkisini kaybedebileceği dikkate alınmalı.

Google Play ayrıca uygulama dışından silme talebi için bir web kaynağı ister. Bu bağlantının konsolda mevcut olduğu doğrulanamadı. [Google hesap silme gereksinimleri](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).

### P1 — Android yayın ayarları hazır değil

Kanıt: `android/app/build.gradle.kts:11`, `:24`, `:27`, `:35`.

- Release build debug anahtarıyla imzalanıyor. Gerçek upload key / Play App Signing kurulmalı.
- `compileSdk` ve `targetSdk` 35. Bu denetimdeki bağımlılıklar compile SDK 36 istiyor; derleme ayrıca NDK 28.2.13676358 ihtiyacı bildiriyor.
- `com.example.flutter_story_app` ve iOS `com.example.flutterStoryApp` örnek kimlikler. Yayından önce kalıcı, geliştiriciye ait kimlikler kararlaştırılmalı; Firebase/OAuth kayıtları ve release SHA parmak izleri buna göre eşleştirilmeli. Kimlik değişikliği mevcut uygulamanın güncelleme yolunu etkiler.
- Gradle/Kotlin sürüm uyarıları birlikte ele alınmalı; yalnızca targetSdk sayısını değiştirmek yeterli doğrulama değildir.

24 Ekim 2026 itibarıyla normal yeni telefon uygulamalarında Google Play API 36 ister (31 Ağustos 2026'dan itibaren; onaylı geçici uzatma ayrı konudur). [Resmî hedef API gereksinimi](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en-EN).

### P1 — iOS giriş ve gizlilik hazırlıkları eksik

Kanıt: `lib/services/firebase_auth_service.dart:13` Google girişi; Apple/eşdeğer giriş uygulaması bulunmadı. `lib` ve `assets/langs` içinde gizlilik politikası bağlantısı/akışı bulunmadı.

Google girişi korunacaksa ve istisna uygulanmıyorsa Apple 4.8 koşullarına uyan eşdeğer bir giriş eklenmeli; Sign in with Apple uygun bir seçenektir. Uygulama içinde ve mağazada gizlilik politikası bağlantısı olmalı. [Apple inceleme kuralları: 4.8 ve 5.1.1](https://developer.apple.com/app-store/review/guidelines/).

AI isteklerinin gözlenen içeriği tema, kahramanın cinsiyet seçimi, hikâye ve şıklardır; mevcut payload'da e-posta/profil fotoğrafı yoktur. Gizlilik açıklaması gerçek veri akışını anlatmalı. Üçüncü taraf AI'a kişisel veri aktarılacaksa Apple 5.1.2(i) kapsamındaki açık izin akışı sağlanmalı. [Apple veri paylaşımı kuralları](https://developer.apple.com/app-store/review/guidelines/#data-use-and-sharing).

### P1 — AI içerik güvenliği ve bildirme akışı yok

Kanıt: `lib/services/story_prompts.dart`, `lib/repositories/story_repository.dart`, `lib/pages/story_page.dart`. Kalite/tekrar kontrolü var; uygulamaya ait içerik güvenliği değerlendirmesi ve uygunsuz hikâyeyi geliştiriciye bildirme akışı bulunmadı. Model sağlayıcısının kendi korumaları, uygulamanın bildirim mekanizmasının yerine geçmez.

Hedef yaş grubuna uygun içerik sınırları, sunucuda içerik kontrolü ve uygulama içi bildirim kanalı eklenmeli. Hikâyeler arasında korku teması da bulunduğundan yaş derecelendirmesi gerçek içeriğe göre yapılmalı. [Google Play AI içerik politikası](https://support.google.com/googleplay/android-developer/answer/13985936?hl=en).

## Güvenlikte ayrıca doğrulanması gerekenler

- Firebase Storage kuralları depoda yok; canlı kurallar okunmadı. Başka kullanıcının `users/{uid}` alanına okuma/yazma, anonim erişim, MIME türü ve dosya boyutu sınırı test edilmeli. Kuralların açık olduğu sonucuna varılmadı; güvenli olduğu da onaylanamıyor.
- Fotoğraf yükleme yalnızca `imageQuality: 75` kullanıyor; bu bir byte/boyut limiti değildir. `settings_page.dart:285` ve Storage kuralları birlikte ele alınmalı.
- Şifreler uygulamanın preferences servisine yazılmıyor; Firebase SDK ile giriş yapılıyor. Hassas hesap değişikliklerinde yeniden doğrulama var. Bunlar olumlu noktalar.
- Kayıtta e-posta doğrulama akışı görünmüyor; AI erişimi yalnızca anonim olmayan hesap kontrolüne bağlı. Ücretsiz kota varsa çok hesapla kötüye kullanım sunucuda sınırlandırılmalı.
- Şifre alanları `.trim()` ile değiştirilerek gönderiliyor (`sign_in_page.dart:144`, `sign_up_page.dart:38`, settings diyalogları). Başında/sonunda boşluk bulunan geçerli şifrelerle giriş sorununa yol açabilir. E-posta normalize edilebilir; şifre aynen gönderilmeli.
- Firebase konsolundaki sağlayıcı ayarları, e-posta enumeration koruması, parola politikası, release OAuth yapılandırması ve bütçe uyarıları ayrıca kontrol edilmeli.
- SDK bağımlılıklarında tam güvenlik açığı taraması yapılmadı; analiz/test başarısı bu anlama gelmez.

## Kod ağacı ve clean code

Mevcut katman düzeni anlaşılır; yeni bir mimariye toplu geçiş gerekmiyor. Ancak “tam clean code” denemez:

1. `lib/models/story_model.dart:3` içindeki `StoryModel` kullanılmıyor; aynı dosyadaki `Story` kullanılıyor.
2. `lib/widgets/theme_button.dart:5` içindeki `ThemeButton` için uygulama/test çağrısı yok.
3. `PreferencesService.saveLastStoryText`, `getLastStoryText`, `clearAll`, `saveLoginStatus`, `getLoginStatus` çağrılmıyor. Eski `lastStoryText` anahtarından yapılan veri göçü ise `getLastStories` içinde hâlâ kullanılıyor; temizlikte bu uyumluluk korunmalı.
4. `http`, `dio`, `google_fonts`, `lottie` için `lib`/`test` içinde doğrudan import yok. Doğrudan pubspec bağımlılıkları kaldırılabilir; başka paketlerin transitif ihtiyaçları lockfile çözümlemesinde kalabilir. Asset fontlar aktif kullanılıyor; font dosyaları gereksiz değildir.
5. `flutter_launcher_icons` ve `flutter_native_splash` geliştirme araçları; `dev_dependencies` altında tutulmaları daha uygun.
6. `lib/contants` yazım hatası; `constants` olarak importlarla birlikte düzeltilebilir.
7. `settings_page.dart:303` arayüzden `FirebaseAuthService` somut sınıfına cast ediyor ve statik Storage servisi çağırıyor. Profil güncelleme AuthRepository sözleşmesi/Cubit üzerinden yürütülmeli.
8. `StoryCubit` doğrudan `.tr()` ve statik PreferencesService kullanıyor. Alan hata kodlarının arayüzde çevrilmesi ve storage bağımlılığının enjekte edilmesi test edilebilirliği artırır.

## Dayanıklılık ve test açıkları

- `main.dart:32–33`: dotenv/Firebase başlangıç hatası için kurtarma ekranı yok.
- Misafir hikâyeleri assetlerden üretiliyor; fakat ilk misafir oturumu `signInAnonymously()` nedeniyle ağ gerektiriyor. “İlk açılıştan itibaren tamamen çevrimdışı” deneyimi doğrulanmış değil.
- AI hikâye geçmişi ve tüm önceki şıklar her devam isteğinde büyüyor. Sınırsız oturumlarda maliyet/context sınırı için bölüm limiti veya güvenli özetleme planlanmalı.
- Çıkış/silme sırasında StoryCubit sıfırlanmıyor; kalıcı hikâye UID kontrolü başka hesaba restore edilmesini engelliyor, ancak bellekteki state ve yerel silme ayrı yönetilmeli.
- Gerçek iPhone/Android release: Google/email giriş, parola sıfırlama, fotoğraf izin reddi/yükleme, yeniden doğrulama/silme, ağ kesilmesi, hesap değişimi ve uzun hikâye testleri gerekli.
- Flutter widget testleri; platform OAuth, keystore, Firebase rules ve gerçek mağaza ödeme akışını kapsamaz.

## Premium / reklam eklenmeden önce

Önerilen sıra: güvenli AI backend → veri silme/Storage kuralları → mağaza gizlilik/giriş/içerik akışları → release yapılandırması ve cihaz testleri → monetizasyon.

Premium için mağaza satın alma entegrasyonu, sunucuda satın alma doğrulaması, restore, iptal/iade/sona erme senaryoları ve kullanıcı kotası gerekir. Tek bir yerel `isPremium` bayrağı yeterli değildir. Reklam için seçilecek SDK'nın veri akışı, bölgeye ve izlemeye göre gerekli izinler, yaş hedefi ve mağaza veri beyanları tasarıma dahil edilmeli. Şu anda bu özellikler uygulamada yok; hazır oldukları iddia edilmiyor.

App Store Connect / Play Console'da Data Safety/App Privacy, destek ve silme URL'leri, yaş derecelendirmesi, inceleme hesabı ve imzalama kayıtları bu denetimde incelenmedi. Uygulamanın kendi privacy manifest ihtiyacı ve bağımlılık manifestlerinin son archive içindeki durumu da teslim öncesinde doğrulanmalı; yalnızca kaynakta manifest bulunmaması tek başına ret kanıtı değildir.

Apple'ın güncel yükleme şartı Xcode 26 / iOS 26 SDK veya sonrası; makinede Xcode 26.3 var. Bu, distribution imzası ve App Store archive doğrulaması yerine geçmez. [Apple SDK gereksinimi](https://developer.apple.com/news/upcoming-requirements/?id=04282026a).

## Release derlemeleri

- `flutter build appbundle --release`: **başarısız**, çıkış kodu 1; `bundleRelease` / AAR metadata kontrolü. Bağımlılıklar compile SDK 36 ve AGP en az 8.9.1 istiyor; proje compile SDK 35 ve AGP 8.7.0 kullanıyor. NDK/Kotlin uyarıları da var. Android yayın paketi doğrulanamadı.
- `flutter build ios --release --no-codesign`: **başarılı**, `build/ios/iphoneos/Runner.app`, 53.2 MB. Bu imzasız bir cihaz derlemesi; imzalı IPA, App Store archive validation veya TestFlight testi değildir.
- Yerel inceleme logları: `/tmp/storify-release-audit-tests.log`, `/tmp/storify-release-audit-analyze.log`, `/tmp/storify-audit-format.log`, `/tmp/storify-audit-android.log`, `/tmp/storify-audit-ios.log`. Geçici loglar kalıcı teslimat sayılmaz; sonuçlar bu rapora kaydedildi.
