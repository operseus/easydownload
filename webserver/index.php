<?php
header("Content-Type: text/html; charset=utf-8");
?><!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>EasyDownload — YouTube Video İndirici</title>
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
  .ed-shot { transition: opacity 0.45s ease, transform 0.45s cubic-bezier(0.2, 0.7, 0.2, 1); }
  .ed-shot.hidden-shot { opacity: 0; transform: scale(0.985); position: absolute; inset: 0; pointer-events: none; }
  .ed-frame { transition: transform 0.4s cubic-bezier(0.2, 0.7, 0.2, 1), box-shadow 0.4s ease; }
  .ed-frame:hover { transform: translateY(-4px); box-shadow: 0 40px 90px -22px rgba(35, 31, 30, 0.34); }
  .ed-card { transition: transform 0.35s cubic-bezier(0.2, 0.7, 0.2, 1), box-shadow 0.35s ease; }
  .ed-card:hover { transform: translateY(-6px); box-shadow: 0 22px 44px -24px rgba(35, 31, 30, 0.25); }
</style>
</head>
<body>
<div id="top" style="background: #FFFCFA; color: #231F1E; font-family: 'Outfit', sans-serif; min-height: 100vh;">

  <!-- ===== GRADIENT HERO ===== -->
  <header data-screen-label="hero" style="background: linear-gradient(135deg, oklch(0.55 0.22 20), oklch(0.66 0.21 40)); color: #fff; padding: 0 56px 250px; position: relative; overflow: hidden;">
    <div style="position: absolute; top: 80px; left: -120px; width: 340px; height: 340px; border-radius: 50%; background: rgba(255,255,255,0.07); filter: blur(2px); pointer-events: none;"></div>
    <div style="position: absolute; top: 260px; right: -90px; width: 260px; height: 260px; border-radius: 50%; background: rgba(255,255,255,0.08); pointer-events: none;"></div>
    <div style="position: absolute; top: 40px; right: 28%; width: 90px; height: 90px; border-radius: 50%; background: rgba(255,255,255,0.1); pointer-events: none;"></div>

    <div style="max-width: 1180px; margin: 0 auto; position: relative;">
      <!-- Navigation -->
      <nav style="display: flex; align-items: center; gap: 30px; padding: 22px 0; flex-wrap: wrap;">
        <a href="#top" style="display: flex; align-items: center; gap: 11px; margin-right: auto; text-decoration: none; color: #fff;">
          <img src="logo512.png" alt="EasyDownload" width="40" height="40" style="display: block;" />
          <span style="font-weight: 800; font-size: 21px; letter-spacing: -0.01em;">EasyDownload</span>
        </a>
        <a class="navlink" href="#features" style="color: rgba(255,255,255,0.88); text-decoration: none; font-size: 15.5px; font-weight: 600;">Özellikler</a>
        <a class="navlink" href="#screenshots" style="color: rgba(255,255,255,0.88); text-decoration: none; font-size: 15.5px; font-weight: 600;">Ekran Görüntüleri</a>
        <a class="navlink" href="releases.php" style="color: rgba(255,255,255,0.88); text-decoration: none; font-size: 15.5px; font-weight: 600;">Sürümler</a>
        <a class="navlink" href="https://github.com/operseus/easydownload" style="color: rgba(255,255,255,0.88); text-decoration: none; font-size: 15.5px; font-weight: 600;">GitHub</a>
        <div id="langToggle" style="display: flex; gap: 2px; padding: 3px; border-radius: 999px; border: 1px solid rgba(255,255,255,0.4); align-items: center;"></div>
        <a class="btn" href="releases.php" style="display: inline-flex; align-items: center; gap: 8px; background: #fff; color: #231F1E; border-radius: 999px; padding: 11px 22px; font-size: 15px; font-weight: 700; text-decoration: none;" id="navDownloadBtn"></a>
      </nav>

      <!-- Hero Content -->
      <div style="text-align: center; padding-top: 60px; max-width: 860px; margin: 0 auto;">
        <div class="hero-in d1" style="display: inline-flex; align-items: center; gap: 8px; background: rgba(255,255,255,0.16); border: 1px solid rgba(255,255,255,0.35); border-radius: 999px; padding: 8px 18px; font-size: 14px; font-weight: 600;">Ücretsiz · Reklamsız · Açık Kaynak</div>
        <h1 class="hero-in d2" style="font-size: 66px; line-height: 1.06; letter-spacing: -0.03em; margin: 26px 0 0; font-weight: 800; text-wrap: balance;">
          YouTube videolarını <span style="background: #fff; color: oklch(0.55 0.22 27); border-radius: 16px; padding: 0 16px; display: inline-block; transform: rotate(-1.5deg);">saniyeler içinde</span> indir
        </h1>
        <p class="hero-in d3" style="font-size: 20px; line-height: 1.55; color: rgba(255,255,255,0.92); max-width: 620px; margin: 24px auto 0; text-wrap: pretty;">EasyDownload ile videoları en iyi kalitede MP4 veya MP3 olarak kaydet. Sıraya ekle, geçmişini gör, tek tıkla indir.</p>
        <div class="hero-in d4" style="display: flex; gap: 14px; justify-content: center; margin-top: 40px;" id="heroButtons"></div>
        <p class="hero-in d5" style="font-size: 13.5px; color: rgba(255,255,255,0.75); margin-top: 18px; font-family: 'IBM Plex Mono', monospace;">v1.0.0 · Windows 10 / 11 · 12 MB</p>
      </div>
    </div>
  </header>

  <!-- ===== SCREENSHOTS ===== -->
  <section id="screenshots" data-screen-label="screenshots" style="max-width: 900px; margin: -195px auto 0; padding: 0 24px; position: relative;">
    <div class="ed-frame" style="background: #fff; border-radius: 22px; padding: 14px; box-shadow: 0 32px 80px -20px rgba(35,31,30,0.3);">
      <div style="position: relative; border-radius: 12px; overflow: hidden; background: #0d1117; min-height: 520px;" id="shotContainer"></div>
    </div>
    <div style="display: flex; gap: 8px; justify-content: center; margin-top: 22px; flex-wrap: wrap; row-gap: 12px;" id="shotButtons"></div>
    <p style="text-align: center; color: #6E6663; font-size: clamp(15px, 3vw, 16.5px); margin: 18px auto 0; max-width: 520px; padding: 0 12px;">Light, Dark, Midnight, Sepia — dört yerleşik tema. Gözüne hangisi hoş geliyorsa.</p>
  </section>

  <!-- ===== FEATURES ===== -->
  <section id="features" data-screen-label="features" style="padding: 104px 56px 96px;">
    <h2 data-reveal style="font-size: 42px; letter-spacing: -0.02em; margin: 0; text-align: center; font-weight: 800;">Neden EasyDownload?</h2>
    <p data-reveal style="color: #6E6663; font-size: 18px; text-align: center; margin: 12px 0 48px;">İhtiyacın olan her şey, gereksiz hiçbir şey.</p>
    <div id="featureGrid" style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; max-width: 1100px; margin: 0 auto;"></div>
  </section>

  <!-- ===== DOWNLOAD BAND ===== -->
  <section data-screen-label="download band" data-reveal style="margin: 0 56px 96px;">
    <div style="max-width: 1100px; margin: 0 auto; padding: 72px 48px; text-align: center; background: linear-gradient(135deg, oklch(0.55 0.22 20), oklch(0.66 0.21 40)); border-radius: 32px; color: #fff; position: relative; overflow: hidden;">
      <div style="position: absolute; bottom: -80px; left: -60px; width: 240px; height: 240px; border-radius: 50%; background: rgba(255,255,255,0.08); pointer-events: none;"></div>
      <div style="position: absolute; top: -70px; right: -40px; width: 200px; height: 200px; border-radius: 50%; background: rgba(255,255,255,0.09); pointer-events: none;"></div>
      <img src="logo512.png" alt="" width="64" height="64" style="position: relative;" />
      <h2 style="font-size: 44px; letter-spacing: -0.02em; margin: 20px 0 10px; font-weight: 800; position: relative;">Hemen başla</h2>
      <p style="color: rgba(255,255,255,0.9); font-size: 18.5px; margin: 0 0 36px; position: relative;">EasyDownload'u indir, ilk videonu 30 saniye içinde kaydet.</p>
      <div style="display: flex; gap: 14px; justify-content: center; position: relative;" id="downloadButtons"></div>
    </div>
  </section>

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
  // Screenshot state
  const shots = [
    { src: "ss-dark-download.png", alt: "EasyDownload — dark download screen" },
    { src: "ss-dark-queue.png", alt: "EasyDownload — dark queue screen" },
    { src: "ss-light-dl.png", alt: "EasyDownload — light download screen" },
    { src: "ss-light-download.png", alt: "EasyDownload — light theme" },
    { src: "ss-light-settings.png", alt: "EasyDownload — light settings screen" },
    { src: "ss-sepia-history.png", alt: "EasyDownload — sepia history screen" },
    { src: "ss-sepia-settings.png", alt: "EasyDownload — sepia settings screen" },
  ];

  const featureTints = [
    { bg: "oklch(0.95 0.035 27)", fg: "oklch(0.55 0.2 27)" },
    { bg: "oklch(0.95 0.035 75)", fg: "oklch(0.55 0.2 75)" },
    { bg: "oklch(0.95 0.035 150)", fg: "oklch(0.55 0.15 150)" },
    { bg: "oklch(0.95 0.035 230)", fg: "oklch(0.55 0.15 230)" },
    { bg: "oklch(0.95 0.035 300)", fg: "oklch(0.55 0.18 300)" },
    { bg: "oklch(0.95 0.035 27)", fg: "oklch(0.55 0.2 27)" },
  ];

  function updatePage() {
    const t = SiteContent[SiteState.lang];
    const os = SiteState.os;

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

    // Update shot buttons
    const shotButtons = document.getElementById("shotButtons");
    shotButtons.innerHTML = t.shotTabs.map((label, i) => `
      <button onclick="setSiteShot(${i})" style="border: ${SiteState.shot === i ? "1.5px solid transparent" : "1.5px solid #F0E7E2"}; background: ${SiteState.shot === i ? "linear-gradient(135deg, oklch(0.55 0.22 20), oklch(0.66 0.21 40))" : "#fff"}; color: ${SiteState.shot === i ? "#fff" : "#6E6663"}; border-radius: 999px; padding: 10px 18px; font-size: clamp(13px, 2.5vw, 14.5px); font-weight: 700; font-family: inherit; cursor: pointer; white-space: nowrap; flex-shrink: 0;">
        ${label}
      </button>
    `).join("");

    // Update screenshots
    const shotContainer = document.getElementById("shotContainer");
    shotContainer.innerHTML = shots.map((s, i) => `
      <img class="ed-shot ${SiteState.shot === i ? "" : "hidden-shot"}" src="${s.src}" alt="${s.alt}" style="width: 100%; height: 100%; display: block; object-fit: contain; background-color: #0d1117;" />
    `).join("");

    // Update features grid
    const featureGrid = document.getElementById("featureGrid");
    featureGrid.innerHTML = t.features.map((f, i) => `
      <div class="ed-card" data-reveal style="--rd: ${(i % 3) * 0.1}s; background: ${featureTints[i].bg}; border-radius: 22px; padding: 28px;">
        <span style="width: 52px; height: 52px; border-radius: 16px; background: #fff; display: grid; place-items: center; margin-bottom: 18px;">
          ${getSiteIcon(SITE_FEATURE_ICONS[i], featureTints[i].fg, 26)}
        </span>
        <h3 style="font-size: 20px; margin: 0 0 8px; font-weight: 700;">${f.title}</h3>
        <p style="color: #6E6663; font-size: 15.5px; line-height: 1.6; margin: 0; text-wrap: pretty;">${f.desc}</p>
      </div>
    `).join("");

    // Update OS-dependent buttons
    const osNames = { windows: "Windows", linux: "Linux" };
    const osVersions = t.osVersion;

    // Hero buttons
    document.getElementById("heroButtons").innerHTML = `
      <div class="ed-split" style="position: relative; z-index: 70; display: inline-flex; filter: drop-shadow(0 10px 22px rgba(0,0,0,0.18));">
        <a class="btn" href="releases.php" style="display: inline-flex; align-items: center; gap: 10px; background: #fff; color: #231F1E; border-radius: 999px 0 0 999px; padding: 17px 24px 17px 32px; font-size: 17px; font-weight: 700; text-decoration: none;">
          ${getSiteIcon("download", "#231F1E", 20)}${t.ctaDownloadOs[os]}
        </a>
        <button onclick="this.nextElementSibling.style.display = this.nextElementSibling.style.display === 'none' ? 'block' : 'none'" aria-label="${t.osPick}" style="display: inline-grid; place-items: center; background: #fff; color: #231F1E; border: none; border-left: 1.5px solid #F0E7E2; border-radius: 0 999px 999px 0; padding: 0 18px 0 14px; cursor: pointer; font-family: inherit;">
          <span style="display: inline-flex; transition: transform 0.2s ease;">
            ${getSiteIcon("chevron", "#231F1E", 18)}
          </span>
        </button>
        <div role="listbox" style="position: absolute; right: 0; min-width: 220px; z-index: 60; top: calc(100% + 10px); background: #fff; border-radius: 16px; padding: 6px; box-shadow: 0 18px 48px rgba(35,31,30,0.25); border: 1.5px solid #F0E7E2; display: none;">
          ${["windows", "linux"].map(o => `
            <button role="option" aria-selected="${os === o}" onclick="setSiteOs('${o}'); this.parentElement.style.display = 'none';" style="display: flex; width: 100%; align-items: center; gap: 10px; padding: 13px 16px; border-radius: 11px; border: none; cursor: pointer; text-align: left; background: ${os === o ? "oklch(0.95 0.035 27)" : "transparent"}; font-family: inherit; font-size: 15.5px; font-weight: 700; color: #231F1E;">
              <span style="flex: 1;">${osNames[o]}</span>
              ${os === o ? getSiteIcon("check", "oklch(0.62 0.22 27)", 16) : ""}
            </button>
          `).join("")}
        </div>
      </div>
      <a class="btn" href="https://github.com/operseus/easydownload" style="display: inline-flex; align-items: center; gap: 10px; background: rgba(255,255,255,0.14); color: #fff; border: 1.5px solid rgba(255,255,255,0.45); border-radius: 999px; padding: 17px 32px; font-size: 17px; font-weight: 600; text-decoration: none;">${t.ctaGithub}</a>
    `;

    // Download buttons
    document.getElementById("downloadButtons").innerHTML = `
      <div class="ed-split" style="position: relative; z-index: 70; display: inline-flex; filter: drop-shadow(0 10px 22px rgba(0,0,0,0.18));">
        <a class="btn" href="releases.php" style="display: inline-flex; align-items: center; gap: 10px; background: #fff; color: #231F1E; border-radius: 999px 0 0 999px; padding: 17px 24px 17px 32px; font-size: 17px; font-weight: 700; text-decoration: none;">
          ${getSiteIcon("download", "#231F1E", 20)}${t.ctaDownloadOs[os]}
        </a>
        <button onclick="this.nextElementSibling.style.display = this.nextElementSibling.style.display === 'none' ? 'block' : 'none'" aria-label="${t.osPick}" style="display: inline-grid; place-items: center; background: #fff; color: #231F1E; border: none; border-left: 1.5px solid #F0E7E2; border-radius: 0 999px 999px 0; padding: 0 18px 0 14px; cursor: pointer; font-family: inherit;">
          <span style="display: inline-flex; transition: transform 0.2s ease;">
            ${getSiteIcon("chevron", "#231F1E", 18)}
          </span>
        </button>
        <div role="listbox" style="position: absolute; right: 0; min-width: 220px; z-index: 60; bottom: calc(100% + 10px); background: #fff; border-radius: 16px; padding: 6px; box-shadow: 0 18px 48px rgba(35,31,30,0.25); border: 1.5px solid #F0E7E2; display: none;">
          ${["windows", "linux"].map(o => `
            <button role="option" aria-selected="${os === o}" onclick="setSiteOs('${o}'); this.parentElement.style.display = 'none';" style="display: flex; width: 100%; align-items: center; gap: 10px; padding: 13px 16px; border-radius: 11px; border: none; cursor: pointer; text-align: left; background: ${os === o ? "oklch(0.95 0.035 27)" : "transparent"}; font-family: inherit; font-size: 15.5px; font-weight: 700; color: #231F1E;">
              <span style="flex: 1;">${osNames[o]}</span>
              ${os === o ? getSiteIcon("check", "oklch(0.62 0.22 27)", 16) : ""}
            </button>
          `).join("")}
        </div>
      </div>
      <a class="btn" href="https://github.com/operseus/easydownload" style="display: inline-flex; align-items: center; gap: 10px; background: rgba(255,255,255,0.14); color: #fff; border: 1.5px solid rgba(255,255,255,0.45); border-radius: 999px; padding: 17px 32px; font-size: 17px; font-weight: 600; text-decoration: none;">${t.ctaGithub}</a>
    `;
  }

  // Initial load and update on state change
  updatePage();
  document.addEventListener("siteStateChanged", updatePage);
  initReveal();
</script>
</body>
</html>
