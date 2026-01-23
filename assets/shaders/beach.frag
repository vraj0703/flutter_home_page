#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

// Standard Uniforms - Defined as individual floats to ensure alignment
uniform vec2 uSize;         // 0, 1
uniform float uTime;        // 2
uniform float uTextY;       // 3
uniform float uWaterY;      // 4
uniform float uTextOpacity; // 5
uniform float uTextScale;   // 6
uniform float uTextWidth;   // 7  (Physical Texture Width)
uniform float uTextHeight;  // 8  (Physical Texture Height)
uniform float uTextX;       // 9  (Logical Center X)
uniform float uPixelRatio;  // 10

uniform sampler2D uTextTexture;

out vec4 fragColor;

// --- Original Shader Global Variables ---
const float pi = 3.14159;
int idObj, idObjGrp;
mat3 bdMat, birdMat[2];
vec3 bdPos, birdPos[2], fltBox, qHit, sunDir, waterDisp, cloudDisp;
float tCur, birdVel, birdLen, legAng;
const float dstFar = 100.0;
const int idWing = 21, idBdy = 22, idEye = 23, idBk = 24, idLeg = 25;

// --- Helper Functions (Hash, Noise, SDFs) ---
const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

vec4 Hashv4f (float p) { return fract (sin (p + cHashA4) * cHashM); }
float Noisefv2 (vec2 p) {
    vec2 i = floor (p); vec2 f = fract (p);
    f = f * f * (3. - 2. * f);
    vec4 t = Hashv4f (dot (i, cHashA3.xy));
    return mix (mix (t.x, t.y, f.x), mix (t.z, t.w, f.x), f.y);
}
float Noisefv3 (vec3 p) {
    vec3 i = floor (p); vec3 f = fract (p);
    f = f * f * (3. - 2. * f);
    float q = dot (i, cHashA3);
    vec4 t1 = Hashv4f (q); vec4 t2 = Hashv4f (q + cHashA3.z);
    return mix (mix (mix (t1.x, t1.y, f.x), mix (t1.z, t1.w, f.x), f.y),
    mix (mix (t2.x, t2.y, f.x), mix (t2.z, t2.w, f.x), f.y), f.z);
}
float SmoothBump (float lo, float hi, float w, float x) {
    return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}
vec2 Rot2D (vec2 q, float a) { return q * cos (a) * vec2 (1., 1.) + q.yx * sin (a) * vec2 (-1., 1.); }
float PrSphDf (vec3 p, float s) { return length (p) - s; }
float PrCapsDf (vec3 p, float r, float h) { return length (p - vec3 (0., 0., h * clamp (p.z / h, -1., 1.))) - r; }
float PrCylDf (vec3 p, float r, float h) { return max (length (p.xy) - r, abs (p.z) - h); }
float PrFlatCylDf (vec3 p, float rhi, float rlo, float h) {
    return max (length (p.xy - vec2 (rhi * clamp (p.x / rhi, -1., 1.), 0.)) - rlo, abs (p.z) - h);
}
float PrTorusDf (vec3 p, float ri, float rc) { return length (vec2 (length (p.xy) - rc, p.z)) - ri; }

