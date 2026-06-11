// EasyDownload — Releases / download page
function ReleasesPage() {
  const [t, lang, setLang] = useSiteLang();
  useReveal();

  return (
    <div style={{ background: SITE.bg, color: SITE.ink, fontFamily: SITE.font, minHeight: "100vh", display: "flex", flexDirection: "column" }}>
      {/* ===== GRADIENT HEADER ===== */}
      <header data-screen-label="releases header" style={{ background: SITE.grad, color: "#fff", padding: "0 56px 120px", position: "relative", overflow: "hidden" }}>
        <div className="ed-blob" style={{ position: "absolute", top: 30, left: -100, width: 260, height: 260, borderRadius: "50%", background: "rgba(255,255,255,0.07)", pointerEvents: "none" }}></div>
        <div className="ed-blob slow" style={{ position: "absolute", top: 90, right: -70, width: 200, height: 200, borderRadius: "50%", background: "rgba(255,255,255,0.09)", pointerEvents: "none" }}></div>
        <div style={{ maxWidth: 1180, margin: "0 auto", position: "relative" }}>
          <SiteNav t={t} lang={lang} setLang={setLang} page="releases" />
          <div style={{ paddingTop: 40, maxWidth: 720 }}>
            <a href="index.html" className="navlink" style={{ color: "rgba(255,255,255,0.85)", textDecoration: "none", fontSize: 15, fontWeight: 600 }}>{t.backHome}</a>
            <h1 className="hero-in d1" style={{ fontSize: 56, lineHeight: 1.05, letterSpacing: "-0.03em", margin: "16px 0 0", fontWeight: 800 }}>{t.relTitle}</h1>
            <p className="hero-in d2" style={{ fontSize: 19, lineHeight: 1.55, color: "rgba(255,255,255,0.92)", margin: "16px 0 0", textWrap: "pretty" }}>{t.relSub}</p>
          </div>
        </div>
      </header>

      {/* ===== LATEST RELEASE CARD (overlapping) ===== */}
      <main style={{ maxWidth: 880, margin: "-70px auto 0", padding: "0 56px 96px", position: "relative", width: "100%", boxSizing: "border-box", flex: 1 }}>
        <div className="hero-in d3" data-screen-label="latest release" style={{ background: "#fff", border: `1.5px solid ${SITE.border}`, borderRadius: 26, padding: 40, boxShadow: "0 32px 80px -28px rgba(35,31,30,0.28)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 14, flexWrap: "wrap" }}>
            <span style={{ width: 54, height: 54, borderRadius: 16, background: SITE.grad, display: "grid", placeItems: "center" }}>
              <img src="logo512.png" alt="" width="34" height="34" />
            </span>
            <h2 style={{ fontSize: 34, fontWeight: 800, letterSpacing: "-0.02em", margin: 0 }}>v1.0.0</h2>
            <span style={{ background: "oklch(0.95 0.035 150)", color: "oklch(0.45 0.12 150)", borderRadius: 999, padding: "7px 16px", fontSize: 13.5, fontWeight: 700 }}>{t.relLatest}</span>
            <span style={{ marginLeft: "auto", color: SITE.dim, fontSize: 14.5, fontFamily: SITE.mono }}>{t.relDate}</span>
          </div>

          <h3 style={{ fontSize: 17, fontWeight: 700, margin: "32px 0 12px" }}>{t.relNotesTitle}</h3>
          <ul style={{ margin: 0, padding: 0, listStyle: "none", display: "grid", gap: 9 }}>
            {t.relNotes.map((n, i) => (
              <li key={i} style={{ display: "flex", gap: 10, alignItems: "baseline", color: SITE.dim, fontSize: 15.5, lineHeight: 1.5 }}>
                <span style={{ width: 7, height: 7, borderRadius: 99, background: SITE.red, flexShrink: 0, position: "relative", top: -2 }}></span>{n}
              </li>
            ))}
          </ul>

          <h3 style={{ fontSize: 17, fontWeight: 700, margin: "34px 0 12px" }}>{t.relAssetsTitle}</h3>
          <div style={{ display: "grid", gap: 10 }}>
            {t.relAssets.map((a, i) => (
              <a key={i} className="ed-asset" href={i === 2 ? SITE.githubUrl : "#"} style={{
                display: "flex", alignItems: "center", gap: 14, textDecoration: "none",
                border: `1.5px solid ${SITE.border}`, borderRadius: 16, padding: "16px 20px", background: "#fff",
              }}>
                <span style={{ width: 42, height: 42, borderRadius: 12, background: "oklch(0.95 0.035 27)", display: "grid", placeItems: "center", flexShrink: 0 }}>
                  <SiteIcon name={i === 2 ? "open" : "file"} color={SITE.red} size={22} />
                </span>
                <span style={{ display: "grid", gap: 2 }}>
                  <span style={{ fontWeight: 700, fontSize: 15.5, color: SITE.ink, fontFamily: SITE.mono }}>{a.name}</span>
                  <span style={{ color: SITE.dim, fontSize: 13.5 }}>{a.desc}</span>
                </span>
                <span style={{ marginLeft: "auto", color: SITE.dim, fontSize: 13.5, fontFamily: SITE.mono }}>{a.size}</span>
                <SiteIcon name="download" color={SITE.dim} size={18} />
              </a>
            ))}
          </div>
          <p style={{ color: SITE.dim, fontSize: 13.5, margin: "20px 0 0", fontFamily: SITE.mono }}>{t.relRequires}</p>
        </div>

        {/* GitHub band */}
        <div data-reveal style={{ marginTop: 28, textAlign: "center", border: `1.5px dashed ${SITE.border}`, borderRadius: 20, padding: "30px 24px" }}>
          <p style={{ color: SITE.dim, fontSize: 16, margin: "0 0 18px" }}>{t.relAllGithub}</p>
          <BtnGrad href={SITE.githubUrl}><SiteIcon name="open" color="#fff" size={18} />GitHub</BtnGrad>
        </div>
      </main>

      <SiteFooter t={t} />
    </div>
  );
}
Object.assign(window, { ReleasesPage });
