// EasyDownload site — shared content, theme, nav, footer, icons, hooks
const SITE = {
  grad: "linear-gradient(135deg, oklch(0.55 0.22 20), oklch(0.66 0.21 40))",
  bg: "#FFFCFA", ink: "#231F1E", dim: "#6E6663", border: "#F0E7E2",
  red: "oklch(0.62 0.22 27)",
  font: "'Outfit', sans-serif",
  mono: "'IBM Plex Mono', monospace",
  // TODO: gerçek linkler — kullanıcıdan alınacak
  githubRepo: "operseus/easydownload",
  githubUrl: "https://github.com/operseus/easydownload",
  downloadUrl: "releases.html",
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
      { label: "Sürümler", href: "releases.html" },
      { label: "GitHub", href: "https://github.com/operseus/easydownload" },
    ],
    // Releases page
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
      { label: "Releases", href: "releases.html" },
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

// ---- language hook (persists to localStorage) ----
function useSiteLang() {
  const [lang, setLangRaw] = React.useState(() => {
    try { return localStorage.getItem("ed-site-lang") || "tr"; } catch (e) { return "tr"; }
  });
  const setLang = (l) => {
    setLangRaw(l);
    try { localStorage.setItem("ed-site-lang", l); } catch (e) {}
  };
  return [SiteContent[lang], lang, setLang];
}

// ---- scroll reveal ----
function useReveal() {
  React.useEffect(() => {
    const els = document.querySelectorAll("[data-reveal]");
    const io = new IntersectionObserver((entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) { e.target.classList.add("revealed"); io.unobserve(e.target); }
      });
    }, { threshold: 0.12, rootMargin: "0px 0px -40px 0px" });
    els.forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, []);
}

// ---- TR/EN pill ----
function SiteLangToggle({ lang, setLang, onGradient }) {
  const fg = onGradient ? "rgba(255,255,255,0.85)" : SITE.dim;
  const activeBg = onGradient ? "#fff" : SITE.ink;
  const activeFg = onGradient ? SITE.ink : "#fff";
  const border = onGradient ? "rgba(255,255,255,0.4)" : SITE.border;
  return (
    <div style={{ display: "flex", gap: 2, padding: 3, borderRadius: 999, border: `1px solid ${border}`, alignItems: "center" }}>
      {["tr", "en"].map((l) => (
        <button key={l} onClick={() => setLang(l)} style={{
          border: "none", cursor: "pointer", padding: "5px 12px", borderRadius: 999,
          fontSize: 13, fontWeight: 700, fontFamily: "inherit", lineHeight: 1,
          background: lang === l ? activeBg : "transparent",
          color: lang === l ? activeFg : fg,
        }}>{l.toUpperCase()}</button>
      ))}
    </div>
  );
}

// ---- simple geometric icons ----
function SiteIcon({ name, color, size = 26 }) {
  const s = { stroke: color, strokeWidth: 2, fill: "none", strokeLinecap: "round", strokeLinejoin: "round" };
  const icons = {
    quality: <g {...s}><rect x="3" y="5" width="20" height="14" rx="2"></rect><path d="M9 22h8"></path></g>,
    audio: <g {...s}><circle cx="8" cy="18" r="3"></circle><circle cx="20" cy="16" r="3"></circle><path d="M11 18V7l12-3v12"></path></g>,
    queue: <g {...s}><path d="M4 6h18"></path><path d="M4 12h18"></path><path d="M4 18h10"></path><path d="M19 15v6"></path><path d="M16 18l3 3 3-3"></path></g>,
    history: <g {...s}><circle cx="13" cy="13" r="10"></circle><path d="M13 7v6l4 3"></path></g>,
    theme: <g {...s}><circle cx="13" cy="13" r="10"></circle><path d="M13 3a10 10 0 0 1 0 20z" fill={color} stroke="none"></path></g>,
    globe: <g {...s}><circle cx="13" cy="13" r="10"></circle><path d="M3 13h20"></path><ellipse cx="13" cy="13" rx="4.5" ry="10"></ellipse></g>,
    open: <g {...s}><path d="M9 8l-5 5 5 5"></path><path d="M17 8l5 5-5 5"></path></g>,
    download: <g {...s}><path d="M13 4v12"></path><path d="M8 11l5 5 5-5"></path><path d="M5 21h16"></path></g>,
    chevron: <g {...s}><path d="M7 10l6 6 6-6"></path></g>,
    check: <g {...s}><path d="M5 14l5 5 11-12"></path></g>,
    file: <g {...s}><path d="M7 3h8l5 5v15H7z"></path><path d="M15 3v5h5"></path></g>,
  };
  return <svg width={size} height={size} viewBox="0 0 26 26">{icons[name]}</svg>;
}
const SITE_FEATURE_ICONS = ["quality", "audio", "queue", "theme", "globe", "open"];