// --- Water & Sky logic ---
float WaterHt (vec3 p) {
    p *= 0.03; p += waterDisp;
    float ht = 0.; const float wb = 1.414; float w = wb;
    for (int j = 0; j < 7; j ++) {
        w *= 0.5;
        p = wb * vec3 (p.y + p.z, p.z - p.y, 2. * p.x) + 20. * waterDisp;
        ht += w * abs (Noisefv3 (p) - 0.5);
    }
    return ht;
}
vec3 WaterNf (vec3 p, float d) {
    vec2 e = vec2 (max (0.01, 0.001 * d * d), 0.);
    float ht = WaterHt (p);
    return normalize (vec3 (ht - WaterHt (p + e.xyy), e.x, ht - WaterHt (p + e.yyx)));
}
float FbmS (vec2 p) {
    float a = 1.; float v = 0.;
    for (int i = 0; i < 5; i ++) {
        v += a * (sin (6. * Noisefv2 (p)) + 1.);
        a *= 0.5; p *= 2.;
        p *= mat2 (0.8, -0.6, 0.6, 0.8);
    }
    return v;
}
vec3 SkyCol (vec3 ro, vec3 rd) {
    vec3 skyCol, sunCol, p;
    float ds, fd, att, attSum, d, dDotS, skyHt = 200.;
    p = ro + rd * (skyHt - ro.y) / rd.y;
    ds = 0.1 * sqrt (distance (ro, p));
    fd = 0.001 / (smoothstep (0., 10., ds) + 0.1);
    p.xz *= fd; p.xz += cloudDisp.xz;
    att = FbmS (p.xz); attSum = att; d = fd; ds *= fd;
    for (int i = 0; i < 4; i ++) { attSum += FbmS (p.xz + d * sunDir.xz); d += ds; }
    attSum *= 0.27; att *= 0.27;
    dDotS = clamp (dot (sunDir, rd), 0., 1.);
    skyCol = mix (vec3 (0.7, 1., 1.), vec3 (1., 0.4, 0.1), 0.25 + 0.75 * dDotS);
    sunCol = vec3 (1., 0.8, 0.7) * pow (dDotS, 1024.) + vec3 (1., 0.4, 0.2) * pow (dDotS, 256.);
    vec3 col = mix (vec3 (0.5, 0.75, 1.), skyCol, exp (-2. * (3. - dDotS) * max (rd.y - 0.1, 0.))) + 0.3 * sunCol;
    attSum = 1. - smoothstep (1., 9., attSum);
    col = mix (vec3 (0.4, 0., 0.2), mix (col, vec3 (0.2), att), attSum) +
    vec3 (1., 0.4, 0.) * pow (attSum * att, 3.) * (pow (dDotS, 10.) + 0.5);
    return col;
}

