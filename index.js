const {
  app,
  BrowserWindow,
  protocol,
  ipcMain,
  shell,
} = require("electron");
const path = require("path");
const fs = require("fs");

// The web app (in ./res) was written for a web server: it uses clean,
// extensionless URLs (e.g. window.location.href = "MainControl_one") and
// root-absolute paths (e.g. /manifest.json). file:// cannot reproduce that,
// so we serve ./res behind a custom, secure "app://" protocol that mimics the
// web server's routing. This keeps ./res byte-identical with upstream ear-web.
protocol.registerSchemesAsPrivileged([
  {
    scheme: "app",
    privileges: {
      standard: true,
      secure: true, // secure context -> Web Serial API is allowed
      supportFetchAPI: true,
      stream: true,
    },
  },
]);

const RES_DIR = path.join(__dirname, "res");

const MIME_TYPES = {
  ".html": "text/html",
  ".js": "text/javascript",
  ".mjs": "text/javascript",
  ".css": "text/css",
  ".json": "application/json",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".gif": "image/gif",
  ".webp": "image/webp",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".ttf": "font/ttf",
  ".otf": "font/otf",
  ".eot": "application/vnd.ms-fontobject",
  ".mp4": "video/mp4",
  ".webm": "video/webm",
  ".wav": "audio/wav",
  ".mp3": "audio/mpeg",
};

// Resolve a request pathname to a real file inside ./res, reproducing the
// web server's behaviour (directory -> index.html, clean URL -> add .html).
function resolveResFile(pathname) {
  let rel = decodeURIComponent(pathname);
  if (!rel || rel === "/") rel = "/index.html";

  const target = path.normalize(path.join(RES_DIR, rel));
  // Guard against path traversal outside ./res.
  if (target !== RES_DIR && !target.startsWith(RES_DIR + path.sep)) {
    return null;
  }

  try {
    const stat = fs.statSync(target);
    if (stat.isFile()) return target;
    if (stat.isDirectory()) {
      const index = path.join(target, "index.html");
      if (fs.existsSync(index)) return index;
    }
  } catch (_) {
    // Not a real file as-is; fall through to the clean-URL fallback.
  }

  // Clean URL: "MainControl_one" -> "MainControl_one.html"
  if (fs.existsSync(target + ".html")) return target + ".html";

  return null;
}

function registerAppProtocol() {
  protocol.handle("app", (request) => {
    const { pathname } = new URL(request.url);
    const file = resolveResFile(pathname);

    if (!file) {
      return new Response("Not Found", {
        status: 404,
        headers: { "content-type": "text/plain" },
      });
    }

    const ext = path.extname(file).toLowerCase();
    const data = fs.readFileSync(file);
    return new Response(data, {
      status: 200,
      headers: {
        "content-type": MIME_TYPES[ext] || "application/octet-stream",
      },
    });
  });
}

// ---- Web Serial (Bluetooth SPP) wiring -------------------------------------
// navigator.serial.requestPort() in the renderer triggers "select-serial-port"
// in main. We forward the candidate ports to the renderer (the preload renders
// a picker overlay) and pass the user's choice back through the callback.
let pendingSelectPortCallback = null;

function setupSerialHandlers(targetSession, win) {
  targetSession.on(
    "select-serial-port",
    (event, portList, webContents, callback) => {
      event.preventDefault();

      // Replace any in-flight request (the old one is abandoned by Chromium).
      if (pendingSelectPortCallback) {
        try {
          pendingSelectPortCallback("");
        } catch (_) {}
      }
      pendingSelectPortCallback = callback;

      win.webContents.send("serial:port-list", portList);
    }
  );

  ipcMain.on("serial:select", (_event, portId) => {
    if (pendingSelectPortCallback) {
      const cb = pendingSelectPortCallback;
      pendingSelectPortCallback = null;
      cb(portId || "");
    }
  });

  // Only our own app:// origin may use Web Serial, and only the "serial"
  // permission — everything else (camera, geolocation, notifications, etc.)
  // is denied by default.
  const isOwnOrigin = (origin) => {
    try {
      return new URL(origin).protocol === "app:";
    } catch (_) {
      return false;
    }
  };

  targetSession.setPermissionCheckHandler(
    (_webContents, permission, requestingOrigin) =>
      permission === "serial" && isOwnOrigin(requestingOrigin)
  );
  targetSession.setPermissionRequestHandler(
    (_webContents, permission, callback, details) => {
      callback(permission === "serial" && isOwnOrigin(details.requestingUrl));
    }
  );
  targetSession.setDevicePermissionHandler(
    (details) => details.deviceType === "serial" && isOwnOrigin(details.origin)
  );
}

function createWindow() {
  // Device pages render a fixed 800x710 layout; size the window so they are
  // never clipped.
  const win = new BrowserWindow({
    width: 840,
    height: 790,
    minWidth: 380,
    backgroundColor: "#0C0C0D",
    autoHideMenuBar: true,
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  setupSerialHandlers(win.webContents.session, win);

  // Deny all new windows/popups; open external http(s) links in the OS browser.
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith("http://") || url.startsWith("https://")) {
      shell.openExternal(url);
    }
    return { action: "deny" };
  });

  // The app never navigates away from its own app:// origin — block any
  // attempt (compromised renderer, malicious link) to load something else.
  win.webContents.on("will-navigate", (event, url) => {
    if (!url.startsWith("app://")) {
      event.preventDefault();
      if (url.startsWith("http://") || url.startsWith("https://")) {
        shell.openExternal(url);
      }
    }
  });

  win.loadURL("app://local/index.html");

  return win;
}

// Some Bluetooth-serial filtering (allowedBluetoothServiceClassIds) rides on
// experimental web-platform features in Chromium.
app.commandLine.appendSwitch("enable-experimental-web-platform-features");

app.whenReady().then(() => {
  registerAppProtocol();
  createWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
