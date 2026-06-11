// EasyDownload — landing page (Variation C: vibrant gradient)
function LandingPage() {
  const [t, lang, setLang] = useSiteLang();
  const [os, setOs] = useSiteOs();
  const [shot, setShot] = React.useState(0);
  useReveal();

  const shots = [
    { src: "ss-dark-download.png", alt: "EasyDownload — dark download screen" },
    { src: "ss-dark-queue.png", alt: "EasyDownload — dark queue screen" },
    { src: "ss-light-download.png", alt: "EasyDownload — light theme" },
    { src: "ss-light-dl.png", alt: "EasyDownload — light download screen" },
    { src: "ss-sepia-history.png", alt: "EasyDownload — sepia history screen" },
    { src: "ss-sepia-settings.png", alt: "EasyDownload — sepia settings screen" },
    { src: "ss-light-settings.png", alt: "EasyDownload — light settings screen" }
  ];
  const tints = [
    { bg: "oklch(0.95 0.035 27)", fg: "oklch(0.55 0.2 27)" },
    { bg: "oklch(0.95 0.035 75)", fg: "oklch(0.55 0.2 75)" },
    { bg: "oklch(0.95 0.035 150)", fg: "oklch(0.55 0.15 150)" },
    { bg: "oklch(0.95 0.035 230)", fg: "oklch(0.55 0.15 230)" },
    { bg: "oklch(0.95 0.035 300)", fg: "oklch(0.55 0.18 300)" },
    { bg: "oklch(0.95 0.035 27)", fg: "oklch(0.55 0.2 27)" },
  ];

  return (
    <div id="top" style={{ background: SITE.bg, color: SITE.ink, fontFamily: SITE.font, minHeight: "100vh" }}>
      {/* ===== GRADIENT HERO ===== */}
      <header data-screen-label="hero" style={{ background: SITE.grad, color: "#fff", padding: "0 56px 250px", position: "relative", overflow: "hidden" }}>
        {/* floating decorative blobs */}
        <div className="ed-blob" style={{ position: "absolute", top: 80, left: -120, width: 340, height: 340, borderRadius: "50%", background: "rgba(255,255,255,0.07)", filter: "blur(2px)", pointerEvents: "none" }}></div>
        <div className="ed-blob slow" style={{ position: "absolute", top: 260, right: -90, width: 260, height: 260, borderRadius: "50%", background: "rgba(255,255,255,0.08)", pointerEvents: "none" }}></div>
        <div className="ed-blob slow" style={{ position: "absolute", top: 40, right: "28%", width: 90, height: 90, borderRadius: "50%", background: "rgba(255,255,255,0.1)", pointerEvents: "none" }}></div>

        <div style={{ maxWidth: 1180, margin: "0 auto", position: "relative" }}>
          <SiteNav t={t} lang={lang} setLang={setLang} page="home" />
          <div style={{ textAlign: "center", paddingTop: 60, maxWidth: 860, margin: "0 auto" }}>
            <div className="hero-in d1" style={{ display: "inline-flex", alignItems: "center", gap: 8, background: "rgba(255,255,255,0.16)", border: "1px solid rgba(255,255,255,0.35)", borderRadius: 999, padding: "8px 18px", fontSize: 14, fontWeight: 600 }}>{t.heroBadge}</div>
            <h1 className="hero-in d2" style={{ fontSize: 66, lineHeight: 1.06, letterSpacing: "-0.03em", margin: "26px 0 0", fontWeight: 800, textWrap: "balance" }}>
              {t.heroTitle1} <span style={{ background: "#fff", color: "oklch(0.55 0.22 27)", borderRadius: 16, padding: "0 16px", display: "inline-block", transform: "rotate(-1.5deg)" }}>{t.heroTitleAccent}</span> {t.heroTitle2}
            </h1>
            <p className="hero-in d3" style={{ fontSize: 20, lineHeight: 1.55, color: "rgba(255,255,255,0.92)", maxWidth: 620, margin: "24px auto 0", textWrap: "pretty" }}>{t.heroSub}</p>
            <div className="hero-in d4" style={{ display: "flex", gap: 14, justifyContent: "center", marginTop: 40 }}>
              <DownloadSplitBtn t={t} os={os} setOs={setOs} />
              <BtnGhostLight href={SITE.githubUrl}>{t.ctaGithub}</BtnGhostLight>
            </div>
            <p className="hero-in d5" style={{ fontSize: 13.5, color: "rgba(255,255,255,0.75)", marginTop: 18, fontFamily: SITE.mono }}>{t.osVersion[os]}</p>
          </div>
        </div>
      </header>

      {/* ===== SCREENSHOTS (overlapping gradient) ===== */}
      <section id="screenshots" data-screen-label="screenshots" style={{ maxWidth: 900, margin: "-195px auto 0", padding: "0 56px", position: "relative" }}>
        <div className="ed-frame" style={{ background: "#fff", borderRadius: 22, padding: 14, boxShadow: "0 32px 80px -20px rgba(35,31,30,0.3)" }}>
          <div style={{ position: "relative", borderRadius: 12, overflow: "hidden", background: "#0d1117", minHeight: 520 }}>
            {shots.map((s, i) => (
              <img key={i} className={"ed-shot" + (shot === i ? "" : " hidden-shot")} src={s.src} alt={s.alt} style={{ width: "100%", height: "100%", display: "block", objectFit: "contain", backgroundColor: "#0d1117" }} />
            ))}
          </div>
        </div>
        <div style={{ display: "flex", gap: 8, justifyContent: "center", marginTop: 22, flexWrap: "wrap" }}>
          {t.shotTabs.map((label, i) => (
            <button key={i} onClick={() => setShot(i)} style={{
              border: shot === i ? "1.5px solid transparent" : `1.5px solid ${SITE.border}`,
              background: shot === i ? SITE.grad : "#fff",
              color: shot === i ? "#fff" : SITE.dim,
              borderRadius: 999, padding: "10px 22px", fontSize: 14.5, fontWeight: 700,
              fontFamily: SITE.font, cursor: "pointer", minWidth: 0,
            }}>{label}</button>
          ))}
        </div>
        <p style={{ textAlign: "center", color: SITE.dim, fontSize: 16.5, margin: "18px auto 0", maxWidth: 520 }}>{t.shotsSub}</p>
      </section>

      {/* ===== FEATURES ===== */}
      <section id="features" data-screen-label="features" style={{ padding: "104px 56px 96px" }}>
        <h2 data-reveal style={{ fontSize: 42, letterSpacing: "-0.02em", margin: 0, textAlign: "center", fontWeight: 800 }}>{t.featuresTitle}</h2>
        <p data-reveal style={{ color: SITE.dim, fontSize: 18, textAlign: "center", margin: "12px 0 48px" }}>{t.featuresSub}</p>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 18, maxWidth: 1100, margin: "0 auto" }}>
          {t.features.map((f, i) => (
            <div key={i} className="ed-card" data-reveal style={{ "--rd": `${(i % 3) * 0.1}s`, background: tints[i].bg, borderRadius: 22, padding: 28 }}>
              <span style={{ width: 52, height: 52, borderRadius: 16, background: "#fff", display: "grid", placeItems: "center" }}>
                <SiteIcon name={SITE_FEATURE_ICONS[i]} color={tints[i].fg} size={26} />
              </span>
              <h3 style={{ fontSize: 20, margin: "18px 0 8px", fontWeight: 700 }}>{f.title}</h3>
              <p style={{ color: SITE.dim, fontSize: 15.5, lineHeight: 1.6, margin: 0, textWrap: "pretty" }}>{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ===== DOWNLOAD BAND ===== */}
      <section data-screen-label="download band" data-reveal style={{ margin: "0 56px 96px" }}>
        <div style={{ maxWidth: 1100, margin: "0 auto", padding: "72px 48px", textAlign: "center", background: SITE.grad, borderRadius: 32, color: "#fff", position: "relative", overflow: "hidden" }}>
          <div className="ed-blob" style={{ position: "absolute", bottom: -80, left: -60, width: 240, height: 240, borderRadius: "50%", background: "rgba(255,255,255,0.08)", pointerEvents: "none" }}></div>
          <div className="ed-blob slow" style={{ position: "absolute", top: -70, right: -40, width: 200, height: 200, borderRadius: "50%", background: "rgba(255,255,255,0.09)", pointerEvents: "none" }}></div>
          <img src="logo512.png" alt="" width="64" height="64" style={{ position: "relative" }} />
          <h2 style={{ fontSize: 44, letterSpacing: "-0.02em", margin: "20px 0 10px", fontWeight: 800, position: "relative" }}>{t.downloadTitle}</h2>
          <p style={{ color: "rgba(255,255,255,0.9)", fontSize: 18.5, margin: "0 0 36px", position: "relative" }}>{t.downloadSub}</p>
          <div style={{ display: "flex", gap: 14, justifyContent: "center", position: "relative" }}>
            <DownloadSplitBtn t={t} os={os} setOs={setOs} dropUp={true} />
            <BtnGhostLight href={SITE.githubUrl}>{t.ctaGithub}</BtnGhostLight>
          </div>
        </div>
      </section>

      <SiteFooter t={t} />
    </div>
  );
}
Object.assign(window, { LandingPage });
