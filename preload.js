// Preload runs isolated from the page (contextIsolation is on) with Node
// access. Two jobs:
//   1. Render a device picker when main asks the user to choose a serial port.
//   2. Stub the legacy `eel` global (the old Python-backend list flow in
//      control.js references it; the Web Serial flow never uses it) and
//      expose it into the page's world via contextBridge.
const { ipcRenderer, contextBridge } = require("electron");

// --- Bluetooth serial device picker ----------------------------------------
function renderPortPicker(ports) {
  // Clean up any previous picker.
  const existing = document.getElementById("__serial_picker__");
  if (existing) existing.remove();

  const overlay = document.createElement("div");
  overlay.id = "__serial_picker__";
  Object.assign(overlay.style, {
    position: "fixed",
    inset: "0",
    background: "rgba(0,0,0,0.6)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    zIndex: "2147483647",
    fontFamily: "sans-serif",
  });

  const panel = document.createElement("div");
  Object.assign(panel.style, {
    background: "#2b2a28",
    color: "#fff",
    width: "min(420px, 90vw)",
    maxHeight: "80vh",
    overflowY: "auto",
    borderRadius: "16px",
    padding: "20px",
    boxShadow: "0 10px 40px rgba(0,0,0,0.5)",
  });

  const title = document.createElement("div");
  title.textContent = "Select your earbuds";
  Object.assign(title.style, {
    fontSize: "1.15rem",
    fontWeight: "bold",
    marginBottom: "14px",
  });
  panel.appendChild(title);

  const finish = (portId) => {
    overlay.remove();
    ipcRenderer.send("serial:select", portId || "");
  };

  if (!ports || ports.length === 0) {
    const empty = document.createElement("p");
    empty.textContent =
      "No paired earbuds found. Pair your Nothing / CMF buds in your system Bluetooth settings first, then try again.";
    empty.style.lineHeight = "1.4";
    panel.appendChild(empty);
  } else {
    ports.forEach((port) => {
      const label =
        port.displayName ||
        port.portName ||
        (port.deviceId ? port.deviceId : "Unknown device");
      const btn = document.createElement("button");
      btn.textContent = label;
      Object.assign(btn.style, {
        display: "block",
        width: "100%",
        textAlign: "left",
        padding: "12px 14px",
        margin: "6px 0",
        borderRadius: "10px",
        border: "2px solid #444",
        background: "#333",
        color: "#fff",
        cursor: "pointer",
        fontSize: "0.95rem",
      });
      btn.onmouseenter = () => (btn.style.borderColor = "#e82525");
      btn.onmouseleave = () => (btn.style.borderColor = "#444");
      btn.onclick = () => finish(port.portId);
      panel.appendChild(btn);
    });
  }

  const cancel = document.createElement("button");
  cancel.textContent = "Cancel";
  Object.assign(cancel.style, {
    display: "block",
    width: "100%",
    padding: "10px 14px",
    marginTop: "12px",
    borderRadius: "10px",
    border: "none",
    background: "#555",
    color: "#fff",
    cursor: "pointer",
  });
  cancel.onclick = () => finish("");
  panel.appendChild(cancel);

  overlay.appendChild(panel);
  document.body.appendChild(overlay);
}

ipcRenderer.on("serial:port-list", (_event, ports) => {
  if (document.body) {
    renderPortPicker(ports);
  } else {
    window.addEventListener("DOMContentLoaded", () => renderPortPicker(ports));
  }
});

// --- Legacy `eel` stub ------------------------------------------------------
// control.js calls eel.getDevices()(), eel.connectToDevice(mac),
// eel.stopReceivingData(). Those belong to the old Python desktop build and
// are never hit by the Web Serial path, but we stub them so any stray
// reference doesn't throw a ReferenceError. contextBridge doesn't support
// exposing Proxy objects, so the stub is a plain object with the exact
// methods control.js calls.
const eelNoop = () => Promise.resolve(undefined);
contextBridge.exposeInMainWorld("eel", {
  getDevices: () => eelNoop,
  connectToDevice: () => eelNoop,
  stopReceivingData: () => eelNoop,
});
