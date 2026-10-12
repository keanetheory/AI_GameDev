// Find where the dock-level walkable region leaks onto the rock above it, and write box positions for invisible barriers.
import fs from "node:fs";
import RAPIER from "file:///C:/GameDev/AI_GameDev/image-blaster/node_modules/.bun/@dimforge+rapier3d-compat@0.19.2/node_modules/@dimforge/rapier3d-compat/rapier.cjs";
const ENV = "C:/GameDev/AI_GameDev/image-blaster/worlds/stormbound-lighthouse-island/environment/";
const OUT = process.argv[2];
const POS = [2.25, 22.275, -22.6], S = 45, LOW = 3.0, MAX_DY = 0.5;
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
for (const [f, p] of [["8-island-collider.glb", true], ["1-gangway.glb", false]]) for (const { v, idx } of load(f, p)) world.createCollider(RAPIER.ColliderDesc.trimesh(v, idx));
world.step();
const CELL = 0.5, X0 = -60, X1 = 60, Z0 = -75, Z1 = 45;
const nx = (X1 - X0) / CELL, nz = (Z1 - Z0) / CELL, H = new Float32Array(nx * nz).fill(NaN);
for (let i = 0; i < nx; i++) for (let k = 0; k < nz; k++) {
  const r = world.castRay(new RAPIER.Ray({ x: X0 + (i + 0.5) * CELL, y: 80, z: Z0 + (k + 0.5) * CELL }, { x: 0, y: -1, z: 0 }), 200, true);
  if (r) H[i * nz + k] = 80 - r.timeOfImpact;
}
const start = Math.floor((0 - X0) / CELL) * nz + Math.floor((-0.5 - Z0) / CELL);
const low = new Uint8Array(nx * nz), q = [start]; low[start] = 1;
const escapes = new Map();
for (let h = 0; h < q.length; h++) {
  const c = q[h], ci = Math.floor(c / nz), ck = c % nz;
  for (let di = -1; di <= 1; di++) for (let dk = -1; dk <= 1; dk++) {
    if (!di && !dk) continue;
    const ni = ci + di, nk = ck + dk; if (ni < 0 || nk < 0 || ni >= nx || nk >= nz) continue;
    const n = ni * nz + nk; if (Number.isNaN(H[n]) || Math.abs(H[n] - H[c]) > MAX_DY * (di && dk ? 1.41 : 1)) continue;
    if (H[n] >= LOW) { escapes.set(n, H[n]); continue; }        // leaves the dock-level region here
    if (!low[n]) { low[n] = 1; q.push(n); }
  }
}
const boxes = [...escapes].map(([n, h]) => ({ x: X0 + (Math.floor(n / nz) + 0.5) * CELL, z: Z0 + ((n % nz) + 0.5) * CELL, y: h }));
console.log(`dock-level region: ${q.length} cells; escape cells onto higher rock: ${boxes.length}`);
const ys = boxes.map((b) => b.y).sort((a, b) => a - b);
console.log(`escape heights: min ${ys[0]?.toFixed(1)} max ${ys.at(-1)?.toFixed(1)}`);
fs.writeFileSync(OUT, JSON.stringify(boxes));
