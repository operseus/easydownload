# EasyDownload

Sade bir video / müzik / oynatma listesi indiricisi.
Arka planda **yt-dlp** ve **FFmpeg** kullanır. Arayüz çok basit tutulmuştur
(her düğmede simge + yazı, büyük yazı tipi, yüksek kontrast).

## Mimari

İki parçadan oluşur:

| Parça | Dil | Görevi |
|------|-----|--------|
| `core.exe`        | **C++** (MSVC) | İndirme motoru: yt-dlp + FFmpeg orkestrasyonu, `temp → merge → taşıma` akışı, meta veri / kapak gömme. İlerlemeyi **stdout'a JSON satırları** (`started`/`stage`/`progress`/`done`/`error`) olarak yazar. |
| `EasyDownload.exe`| **Object Pascal** (Lazarus/FPC, LCL) | Native masaüstü arayüz. Dil/tema/font/ayar yönetimini yapar, `core.exe`'yi `TProcess` ile arka planda çalıştırıp satır satır gelen JSON olaylarını arayüze yansıtır. |

## Klasör yapısı

```
1.1.0/
├─ EasyDownload.exe      (derlenince oluşur)  Lazarus arayüzü
├─ core.exe              (derlenince oluşur)  C++ motor
├─ bin/                  ffmpeg.exe, yt-dlp.exe
├─ assets/
│  ├─ languages/         <kod>.json            (yeni dil = yeni .json)
│  ├─ themes/            light.css, dark.css, sepia.css, midnight.css (yeni tema = yeni .css)
│  ├─ fonts/             özel yazı tipleri (.ttf)
│  └─ logos/             uygulama ikonu/logoları
├─ data/                 settings.json, history.json (kullanıcı verisi)
├─ temp/                 indirme sırasında geçici (otomatik temizlenir)
├─ server/               cPanel/PHP güncelleme sunucusu (bkz. server/KURULUM.md)
├─ ui/                    Lazarus/Object Pascal arayüz kaynak kodu (.pas/.lfm/.lpi)
├─ src/engine/            C++ motor kaynak kodu (core.exe)
├─ setup/                 Inno Setup için license/before/after metinleri
├─ EasyDownload.iss       Inno Setup kurulum betiği
└─ how_to_build.md        Build & yayın rehberi
```

## Derleme

Gereksinimler: Lazarus/FPC (Object Pascal arayüz için), Visual Studio 2022
(C++ iş yükü) + CMake (`core.exe` için).

```powershell
# core.exe (C++ motor)
cmake -S src/engine -B src/engine/build -G "Visual Studio 17 2022" -A x64
cmake --build src/engine/build --config Release
Copy-Item src/engine/build/Release/core.exe core.exe -Force

# EasyDownload.exe (Lazarus arayüz)
lazbuild ui/EasyDownload.lpi
```

Sonra `EasyDownload.exe` çalıştırılır.

## İndirme akışı (motorun mantığı)

1. Kullanıcı indirmeyi başlatır.
2. `temp/<jobid>` klasörü oluşur; tüm `.part`/ara dosyalar oraya iner
   (masaüstü/hedef klasör kirlenmez).
3. yt-dlp medyayı `temp`'e indirir (video+ses birleştirmesi dahil).
4. Meta veri/kapak eklenecekse `temp/<jobid>/merge` oluşur ve FFmpeg tek
   bir dosyada birleştirir.
5. Son dosya hedef klasöre **taşınır**, ardından `temp` temizlenir.

## Dil / tema ekleme

- **Dil:** `assets/languages/` içine `<kod>.json` koy (örn. `de.json`).
  İçindeki `_meta.name` ayarlardaki listede otomatik görünür.
- **Tema:** `assets/themes/` içine `<ad>.css` koy. İlk satıra `/* @name Ad */`
  yazarsan ayarlarda o adla görünür.

## Varlıklar (assets)

- `assets/logos/` — uygulama logosu (`logo.ico`, `logo.png`, `logo.svg`)
- `assets/fonts/` — ayarlardan seçilebilen yedek yazı tipleri (`.ttf`)
- `assets/languages/` — dil dosyaları (`<kod>.json`)
- `assets/themes/` — tema dosyaları (`<ad>.css`)

Bu klasörler olmadan da uygulama çalışır; eksik dosyalar yerleşik
varsayılanlara düşer.
