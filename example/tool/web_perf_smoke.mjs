import { mkdtemp, rm } from 'node:fs/promises';
import { existsSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawn } from 'node:child_process';

const root = resolve(import.meta.dirname, '..');
const webDir = resolve(root, 'build/web');
const serverPort = Number(process.env.LM_WEB_PERF_PORT ?? 8097);
const debugPort = Number(process.env.LM_WEB_DEBUG_PORT ?? 9337);
const chromePath =
  process.env.CHROME_PATH ??
  [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
  ].find((candidate) => existsSync(candidate));

if (!chromePath) {
  throw new Error('Chrome executable not found. Set CHROME_PATH to run smoke.');
}

const userDataDir = await mkdtemp(join(tmpdir(), 'lm-router-chrome-'));
const server = spawn(
  'python3',
  ['-m', 'http.server', String(serverPort), '--directory', webDir],
  { stdio: 'ignore' },
);
const chrome = spawn(
  chromePath,
  [
    '--headless=new',
    '--disable-gpu',
    '--no-first-run',
    '--no-default-browser-check',
    `--remote-debugging-port=${debugPort}`,
    `--user-data-dir=${userDataDir}`,
    '--window-size=1200,900',
    `http://127.0.0.1:${serverPort}`,
  ],
  { stdio: 'ignore' },
);