// --- Bird Animation ---
float AngQnt (float a, float s1, float s2, float nr) { return (s1 + floor (s2 + a * (nr / (2. * pi)))) * (2. * pi / nr); }
float BdWingDf (vec3 p, float dHit) {
    vec3 q, qh = vec3(0.); float d, dd, a, wr, wngFreq = 6., wSegLen = 0.18, wChord = 0.36, wSpar = 0.036, fTap = 8., tFac = 0.875;
    q = p - vec3 (0., 0., 0.36); q.x = abs (q.x) - 0.12;
    float wf = 1.0; a = -0.1 + 0.2 * sin (wngFreq * tCur); d = dHit; qh = q;
    for (int k = 0; k < 5; k ++) {
        q.xy = Rot2D (q.xy, a); q.x -= wSegLen; wr = wf * (1. - 0.5 * q.x / (fTap * wSegLen));
        dd = PrFlatCylDf (q.zyx, wr * wChord, wr * wSpar, wSegLen);
        if (k < 4) { q.x -= wSegLen; dd = min (dd, PrCapsDf (q, wr * wSpar, wr * wChord)); }
        else { q.x += wSegLen; dd = max (dd, PrCylDf (q.xzy, wr * wChord, wSpar)); dd = min (dd, max (PrTorusDf (q.xzy, 0.98 * wr * wSpar, wr * wChord), - q.x)); }
        if (dd < d) { d = dd;  qh = q; }
        a *= 1.03; wf *= tFac;
    }
    if (d < dHit) { dHit = min (dHit, d);  idObj = idObjGrp + idWing;  qHit = qh; }
    return dHit;
}
float BdBodyDf (vec3 p, float dHit) {
    vec3 q = p; float d, wr = q.z / birdLen, tr, u, bkLen = 0.15 * birdLen;
    if (wr > 0.5) { u = (wr - 0.5) / 0.5; tr = 0.17 - 0.11 * u * u; }
    else { u = clamp ((wr - 0.5) / 1.5, -1., 1.); u *= u; tr = 0.17 - u * (0.34 - 0.18 * u); }
    d = PrCapsDf (q, tr * birdLen, birdLen);
    if (d < dHit) { dHit = d;  idObj = idObjGrp + idBdy;  qHit = q; }
    q = p; q.x = abs (q.x); wr = (wr + 1.) * (wr + 1.); q -= birdLen * vec3 (0.3 * wr, 0.1 * wr, -1.2);
    d = PrCylDf (q, 0.009 * birdLen, 0.2 * birdLen);
    if (d < dHit) { dHit = min (dHit, d);  idObj = idObjGrp + idBdy;  qHit = q; }
    q = p; q.x = abs (q.x); q -= birdLen * vec3 (0.08, 0.05, 0.9);
    d = PrSphDf (q, 0.04 * birdLen);
    if (d < dHit) { dHit = d;  idObj = idObjGrp + idEye;  qHit = q; }
    q = p; q -= birdLen * vec3 (0., -0.015, 1.15); wr = clamp (0.5 - 0.3 * q.z / bkLen, 0., 1.);
    d = PrFlatCylDf (q, 0.25 * wr * bkLen, 0.25 * wr * bkLen, bkLen);
    if (d < dHit) { dHit = d;  idObj = idObjGrp + idBk;  qHit = q; }
    return dHit;
}
float BdFootDf (vec3 p, float dHit) {
    vec3 q = p; float d, lgLen = 0.1 * birdLen, ftLen = 0.5 * lgLen;
    q.x = abs (q.x); q -= birdLen * vec3 (0.1, -0.12, 0.6);
    q.yz = Rot2D (q.yz, legAng); q.xz = Rot2D (q.xz, -0.05 * pi); q.z += lgLen;
    d = PrCylDf (q, 0.15 * lgLen, lgLen);
    if (d < dHit) { dHit = d;  idObj = idLeg;  qHit = q; }
    q.z += lgLen; q.xy = Rot2D (q.xy, 0.5 * pi); q.xy = Rot2D (q.xy, AngQnt (atan (q.y, - q.x), 0., 0.5, 3.));
    q.xz = Rot2D (q.xz, - pi + 0.4 * legAng); q.z -= ftLen;
    d = PrCapsDf (q, 0.2 * ftLen, ftLen);
    if (d < dHit) { dHit = d;  idObj = idObjGrp + idLeg;  qHit = q; }
    return dHit;
}
float BirdDf (vec3 p, float dHit) {
    dHit = BdWingDf (p, dHit);
    dHit = BdBodyDf (p, dHit);
    dHit = BdFootDf (p, dHit);
    return dHit;
}
vec4 BirdCol (vec3 n) {
    vec3 col = vec3(0.); int ig = idObj / 256; int id = idObj - 256 * ig; float spec = 1.;
    if (id == idWing) {
        float gw = 0.15 * birdLen; float w = mod (qHit.x, gw);
        w = SmoothBump (0.15 * gw, 0.65 * gw, 0.1 * gw, w);
        col = mix (vec3 (0.05), vec3 (1.), w);
    } else if (id == idEye) { col = vec3 (0., 0.6, 0.); spec = 5.; }
    else if (id == idBdy) {
        vec3 nn = (ig == 1) ? birdMat[0] * n : birdMat[1] * n;
        col = mix (mix (vec3 (1.), vec3 (0.1), smoothstep (0.5, 1., nn.y)), vec3 (1.), 1. - smoothstep (-1., -0.7, nn.y));
    } else if (id == idBk) { col = vec3 (1., 1., 0.); }
    else if (id == idLeg) { col = (0.5 + 0.4 * sin (100. * qHit.z)) * vec3 (0.6, 0.4, 0.); }
    col.gb *= 0.7; return vec4 (col, spec);
}
float ObjDf (vec3 p) {
    float dHit = dstFar;
    idObjGrp = 256; dHit = BirdDf (birdMat[0] * (p - birdPos[0]), dHit);
    idObjGrp = 512; dHit = BirdDf (birdMat[1] * (p - birdPos[1]), dHit);
    return 0.9 * dHit;
}
float ObjRay (vec3 ro, vec3 rd) {
    float d, dHit = 0.;
    for (int j = 0; j < 100; j ++) {
        d = ObjDf (ro + dHit * rd); dHit += d;
        if (d < 0.001 || dHit > dstFar) break;
    }
    return dHit;
}
vec3 ObjNf (vec3 p) {
    vec3 e = vec3 (0.001, -0.001, 0.);
    vec4 v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
    return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * vec3 (v.y, v.z, v.w));
}
vec3 ShowScene (vec3 ro, vec3 rd) {
    vec3 vn; vec4 objCol; float dstHit, htWat = -1.5, reflFac = 1.;
    vec3 col = vec3 (0.); idObj = -1;
    dstHit = ObjRay (ro, rd);
    if (rd.y < 0. && dstHit >= dstFar) {
        float dw = - (ro.y - htWat) / rd.y;
        ro += dw * rd; rd = reflect (rd, WaterNf (ro, dw)); ro += 0.01 * rd;
        idObj = -1; dstHit = ObjRay (ro, rd); reflFac *= 0.7;
    }
    if (idObj < 0 || dstHit >= dstFar) col = reflFac * SkyCol (ro, rd);
    else {
        ro += rd * dstHit; vn = ObjNf (ro); objCol = BirdCol (vn); float dif = max (dot (vn, sunDir), 0.);
        col = reflFac * objCol.xyz * (0.2 + max (0., dif) * (dif + objCol.a * pow (max (0., dot (sunDir, reflect (rd, vn))), 128.)));
    }
    return col;
}
vec3 BirdTrack (float t) {
    t = -t; vec3 bp; float rdTurn = 0.45 * min (fltBox.x, fltBox.z), tC = 0.5 * pi * rdTurn / birdVel;
    vec3 tt = vec3 (fltBox.x - rdTurn, length (fltBox.xy), fltBox.z - rdTurn) * 2. / birdVel;
    float tCyc = 2. * (2. * tt.z + tt.x  + 4. * tC + tt.y), tSeq = mod (t, tCyc), ti[9];
    ti[0] = 0.; ti[1] = tt.z; ti[2] = ti[1] + tC; ti[3] = ti[2] + tt.x; ti[4] = ti[3] + tC;
    ti[5] = ti[4] + tt.z; ti[6] = ti[5] + tC; ti[7] = ti[6] + tt.y; ti[8] = ti[7] + tC;
    float a, h = -fltBox.y, hd = 1., tf, rSeg = -1.;
    if (tSeq > 0.5 * tCyc) { tSeq -= 0.5 * tCyc; h = - h; hd = - hd; }
    vec3 fbR = 1.0 - vec3(rdTurn) / fltBox;
    bp.xz = fltBox.xz; bp.y = h;
    if (tSeq < ti[4]) {
        if (tSeq < ti[1]) { tf = tSeq / ti[1]; bp.xz *= vec2 (1., fbR.z * (2. * tf - 1.)); }
        else if (tSeq < ti[2]) { tf = (tSeq - ti[1]) / tC; rSeg = 0.; bp.xz *= fbR.xz; }
        else if (tSeq < ti[3]) { tf = (tSeq - ti[2]) / tt.x; bp.xz *= vec2 (fbR.x * (1. - 2. * tf), 1.); }
        else { tf = (tSeq - ti[3]) / tC; rSeg = 1.; bp.xz *= fbR.xz * vec2 (-1., 1.); }
    } else {
        if (tSeq < ti[5]) { tf = (tSeq - ti[4]) / tt.z; bp.xz *= vec2 (- 1., fbR.z * (1. - 2. * tf)); }
        else if (tSeq < ti[6]) { tf = (tSeq - ti[5]) / tC; rSeg = 2.; bp.xz *= - fbR.xz; }
        else if (tSeq < ti[7]) { tf = (tSeq - ti[6]) / tt.y; bp.xz *= vec2 (fbR.x * (2. * tf - 1.), - 1.); bp.y = h + 2. * fltBox.y * hd * tf; }
        else { tf = (tSeq - ti[7]) / tC; rSeg = 3.; bp.xz *= fbR.xz * vec2 (1., -1.); bp.y = - h; }
    }
    if (rSeg >= 0.) { a = 0.5 * pi * (rSeg + tf); bp += rdTurn * vec3 (cos (a), 0., sin (a)); }
    bp.y -= -1.1 * fltBox.y; return bp;
}
void BirdPM (float t) {
    float dt = 1.; bdPos = BirdTrack (t); vec3 bpF = BirdTrack (t + dt), bpB = BirdTrack (t - dt);
    vec3 vel = (bpF - bpB) / (2. * dt); float vy = vel.y; vel.y = 0.;
    vec3 acc = (bpF - 2. * bdPos + bpB) / (dt * dt); acc.y = 0.;
    vec3 va = cross (acc, vel) / length (vel); vel.y = vy;
    float el = -0.7 * asin (vel.y / length (vel));
    vec3 ort = vec3 (el, atan (vel.z, vel.x) - 0.5 * pi, 0.2 * length (va) * sign (va.y)), cr = cos (ort), sr = sin (ort);
    bdMat = mat3 (cr.z, - sr.z, 0., sr.z, cr.z, 0., 0., 0., 1.) *
    mat3 (1., 0., 0., 0., cr.x, - sr.x, 0., sr.x, cr.x) *
    mat3 (cr.y, 0., - sr.y, 0., 1., 0., sr.y, 0., cr.y);
    legAng = pi * clamp (0.4 + 1.5 * el, 0.12, 0.8);
}

