// EasyDownload site — shared content, theme, nav, footer, icons, hooks (Vanilla JS)
const SITE = {
  grad: "linear-gradient(135deg, oklch(0.55 0.22 20), oklch(0.66 0.21 40))",
  bg: "#FFFCFA", ink: "#231F1E", dim: "#6E6663", border: "#F0E7E2",
  red: "oklch(0.62 0.22 27)",
  font: "'Outfit', sans-serif",
  mono: "'IBM Plex Mono', monospace",
  githubRepo: "operseus/easydownload",
  githubUrl: "https://github.com/operseus/easydownload",
  downloadUrl: "releases.php",
};

const SiteContent = {
  tr: {
    nav: { features: "Özellikler", shots: "Ekran Görüntüleri", releases: "Sürümler", github: "GitHub", download: "İndir" },
    heroBadge: "Ücretsiz · Reklamsız · Açık Kaynak",
    heroTitle1: "YouTube videolarını",
    heroTitleAccent: "saniyeler içinde",
    heroTitle2: "indir",
    heroSub: "EasyDownload ile videoları en iyi kalitede MP4 veya MP3 olarak kaydet. Sıraya ekle, geçmişini gör, tek tıkla indir.",
    ctaDownload: "Windows için İndir",
    ctaDownloadOs: { windows: "Windows için İndir", linux: "Linux için İndir" },
    osVersion: { windows: "v1.0.0 · Windows 10 / 11 · 12 MB", linux: "v1.0.0 · Linux (64-bit) · 12 MB" },
    osPick: "İşletim sistemi seç",
    ctaGithub: "GitHub'da İncele",
    version: "v1.0.0 · Windows 10 / 11 · 12 MB",
    shotsTitle: "Uygulamaya göz at",
    shotsSub: "Light, Dark, Midnight, Sepia — dört yerleşik tema. Gözüne hangisi hoş geliyorsa.",
    shotTabs: ["Midnight · İndir", "Midnight · Sıra", "Açık Tema · İndir", "Açık Tema · Özel Font", "Sepia · Geçmiş", "Sepia · Ayarlar", "Açık Tema · Ayarlar"],
    featuresTitle: "Neden EasyDownload?",
    featuresSub: "İhtiyacın olan her şey, gereksiz hiçbir şey.",
    features: [
      { title: "En iyi kalite", desc: "4K'ya kadar çözünürlük seçenekleri. Videoyu kaynağındaki en yüksek kalitede kaydet." },
      { title: "MP3 desteği", desc: "Sadece sesi mi istiyorsun? Tek tıkla MP3 olarak indir." },
      { title: "Sıra & geçmiş", desc: "Birden fazla videoyu sıraya ekle, hepsi otomatik insin. İndirdiklerin geçmiş ekranında kayıtlı." },
      { title: "4 tema seçeneği", desc: "Light, Dark, Midnight ve Sepia — gözüne en uygun temayı seç." },
      { title: "10 dil desteği", desc: "Türkçe, İngilizce, Almanca, Fransızca, İspanyolca, İtalyanca, Portekizce, Rusça, Azerice ve Arapça arayüz." },
      { title: "Ücretsiz & açık kaynak", desc: "Tamamen ücretsiz, reklamsız. Kaynak kodu GitHub'da herkese açık." },
    ],
    downloadTitle: "Hemen başla",
    downloadSub: "EasyDownload'u indir, ilk videonu 30 saniye içinde kaydet.",
    footerMade: "EasyDownload — p4rs tarafından yapıldı",
    footerLinks: [
      { label: "Sürümler", href: "releases.php" },
      { label: "GitHub", href: "https://github.com/operseus/easydownload" },
    ],
    relTitle: "Sürümler",
    relSub: "Tüm EasyDownload sürümleri ve indirme dosyaları.",
    relLatest: "En son sürüm",
    relDate: "Haziran 2026",
    relNotesTitle: "Bu sürümde neler var?",
    relNotes: [
      "İlk kararlı sürüm",
      "4K'ya kadar video indirme (MP4, WebM, MKV)",
      "MP3 ses indirme desteği",
      "İndirme sırası ve geçmiş ekranları",
      "4 tema: Light, Dark, Midnight, Sepia",
      "10 dil desteği (TR, EN, DE, FR, ES, IT, PT, RU, AZ, AR)",
    ],
    relAssetsTitle: "İndirme dosyaları",
    relAssets: [
      { name: "EasyDownload-Setup-1.0.0.exe", size: "12 MB", desc: "Kurulum (önerilen)" },
      { name: "EasyDownload-1.0.0-portable.zip", size: "9 MB", desc: "Taşınabilir — kurulum gerekmez" },
      { name: "Kaynak kodu (zip)", size: "—", desc: "GitHub üzerinden" },
    ],
    relRequires: "Gereksinimler: Windows 10 veya 11 (64-bit)",
    relAllGithub: "Tüm sürümleri ve değişiklik geçmişini GitHub'da görüntüle",
    backHome: "← Ana sayfa",
  },
  en: {
    nav: { features: "Features", shots: "Screenshots", releases: "Releases", github: "GitHub", download: "Download" },
    heroBadge: "Free · No ads · Open source",
    heroTitle1: "Download YouTube videos",
    heroTitleAccent: "in seconds",
    heroTitle2: "",
    heroSub: "Save videos in the best quality as MP4 or MP3 with EasyDownload. Queue downloads, track history, download in one click.",
    ctaDownload: "Download for Windows",
    ctaDownloadOs: { windows: "Download for Windows", linux: "Download for Linux" },
    osVersion: { windows: "v1.0.0 · Windows 10 / 11 · 12 MB", linux: "v1.0.0 · Linux (64-bit) · 12 MB" },
    osPick: "Choose operating system",
    ctaGithub: "View on GitHub",
    version: "v1.0.0 · Windows 10 / 11 · 12 MB",
    shotsTitle: "Take a look inside",
    shotsSub: "Light, Dark, Midnight, Sepia — four built-in themes. Pick whichever suits your eyes.",
    shotTabs: ["Midnight · Download", "Midnight · Queue", "Light Theme", "Settings", "Sepia · History", "Sepia · Settings", "Light Theme · Settings"],
    featuresTitle: "Why EasyDownload?",
    featuresSub: "Everything you need, nothing you don't.",
    features: [
      { title: "Best quality", desc: "Resolution options up to 4K. Save the video at the highest quality available." },
      { title: "MP3 support", desc: "Only want the audio? Download as MP3 in one click." },
      { title: "Queue & history", desc: "Add multiple videos to the queue and they download automatically. Everything is logged in the history screen." },
      { title: "4 theme options", desc: "Light, Dark, Midnight and Sepia — pick the theme that suits your eyes." },
      { title: "10 languages", desc: "Turkish, English, German, French, Spanish, Italian, Portuguese, Russian, Azerbaijani and Arabic interface." },
      { title: "Free & open source", desc: "Completely free, no ads. Source code is public on GitHub." },
    ],
    downloadTitle: "Get started now",
    downloadSub: "Download EasyDownload and save your first video within 30 seconds.",
    footerMade: "EasyDownload — made by p4rs",
    footerLinks: [
      { label: "Releases", href: "releases.php" },
      { label: "GitHub", href: "https://github.com/operseus/easydownload" },
    ],
    relTitle: "Releases",
    relSub: "All EasyDownload versions and download files.",
    relLatest: "Latest release",
    relDate: "June 2026",
    relNotesTitle: "What's in this release?",
    relNotes: [
      "First stable release",
      "Video downloads up to 4K (MP4, WebM, MKV)",
      "MP3 audio download support",
      "Download queue and history screens",
      "4 themes: Light, Dark, Midnight, Sepia",
      "10 interface languages (TR, EN, DE, FR, ES, IT, PT, RU, AZ, AR)",
    ],
    relAssetsTitle: "Download files",
    relAssets: [
      { name: "EasyDownload-Setup-1.0.0.exe", size: "12 MB", desc: "Installer (recommended)" },
      { name: "EasyDownload-1.0.0-portable.zip", size: "9 MB", desc: "Portable — no install needed" },
      { name: "Source code (zip)", size: "—", desc: "Via GitHub" },
    ],
    relRequires: "Requirements: Windows 10 or 11 (64-bit)",
    relAllGithub: "View all releases and the full changelog on GitHub",
    backHome: "← Home",
  },
};

