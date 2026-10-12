import fs from "node:fs";
import RAPIER from "file:///C:/GameDev/AI_GameDev/image-blaster/node_modules/.bun/@dimforge+rapier3d-compat@0.19.2/node_modules/@dimforge/rapier3d-compat/rapier.cjs";
const ENV = "C:/GameDev/AI_GameDev/image-blaster/worlds/stormbound-lighthouse-island/environment/";
const POS = [2.25, 22.275, -22.6], S = 45;
const GATE_SOLID = process.argv[2] === "solid";
function load(file, place) {
  const b = fs.readFileSync(ENV + file), jl = b.readUInt32LE(12), json = JSON.parse(b.toString("utf8", 20, 20 + jl)), bs = 20 + jl + 8;
  const rd = (acc, T) => { const a = json.accessors[acc], bv = json.bufferViews[a.bufferView], o = bs + (bv.byteOffset || 0) + (a.byteOffset || 0), n = a.count * ({ SCALAR: 1, VEC3: 3 }[a.type]); return new T(b.buffer.slice(b.byteOffset + o, b.byteOffset + o + n * T.BYTES_PER_ELEMENT)); };
  const out = [];
  for (const prim of json.meshes[0].primitives) {                // every primitive (materials)
    const pos = rd(prim.attributes.POSITION, Float32Array), idx = Uint32Array.from(rd(prim.indices, { 5125: Uint32Array, 5123: Uint16Array }[json.accessors[prim.indices].componentType]));
    const v = new Float32Array(pos.length);
    for (let i = 0; i < pos.length; i += 3) for (let k = 0; k < 3; k++) v[i + k] = place ? pos[i + k] * S + POS[k] : pos[i + k];
    out.push({ v, idx });
  }
  return out;
}
await RAPIER.init();
const world = new RAPIER.World({ x: 0, y: -9.81, z: 0 });
const files = [["8-island-collider.glb", true], ["1-gangway.glb", false], ["4-tunnel.glb", false]];
if (GATE_SOLID) files.push(["1-gate.glb", false]);
for (const [f, place] of files) for (const { v, idx } of load(f, place)) world.createCollider(RAPIER.ColliderDesc.trimesh(v, idx));
const tp = JSON.parse(fs.readFileSync(process.argv[3] ?? "tunnel_path.json", "utf8")).path;   // [x, z, y]
const body = world.createRigidBody(RAPIER.RigidBodyDesc.dynamic().setTranslation(0, 1.05, -0.5).lockRotations());
world.createCollider(RAPIER.ColliderDesc.capsule(0.55, 0.25).setFriction(0.5), body);
for (let i = 0; i < 90; i++) world.step();
const tail = [[10.8,-27.2],[12.2,-28.8],[13.5,-30.2],[14.9,-31.9]];
const route = [[0.0, -6.0], [0.45, -7.4], [1.1, -9.5], [1.7, -11.5], ...tp.map((p) => [p[0], p[1]]), ...tail];
let idx = 0, t = 0, noProg = 0, best = 0, jumps = 0;
while (idx < route.length - 1 && t < 60 * 240) {
  const p = body.translation();
  for (let j = idx; j < Math.min(route.length, idx + 6); j++) if (Math.hypot(route[j][0] - p.x, route[j][1] - p.z) < 0.9) idx = Math.max(idx, j);
  const tg = route[Math.min(idx + 2, route.length - 1)];
  const dx = tg[0] - p.x, dz = tg[1] - p.z, d = Math.hypot(dx, dz) || 1, v = body.linvel();
  let vy = v.y;
  const grounded = world.castRay(new RAPIER.Ray({ x: p.x, y: p.y, z: p.z }, { x: 0, y: -1, z: 0 }), 0.9, true, undefined, undefined, undefined, body);
  if (grounded && t % 25 === 0 && Math.hypot(v.x, v.z) < 1.2) { vy = 3; jumps++; }
  body.setLinvel({ x: (dx / d) * 4, y: vy, z: (dz / d) * 4 }, true);
  world.step(); t++;
  if (idx > best) { best = idx; noProg = 0; } else if (++noProg > 60 * 8) break;
  if (p.y < -5) break;
}
const p = body.translation();
console.log(`gate ${GATE_SOLID ? "SOLID" : "open"}: progressed ${best}/${route.length - 1} route points in ${(t / 60).toFixed(1)}s, jumps ${jumps}`);
console.log(`ended at (${p.x.toFixed(2)}, ${p.y.toFixed(2)}, ${p.z.toFixed(2)}); route end is (${route.at(-1)[0].toFixed(1)}, ~${tp.at(-1)[2].toFixed(1)}, ${route.at(-1)[1].toFixed(1)})`);





