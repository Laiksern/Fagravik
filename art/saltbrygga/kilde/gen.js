// Saltbrygga – prosedyregenerert pikselkunst i 640×360-oppløsning, etter Fagravik stilguide v0.2.
// Lagene tegnes i spillets piksler. Gulvlinjen (der Ingrid går) er y = 312, som i prototypen.
(function (root) {
  'use strict';
  const H = 360, FLOOR = 312;

  // ---------------------------------------------------------------- farger
  const hexrgb = h => [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
  const toHex = c => '#' + c.map(v => Math.max(0, Math.min(255, Math.round(v / 4) * 4)).toString(16).padStart(2, '0')).join('');
  const mix = (a, b, t) => { const A = hexrgb(a), B = hexrgb(b); return toHex(A.map((v, i) => v + (B[i] - v) * t)); };
  const dark = (h, t) => mix(h, '#000000', t), light = (h, t) => mix(h, '#ffffff', t);
  const bayer = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]];

  // Lyssettingene følger prototypens faser. "dag" = formiddag.
  const PH = {
    morgen:      { sky: ['#3d4a73', '#8a6f9e', '#e39b8a', '#f4cf9a', '#fbe7c0'], orb: '#fff1c7', orbX: 150, orbY: 150, halo: '#f4cf9a', far: '#9a8db0', mid: '#6a6a8c', hill: '#5e6a46', snow: '#f6e8ee', water: '#7a86ad', wave: '#f0c0a0', wood: '#6b4a3a', wood2: '#8a6a52', tar: '#3a2a2a', turf: '#7c7a42', birch: '#e8b84a', win: '#2a2430', lit: false, church: '#3a2c2a', pine: '#3b4652', stone: '#7a7472', mist: '#efd3cc', hull: '#3a2a2a', sail: '#e8d8c8', rope: '#c8b088', smoke: '#d9c0c8', river: '#8a7a6a' },
    dag:         { sky: ['#3f7fc0', '#5f9fd6', '#8fc3e6', '#b9dcee', '#dcecf3'], orb: '#fffbe8', orbX: 470, orbY: 36, halo: '#dff3fb', far: '#7a9db0', mid: '#4f7a6a', hill: '#5f8a32', snow: '#f8fbfb', water: '#2f6f8f', wave: '#a8dceb', wood: '#6a4630', wood2: '#9a7048', tar: '#2e2420', turf: '#5f8a32', birch: '#f0c23a', win: '#1e2226', lit: false, church: '#2e2420', pine: '#24453a', stone: '#8a949a', mist: null, hull: '#2e2420', sail: '#d9cdb4', rope: '#c9a477', smoke: '#e8ecec', river: '#6f7a62' },
    ettermiddag: { sky: ['#4a6aa8', '#7a92c0', '#c8b6a8', '#e8c088', '#f2d49a'], orb: '#fff4d0', orbX: 560, orbY: 110, halo: '#f6d8a0', far: '#8a90a8', mid: '#5a7262', hill: '#6a8a3a', snow: '#f8ecd8', water: '#3a6a8a', wave: '#e8c088', wood: '#6a4630', wood2: '#a07848', tar: '#2e2420', turf: '#688a36', birch: '#f0b83a', win: '#262226', lit: false, church: '#2e2420', pine: '#2a4a3a', stone: '#8c8a84', mist: null, hull: '#2e2420', sail: '#d9cdb4', rope: '#c9a477', smoke: '#e8e0d0', river: '#6f7262' },
    kveld:       { sky: ['#2a2350', '#5a3a6e', '#a0505e', '#d8784e', '#f0a050'], orb: '#ffd890', orbX: 110, orbY: 216, halo: '#f6b070', far: '#6a5276', mid: '#463a5a', hill: '#4a4a3a', snow: '#f4c8a4', water: '#3e3a5e', wave: '#f0a050', wood: '#4a3036', wood2: '#6a4a44', tar: '#24181e', turf: '#4a4a36', birch: '#c8803a', win: '#ffcf6a', lit: true, church: '#24181e', pine: '#262838', stone: '#5a4e56', mist: null, hull: '#24181e', sail: '#c8a088', rope: '#9a7a5a', smoke: '#8a6a78', river: '#4a3e52' },
    natt:        { sky: ['#060b1c', '#0b1428', '#122040', '#1a2c50', '#1f3458'], orb: '#e8ecdc', orbX: 520, orbY: 50, halo: '#2c3e64', far: '#1c2a44', mid: '#141c32', hill: '#182028', snow: '#8a9ec0', water: '#0e1a30', wave: '#3a5a8a', wood: '#1e1c26', wood2: '#2c2834', tar: '#0e0e16', turf: '#1c2428', birch: '#3a3a3a', win: '#ffc860', lit: true, church: '#0e0e16', pine: '#0c141c', stone: '#262a36', mist: null, hull: '#0e0e16', sail: '#4a5468', rope: '#4a4a50', smoke: '#2a3246', stars: true, lantern: true, river: '#101828' },
  };

  // ---------------------------------------------------------------- lag
  // bredde i px og parallaksefaktor (1 = følger kameraet, 0 = står stille)
  const LAYERS = [
    { id: 'himmel',   w: 640,  par: 0 },
    { id: 'fjell',    w: 900,  par: 0.25 },
    { id: 'bakken',   w: 1140, par: 0.55 },
    { id: 'brygga',   w: 1568, par: 1 },
    { id: 'forgrunn', w: 1720, par: 1.2 },
  ];
  const ROOM_W = 1568; // 2400 verdensenheter × 0,653

  function make(layerId, phase) {
    const L = LAYERS.find(l => l.id === layerId), p = PH[phase];
    const cv = (typeof OffscreenCanvas !== 'undefined') ? new OffscreenCanvas(L.w, H) : Object.assign(document.createElement('canvas'), { width: L.w, height: H });
    const ctx = cv.getContext('2d');
    const W = L.w;
    let seed = 1;
    const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    const R = (x, y, w, h, c) => { ctx.fillStyle = c; ctx.fillRect(Math.round(x), Math.round(y), Math.max(1, Math.round(w)), Math.max(1, Math.round(h))); };
    const P = (x, y, c) => R(x, y, 1, 1, c);
    const disc = (cx, cy, r, c) => { for (let dy = -r; dy <= r; dy++) { const dx = Math.floor(Math.sqrt(r * r - dy * dy)); R(cx - dx, cy + dy, dx * 2 + 1, 1, c); } };
    const dith = (x, y, t) => t * 16 > bayer[y & 3][x & 3];
    function gradient(y0, y1, cols, x0 = 0, x1 = W, steps = 10) {
      const n = cols.length - 1;
      for (let y = y0; y < y1; y++) {
        const t = (y - y0) / (y1 - y0) * n, i = Math.min(Math.floor(t), n - 1), f = t - i, q = f * steps, lo = Math.floor(q), fr = q - lo;
        const a = mix(cols[i], cols[i + 1], lo / steps), b = mix(cols[i], cols[i + 1], Math.min(1, (lo + 1) / steps));
        for (let x = x0; x < x1; x++) P(x, y, dith(x, y, fr) ? b : a);
      }
    }
    const S = { ctx, W, p, R, P, disc, dith, gradient, rnd, reset: s => { seed = s; } };
    ({ himmel, fjell, bakken, brygga, forgrunn })[layerId](S);
    return cv;
  }

  // ---------------------------------------------------------------- 1 himmel
  function himmel(S) {
    const { p, W, R, P, disc, gradient, rnd } = S;
    gradient(0, H, p.sky);
    if (p.stars) { S.reset(3); for (let i = 0; i < 170; i++) { const b = rnd(); P(rnd() * W, rnd() * 200, b > .85 ? '#ffffff' : b > .5 ? '#9fb2d6' : '#55688c'); } }
    const band = p.sky[Math.min(4, Math.floor(p.orbY / H * 4) + 1)];
    [40, 34, 29, 24, 20, 16, 13].forEach((r, i) => disc(p.orbX, p.orbY, r, mix(band, p.halo, .1 + i * .11)));
    disc(p.orbX, p.orbY, 11, p.orb);
    if (p.stars) disc(p.orbX + 6, p.orbY - 3, 10, p.sky[2]);
    // tynne skyer
    S.reset(17);
    const cc = p.stars ? mix(p.sky[2], '#ffffff', .08) : mix(p.sky[1], p.halo, .35);
    for (let i = 0; i < 9; i++) { const cx = rnd() * W, cy = 30 + rnd() * 120, len = 40 + rnd() * 90;
      for (let k = 0; k < 3; k++) { const yy = cy + k * 2, w = len * (1 - k * .25); R(cx - w / 2 + k * 6, yy, w, 1, k === 0 ? light(cc, .1) : cc); } }
  }

  // ---------------------------------------------------------------- 2 fjell
  function fjell(S) {
    const { p, W, R, P, gradient, rnd } = S;
    const sb = p.sky[4];
    const farTop = x => 158 + 30 * Math.sin(x * .011 + 1) + 12 * Math.sin(x * .031 + 2) + 5 * Math.sin(x * .09) + 2 * Math.sin(x * .3);
    const shadeOf = (fn, x) => { let a = 0; for (let k = -24; k <= 24; k += 8) a += fn(x + k - 12) - fn(x + k + 12); return Math.max(-1, Math.min(1, a / 7 / 16)); };
    for (let x = 0; x < W; x++) { const t = Math.floor(farTop(x)), s = shadeOf(farTop, x); const base = s > 0 ? light(p.far, .12 * s) : dark(p.far, -.18 * s);
      for (let y = t; y < 300; y++) { const haze = Math.min(.6, (y - t) / (300 - t) * .8); let c = mix(base, sb, haze);
        if (t < 165 && y < t + Math.max(3, (165 - t) * .9)) c = mix(p.snow, c, Math.min(1, (y - t) / Math.max(4, 165 - t))); P(x, y, c); } }
    // nærmere fjordvegg med granskog
    const midTop = x => 214 + 18 * Math.sin(x * .017 + 4) + 7 * Math.sin(x * .05 + 1);
    for (let x = 0; x < W; x++) { const t = Math.floor(midTop(x)); for (let y = t; y < 320; y++) P(x, y, mix(p.mid, sb, Math.min(.35, (y - t) / 120 * .5))); }
    S.reset(11);
    for (let row = 0; row < 3; row++) for (let x = row * 2; x < W; x += 5 + Math.floor(rnd() * 3)) { const base = Math.floor(midTop(x)) + 4 + row * 9 + Math.floor(rnd() * 4), h = 8 + Math.floor(rnd() * 6), c = mix(row === 0 ? p.pine : dark(p.pine, .15), sb, .15 + row * .05);
      for (let i = 0; i < h; i++) { const w = Math.floor(i / 2.4) * 2 + 1; R(x - (w >> 1), base - h + i, w, 1, c); } }
  }

  // ---------------------------------------------------------------- 3 bakken (Kirkebakken, Storbrua, bakre hus)
  function bakken(S) {
    const { p, W, R, P, disc, rnd } = S;
    const sb = p.sky[4];
    const hillTop = x => 236 + 10 * Math.sin(x * .012 + 2) + 4 * Math.sin(x * .04) - (x > 380 && x < 760 ? 26 * Math.sin((x - 380) / 380 * Math.PI) : 0) + (x > 150 && x < 470 ? 18 * Math.sin((x - 150) / 320 * Math.PI) : 0);
    // elva kommer inn fra venstre bak brua: vann der bakken er lav
    for (let x = 0; x < W; x++) { const t = Math.floor(hillTop(x)); for (let y = t; y < H; y++) { const c = y < t + 3 ? light(p.hill, .15) : mix(p.hill, sb, Math.min(.25, (y - t) / 150)); P(x, y, c); } }
    // elvemunning bak brua
    for (let x = 170; x < 450; x++) { const edge = 232 + 10 * Math.sin((x - 170) / 280 * Math.PI) ; for (let y = Math.floor(edge); y < H; y++) P(x, y, mix(p.river, p.water, (y - edge) / 100)); }
    S.reset(9); for (let i = 0; i < 60; i++) R(180 + rnd() * 260, 240 + rnd() * 80, 3 + rnd() * 8, 1, mix(p.wave, p.river, .6));
    // Storbrua: majestetisk trebru over elva
    const bx0 = 160, bx1 = 460, by = 204;
    R(bx0, by, bx1 - bx0, 4, p.wood2); R(bx0, by, bx1 - bx0, 1, light(p.wood2, .25)); R(bx0, by + 4, bx1 - bx0, 2, dark(p.wood, .2));
    R(bx0, by - 8, bx1 - bx0, 1, p.wood); for (let x = bx0; x <= bx1; x += 7) R(x, by - 8, 1, 8, p.wood);
    for (let x = bx0 + 14; x < bx1; x += 34) { R(x, by + 6, 3, 60, dark(p.wood, .15)); R(x - 4, by + 6, 11, 2, p.wood); R(x - 6, by + 30, 15, 2, dark(p.wood, .3)); for (let k = 0; k < 3; k++) { R(x - 6 + k, by + 8 + k * 3, 1, 1, light(p.wood, .1)); R(x + 8 - k, by + 8 + k * 3, 1, 1, light(p.wood, .1)); } }
    // Kirkebakken: stein mur, bjørker og stavkirken med spir
    const cx = 560, cb = Math.floor(hillTop(cx)) + 2, ch = p.church, sh = dark(ch, .3), ro = light(ch, .14);
    R(cx - 26, cb - 24, 52, 24, ch); for (let i = 0; i < 24; i += 3) R(cx - 26, cb - 24 + i, 52, 1, sh);
    roofRows(S, cx, cb - 36, 30, 60, 12, i => i & 1 ? ro : ch);
    R(cx - 15, cb - 52, 30, 16, ch); for (let i = 0; i < 16; i += 3) R(cx - 15, cb - 52 + i, 30, 1, sh);
    roofRows(S, cx, cb - 62, 16, 38, 10, i => i & 1 ? ro : ch);
    R(cx - 6, cb - 82, 12, 20, ch); roofRows(S, cx, cb - 100, 2, 18, 18, i => i & 1 ? ro : ch);
    R(cx, cb - 110, 1, 10, ch); R(cx - 2, cb - 107, 5, 1, ch);
    for (let k = 0; k < 4; k++) { R(cx - 30 - k, cb - 36 + k * 2, 1, 1, ro); R(cx + 30 + k, cb - 36 + k * 2, 1, 1, ro); }
    R(cx - 3, cb - 16, 6, 16, p.lit ? p.win : dark(ch, .5)); R(cx + 16, cb - 20, 4, 7, p.lit ? p.win : dark(ch, .5)); R(cx - 20, cb - 20, 4, 7, p.lit ? p.win : dark(ch, .5));
    // kirkegårdsmur
    for (let x = cx - 70; x < cx + 80; x += 1) { const t = Math.floor(hillTop(x)) + 6; R(x, t, 1, 7, (x % 5 === 0) ? dark(p.stone, .3) : p.stone); P(x, t, light(p.stone, .2)); }
    // bjørker på bakken
    S.reset(5);
    for (let i = 0; i < 34; i++) { const x = Math.floor(rnd() * W), base = Math.floor(hillTop(x)) + 8 + Math.floor(rnd() * 30); if (x > 150 && x < 470 && base > 228) continue; if (x > cx - 40 && x < cx + 40) continue; const s = 1 + (rnd() > .5 ? 1 : 0), r = 2 + s * 2, cy = base - 4 * s - r;
      R(x, base - 6 * s, 1, 6 * s, p.snow); P(x, base - 3 * s, dark(p.snow, .4));
      disc(x, cy, r, p.birch); disc(x - r + 1, cy + 1, Math.max(1, r - 2), p.birch); disc(x + r - 1, cy - 1, Math.max(1, r - 2), p.birch); disc(x - 1, cy - r + 1, Math.max(1, r - 2), p.birch);
      disc(x - 2, cy - 2, Math.max(1, r - 3), light(p.birch, .25)); disc(x + 2, cy + 2, Math.max(1, r - 3), dark(p.birch, .25)); }
    // bakre husrekke (Kaupgata) oppe på bakken, bare tak og gavler
    S.reset(23); let hx = 640;
    while (hx < W - 40) { const w = 26 + Math.floor(rnd() * 22), h = 14 + Math.floor(rnd() * 8), base = Math.floor(hillTop(hx + w / 2)) + 10, y = base - h, wall = rnd() > .5 ? p.wood : p.wood2;
      R(hx, y, w, h, wall); for (let i = 3; i < h; i += 4) R(hx, y + i, w, 1, dark(wall, .35));
      const rh = Math.ceil(w / 4) + 3; roofRows(S, hx + w / 2, y - rh + 2, Math.max(4, w - 10), w + 4, rh, i => i < 2 ? light(p.turf, .2) : p.turf);
      R(hx + w - 8, y + 4, 4, 4, p.lit && rnd() > .3 ? p.win : dark(wall, .4));
      hx += w + 8 + Math.floor(rnd() * 14); }
  }

  // ---------------------------------------------------------------- byggeklosser for hovedlaget
  function logWall(S, x, y, w, h, wall, opts = {}) {
    const { R, P } = S, step = opts.step || 5;
    R(x, y, w, h, wall);
    for (let i = step - 1; i < h; i += step) { R(x, y + i, w, 1, dark(wall, .42)); R(x, y + i - 1, w, 1, light(wall, .08)); if (opts.grain) for (let g = x + 2 + (i % 7); g < x + w - 2; g += 6 + (i % 3)) R(g, y + i - 3, 2, 1, dark(wall, .14)); }
    R(x, y, 1, h, dark(wall, .35)); R(x + w - 1, y, 1, h, light(wall, .12));
    if (opts.corner) { for (let i = 0; i < h; i += step) { R(x - 2, y + i, 3, step - 1, dark(wall, .25)); R(x + w - 1, y + i, 3, step - 1, light(wall, .05)); } }
  }
  // tak: rad i fra toppen får bredde fra topW (mønet) til botW (takskjegget)
  function roofRows(S, cx, yTop, topW, botW, h, colorAt) {
    for (let i = 0; i < h; i++) { const ww = Math.round(topW + (botW - topW) * (i / Math.max(1, h - 1))); S.R(cx - Math.floor(ww / 2), yTop + i, ww, 1, colorAt(i)); }
  }
  function turfRoof(S, x, y, w, over, opts = {}) {
    const { p, R, P, rnd } = S, rh = opts.h || Math.ceil(w / 2) + 3, c = opts.c || p.turf;
    roofRows(S, x + w / 2, y - rh + 2, Math.max(6, w - rh * 2 * (opts.slope || 1)), w + over * 2, rh, i => i < 2 ? light(c, .22) : (i % 4 === 3 ? dark(c, .08) : c));
    R(x - over, y + 1, w + over * 2, 2, dark(c, .35)); R(x - over, y + 3, w + over * 2, 1, dark(p.wood, .3));
    S.reset(x * 3); for (let i = 0; i < w; i++) { const tx = x - over + rnd() * (w + over * 2), ty = y - rnd() * (rh - 4); const k = ty - (y - rh + 2); if (tx > x - over + k && tx < x + w + over - k) P(tx, ty, light(c, .2 + rnd() * .2)); }
    return rh;
  }
  function winFrame(S, x, y, w, h, lit, wall, cross = true) {
    const { p, R } = S;
    R(x - 1, y - 1, w + 2, h + 2, dark(wall, .5)); R(x, y, w, h, lit ? p.win : p.win === '#ffcf6a' || p.win === '#ffc860' ? dark(p.win, .75) : p.win);
    if (cross) { R(x + Math.floor(w / 2), y, 1, h, dark(wall, .55)); R(x, y + Math.floor(h / 2), w, 1, dark(wall, .55)); }
    R(x, y, Math.floor(w / 2) - 1, Math.floor(h / 2) - 1, lit ? light(p.win, .3) : light(p.win, .1));
    if (lit) S.lights.push([x + w / 2, y + h / 2, w]);
  }
  function door(S, x, base, w, h, wall) {
    const { p, R, P } = S;
    R(x - 1, base - h - 1, w + 2, h + 1, dark(wall, .55)); R(x, base - h, w, h, dark(p.wood2, .3));
    for (let i = 2; i < w; i += 3) R(x + i, base - h, 1, h, dark(p.wood2, .5));
    R(x, base - h + 3, w, 1, dark(p.wood2, .55)); R(x, base - 5, w, 1, dark(p.wood2, .55));
    R(x + w - 3, base - Math.floor(h / 2), 2, 1, '#c9a477'); P(x + w - 2, base - Math.floor(h / 2) + 1, '#8a7a5a');
  }
  function lantern(S, x, y, on) {
    const { p, R, P, disc } = S;
    R(x, y, 3, 1, '#5a4020'); R(x + 1, y + 1, 1, 1, '#5a4020'); R(x - 1, y + 2, 5, 7, dark('#8a8a8a', .4)); R(x, y + 3, 3, 5, on ? '#ffe9a8' : '#4a4a50'); R(x - 1, y + 9, 5, 1, dark('#8a8a8a', .5));
    if (on) { P(x + 1, y + 4, '#ffffff'); S.lights.push([x + 1.5, y + 5, 10]); }
  }
  function barrel(S, x, base, w, h) {
    const { p, R } = S, c = S.p.wood2;
    R(x, base - h, w, h, c); R(x, base - h, 1, h, dark(c, .3)); R(x + w - 1, base - h, 1, h, dark(c, .2)); R(x + 2, base - h, 2, h, light(c, .12));
    R(x, base - h + 2, w, 1, dark(c, .55)); R(x, base - 3, w, 1, dark(c, .55)); R(x, base - Math.floor(h / 2), w, 1, dark(c, .4));
    R(x, base - h, w, 1, dark(c, .25));
  }
  function ropeCoil(S, x, base, r) {
    const { p, R, disc } = S;
    for (let k = r; k > 0; k -= 2) { disc(x, base - r, k, k % 4 === 0 ? dark(p.rope, .25) : p.rope); }
    disc(x, base - r, Math.max(1, r - 6), dark(p.rope, .45));
    R(x - r, base - 1, r * 2 + 1, 1, dark(p.rope, .45));
  }
  function post(S, x, base, h, c) { const { R, P } = S; R(x, base - h, 4, h, c); R(x, base - h, 1, h, light(c, .15)); R(x + 3, base - h, 1, h, dark(c, .3)); R(x, base - h, 4, 1, light(c, .25)); R(x - 1, base - h + 1, 6, 1, dark(c, .2)); }
  function fish(S, x, y, c) { const { R, P } = S; R(x, y, 2, 6, c); P(x, y + 6, dark(c, .3)); P(x + 1, y - 1, dark(c, .3)); P(x - 1, y + 7, dark(c, .3)); P(x + 2, y + 7, dark(c, .3)); }

  // ---------------------------------------------------------------- 4 brygga (hovedlaget, parallakse 1)
  function brygga(S) {
    const { p, W, R, P, disc, rnd, gradient } = S;
    S.lights = [];
    const GRD = FLOOR;              // 312: gulvlinje
    const sb = p.sky[4];
    // ---- bakke/sokkel bak byggene (stein og jord opp til bakken bak)
    for (let x = 0; x < W; x++) { const t = 230 + 6 * Math.sin(x * .02) + 2 * Math.sin(x * .07); for (let y = Math.floor(t); y < GRD; y++) P(x, y, y < t + 2 ? light(p.hill, .12) : mix(p.hill, p.stone, .25)); }
    S.reset(41); for (let i = 0; i < W / 2; i++) { const x = Math.floor(rnd() * W), t = 230 + 6 * Math.sin(x * .02) + 2 * Math.sin(x * .07), y = t + 2 + rnd() * (GRD - t - 4); if (rnd() > .5) { P(x, y, light(p.hill, .18)); P(x, y - 1, light(p.hill, .3)); } else { R(x, y, 2 + Math.floor(rnd() * 3), 1 + Math.floor(rnd() * 2), mix(p.stone, p.hill, .4)); } }
    // elvemunningen (x 240–380): bakken åpner seg, vann helt inn
    for (let x = 236; x < 384; x++) { const e = 246 + 3 * Math.sin(x * .09); for (let y = Math.floor(e); y < GRD + 48; y++) P(x, y, mix(p.river, p.water, Math.min(1, (y - e) / 70))); }
    S.reset(31); for (let i = 0; i < 70; i++) R(240 + rnd() * 140, 250 + rnd() * 90, 3 + rnd() * 9, 1, mix(p.wave, p.river, .55));
    // steinmur mot elva, begge sider
    for (const [x0, x1] of [[214, 240], [380, 404]]) for (let y = 236; y < GRD; y += 1) for (let x = x0; x < x1; x++) P(x, y, ((x * 7 + y * 3) % 11 === 0) ? dark(p.stone, .35) : (y % 6 === 0 ? dark(p.stone, .2) : p.stone));
    // ---- planker over gammel åpning (gangen under brua), x ≈ 140–200
    R(132, 236, 76, GRD - 236, dark(p.stone, .1)); for (let y = 236; y < GRD; y += 1) for (let x = 132; x < 208; x++) if ((x * 5 + y * 7) % 13 === 0) P(x, y, dark(p.stone, .35));
    R(146, 250, 48, 62, '#0e0c10');
    for (let i = 0; i < 6; i++) { const yy = 252 + i * 10 + (i % 2); R(144, yy, 52, 7, dark(p.wood2, i % 2 ? .25 : .15)); R(144, yy, 52, 1, light(p.wood2, .05)); R(144, yy + 6, 52, 1, dark(p.wood2, .5)); P(147, yy + 3, '#555'); P(191, yy + 3, '#555'); }
    // ---- klopp (liten gangbru) over elvemunningen, x 236–384
    R(232, GRD - 6, 156, 6, p.wood2); R(232, GRD - 6, 156, 1, light(p.wood2, .25)); R(232, GRD, 156, 3, dark(p.wood, .25));
    for (let x = 236; x < 384; x += 7) R(x, GRD - 5, 1, 5, dark(p.wood2, .35));
    for (let x = 248; x < 384; x += 44) { R(x, GRD - 30, 3, 24, p.wood); R(x - 1, GRD - 30, 5, 2, light(p.wood, .1)); R(x, GRD + 3, 3, 40, dark(p.wood, .35)); }
    R(248, GRD - 24, 136, 2, p.wood); R(248, GRD - 14, 136, 1, dark(p.wood, .2));
    // ---- sjøbodene (x 560–800): to boder på påler, tjæret, med heisebom
    function boathouse(x, w, h, tone) {
      const wall = tone ? p.tar : p.wood, base = GRD, y = base - h;
      // påler og skrå understell ned i vannet
      for (let k = 6; k < w; k += 22) { R(x + k, base - 4, 4, 52, dark(p.wood, .45)); R(x + k, base - 4, 1, 52, dark(p.wood, .25)); }
      logWall(S, x, y, w, h, wall, { step: 6, grain: true, corner: true });
      // skifertak/bordtak med møne
      const rh = Math.ceil(w / 2.2); roofRows(S, x + w / 2, y - rh + 2, 3, w + 6, rh, i => (i % 3 === 0) ? dark(p.wood, .45) : (i % 3 === 1 ? dark(p.wood, .3) : dark(p.wood, .2)));
      R(x - 3, y + 1, w + 6, 2, dark(p.wood, .55)); R(x + Math.floor(w / 2) - 1, y - rh + 1, 3, 2, dark(p.wood, .5));
      // loftsluke med heisebom og tau
      R(x + Math.floor(w / 2) - 7, y + 4, 14, 14, dark(wall, .5)); R(x + Math.floor(w / 2) - 6, y + 5, 12, 12, '#0e0c10'); R(x + Math.floor(w / 2) - 6, y + 5, 5, 12, dark(p.wood2, .4));
      R(x + Math.floor(w / 2) - 1, y - 3, 3, 10, p.wood); R(x + Math.floor(w / 2) - 1, y - 4, 10, 2, p.wood); R(x + Math.floor(w / 2) + 8, y - 2, 1, 22, p.rope); R(x + Math.floor(w / 2) + 6, y + 19, 5, 3, '#8a8a8a');
      // stor port og lite vindu
      R(x + 6, base - 34, 22, 34, dark(wall, .35)); for (let i = 0; i < 22; i += 3) R(x + 6 + i, base - 34, 1, 34, dark(wall, .55)); R(x + 6, base - 34, 22, 1, dark(wall, .6)); R(x + 6, base - 18, 22, 1, dark(wall, .6)); R(x + 16, base - 22, 2, 2, '#8a8a8a');
      winFrame(S, x + w - 16, y + 24, 7, 8, p.lit, wall);
      // tørrfisk på veggen og tauverk
      for (let k = 0; k < 5; k++) fish(S, x + 34 + k * 5, base - 50 + (k % 2) * 2, mix(p.sail, p.wood2, .4));
      R(x + 33, base - 52, 26, 1, p.rope);
    }
    boathouse(556, 110, 70, true); boathouse(676, 124, 78, false);
    // ---- fiskeboden (x 820–950): åpen bod med disk og fisk på kroker
    { const x = 818, w = 134, h = 56, y = GRD - h, wall = p.wood2;
      logWall(S, x, y, w, h, wall, { step: 5 });
      // skråtak med torv, lavt
      const rh = turfRoof(S, x, y, w, 5, { h: 22, slope: 2 });
      // åpning med disk
      R(x + 24, y + 14, 86, 42, '#141018'); R(x + 24, y + 14, 86, 2, dark(wall, .5));
      R(x + 20, GRD - 20, 94, 4, p.wood2); R(x + 20, GRD - 20, 94, 1, light(p.wood2, .25)); R(x + 20, GRD - 16, 94, 16, dark(p.wood2, .15)); for (let i = 0; i < 94; i += 6) R(x + 20 + i, GRD - 16, 1, 16, dark(p.wood2, .4));
      // stolper som bærer taket
      R(x + 22, y + 10, 3, 46, dark(wall, .3)); R(x + 108, y + 10, 3, 46, dark(wall, .3));
      // fisk på rekke under taket og i kasser
      R(x + 26, y + 20, 82, 1, p.rope); for (let k = 0; k < 11; k++) fish(S, x + 30 + k * 7, y + 21 + (k % 3), k % 3 === 0 ? mix(p.sail, p.wood2, .3) : mix('#9fb6c0', p.sail, .3));
      R(x + 34, GRD - 30, 24, 10, dark(p.wood2, .25)); for (let k = 0; k < 6; k++) P(x + 36 + k * 4, GRD - 29 + (k % 2), '#b8c4c8');
      R(x + 70, GRD - 30, 28, 10, dark(p.wood2, .25)); for (let k = 0; k < 7; k++) P(x + 72 + k * 4, GRD - 29 + (k % 2), '#c8b090');
      // lykt ved boden
      lantern(S, x + w + 6, y + 18, p.lit); R(x + w + 7, y + 28, 1, GRD - y - 28, dark(p.wood, .2)); }
    // ---- fiskehjell og tønner (x 960–1020)
    { const x = 962; R(x, GRD - 44, 3, 44, dark(p.wood, .15)); R(x + 50, GRD - 44, 3, 44, dark(p.wood, .15)); R(x - 2, GRD - 44, 57, 2, p.wood); R(x, GRD - 32, 53, 1, p.rope); R(x, GRD - 20, 53, 1, p.rope);
      for (let k = 0; k < 8; k++) { fish(S, x + 6 + k * 6, GRD - 43, mix(p.sail, p.wood2, .35)); fish(S, x + 8 + k * 6, GRD - 31, mix(p.sail, p.wood2, .45)); }
      barrel(S, 1000, GRD, 12, 16); barrel(S, 1014, GRD, 12, 16); barrel(S, 1007, GRD - 16, 12, 16); }
    // ---- vertshuset (x 1030–1270): to etasjer, torvtak, skilt, trapp
    { const x = 1028, w = 240, h = 128, y = GRD - h, wall = p.wood;
      logWall(S, x, y, w, h, wall, { step: 6, grain: true, corner: true });
      R(x, y + 62, w, 3, dark(wall, .5)); R(x, y + 62, w, 1, light(wall, .1));  // etasjeskille
      const rh = turfRoof(S, x, y, w, 10, { h: 44, slope: 2.6 });
      // takvindu-røykhull og røyk tegnes av spillet; her: ljore
      R(x + 110, y - 36, 14, 10, dark(wall, .4)); R(x + 112, y - 34, 10, 6, '#0e0c10');
      // vinduer oppe og nede
      for (let k = 0; k < 4; k++) winFrame(S, x + 28 + k * 56, y + 20, 10, 12, p.lit, wall);
      winFrame(S, x + 24, y + 80, 12, 14, p.lit, wall); winFrame(S, x + 180, y + 80, 12, 14, p.lit, wall); winFrame(S, x + 212, y + 80, 12, 14, p.lit, wall);
      // døra (prototypen: verden 1750 → px 1143)
      door(S, 1134, GRD, 18, 36, wall);
      R(1130, GRD - 2, 26, 2, light(p.stone, .1)); R(1130, GRD, 26, 1, dark(p.stone, .2));
      // skilt: en klokke på en plate
      R(1162, y + 66, 2, 14, dark(wall, .5)); R(1160, y + 66, 22, 2, dark(wall, .5)); R(1163, y + 69, 16, 14, p.wood2); R(1163, y + 69, 16, 1, light(p.wood2, .2));
      disc(1171, y + 75, 4, '#b07a2a'); R(1168, y + 79, 7, 2, '#8a5a1e'); P(1171, y + 81, '#5a3a14');
      // benk og lykt ved døra
      R(1190, GRD - 12, 30, 3, p.wood2); R(1192, GRD - 9, 3, 9, dark(p.wood2, .3)); R(1215, GRD - 9, 3, 9, dark(p.wood2, .3));
      lantern(S, 1118, y + 86, p.lit);
      // trapp ned mot vannet til høyre for vertshuset (der Toras båt står om natta)
      for (let k = 0; k < 4; k++) { R(1280 + k * 10, GRD + k * 6, 40 - k * 10, 6, k % 2 ? dark(p.stone, .15) : p.stone); R(1280 + k * 10, GRD + k * 6, 40 - k * 10, 1, light(p.stone, .2)); } }
    // ---- venstre ende: trapp opp mot Torget og steinmur
    for (let k = 0; k < 7; k++) { R(0, GRD - 8 - k * 8, 60 - k * 8, 8, k % 2 ? dark(p.stone, .12) : p.stone); R(0, GRD - 8 - k * 8, 60 - k * 8, 1, light(p.stone, .25)); }
    R(60, 232, 70, 80, mix(p.stone, p.hill, .3)); for (let y = 232; y < GRD; y += 1) for (let x = 60; x < 130; x++) if ((x * 3 + y * 5) % 9 === 0) P(x, y, dark(p.stone, .3));
    R(60, 232, 70, 2, light(p.stone, .2));
    // ---- brygga: dekket (gulvlinjen), kantbjelke, påler og vann
    R(0, GRD, W, 6, p.wood2); R(0, GRD, W, 1, light(p.wood2, .3)); R(0, GRD + 5, W, 1, dark(p.wood2, .45));
    for (let x = 3; x < W; x += 9) R(x, GRD + 1, 1, 4, dark(p.wood2, .3));
    R(0, GRD + 6, W, 8, dark(p.wood, .2)); R(0, GRD + 6, W, 1, dark(p.wood, .45)); for (let x = 0; x < W; x += 14) R(x, GRD + 7, 1, 7, dark(p.wood, .45));
    // vann under og foran brygga
    gradient(GRD + 14, H, [mix(p.water, sb, .2), p.water, dark(p.water, .35)], 0, W, 8);
    S.reset(9); for (let i = 0; i < W / 3; i++) { const y = GRD + 16 + rnd() * (H - GRD - 16); R(rnd() * W, y, 3 + rnd() * 9, 1, mix(p.wave, p.water, .25 + (y - GRD) / 48 * .5)); }
    // påler under brygga
    for (let x = 10; x < W; x += 26) { R(x, GRD + 14, 5, 30, dark(p.wood, .4)); R(x, GRD + 14, 1, 30, dark(p.wood, .2)); R(x + 4, GRD + 14, 1, 30, dark(p.wood, .6)); R(x - 1, GRD + 14, 7, 2, dark(p.wood, .5)); }
    // speilbilder av lys i vannet
    if (p.lit) S.lights.forEach(([lx, ly, lw], i) => { for (let k = 0; k < 7; k++) R(lx - lw / 4 + ((k * 7 + i) % 3) - 1, GRD + 18 + k * 5, lw / 2, 1, mix(p.win, p.water, .35 + k * .09)); });
    // ---- løse ting på dekket: tauverk (x≈457), fortøyningspåler, tønner, kasser
    ropeCoil(S, 448, GRD, 9); ropeCoil(S, 470, GRD, 7); R(430, GRD - 4, 60, 2, p.rope); R(458, GRD - 8, 1, 8, p.rope);
    post(S, 420, GRD, 18, dark(p.wood, .1)); post(S, 540, GRD, 18, dark(p.wood, .1)); post(S, 1395, GRD, 18, dark(p.wood, .1)); post(S, 1520, GRD, 18, dark(p.wood, .1));
    for (const [a, b] of [[422, 542], [1397, 1522]]) for (let x = a; x < b; x++) { const t = (x - a) / (b - a); P(x, GRD - 16 + Math.round(Math.sin(t * Math.PI) * 9), p.rope); }
    barrel(S, 1340, GRD, 12, 16); R(1356, GRD - 10, 18, 10, dark(p.wood2, .2)); R(1356, GRD - 10, 18, 1, light(p.wood2, .15)); for (let i = 0; i < 18; i += 5) R(1356 + i, GRD - 10, 1, 10, dark(p.wood2, .45));
    // den løse planken (sprekken): én planke litt lysere, litt skjev, x ≈ 1460
    R(1458, GRD + 1, 9, 4, light(p.wood2, .22)); R(1458, GRD, 9, 1, light(p.wood2, .4)); P(1466, GRD + 2, dark(p.wood2, .6));
    // morgentåke lavt over vannet
    if (p.mist) for (let y = GRD + 10; y < H; y++) { const d = Math.max(0, 1 - Math.abs((y - (GRD + 26)) / 20)); for (let x = 0; x < W; x++) if (d * 7 + 1.5 * Math.sin(x * .03 + y * .2) > bayer[y & 3][x & 3]) P(x, y, mix(p.mist, p.water, .35)); }
    // vannmerket på vertshusets sokkel (elva stiger: spillet kan flytte det)
    R(1028, GRD - 2, 60, 1, light(p.wood, .18));
  }

  // ---------------------------------------------------------------- 5 forgrunn (parallakse 1,2)
  function forgrunn(S) {
    const { p, W, R, P, rnd, disc } = S;
    // fortøyd robåt nederst, x 300–420
    { const x = 300, y = 334; R(x, y, 120, 7, p.hull); R(x + 4, y + 7, 112, 5, dark(p.hull, .2)); R(x + 10, y + 12, 100, 3, dark(p.hull, .4));
      R(x - 4, y - 8, 5, 10, p.hull); R(x + 119, y - 8, 5, 10, p.hull); R(x + 2, y + 1, 116, 1, light(p.hull, .25)); for (let k = 0; k < 4; k++) R(x + 20 + k * 26, y - 4, 10, 4, light(p.hull, .15)); R(x + 50, y - 20, 2, 16, dark(p.hull, .1)); }
    // nett hengt til tørk, x 880–990, øverst i bildet
    { const x = 880, y = 206; R(x, y, 2, 154, dark(p.wood, .15)); R(x + 108, y, 2, 154, dark(p.wood, .15)); R(x - 1, y, 112, 2, p.wood);
      for (let i = 0; i < 70; i++) for (let j = 0; j < 104; j++) if ((i + j) % 5 === 0 || (j - i) % 5 === 0) P(x + 3 + j, y + 4 + i + Math.round(Math.sin(j * .09) * 3), (i + j) % 10 === 0 ? dark(p.rope, .2) : p.rope);
      for (let j = 0; j < 104; j += 13) R(x + 3 + j, y + 76 + Math.round(Math.sin(j * .09) * 3), 2, 4, dark(p.rope, .3)); }
    // stor fortøyningspåle med tau helt til venstre, og en til høyre
    for (const x of [70, 1600]) { R(x, 250, 10, 110, dark(p.wood, .25)); R(x, 250, 2, 110, light(p.wood, .05)); R(x + 8, 250, 2, 110, dark(p.wood, .5)); R(x - 1, 248, 12, 3, dark(p.wood, .35));
      for (let k = 0; k < 5; k++) R(x - 1, 262 + k * 3, 12, 2, k % 2 ? p.rope : dark(p.rope, .2)); }
    // måkefjær og noen tauender
    R(1180, 346, 30, 2, p.rope); R(1210, 344, 12, 2, p.rope);
  }

  root.Saltbrygga = { LAYERS, PH, H, FLOOR, ROOM_W, make, phases: Object.keys(PH) };
})(typeof window !== 'undefined' ? window : globalThis);