// ---- Language state (persists to localStorage) ----
const SiteState = {
  lang: (() => { try { return localStorage.getItem("ed-site-lang") || "tr"; } catch (e) { return "tr"; } })(),
  os: (() => { try { return localStorage.getItem("ed-site-os") || "windows"; } catch (e) { return "windows"; } })(),
  shot: 0,
};

function setSiteLang(l) {
  SiteState.lang = l;
  try { localStorage.setItem("ed-site-lang", l); } catch (e) {}
  document.dispatchEvent(new CustomEvent("siteStateChanged"));
}

function setSiteOs(o) {
  SiteState.os = o;
  try { localStorage.setItem("ed-site-os", o); } catch (e) {}
  document.dispatchEvent(new CustomEvent("siteStateChanged"));
}

function setSiteShot(i) {
  SiteState.shot = i;
  document.dispatchEvent(new CustomEvent("siteStateChanged"));
}

// ---- scroll reveal ----
function initReveal() {
  const els = document.querySelectorAll("[data-reveal]");
  const io = new IntersectionObserver((entries) => {
    entries.forEach((e) => {
      if (e.isIntersecting) { e.target.classList.add("revealed"); io.unobserve(e.target); }
    });
  }, { threshold: 0.12, rootMargin: "0px 0px -40px 0px" });
  els.forEach((el) => io.observe(el));
}