let cdp;
let nextId = 1;
const callbacks = new Map();
const runtimeErrors = [];
let stage = 'startup';
try {
  cdp = await connectToChrome(debugPort);
  installCdpHandlers();
  await send('Page.enable');
  await send('Runtime.enable');
  await send('Log.enable');
  await send('Emulation.setDeviceMetricsOverride', {
    width: 1200,
    height: 900,
    deviceScaleFactor: 1,
    mobile: false,
  });

  await waitForFlutterFrame(10000);
  const initialShot = await screenshotData();

  stage = 'open-orders';
  await click(110, 175);
  await delay(300);

  stage = 'rapid-navigation';
  const started = performance.now();
  await click(420, 240);
  await delay(90);
  await click(420, 325);
  await delay(90);
  await click(420, 240);
  await delay(900);
  const rapidNavigationMs = performance.now() - started;
  const detailShot = await screenshotData();
  const detailPath = await currentAppPath();

  if (rapidNavigationMs > 3000) {
    throw new Error(
      `Rapid tablet navigation took ${rapidNavigationMs.toFixed(1)}ms`,
    );
  }
  assertUsefulScreenshot(initialShot, 'initial');
  assertUsefulScreenshot(detailShot, 'detail');
  if (initialShot === detailShot) {
    throw new Error('Rapid navigation screenshot did not change.');
  }
  if (!detailPath.startsWith('/orders/')) {
    throw new Error(`Tablet detail click did not update URL: ${detailPath}`);
  }

  stage = 'same-route-spam';
  await moveMouse(20, 850);
  await delay(150);
  const stablePath = await currentAppPath();
  const spamStarted = performance.now();
  for (let index = 0; index < 6; index += 1) {
    await click(420, 240);
    await delay(40);
  }
  await delay(250);
  const sameRouteMs = performance.now() - spamStarted;
  await moveMouse(20, 850);
  await delay(150);
  const afterStableShot = await screenshotData();
  const afterStablePath = await currentAppPath();
  assertUsefulScreenshot(afterStableShot, 'same-route-spam');
  if (sameRouteMs > 1500) {
    throw new Error(`Same-route spam took ${sameRouteMs.toFixed(1)}ms`);
  }
  if (afterStablePath !== stablePath) {
    throw new Error(
      `Same-route spam changed the route: ${stablePath} -> ${afterStablePath}`,
    );
  }

  stage = 'open-action-sheet';
  await callSmokeBridge('lmRouterSmokePresent', '/orders/1042/actions');
  await delay(500);
  const actionSheetShot = await screenshotData();
  const actionSheetPath = await currentAppPath();
  assertUsefulScreenshot(actionSheetShot, 'action-sheet');
  if (actionSheetShot === detailShot) {
    throw new Error('Action sheet screenshot did not change.');
  }
  if (!actionSheetPath.endsWith('/orders/1042/actions')) {
    const screenshotPath = '/tmp/lm_router_action_sheet_url_failure.png';
    await saveScreenshot(screenshotPath);
    throw new Error(
      `Action sheet route did not update URL: ${actionSheetPath} state=${await historyState()} router=${await smokeState()}`,
    );
  }

  stage = 'open-bottom-sheet';
  await callSmokeBridge('lmRouterSmokePop');
  await delay(550);
  await callSmokeBridge('lmRouterSmokePresent', '/orders/1042/reschedule');
  await delay(700);
  const bottomSheetShot = await screenshotData();
  const bottomSheetPath = await currentAppPath();
  assertUsefulScreenshot(bottomSheetShot, 'bottom-sheet');
  if (bottomSheetShot === actionSheetShot) {
    throw new Error('Bottom sheet screenshot did not change.');
  }
  if (!bottomSheetPath.endsWith('/orders/1042/reschedule')) {
    throw new Error(`Bottom sheet route did not update URL: ${bottomSheetPath}`);
  }

  stage = 'browser-back-dismisses-bottom-sheet';
  await historyBack();
  await waitForAppPath('/orders/1042', 5000);
  await delay(1200);
  const afterBackShot = await screenshotData();
  assertUsefulScreenshot(afterBackShot, 'browser-back-detail');
  if (afterBackShot === bottomSheetShot) {
    await saveScreenshot('/tmp/lm_router_browser_back_failure.png');
    throw new Error('Browser back did not dismiss the bottom sheet frame.');
  }

  stage = 'browser-forward-restores-bottom-sheet';
  await historyForward();
  await waitForAppPath('/orders/1042/reschedule', 5000);
  await delay(1200);
  const afterForwardShot = await screenshotData();
  assertUsefulScreenshot(afterForwardShot, 'browser-forward-bottom-sheet');
  if (afterForwardShot === afterBackShot) {
    await saveScreenshot('/tmp/lm_router_browser_forward_failure.png');
    throw new Error('Browser forward did not restore the bottom sheet frame.');
  }

  stage = 'open-heavy-view';
  const heavyStarted = performance.now();
  await callSmokeBridge('lmRouterSmokeGo', '/lab/heavy');
  await waitForAppPath('/lab/heavy', 5000);
  await delay(1200);
  const heavyRouteMs = performance.now() - heavyStarted;
  const heavyShot = await screenshotData();
  assertUsefulScreenshot(heavyShot, 'heavy-view');
  if (heavyRouteMs > 3000) {
    throw new Error(`Heavy route took ${heavyRouteMs.toFixed(1)}ms`);
  }
  if (heavyShot === afterForwardShot) {
    await saveScreenshot('/tmp/lm_router_heavy_view_failure.png');
    throw new Error('Heavy view screenshot did not change.');
  }

  if (runtimeErrors.length > 0) {
    throw new Error(`Runtime errors: ${runtimeErrors.join(' | ')}`);
  }

  console.log(
    `web_perf_smoke_pass rapid_navigation_ms=${rapidNavigationMs.toFixed(1)} same_route_ms=${sameRouteMs.toFixed(1)} heavy_route_ms=${heavyRouteMs.toFixed(1)} screenshots=${[
      initialShot.length,
      detailShot.length,
      actionSheetShot.length,
      bottomSheetShot.length,
      afterBackShot.length,
      afterForwardShot.length,
      heavyShot.length,
    ].join(',')}`,
  );
} finally {
  cdp?.close();
  chrome.kill('SIGTERM');
  server.kill('SIGTERM');
  try {
    await rm(userDataDir, {
      recursive: true,
      force: true,
      maxRetries: 3,
      retryDelay: 100,
    });
  } catch {
    // Chrome can keep a profile file open for a moment after SIGTERM.
  }
}

async function connectToChrome(port) {
  const deadline = Date.now() + 10000;
  let wsUrl;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(`http://127.0.0.1:${port}/json`);
      if (response.ok) {
        const targets = await response.json();
        wsUrl = targets.find((target) => target.type === 'page')
          ?.webSocketDebuggerUrl;
        if (wsUrl) {
          break;
        }
      }
    } catch {
      await delay(100);
    }
  }
  if (!wsUrl) {
    throw new Error('Chrome remote debugging endpoint did not start.');
  }
  const socket = new WebSocket(wsUrl);
  await new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, { once: true });
    socket.addEventListener('error', reject, { once: true });
  });
  return socket;
}

function send(method, params = {}) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    callbacks.set(id, { resolve, reject });
    cdp.send(JSON.stringify({ id, method, params }));
  });
}

