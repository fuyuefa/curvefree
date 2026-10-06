import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { access, mkdir, writeFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import handler from 'serve-handler';
import { chromium } from 'playwright';
import lighthouse from 'lighthouse';

const require = createRequire(import.meta.url);
const chromeLauncher = require('chrome-launcher');

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '../..');
const webDist = path.join(repoRoot, 'build', 'web');
const artifactsDir = path.join(__dirname, 'artifacts');

const args = new Set(process.argv.slice(2));
const screenshotOnly = args.has('--screenshot-only');
const lighthouseOnly = args.has('--lighthouse-only');
const skipBuild = args.has('--skip-build');

const thresholds = {
  performance: 0.5,
  accessibility: 0.9,
  'best-practices': 0.8,
};

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function run(command, commandArgs) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, commandArgs, {
      cwd: repoRoot,
      stdio: 'inherit',
      shell: process.platform === 'win32',
      env: {
        ...process.env,
        PATH: `C:\\flutter\\bin;${process.env.PATH ?? ''}`,
      },
    });
    child.on('exit', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`${command} ${commandArgs.join(' ')} exited with ${code}`));
      }
    });
  });
}

async function ensureWebBuild() {
  if (skipBuild) {
    await access(path.join(webDist, 'index.html'));
    return;
  }
  await run('flutter', ['build', 'web', '--release', '--no-wasm-dry-run']);
}

async function startStaticServer() {
  const server = createServer((request, response) =>
    handler(request, response, { public: webDist }),
  );
  await new Promise((resolve) => server.listen(4173, '127.0.0.1', resolve));
  return server;
}

async function waitForPreview(page) {
  await page.waitForFunction(
    () => document.title.includes('曲线自由'),
    undefined,
    { timeout: 120000 },
  );
  await page.waitForSelector('#qa-boot, flutter-view, flt-glass-pane', {
    timeout: 120000,
  });
  // Allow Flutter engine first paint; do not assert CanvasKit glyph text.
  await sleep(6000);
}

async function captureScreenshots(baseUrl) {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage({
      viewport: { width: 390, height: 844 },
    });
    await page.goto(baseUrl, { waitUntil: 'networkidle', timeout: 120000 });
    await waitForPreview(page);

    const boot = page.locator('#qa-boot .brand');
    await boot.waitFor({ state: 'attached', timeout: 30000 });

    await page.screenshot({
      path: path.join(artifactsDir, 'home-mobile.png'),
      fullPage: true,
    });
  } finally {
    await browser.close();
  }
}

async function runLighthouse(baseUrl) {
  // Warm the preview so Lighthouse does not score a blank boot.
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    await page.goto(baseUrl, { waitUntil: 'networkidle', timeout: 120000 });
    await waitForPreview(page);
  } finally {
    await browser.close();
  }

  const chrome = await chromeLauncher.launch({
    chromeFlags: ['--headless', '--no-sandbox', '--disable-gpu'],
  });
  try {
    const result = await lighthouse(baseUrl, {
      port: chrome.port,
      output: 'json',
      logLevel: 'error',
      onlyCategories: ['performance', 'accessibility', 'best-practices'],
      formFactor: 'desktop',
      screenEmulation: { disabled: true },
    });
    const report = Array.isArray(result.report)
      ? result.report.join('')
      : result.report;
    await writeFile(path.join(artifactsDir, 'lighthouse.json'), report);
    return result.lhr;
  } finally {
    await chrome.kill();
  }
}

function collectDefects(lhr) {
  const defects = [];
  if (!lhr) {
    return defects;
  }
  for (const [category, minScore] of Object.entries(thresholds)) {
    const score = lhr.categories[category]?.score ?? 0;
    if (score < minScore) {
      defects.push({
        type: 'lighthouse',
        category,
        score,
        minScore,
        message: `Lighthouse ${category} score ${score} < ${minScore}`,
      });
    }
  }
  return defects;
}

async function main() {
  await mkdir(artifactsDir, { recursive: true });
  const defects = [];

  if (!lighthouseOnly && !screenshotOnly) {
    try {
      await run('flutter', ['analyze']);
    } catch (error) {
      defects.push({ type: 'analyze', message: String(error) });
    }
    try {
      await run('flutter', ['test']);
    } catch (error) {
      defects.push({ type: 'test', message: String(error) });
    }
  }

  try {
    await ensureWebBuild();
  } catch (error) {
    defects.push({ type: 'web-build', message: String(error) });
    await writeFile(
      path.join(artifactsDir, 'defects.json'),
      JSON.stringify({ ok: false, defects }, null, 2),
    );
    process.exitCode = 1;
    return;
  }

  const server = await startStaticServer();
  const baseUrl = 'http://127.0.0.1:4173';
  try {
    if (!lighthouseOnly) {
      try {
        await captureScreenshots(baseUrl);
      } catch (error) {
        defects.push({ type: 'screenshot', message: String(error) });
      }
    }
    if (!screenshotOnly) {
      try {
        const lhr = await runLighthouse(baseUrl);
        defects.push(...collectDefects(lhr));
      } catch (error) {
        defects.push({ type: 'lighthouse', message: String(error) });
      }
    }
  } finally {
    server.close();
  }

  const payload = {
    ok: defects.length === 0,
    generatedAt: new Date().toISOString(),
    defects,
  };
  await writeFile(
    path.join(artifactsDir, 'defects.json'),
    JSON.stringify(payload, null, 2),
  );
  console.log(JSON.stringify(payload, null, 2));
  if (defects.length > 0) {
    process.exitCode = 1;
  }
}

main().catch(async (error) => {
  await mkdir(artifactsDir, { recursive: true });
  const payload = {
    ok: false,
    defects: [{ type: 'fatal', message: String(error) }],
  };
  await writeFile(
    path.join(artifactsDir, 'defects.json'),
    JSON.stringify(payload, null, 2),
  );
  console.error(error);
  process.exitCode = 1;
});