// ---- Helper: Create element with styles ----
function el(tag, attrs = {}, children = "") {
  const elem = document.createElement(tag);
  Object.keys(attrs).forEach(key => {
    if (key === "style" && typeof attrs[key] === "object") {
      Object.assign(elem.style, attrs[key]);
    } else if (key === "className") {
      elem.className = attrs[key];
    } else if (key.startsWith("on")) {
      const eventName = key.slice(2).toLowerCase();
      elem.addEventListener(eventName, attrs[key]);
    } else {
      elem.setAttribute(key, attrs[key]);
    }
  });
  if (typeof children === "string") {
    elem.innerHTML = children;
  } else if (Array.isArray(children)) {
    children.forEach(child => {
      if (child) elem.appendChild(typeof child === "string" ? document.createTextNode(child) : child);
    });
  }
  return elem;
}

// ---- Icons SVG ----
function getSiteIcon(name, color = SITE.dim, size = 26) {
  const iconPaths = {
    quality: { d: [["M3","5"],["M23","19"],["M9","22"],["M17","22"]], r: ["rect:3,5,20,14,2"] },
    audio: { d: [["M8","21"],["M20","19"],["M11","18"],["M23","15"]], c: ["8,18,3","20,16,3"] },
    queue: { d: [["M4","6"],["M22","6"],["M4","12"],["M22","12"],["M4","18"],["M14","18"],["M19","15"],["M22","21"],["M16","18"]] },
    history: { d: [["M13","7"],["M17","16"]], c: ["13,13,10"] },
    theme: { d: [["M13","3"]], c: ["13,13,10"] },
    globe: { d: [["M3","13"],["M23","13"]], e: ["13,13,4.5,10"] },
    open: { d: [["M9","8"],["M4","13"],["M9","18"],["M17","8"],["M22","13"],["M17","18"]] },
    download: { d: [["M13","4"],["M13","16"],["M8","11"],["M13","16"],["M18","11"],["M5","21"],["M21","21"]] },
    chevron: { d: [["M7","10"],["M13","16"],["M19","10"]] },
    check: { d: [["M5","14"],["M10","19"],["M21","7"]] },
    file: { d: [["M7","3"],["M15","3"],["M15","8"],["M20","8"]] },
  };
  
  let g = `<g stroke="${color}" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round">`;
  if (name === "quality") g += `<rect x="3" y="5" width="20" height="14" rx="2"></rect><path d="M9 22h8"></path>`;
  else if (name === "audio") g += `<circle cx="8" cy="18" r="3"></circle><circle cx="20" cy="16" r="3"></circle><path d="M11 18V7l12-3v12"></path>`;
  else if (name === "queue") g += `<path d="M4 6h18"></path><path d="M4 12h18"></path><path d="M4 18h10"></path><path d="M19 15v6"></path><path d="M16 18l3 3 3-3"></path>`;
  else if (name === "history") g += `<circle cx="13" cy="13" r="10"></circle><path d="M13 7v6l4 3"></path>`;
  else if (name === "theme") g += `<circle cx="13" cy="13" r="10"></circle><path d="M13 3a10 10 0 0 1 0 20z" fill="${color}" stroke="none"></path>`;
  else if (name === "globe") g += `<circle cx="13" cy="13" r="10"></circle><path d="M3 13h20"></path><ellipse cx="13" cy="13" rx="4.5" ry="10"></ellipse>`;
  else if (name === "open") g += `<path d="M9 8l-5 5 5 5"></path><path d="M17 8l5 5-5 5"></path>`;
  else if (name === "download") g += `<path d="M13 4v12"></path><path d="M8 11l5 5 5-5"></path><path d="M5 21h16"></path>`;
  else if (name === "chevron") g += `<path d="M7 10l6 6 6-6"></path>`;
  else if (name === "check") g += `<path d="M5 14l5 5 11-12"></path>`;
  else if (name === "file") g += `<path d="M7 3h8l5 5v15H7z"></path><path d="M15 3v5h5"></path>`;
  g += `</g>`;
  
  return `<svg width="${size}" height="${size}" viewBox="0 0 26 26">${g}</svg>`;
}

const SITE_FEATURE_ICONS = ["quality", "audio", "queue", "theme", "globe", "open"];

// ---- Initialize on load ----
document.addEventListener("DOMContentLoaded", () => {
  initReveal();
});
