import { copyFileSync, existsSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";

const rootDir = process.cwd();
const outDir = path.join(rootDir, "site");
const featuresSrc = path.join(rootDir, "features.md");
const changelogSrc = path.join(rootDir, "changelog.md");

if (!existsSync(featuresSrc) || !existsSync(changelogSrc)) {
    throw new Error("Missing features.md or changelog.md. Run 'npm run docs:update-diff' first.");
}

rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

copyFileSync(featuresSrc, path.join(outDir, "features.md"));
copyFileSync(changelogSrc, path.join(outDir, "changelog.md"));

const html = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Jellyfin Roku Fork - Diff Docs</title>
  <style>
    :root {
      --bg: #0f1317;
      --panel: #172028;
      --text: #e7edf3;
      --muted: #9db0c4;
      --accent: #2eaadc;
      --border: #2a3946;
      --btn: #243646;
      --btn-active: #2eaadc;
      --btn-active-text: #08131b;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: Segoe UI, Tahoma, sans-serif;
      background: radial-gradient(circle at top right, #1a2833 0%, var(--bg) 45%);
      color: var(--text);
    }
    .wrap {
      max-width: 1100px;
      margin: 0 auto;
      padding: 28px 20px 48px;
    }
    h1 { margin: 0 0 8px; font-size: 28px; }
    .sub { color: var(--muted); margin: 0 0 18px; }
    .toolbar {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      margin-bottom: 16px;
    }
    button {
      background: var(--btn);
      color: var(--text);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 10px 14px;
      cursor: pointer;
      font-weight: 600;
    }
    button.active {
      background: var(--btn-active);
      color: var(--btn-active-text);
      border-color: #5ac2eb;
    }
    .links {
      margin-bottom: 14px;
      color: var(--muted);
      font-size: 14px;
    }
    .links a {
      color: #8cd8f7;
      text-decoration: none;
      margin-right: 12px;
    }
    .panel {
      background: color-mix(in srgb, var(--panel) 86%, #000);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 18px;
      overflow-x: auto;
      line-height: 1.55;
    }
    .panel h1, .panel h2, .panel h3 { margin-top: 1.2em; }
    .panel h1:first-child { margin-top: 0; }
    .panel code {
      background: #223142;
      padding: 1px 5px;
      border-radius: 5px;
    }
    .panel pre {
      background: #1b2a38;
      border: 1px solid #2e4356;
      border-radius: 10px;
      padding: 12px;
      overflow-x: auto;
    }
    .panel table {
      border-collapse: collapse;
      width: 100%;
      margin: 10px 0;
    }
    .panel th, .panel td {
      border: 1px solid #32485d;
      padding: 8px 10px;
      text-align: left;
    }
    .panel th { background: #223242; }
    .footer {
      margin-top: 14px;
      color: var(--muted);
      font-size: 13px;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Jellyfin Roku Fork Documentation</h1>
    <p class="sub">Published from main branch via GitHub Pages workflow.</p>

    <div class="toolbar">
      <button id="btn-features" class="active" type="button">Features</button>
      <button id="btn-changelog" type="button">Changelog</button>
    </div>

    <div class="links">
      <a href="features.md" target="_blank" rel="noopener noreferrer">Raw features.md</a>
      <a href="changelog.md" target="_blank" rel="noopener noreferrer">Raw changelog.md</a>
    </div>

    <div id="content" class="panel">Loading...</div>
    <div id="footer" class="footer"></div>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <script>
    const pages = {
      features: "features.md",
      changelog: "changelog.md"
    };

    const content = document.getElementById("content");
    const footer = document.getElementById("footer");
    const buttons = {
      features: document.getElementById("btn-features"),
      changelog: document.getElementById("btn-changelog")
    };

    function setActive(which) {
      Object.keys(buttons).forEach((key) => {
        buttons[key].classList.toggle("active", key === which);
      });
    }

    async function loadDoc(which) {
      setActive(which);
      content.textContent = "Loading...";

      try {
        const res = await fetch(pages[which], { cache: "no-store" });
        if (!res.ok) {
          throw new Error("HTTP " + res.status);
        }

        const markdown = await res.text();
        if (window.marked && typeof window.marked.parse === "function") {
          content.innerHTML = window.marked.parse(markdown);
        } else {
          content.textContent = markdown;
        }

        footer.textContent = "Showing " + which + ". Last loaded at " + new Date().toLocaleString();
      } catch (err) {
        content.textContent = "Failed to load " + which + ": " + err.message;
      }
    }

    buttons.features.addEventListener("click", () => loadDoc("features"));
    buttons.changelog.addEventListener("click", () => loadDoc("changelog"));

    loadDoc("features");
  </script>
</body>
</html>
`;

writeFileSync(path.join(outDir, "index.html"), html, "utf8");

console.log("GitHub Pages site generated in ./site");