// ---- OS choice hook (persists to localStorage) ----
function useSiteOs() {
  const [os, setOsRaw] = React.useState(() => {
    try { return localStorage.getItem("ed-site-os") || "windows"; } catch (e) { return "windows"; }
  });
  const setOs = (o) => {
    setOsRaw(o);
    try { localStorage.setItem("ed-site-os", o); } catch (e) {}
  };
  return [os, setOs];
}

// ---- split download button: main CTA + chevron → OS popup (Windows / Linux) ----
function DownloadSplitBtn({ t, os, setOs, dropUp }) {
  const [open, setOpen] = React.useState(false);
  const ref = React.useRef(null);
  React.useEffect(() => {
    if (!open) return;
    const onDoc = (e) => { if (ref.current && !ref.current.contains(e.target)) setOpen(false); };
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [open]);
  const osNames = { windows: "Windows", linux: "Linux" };
  return (
    <div ref={ref} className="ed-split" style={{ position: "relative", zIndex: 70, display: "inline-flex", filter: "drop-shadow(0 10px 22px rgba(0,0,0,0.18))" }}>
      <a className="btn" href={SITE.downloadUrl} style={{
        display: "inline-flex", alignItems: "center", gap: 10, background: "#fff", color: SITE.ink,
        borderRadius: "999px 0 0 999px", padding: "17px 24px 17px 32px", fontSize: 17, fontWeight: 700,
      }}><SiteIcon name="download" color={SITE.ink} size={20} />{t.ctaDownloadOs[os]}</a>
      <button onClick={() => setOpen(!open)} aria-label={t.osPick} aria-expanded={open} style={{
        display: "inline-grid", placeItems: "center", background: "#fff", color: SITE.ink,
        border: "none", borderLeft: `1.5px solid ${SITE.border}`, borderRadius: "0 999px 999px 0",
        padding: "0 18px 0 14px", cursor: "pointer", fontFamily: SITE.font,
      }}>
        <span style={{ display: "inline-flex", transform: open ? "rotate(180deg)" : "none", transition: "transform 0.2s ease" }}>
          <SiteIcon name="chevron" color={SITE.ink} size={18} />
        </span>
      </button>
      {open && (
        <div role="listbox" style={{
          position: "absolute", right: 0, minWidth: 220, zIndex: 60,
          ...(dropUp ? { bottom: "calc(100% + 10px)" } : { top: "calc(100% + 10px)" }),
          background: "#fff", borderRadius: 16, padding: 6,
          boxShadow: "0 18px 48px rgba(35,31,30,0.25)", border: `1.5px solid ${SITE.border}`,
        }}>
          {["windows", "linux"].map((o) => (
            <button key={o} role="option" aria-selected={os === o} onClick={() => { setOs(o); setOpen(false); }} style={{
              display: "flex", width: "100%", alignItems: "center", gap: 10, padding: "13px 16px",
              borderRadius: 11, border: "none", cursor: "pointer", textAlign: "left",
              background: os === o ? "oklch(0.95 0.035 27)" : "transparent",
              fontFamily: SITE.font, fontSize: 15.5, fontWeight: 700, color: SITE.ink,
            }}>
              <span style={{ flex: 1 }}>{osNames[o]}</span>
              {os === o && <SiteIcon name="check" color={SITE.red} size={16} />}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

// ---- shared buttons ----
function BtnWhite({ children, href }) {
  return (
    <a className="btn" href={href || "#"} style={{
      display: "inline-flex", alignItems: "center", gap: 10, background: "#fff", color: SITE.ink,
      borderRadius: 999, padding: "17px 32px", fontSize: 17, fontWeight: 700,
      boxShadow: "0 10px 30px rgba(0,0,0,0.18)",
    }}>{children}</a>
  );
}
function BtnGhostLight({ children, href }) {
  return (
    <a className="btn" href={href || "#"} style={{
      display: "inline-flex", alignItems: "center", gap: 10, background: "rgba(255,255,255,0.14)",
      color: "#fff", border: "1.5px solid rgba(255,255,255,0.45)", borderRadius: 999,
      padding: "17px 32px", fontSize: 17, fontWeight: 600,
    }}>{children}</a>
  );
}
function BtnGrad({ children, href }) {
  return (
    <a className="btn" href={href || "#"} style={{
      display: "inline-flex", alignItems: "center", gap: 10, background: SITE.grad, color: "#fff",
      borderRadius: 999, padding: "16px 30px", fontSize: 16.5, fontWeight: 700,
      boxShadow: "0 10px 28px oklch(0.62 0.22 27 / 0.35)",
    }}>{children}</a>
  );
}

// ---- nav (sits on gradient) ----
function SiteNav({ t, lang, setLang, page }) {
  const navLink = { color: "rgba(255,255,255,0.88)", textDecoration: "none", fontSize: 15.5, fontWeight: 600 };
  const home = page === "home" ? "" : "index.html";
  return (
    <nav style={{ display: "flex", alignItems: "center", gap: 30, padding: "22px 0", flexWrap: "wrap" }}>
      <a href={home || "#top"} style={{ display: "flex", alignItems: "center", gap: 11, marginRight: "auto", textDecoration: "none", color: "#fff" }}>
        <img src="logo512.png" alt="EasyDownload" width="40" height="40" style={{ display: "block" }} />
        <span style={{ fontWeight: 800, fontSize: 21, letterSpacing: "-0.01em" }}>EasyDownload</span>
      </a>
      <a className="navlink" href={home ? home + "#features" : "#features"} style={navLink}>{t.nav.features}</a>
      <a className="navlink" href={home ? home + "#screenshots" : "#screenshots"} style={navLink}>{t.nav.shots}</a>
      <a className="navlink" href="releases.html" style={{ ...navLink, ...(page === "releases" ? { color: "#fff", textDecoration: "underline", textUnderlineOffset: 5 } : {}) }}>{t.nav.releases}</a>
      <a className="navlink" href={SITE.githubUrl} style={navLink}>{t.nav.github}</a>
      <SiteLangToggle lang={lang} setLang={setLang} onGradient={true} />
      <a className="btn" href="releases.html" style={{ display: "inline-flex", alignItems: "center", gap: 8, background: "#fff", color: SITE.ink, borderRadius: 999, padding: "11px 22px", fontSize: 15, fontWeight: 700 }}>
        <SiteIcon name="download" color={SITE.ink} size={16} />{t.nav.download}
      </a>
    </nav>
  );
}

// ---- footer ----
function SiteFooter({ t }) {
  return (
    <footer style={{ display: "flex", alignItems: "center", padding: "26px 56px", borderTop: `1.5px solid ${SITE.border}`, color: SITE.dim, fontSize: 14.5 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, marginRight: "auto" }}>
        <span style={{ width: 28, height: 28, borderRadius: 9, background: SITE.grad, display: "grid", placeItems: "center" }}>
          <img src="logo512.png" alt="" width="18" height="18" />
        </span>
        <span>{t.footerMade}</span>
      </div>
      <div style={{ display: "flex", gap: 24 }}>
        {t.footerLinks.map((l, i) => <a key={i} href={l.href} style={{ color: SITE.dim, textDecoration: "none" }}>{l.label}</a>)}
      </div>
    </footer>
  );
}

Object.assign(window, {
  SITE, SiteContent, useSiteLang, useSiteOs, useReveal, SiteLangToggle, SiteIcon,
  SITE_FEATURE_ICONS, BtnWhite, BtnGhostLight, BtnGrad, SiteNav, SiteFooter, DownloadSplitBtn,
});
