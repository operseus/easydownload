# EasyDownload — Build & Release Rehberi

Bu belge, `versions/1.1.0/` kaynağından **çalışır son hâli** üretmeyi ve
**Inno Setup** ile kurulum dosyası (installer) hazırlamayı anlatır.

## Gereksinimler

- **Lazarus/FPC** (Object Pascal arayüz için) — `lazbuild.exe` PATH'te veya
  `C:\Lazarus\lazbuild.exe`
- **Visual Studio 2022** (C++ iş yükü) + **CMake** — `core.exe` için
- **Inno Setup 6** — kurulum dosyası için (`ISCC.exe`)

---

## 1. Adım — `core.exe` (C++ motor) derle

```powershell
cd versions\1.1.0
cmake -S src/engine -B src/engine/build -G "Visual Studio 17 2022" -A x64
cmake --build src/engine/build --config Release
Copy-Item src/engine/build/Release/core.exe core.exe -Force
```

`core.exe` statik bağlanır (`/MT`), yani ekstra VC++ Redistributable DLL'i
gerekmez.

Derleme bitince `src/engine/build/` klasörünü silebilirsin — tamamen
yeniden oluşturulabilir, kaynak pakete dahil edilmemeli:

```powershell
Remove-Item -Recurse -Force src/engine/build
```

---

## 2. Adım — `EasyDownload.exe` (Lazarus arayüz) derle

```powershell
lazbuild ui/EasyDownload.lpi
```

Çıktı doğrudan `versions/1.1.0/EasyDownload.exe` olarak oluşur (proje
hedefi `../EasyDownload`). Derleme `ui/lib/` altında ara dosyalar (.o,
.ppu, .a) bırakır — bunlar da regenerable'dır, paketten önce silinmeli:

```powershell
Remove-Item -Recurse -Force ui/lib
```

---

## 3. Adım — Sürüm numarasını güncelle (her yeni sürümde)

`ui/updater.pas` başındaki sabitler **bu derlemenin kimliğidir** — yeni bir
sürüm hazırlarken ilk iş bunları bumplamaktır:

```pascal
const
  CurrentVersion     = '1.1.0';
  CurrentVersionCode = 10100;   // 1.1.0 ; sonraki sürüm 10101, 10200...
```

Sayısal kod şeması: `MAJOR*10000 + MINOR*100 + PATCH` (örn. 1.0.2b → 10002,
1.1.0 → 10100, 1.1.1 → 10101, 1.2.0 → 10200). Bu kod, sunucudaki
`server/api/latest.json` içindeki `version_code` ile karşılaştırılır — bkz.
[6. Adım](#6-adım--yayınla-self-update-sunucusu).

Sabitleri değiştirdikten sonra **2. Adımı tekrar çalıştır** (yeni
`EasyDownload.exe`'yi üret).

---

## 4. Adım — Yayın klasörünü hazırla

`versions/1.1.0/` içinde, son kullanıcıya gidecek olanlar ile geliştirme
kaynağı net ayrılır:

**Installer'a dahil edilecekler:**
```
EasyDownload.exe
core.exe
bin/            (ffmpeg.exe, yt-dlp.exe)
assets/         (languages/, themes/, fonts/, logos/)
data/settings.json   (boş "{}" — ilk kurulumda varsayılan)
```

**Installer'a DAHİL EDİLMEYECEKLER** (geliştirici kaynağı, son kullanıcıya
gerekmez):
```
ui/             (Pascal kaynak kodu)
src/            (C++ motor kaynak kodu)
server/         (cPanel/PHP güncelleme sunucusu kaynağı)
README.md, how_to_build.md, *.iss
```

`temp/` klasörü pakete dahil edilmez — uygulama ilk çalıştığında kendisi
oluşturur ve kullanır.

---

## 5. Adım — Inno Setup ile kurulum dosyası oluştur

`versions/1.1.0/EasyDownload.iss` dosyası hazır. Uygulama
**`%LocalAppData%\EasyDownload`** altına, **yönetici izni gerektirmeden**
kurulur (self-update'in sorunsuz çalışması için önemli — Program Files
admin ister).

```powershell
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" EasyDownload.iss
```

Çıktı: `Output\EasyDownload-Setup-1.1.0.exe`

İlk derlemeden önce script başındaki `#define MyAppVersion "1.1.0"`
satırını [3. Adımdaki](#3-adım--sürüm-numarasını-güncelle-her-yeni-sürümde)
sürüm ile **aynı** tut.

---

## 6. Adım — Yayınla (self-update sunucusu)

1. `Output\EasyDownload-Setup-1.1.0.exe` dosyasını cPanel'de
   `server/files/` altına yükle (bkz. `server/KURULUM.md`).
2. `server/api/latest.json` dosyasını güncelle:
   - `version`: `"1.1.0"`
   - `version_code`: `10100` (3. Adımdaki ile **aynı** olmalı)
   - `file`: yeni installer dosya adı
   - `notes`: değişiklik özeti
   - `auto`: `updater.pas` değişmediyse `true`, değiştiyse (örn. yeni
     `CurrentVersionCode` şeması) `false` (kullanıcı manuel indirir)
3. Eski sürümler `api/version.php` üzerinden bu bilgiyi okuyup güncelleme
   olduğunu görecektir.
