// Can a player reach the summit from the spawn WITHOUT the tunnel? Grid search over the walkable surface.
import fs from "node:fs";
import RAPIER from "file:///C:/GameDev/AI_GameDev/image-blaster/node_modules/.bun/@dimforge+rapier3d-compat@0.19.2/node_modules/@dimforge/rapier3d-compat/rapier.cjs";
const ENV = "C:/GameDev/AI_GameDev/image-blaster/worlds/stormbound-lighthouse-island/environment/";
const POS = [2.25, 22.275, -22.6], S = 45;
const MAX_DY = Number(process.argv[2] ?? 0.35), WITH_TUNNEL = process.argv[3] === "tunnel";
function load(file, place) {
  const b = fs.readFileSync(ENV + file), jl = b.readUInt32LE(12), json = JSON.parse(b.toString("utf8", 20, 20 + jl)), bs = 20 + jl + 8;
  const rd = (acc, T) => { const a = json.accessors[acc], bv = json.bufferViews[a.bufferView], o = bs + (bv.byteOffset || 0) + (a.byteOffset || 0), n = a.count * ({ SCALAR: 1, VEC3: 3 }[a.type]); return new T(b.buffer.slice(b.byteOffset + o, b.byteOffset + o + n * T.BYTES_PER_ELEMENT)); };
  return json.meshes[0].primitives.map((prim) => {
    const pos = rd(prim.attributes.POSITION, Float32Array), idx = Uint32Array.from(rd(prim.indices, { 5125: Uint32Array, 5123: Uint16Array }[json.accessors[prim.indices].componentType]));
    const v = new Float32Array(pos.length);
    for (let i = 0; i < pos.length; i += 3) for (let k = 0; k < 3; k++) v[i + k] = place ? pos[i + k] * S + POS[k] : pos[i + k];
    return { v, idx };
  });
}
await RAPIER.init();
const world = new RAPIER.World({ x: 0, y: -9.81, z: 0 });
const files = [["8-island-collider.glb", true], ["1-gangway.glb", false], ["1-barriers.glb", false]];
if (WITH_TUNNEL) files.push(["4-tunnel.glb", false]);
for (const [f, p] of files) for (const { v, idx } of load(f, p)) world.createCollider(RAPIER.ColliderDesc.trimesh(v, idx));
world.step();
const CELL = 0.5, X0 = -60, X1 = 60, Z0 = -75, Z1 = 45;
const nx = (X1 - X0) / CELL, nz = (Z1 - Z0) / CELL, H = new Float32Array(nx * nz).fill(NaN);
// Highest walkable surface under 2.2 m of clearance: cast from just above each candidate; use top-down hits only
// (tunnel interiors are handled separately by the capsule test, so top-down is right for "outside" routes).
for (let i = 0; i < nx; i++) for (let k = 0; k < nz; k++) {
  const x = X0 + (i + 0.5) * CELL, z = Z0 + (k + 0.5) * CELL;
  const r = world.castRay(new RAPIER.Ray({ x, y: 80, z }, { x: 0, y: -1, z: 0 }), 200, true);
  if (r) H[i * nz + k] = 80 - r.timeOfImpact;
}
const cell = (x, z) => [Math.floor((x - X0) / CELL), Math.floor((z - Z0) / CELL)];
const [si, sk] = cell(0, -0.5), start = si * nz + sk;
const seen = new Uint8Array(nx * nz), q = [start]; seen[start] = 1;
for (let h = 0; h < q.length; h++) {
  const c = q[h], ci = Math.floor(c / nz), ck = c % nz;
  for (let di = -1; di <= 1; di++) for (let dk = -1; dk <= 1; dk++) {
    if (!di && !dk) continue;
    const ni = ci + di, nk = ck + dk; if (ni < 0 || nk < 0 || ni >= nx || nk >= nz) continue;
    const n = ni * nz + nk; if (seen[n] || Number.isNaN(H[n])) continue;
    if (Math.abs(H[n] - H[c]) > MAX_DY * (di && dk ? 1.41 : 1)) continue;
    seen[n] = 1; q.push(n);
  }
}
let maxH = -1e9, maxC = -1, near = 1e9, nearC = -1, summit = 0;
for (const c of q) {
  const x = X0 + (Math.floor(c / nz) + 0.5) * CELL, z = Z0 + ((c % nz) + 0.5) * CELL;
  if (H[c] > maxH) { maxH = H[c]; maxC = c; }
  const d = Math.hypot(x - 14.9, z + 31.9); if (d < near) { near = d; nearC = c; }
  if (H[c] > 13) summit++;
}
const at = (c) => `(${(X0 + (Math.floor(c / nz) + 0.5) * CELL).toFixed(1)}, y=${H[c].toFixed(1)}, ${(Z0 + ((c % nz) + 0.5) * CELL).toFixed(1)})`;
console.log(`${WITH_TUNNEL ? "WITH" : "WITHOUT"} tunnel, step<=${MAX_DY}: reachable cells ${q.length}, cells above y=13: ${summit}`);
console.log(`  highest reachable: ${at(maxC)}   closest to lighthouse base: ${near.toFixed(1)} m at ${at(nearC)}`);