// --- REFLECTION LOGIC ---
vec3 RenderTextReflection(vec2 logicalPos) {
    if (uTextOpacity <= 0.01 || uTextWidth <= 0.0) return vec3(0.0);

    // Only render below the horizon line
    float distToHorizon = logicalPos.y - uWaterY;
    if (distToHorizon < 0.0) return vec3(0.0);

    // TextWidth is already logical (from 1x texture). Do not divide by DPR.
    float logicalW = uTextWidth * uTextScale;
    float logicalH = uTextHeight * uTextScale;

    // Smooth wobble to stop shredding
    float wobble = sin(logicalPos.y * 0.1 + uTime * 3.0) * (8.0 / uPixelRatio);

    // Horizontal mapping centered on uTextX
    float dx = (logicalPos.x + wobble) - uTextX;
    float u = 0.5 + (dx / logicalW);

    // Vertical stretching covering entire water area
    float waterArea = uSize.y - uWaterY;
    float v = 1.0 - (distToHorizon / waterArea);

    if (u < 0.0 || u > 1.0 || v < 0.0 || v > 1.0) return vec3(0.0);

    vec4 tex = texture(uTextTexture, vec2(u, v));
    float fade = smoothstep(uSize.y, uWaterY, logicalPos.y);

    return tex.rgb * tex.a * uTextOpacity * fade;
}

