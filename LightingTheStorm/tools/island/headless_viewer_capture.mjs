// usage: bun cdp.mjs <url> <waitSec> <outPrefix> [scriptFile]
// Launches headless Chrome, loads the page, logs console output, takes screenshots.
// scriptFile (optional) exports default async (cdp, sleep, shot) => {...} for key presses / evals.
import { spawn } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const [url, waitSec = "20", outPrefix = "shot", scriptFile] = process.argv.slice(2);
const chrome = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const port = 9333 + Math.floor(Math.random() * 500);
const profile = fs.mkdtempSync(path.join(os.tmpdir(), "cdp-"));
const proc = spawn(chrome, [
  "--headless=new", `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`,
  "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--enable-webgl",
  "--window-size=1280,720", "--no-first-run", "--no-default-browser-check", "--autoplay-policy=no-user-gesture-required",
  "about:blank",
], { stdio: "ignore" });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let targets;
for (let i = 0; i < 50; i++) {
  try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {}
  await sleep(300);
}
const page = targets.find((t) => t.type === "page");
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));
let id = 0; const pending = new Map(); const logs = [];
ws.onmessage = (m) => {
  const msg = JSON.parse(m.data);
  if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); }
  else if (msg.method === "Runtime.consoleAPICalled") logs.push(`[${msg.params.type}] ` + msg.params.args.map((a) => a.value ?? a.description ?? "").join(" "));
  else if (msg.method === "Runtime.exceptionThrown") logs.push("[EXCEPTION] " + (msg.params.exceptionDetails.exception?.description ?? msg.params.exceptionDetails.text));
  else if (msg.method === "Log.entryAdded") logs.push(`[log:${msg.params.entry.level}] ${msg.params.entry.text} ${msg.params.entry.url ?? ""}`);
};
const cdp = (method, params = {}) => new Promise((res) => { const i = ++id; pending.set(i, res); ws.send(JSON.stringify({ id: i, method, params })); });
const shot = async (name) => {
  const r = await cdp("Page.captureScreenshot", { format: "png" });
  fs.writeFileSync(`${outPrefix}_${name}.png`, Buffer.from(r.result.data, "base64"));
  console.log("SHOT", `${outPrefix}_${name}.png`);
};
await cdp("Runtime.enable"); await cdp("Log.enable"); await cdp("Page.enable");
await cdp("Page.navigate", { url });
await sleep(Number(waitSec) * 1000);
await shot("loaded");
if (scriptFile) {
  const mod = await import("file:///" + scriptFile.replace(/\\/g, "/"));
  await mod.default(cdp, sleep, shot);
}
console.log("CONSOLE (" + logs.length + "):"); for (const l of logs.slice(-40)) console.log("  " + l.slice(0, 300));
ws.close(); proc.kill(); await sleep(500);
try { fs.rmSync(profile, { recursive: true, force: true }); } catch {}
process.exit(0);