function installCdpHandlers() {
  cdp.addEventListener('message', (event) => {
    const message = JSON.parse(event.data);
    if (message.method === 'Runtime.exceptionThrown') {
      return;
    }
    if (message.method === 'Log.entryAdded') {
      const entry = message.params?.entry;
      if (entry?.level === 'error') {
        runtimeErrors.push(entry.text ?? 'Log.entryAdded');
      }
      return;
    }
    if (!message.id) {
      return;
    }
    const callback = callbacks.get(message.id);
    callbacks.delete(message.id);
    if (!callback) {
      return;
    }
    if (message.error) {
      callback.reject(new Error(message.error.message));
    } else {
      callback.resolve(message.result);
    }
  });
}

async function click(x, y) {
  await moveMouse(x, y);
  await delay(40);
  await send('Input.dispatchMouseEvent', {
    type: 'mousePressed',
    x,
    y,
    button: 'left',
    clickCount: 1,
  });
  await send('Input.dispatchMouseEvent', {
    type: 'mouseReleased',
    x,
    y,
    button: 'left',
    clickCount: 1,
  });
}

async function tap(x, y) {
  await send('Input.dispatchTouchEvent', {
    type: 'touchStart',
    touchPoints: [{ x, y, radiusX: 1, radiusY: 1 }],
  });
  await delay(40);
  await send('Input.dispatchTouchEvent', {
    type: 'touchEnd',
    touchPoints: [],
  });
}

async function moveMouse(x, y) {
  await send('Input.dispatchMouseEvent', {
    type: 'mouseMoved',
    x,
    y,
    button: 'none',
  });
}

async function waitForFlutterFrame(timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const result = await send('Runtime.evaluate', {
      expression: `
        Boolean(
          document.querySelector('flutter-view') ||
          document.querySelector('flt-glass-pane') ||
          document.querySelector('canvas')
        )
      `,
      returnByValue: true,
    });
    const shot = await screenshotData();
    if (result.result?.value === true && shot.length > 20000) {
      return;
    }
    await delay(100);
  }
  const location = await currentLocation();
  const screenshotPath = '/tmp/lm_router_web_perf_failure.png';
  await saveScreenshot(screenshotPath);
  throw new Error(
    `Timed out waiting for Flutter frame. Location: ${location}. Screenshot: ${screenshotPath}`,
  );
}

async function currentLocation() {
  const result = await send('Runtime.evaluate', {
    expression: 'window.location.href',
    returnByValue: true,
  });
  return result.result?.value ?? '';
}

async function currentAppPath() {
  const result = await send('Runtime.evaluate', {
    expression: `
      (() => {
        const url = new URL(window.location.href);
        if (url.hash && url.hash.startsWith('#/')) {
          return url.hash.slice(1);
        }
        return url.pathname + url.search + url.hash;
      })()
    `,
    returnByValue: true,
  });
  return result.result?.value ?? '';
}

async function historyState() {
  const result = await send('Runtime.evaluate', {
    expression: 'JSON.stringify(window.history.state)',
    returnByValue: true,
  });
  return result.result?.value ?? '';
}

async function smokeState() {
  const result = await send('Runtime.evaluate', {
    expression:
      'typeof window.lmRouterSmokeState === "function" ? window.lmRouterSmokeState() : "<missing>"',
    returnByValue: true,
  });
  return result.result?.value ?? '';
}

async function callSmokeBridge(name, argument) {
  const expression =
    argument === undefined
      ? `window.${name}()`
      : `window.${name}(${JSON.stringify(argument)})`;
  const result = await send('Runtime.evaluate', {
    expression: `
      (() => {
        if (typeof window.${name} !== 'function') {
          throw new Error('${name} is not installed');
        }
        return ${expression};
      })()
    `,
    returnByValue: true,
    awaitPromise: true,
  });
  return result.result?.value;
}

async function historyBack() {
  await send('Runtime.evaluate', {
    expression: 'window.history.back()',
    returnByValue: true,
  });
}

async function historyForward() {
  await send('Runtime.evaluate', {
    expression: 'window.history.forward()',
    returnByValue: true,
  });
}

async function waitForAppPath(expectedSuffix, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const path = await currentAppPath();
    if (path.endsWith(expectedSuffix)) {
      return;
    }
    await delay(100);
  }
  throw new Error(
    `Timed out waiting for app path ${expectedSuffix}; current=${await currentAppPath()}`,
  );
}

async function saveScreenshot(path) {
  writeFileSync(path, Buffer.from(await screenshotData(), 'base64'));
}

async function screenshotData() {
  const result = await send('Page.captureScreenshot', { format: 'png' });
  return result.data;
}

function assertUsefulScreenshot(data, label) {
  if (data.length < 30000) {
    throw new Error(`${label} screenshot looks blank: ${data.length} bytes`);
  }
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
