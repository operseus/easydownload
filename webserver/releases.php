<?php
header("Content-Type: text/html; charset=utf-8");
?><!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Sürümler — EasyDownload</title>
<link rel="icon" href="logo512.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&family=IBM+Plex+Mono:wght@400;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="site.css">
<style>
  [data-reveal] { opacity: 1; transform: none; }
  @media (prefers-reduced-motion: no-preference) {
    [data-reveal] { opacity: 0; transform: translateY(30px); transition: opacity 0.7s ease, transform 0.75s cubic-bezier(0.2, 0.7, 0.2, 1); transition-delay: var(--rd, 0s); }
    [data-reveal].revealed { opacity: 1; transform: none; }
  }
  .ed-asset { transition: background 0.18s ease, transform 0.18s ease; }
  .ed-asset:hover { background: #FFF6F2 !important; transform: translateX(4px); }
</style>
</head>
<body>
<div style="background: #FFFCFA; color: #231F1E; font-family: 'Outfit', sans-serif; min-height: 100vh; display: flex; flex-direction: column;">

  <!-- ===== GRADIENT HEADER ===== -->
  <header data-screen-label="releases header" style="background: linear-gradient(135deg, oklch(0.55 0.22 20), oklch(0.66 0.21 40)); color: #fff; padding: 0 56px 120px; position: relative; overflow: hidden;">
    <div style="position: absolute; top: 30px; left: -100px; width: 260px; height: 260px; border-radius: 50%; background: rgba(255,255,255,0.07); pointer-events: none;"></div>
    <div style="position: absolute; top: 90px; right: -70px; width: 200px; height: 200px; border-radius: 50%; background: rgba(255,255,255,0.09); pointer-events: none;"></div>

    <div style="max-width: 1180px; margin: 0 auto; position: relative;">
      <!-- Navigation -->
      <nav style="display: flex; align-items: center; gap: 30px; padding: 22px 0; flex-wrap: wrap;">
        <a href="index.php" style="display: flex; align-items: center; gap: 11px; margin-right: auto; text-decoration: none; color: #fff;">
          <img src="logo512.png" alt="EasyDownload" width="40" height="40" style="display: block;" />
          <span style="font-weight: 800; font-size: 21px; letter-spacing: -0.01em;">EasyDownload</span>
        </a>
        <a class="navlink" href="index.php#features" style="color: rgba(255,255,255,0.88); text-decoration: none; font-size: 15.5px; font-weight: 600;">Özellikler</a>
        <a class="navlink" href="index.php#screenshots" style="color: rgba(255,255,255,0.88); text-decoration: none; font-size: 15.5px; font-weight: 600;">Ekran Görüntüleri</a>
        <a class="navlink" href="#" style="color: #fff; text-decoration: underline; text-underline-offset: 5px; font-size: 15.5px; font-weight: 600;">Sürümler</a>
        <a class="navlink" href="https://github.com/operseus/easydownload" style="color: rgba(255,255,255,0.88); text-decoration: none; font-size: 15.5px; font-weight: 600;">GitHub</a>
        <div id="langToggle" style="display: flex; gap: 2px; padding: 3px; border-radius: 999px; border: 1px solid rgba(255,255,255,0.4); align-items: center;"></div>
        <a class="btn" href="releases.php" style="display: inline-flex; align-items: center; gap: 8px; background: #fff; color: #231F1E; border-radius: 999px; padding: 11px 22px; font-size: 15px; font-weight: 700; text-decoration: none;" id="navDownloadBtn"></a>
      </nav>

      <!-- Hero Content -->
      <div style="padding-top: 40px; max-width: 720px;">
        <a href="index.php" class="navlink" style="color: rgba(255,255,255,0.85); text-decoration: none; font-size: 15px; font-weight: 600;">← Ana sayfa</a>
        <h1 class="hero-in d1" style="font-size: 56px; line-height: 1.05; letter-spacing: -0.03em; margin: 16px 0 0; font-weight: 800;">Sürümler</h1>
        <p class="hero-in d2" style="font-size: 19px; line-height: 1.55; color: rgba(255,255,255,0.92); margin: 16px 0 0; text-wrap: pretty;">Tüm EasyDownload sürümleri ve indirme dosyaları.</p>
      </div>
    </div>
  </header>

  <!-- ===== LATEST RELEASE CARD ===== -->
  <main style="max-width: 880px; margin: -70px auto 0; padding: 0 56px 96px; position: relative; width: 100%; box-sizing: border-box; flex: 1;">
    <div class="hero-in d3" data-screen-label="latest release" style="background: #fff; border: 1.5px solid #F0E7E2; border-radius: 26px; padding: 40px; box-shadow: 0 32px 80px -28px rgba(35,31,30,0.28);">
      <div style="display: flex; align-items: center; gap: 14px; flex-wrap: wrap;">
        <span style="width: 54px; height: 54px; border-radius: 16px; background: linear-gradient(135deg, oklch(0.55 0.22 20), oklch(0.66 0.21 40)); display: grid; place-items: center;">
          <img src="logo512.png" alt="" width="34" height="34" />
        </span>
        <h2 style="font-size: 34px; font-weight: 800; letter-spacing: -0.02em; margin: 0;">v1.0.0</h2>
        <span style="background: oklch(0.95 0.035 150); color: oklch(0.45 0.12 150); border-radius: 999px; padding: 7px 16px; font-size: 13.5px; font-weight: 700;">En son sürüm</span>
        <span style="margin-left: auto; color: #6E6663; font-size: 14.5px; font-family: 'IBM Plex Mono', monospace;">Haziran 2026</span>
      </div>

      <h3 style="font-size: 17px; font-weight: 700; margin: 32px 0 12px;">Bu sürümde neler var?</h3>
      <ul id="releaseNotes" style="margin: 0; padding: 0; list-style: none; display: grid; gap: 9px;"></ul>

      <h3 style="font-size: 17px; font-weight: 700; margin: 34px 0 12px;">İndirme dosyaları</h3>
      <div id="releaseAssets" style="display: grid; gap: 10px;"></div>

      <p style="color: #6E6663; font-size: 13.5px; margin: 20px 0 0; font-family: 'IBM Plex Mono', monospace;">Gereksinimler: Windows 10 veya 11 (64-bit)</p>
    </div>

    <!-- GitHub band -->
    <div data-reveal style="margin-top: 28px; text-align: center; border: 1.5px dashed #F0E7E2; border-radius: 20px; padding: 30px 24px;">
      <p style="color: #6E6663; font-size: 16px; margin: 0 0 18px;">Tüm sürümleri ve değişiklik geçmişini GitHub'da görüntüle</p>
      <a href="https://github.com/operseus/easydownload" style="display: inline-flex; align-items: center; gap: 10px; background: linear-gradient(135deg, oklch(0.55 0.22 20), oklch(0.66 0.21 40)); color: #fff; border-radius: 999px; padding: 16px 30px; font-size: 16.5px; font-weight: 700; box-shadow: 0 10px 28px oklch(0.62 0.22 27 / 0.35); text-decoration: none;">
        <span style="display: inline-flex; width: 18px; height: 18px;"><?php echo file_get_contents('data:image/svg+xml;utf8,<svg viewBox="0 0 26 26"><g stroke="white" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M9 8l-5 5 5 5"/><path d="M17 8l5 5-5 5"/></g></svg>'); ?></span>
        GitHub
      </a>
    </div>
  </main>

  <!-- ===== FOOTER ===== -->
  <footer style="display: flex; align-items: center; padding: 26px 56px; border-top: 1.5px solid #F0E7E2; color: #6E6663; font-size: 14.5px;">
    <div style="display: flex; align-items: center; gap: 10px; margin-right: auto;">
      <span style="width: 28px; height: 28px; border-radius: 9px; background: linear-gradient(135deg, oklch(0.55 0.22 20), oklch(0.66 0.21 40)); display: grid; place-items: center;">
        <img src="logo512.png" alt="" width="18" height="18" />
      </span>
      <span>EasyDownload — p4rs tarafından yapıldı</span>
    </div>
    <div style="display: flex; gap: 24px;">
      <a href="releases.php" style="color: #6E6663; text-decoration: none;">Sürümler</a>
      <a href="https://github.com/operseus/easydownload" style="color: #6E6663; text-decoration: none;">GitHub</a>
    </div>
  </footer>

</div>

<script src="site-shared.js"></script>
<script>
  let ghData = null;
  async function fetchGh() {
    try {
      const res = await fetch(`https://api.github.com/repos/${SITE.githubRepo}/releases/latest`);
      if (res.ok) ghData = await res.json();
    } catch(e) {
      console.error(e);
    }
  }

  async function updatePage() {
    const t = SiteContent[SiteState.lang];

    // Update nav download button
    document.getElementById("navDownloadBtn").innerHTML = `
      ${getSiteIcon("download", "#231F1E", 16)}
      ${t.nav.download}
    `;

    // Update language toggle
    const langToggle = document.getElementById("langToggle");
    langToggle.innerHTML = ["tr", "en"].map(l => `
      <button onclick="setSiteLang('${l}')" style="border: none; cursor: pointer; padding: 5px 12px; border-radius: 999px; font-size: 13px; font-weight: 700; font-family: inherit; line-height: 1; background: ${SiteState.lang === l ? "#fff" : "transparent"}; color: ${SiteState.lang === l ? "#231F1E" : "rgba(255,255,255,0.85)"};">${l.toUpperCase()}</button>
    `).join("");

    if (!ghData) await fetchGh();

    const releaseNotes = document.getElementById("releaseNotes");
    const releaseAssets = document.getElementById("releaseAssets");

    if (ghData) {
      document.querySelector('[data-screen-label="latest release"] h2').textContent = ghData.tag_name || "v1.0.0";
      const dateEl = document.querySelector('[data-screen-label="latest release"] > div > span:last-child');
      if (dateEl) {
        dateEl.textContent = new Date(ghData.published_at).toLocaleDateString(SiteState.lang === 'tr' ? 'tr-TR' : 'en-US', { year: 'numeric', month: 'long' });
      }

      const notes = (ghData.body || "").split('\n').map(l => l.trim().replace(/^[*-]\s+/, '')).filter(l => l.length > 0);
      releaseNotes.innerHTML = (notes.length ? notes : t.relNotes).map(n => `
        <li style="display: flex; gap: 10px; align-items: baseline; color: #6E6663; font-size: 15.5px; line-height: 1.5;">
          <span style="width: 7px; height: 7px; border-radius: 99px; background: oklch(0.62 0.22 27); flex-shrink: 0; position: relative; top: -2px;"></span>${n}
        </li>
      `).join("");

      let assetsHTML = ghData.assets.map((a) => {
        const sizeMB = (a.size / (1024 * 1024)).toFixed(1) + " MB";
        let desc = a.name.endsWith('.exe') ? (SiteState.lang === 'tr' ? "Kurulum" : "Installer") : (SiteState.lang === 'tr' ? "Taşınabilir" : "Portable");
        return `
        <a class="ed-asset" href="${a.browser_download_url}" style="display: flex; align-items: center; gap: 14px; text-decoration: none; border: 1.5px solid #F0E7E2; border-radius: 16px; padding: 16px 20px; background: #fff; color: inherit;">
          <span style="width: 42px; height: 42px; border-radius: 12px; background: oklch(0.95 0.035 27); display: grid; place-items: center; flex-shrink: 0;">
            ${getSiteIcon("file", "oklch(0.62 0.22 27)", 22)}
          </span>
          <span style="display: grid; gap: 2px;">
            <span style="font-weight: 700; font-size: 15.5px; color: #231F1E; font-family: 'IBM Plex Mono', monospace;">${a.name}</span>
            <span style="color: #6E6663; font-size: 13.5px;">${desc}</span>
          </span>
          <span style="margin-left: auto; color: #6E6663; font-size: 13.5px; font-family: 'IBM Plex Mono', monospace;">${sizeMB}</span>
          <span style="display: inline-flex; width: 18px; height: 18px;">${getSiteIcon("download", "#6E6663", 18)}</span>
        </a>`;
      }).join("");

      assetsHTML += `
        <a class="ed-asset" href="${ghData.html_url}" style="display: flex; align-items: center; gap: 14px; text-decoration: none; border: 1.5px solid #F0E7E2; border-radius: 16px; padding: 16px 20px; background: #fff; color: inherit;">
          <span style="width: 42px; height: 42px; border-radius: 12px; background: oklch(0.95 0.035 27); display: grid; place-items: center; flex-shrink: 0;">
            ${getSiteIcon("open", "oklch(0.62 0.22 27)", 22)}
          </span>
          <span style="display: grid; gap: 2px;">
            <span style="font-weight: 700; font-size: 15.5px; color: #231F1E; font-family: 'IBM Plex Mono', monospace;">${SiteState.lang === 'tr' ? 'Kaynak kodu' : 'Source code'}</span>
            <span style="color: #6E6663; font-size: 13.5px;">${SiteState.lang === 'tr' ? 'GitHub üzerinden' : 'Via GitHub'}</span>
          </span>
          <span style="margin-left: auto; color: #6E6663; font-size: 13.5px; font-family: 'IBM Plex Mono', monospace;">—</span>
          <span style="display: inline-flex; width: 18px; height: 18px;">${getSiteIcon("download", "#6E6663", 18)}</span>
        </a>`;
      
      releaseAssets.innerHTML = assetsHTML;
    } else {
      // Fallback
      releaseNotes.innerHTML = t.relNotes.map(n => `
        <li style="display: flex; gap: 10px; align-items: baseline; color: #6E6663; font-size: 15.5px; line-height: 1.5;">
          <span style="width: 7px; height: 7px; border-radius: 99px; background: oklch(0.62 0.22 27); flex-shrink: 0; position: relative; top: -2px;"></span>${n}
        </li>
      `).join("");
      releaseAssets.innerHTML = t.relAssets.map((a, i) => `
        <a class="ed-asset" href="${i === 2 ? SITE.githubUrl : "#"}" style="display: flex; align-items: center; gap: 14px; text-decoration: none; border: 1.5px solid #F0E7E2; border-radius: 16px; padding: 16px 20px; background: #fff; color: inherit;">
          <span style="width: 42px; height: 42px; border-radius: 12px; background: oklch(0.95 0.035 27); display: grid; place-items: center; flex-shrink: 0;">
            ${getSiteIcon(i === 2 ? "open" : "file", "oklch(0.62 0.22 27)", 22)}
          </span>
          <span style="display: grid; gap: 2px;">
            <span style="font-weight: 700; font-size: 15.5px; color: #231F1E; font-family: 'IBM Plex Mono', monospace;">${a.name}</span>
            <span style="color: #6E6663; font-size: 13.5px;">${a.desc}</span>
          </span>
          <span style="margin-left: auto; color: #6E6663; font-size: 13.5px; font-family: 'IBM Plex Mono', monospace;">${a.size}</span>
          <span style="display: inline-flex; width: 18px; height: 18px;">${getSiteIcon("download", "#6E6663", 18)}</span>
        </a>
      `).join("");
    }
  }

  // Initial load and update on state change
  updatePage();
  document.addEventListener("siteStateChanged", updatePage);
  initReveal();
</script>
</body>
</html>