void main() {
    vec2 physCoord = FlutterFragCoord().xy;
    vec2 logicalCoord = physCoord / uPixelRatio;

    // --- Scene Rendering ---
    vec2 sceneCoord = vec2(logicalCoord.x, uSize.y - logicalCoord.y);
    vec2 uv = 2.0 * sceneCoord / uSize.xy - 1.0;
    uv.x *= uSize.x / uSize.y;

    tCur = uTime;
    sunDir = normalize(vec3(-1.0, 0.05, 0.0));
    waterDisp = -0.002 * tCur * vec3(-1.0, 0.0, 1.0);
    cloudDisp = -0.05 * tCur * vec3(1.0, 0.0, 1.0);
    birdLen = 1.2; birdVel = 7.0;
    fltBox = vec3(12.0, 4.0, 12.0);

    BirdPM(tCur); birdMat[0] = bdMat; birdPos[0] = bdPos;
    BirdPM(tCur + 10.0); birdMat[1] = bdMat; birdPos[1] = bdPos;

    mat3 vuMat = mat3(0., 0., 1., 0., 1., 0., -1., 0., 0.);
    vec3 rd = vuMat * normalize(vec3(uv, 2.4));
    vec3 ro = vuMat * vec3(0.0, 4.0, -30.0);

    vec3 col = ShowScene(ro, rd);

    // --- Add Reflection ---
    //col += RenderTextReflection(logicalCoord);

    fragColor = vec4(col, 1.0);
}