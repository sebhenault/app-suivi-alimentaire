import { allMeals, saveMeal, deleteMeal, uuid } from "./db.js";
import { analyze } from "./claude.js";

// ---------- Constantes ----------
const NUT = [
  { key: "protein", label: "Protéines", unit: "g", color: "#3b82f6" },
  { key: "carbs",   label: "Glucides",  unit: "g", color: "#2ea05c" },
  { key: "fat",     label: "Lipides",   unit: "g", color: "#f5a623" },
  { key: "fiber",   label: "Fibres",    unit: "g", color: "#a3763b" },
  { key: "sugar",   label: "Sucres",    unit: "g", color: "#ec4899", limit: true },
  { key: "sodium",  label: "Sodium",    unit: "mg", color: "#e5484d", limit: true },
  { key: "calcium", label: "Calcium",   unit: "mg", color: "#14b8a6" },
];
const NUT_KEYS = ["calories", ...NUT.map(n => n.key)];
const DEFAULT_GOALS = {
  calories: 2000, protein: 100, carbs: 250, fat: 70,
  fiber: 30, sugar: 50, sodium: 2300, calcium: 1000,
};
const MEAL_TYPES = [
  { key: "breakfast", label: "Petit-déjeuner", emoji: "🌅" },
  { key: "lunch", label: "Déjeuner", emoji: "☀️" },
  { key: "dinner", label: "Dîner", emoji: "🌙" },
  { key: "snack", label: "Collation", emoji: "🥕" },
];

// ---------- Réglages / objectifs (localStorage) ----------
const getSettings = () => ({
  apiKey: localStorage.getItem("apiKey") || "",
  model: localStorage.getItem("model") || "claude-sonnet-5",
});
const getGoals = () => {
  try { return { ...DEFAULT_GOALS, ...JSON.parse(localStorage.getItem("goals") || "{}") }; }
  catch { return { ...DEFAULT_GOALS }; }
};
const setGoals = (g) => localStorage.setItem("goals", JSON.stringify(g));

// ---------- Utilitaires ----------
const $ = (sel, root = document) => root.querySelector(sel);
const app = $("#app");
const n0 = (v) => Math.round(Number(v) || 0);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, c =>
  ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

function mealTypeInfo(key) { return MEAL_TYPES.find(m => m.key === key) || MEAL_TYPES[3]; }
function suggestedType() {
  const h = new Date().getHours();
  if (h >= 5 && h < 11) return "breakfast";
  if (h >= 11 && h < 15) return "lunch";
  if (h >= 15 && h < 18) return "snack";
  return "dinner";
}
function sumNut(items) {
  const t = { calories: 0 }; NUT.forEach(x => t[x.key] = 0);
  for (const it of items) for (const k of NUT_KEYS) t[k] += Number(it[k]) || 0;
  return t;
}
function isToday(iso) {
  const d = new Date(iso), n = new Date();
  return d.getFullYear() === n.getFullYear() && d.getMonth() === n.getMonth() && d.getDate() === n.getDate();
}
function dayKey(iso) { const d = new Date(iso); return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`; }
function dayTitle(iso) {
  const d = new Date(iso), n = new Date();
  const y = new Date(n); y.setDate(n.getDate() - 1);
  if (dayKey(iso) === dayKey(n.toISOString())) return "Aujourd'hui";
  if (dayKey(iso) === dayKey(y.toISOString())) return "Hier";
  return d.toLocaleDateString("fr-FR", { weekday: "long", day: "numeric", month: "long" });
}
function timeStr(iso) { return new Date(iso).toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" }); }

function toast(msg) {
  let t = $(".toast");
  if (!t) { t = document.createElement("div"); t.className = "toast"; document.body.appendChild(t); }
  t.textContent = msg; t.classList.add("show");
  clearTimeout(t._to); t._to = setTimeout(() => t.classList.remove("show"), 2200);
}

// Redimensionne un fichier image en dataURL JPEG (limite l'upload).
function fileToDataURL(file, maxDim = 1280) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const img = new Image();
      img.onload = () => {
        let { width: w, height: h } = img;
        const m = Math.max(w, h);
        if (m > maxDim) { const s = maxDim / m; w = Math.round(w * s); h = Math.round(h * s); }
        const c = document.createElement("canvas");
        c.width = w; c.height = h;
        c.getContext("2d").drawImage(img, 0, 0, w, h);
        resolve(c.toDataURL("image/jpeg", 0.7));
      };
      img.onerror = reject;
      img.src = reader.result;
    };
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

// ---------- Composants HTML ----------
function ringHTML(consumed, goal) {
  const r = 76, circ = 2 * Math.PI * r;
  const p = goal > 0 ? Math.min(consumed / goal, 1) : 0;
  const over = goal > 0 && consumed > goal;
  const off = circ * (1 - p);
  return `<div class="ring-wrap"><div class="ring">
    <svg width="168" height="168" viewBox="0 0 168 168">
      <circle cx="84" cy="84" r="${r}" fill="none" stroke="var(--line)" stroke-width="14"/>
      <circle cx="84" cy="84" r="${r}" fill="none" stroke="${over ? 'var(--warn)' : 'var(--accent)'}"
        stroke-width="14" stroke-linecap="round"
        stroke-dasharray="${circ.toFixed(1)}" stroke-dashoffset="${off.toFixed(1)}"/>
    </svg>
    <div class="center">
      <div class="kcal">${n0(consumed)}</div>
      <div class="kcal-sub">/ ${n0(goal)} kcal</div>
      ${over ? '<div class="over">dépassé</div>' : ''}
    </div>
  </div></div>`;
}
function macroBarHTML(def, consumed, goal) {
  const p = goal > 0 ? Math.min(consumed / goal, 1) * 100 : 0;
  const over = goal > 0 && consumed > goal;
  const valClass = over && def.limit ? "val over" : "val";
  const fill = over && def.limit ? "var(--danger)" : def.color;
  return `<div class="macro">
    <div class="row"><span>${def.label}</span>
      <span class="${valClass}">${n0(consumed)} / ${n0(goal)} ${def.unit}</span></div>
    <div class="bar"><span style="width:${p}%;background:${fill}"></span></div>
  </div>`;
}

// ---------- Écrans ----------
async function renderJournal() {
  setTab("journal");
  const goals = getGoals();
  const meals = (await allMeals()).filter(m => isToday(m.date));
  const total = sumNut(meals.flatMap(m => m.items));

  let mealsHTML;
  if (!meals.length) {
    mealsHTML = `<div class="empty"><div class="big">🍽️</div>
      <p><b>Aucun repas aujourd'hui</b></p>
      <p class="hint">Touchez le bouton ＋ en bas pour ajouter votre premier repas.</p></div>`;
  } else {
    mealsHTML = meals.map(m => {
      const info = mealTypeInfo(m.type);
      const thumb = m.image
        ? `<img class="thumb" src="${m.image}" alt="">`
        : `<div class="thumb">${info.emoji}</div>`;
      const nm = m.note || (m.items[0]?.name ? (m.items.length > 1 ? `${m.items[0].name} +${m.items.length - 1}` : m.items[0].name) : info.label);
      return `<div class="card meal" data-meal="${m.id}">
        ${thumb}
        <div class="info"><div class="name">${esc(nm)}</div>
          <div class="sub">${info.emoji} ${info.label} · ${timeStr(m.date)}</div></div>
        <div class="kcal">${n0(sumNut(m.items).calories)} kcal</div>
      </div>`;
    }).join("");
  }

  app.innerHTML = `<h1 class="screen-title">Aujourd'hui</h1>
    <div class="card">${ringHTML(total.calories, goals.calories)}
      <div style="margin-top:14px">${NUT.map(d => macroBarHTML(d, total[d.key], goals[d.key])).join("")}</div>
    </div>
    ${mealsHTML}`;

  app.querySelectorAll("[data-meal]").forEach(el =>
    el.onclick = async () => {
      const m = (await allMeals()).find(x => x.id === el.dataset.meal);
      if (m) openMealDetail(m);
    });
}

async function renderHistory() {
  setTab("history");
  const goals = getGoals();
  const meals = await allMeals();
  const groups = {};
  for (const m of meals) (groups[dayKey(m.date)] ||= { date: m.date, meals: [] }).meals.push(m);
  const days = Object.values(groups).sort((a, b) => new Date(b.date) - new Date(a.date));

  if (!days.length) {
    app.innerHTML = `<h1 class="screen-title">Historique</h1>
      <div class="empty"><div class="big">📊</div><p><b>Pas encore d'historique</b></p>
      <p class="hint">Vos journées apparaîtront ici au fil du temps.</p></div>`;
    return;
  }
  app.innerHTML = `<h1 class="screen-title">Historique</h1>` + days.map(d => {
    const t = sumNut(d.meals.flatMap(m => m.items));
    const p = goals.calories > 0 ? Math.min(t.calories / goals.calories, 1) * 100 : 0;
    return `<div class="card">
      <div class="row" style="display:flex;justify-content:space-between;font-weight:700">
        <span>${dayTitle(d.date)}</span><span>${n0(t.calories)} kcal</span></div>
      <div class="bar" style="margin:8px 0"><span style="width:${p}%;background:var(--accent)"></span></div>
      <div class="hint">${d.meals.length} repas · P ${n0(t.protein)}g · G ${n0(t.carbs)}g · L ${n0(t.fat)}g</div>
    </div>`;
  }).join("");
}

function renderGoals() {
  setTab("goals");
  const g = getGoals();
  const rows = [
    { key: "calories", label: "Calories", unit: "kcal" },
    ...NUT.map(x => ({ key: x.key, label: x.label, unit: x.unit })),
  ];
  app.innerHTML = `<h1 class="screen-title">Objectifs</h1>
    <div class="card">${rows.map(r => `
      <div class="num-row"><label>${r.label}</label>
        <input type="number" inputmode="decimal" data-goal="${r.key}" value="${g[r.key]}"> </div>`).join("")}
    </div>
    <p class="hint" style="margin:0 4px 14px">Sucres et sodium sont des limites : ils deviennent rouges dans le journal s'ils sont dépassés.</p>
    <button class="btn secondary" id="reset-goals">Réinitialiser les valeurs par défaut</button>`;

  app.querySelectorAll("[data-goal]").forEach(inp =>
    inp.onchange = () => { const g2 = getGoals(); g2[inp.dataset.goal] = Number(inp.value) || 0; setGoals(g2); toast("Objectif enregistré"); });
  $("#reset-goals").onclick = () => { setGoals({ ...DEFAULT_GOALS }); renderGoals(); toast("Réinitialisé"); };
}

function renderSettings() {
  setTab("settings");
  const s = getSettings();
  const hasKey = !!s.apiKey;
  app.innerHTML = `<h1 class="screen-title">Réglages</h1>
    <div class="card">
      <h2 style="margin-top:0">Clé API Claude</h2>
      ${hasKey ? `
        <p class="center-row" style="justify-content:flex-start;color:var(--accent);font-weight:700">✓ Clé enregistrée</p>
        <button class="btn danger" id="del-key">Supprimer la clé</button>` : `
        <label class="field"><span class="lab">Collez votre clé (sk-ant-...)</span>
          <input type="password" id="api-key" autocomplete="off" placeholder="sk-ant-..."></label>
        <button class="btn" id="save-key">Enregistrer</button>`}
      <p class="hint" style="margin-top:12px">Créez une clé sur console.anthropic.com. Elle est stockée uniquement sur cet appareil. Aucune connexion demandée ensuite.</p>
    </div>
    <div class="card">
      <h2 style="margin-top:0">Modèle d'analyse</h2>
      <select id="model">
        <option value="claude-sonnet-5">Sonnet (équilibré)</option>
        <option value="claude-opus-5">Opus (plus précis)</option>
        <option value="claude-haiku-4-5-20251001">Haiku (plus rapide/éco)</option>
      </select>
    </div>
    <div class="card">
      <h2 style="margin-top:0">À propos</h2>
      <p class="hint">MonAssiette — version PWA 0.1. Vos données (journal, objectifs) restent sur cet appareil. Seules les photos analysées sont envoyées à l'API Claude, au moment de l'analyse.</p>
    </div>`;

  $("#model").value = s.model;
  $("#model").onchange = e => { localStorage.setItem("model", e.target.value); toast("Modèle mis à jour"); };
  if (hasKey) {
    $("#del-key").onclick = () => { localStorage.removeItem("apiKey"); renderSettings(); toast("Clé supprimée"); };
  } else {
    $("#save-key").onclick = () => {
      const v = $("#api-key").value.trim();
      if (!v) return;
      localStorage.setItem("apiKey", v); renderSettings(); toast("Clé enregistrée");
    };
  }
}

// ---------- Détail d'un repas ----------
function openMealDetail(m) {
  const info = mealTypeInfo(m.type);
  const t = sumNut(m.items);
  const ov = document.createElement("div");
  ov.className = "overlay";
  ov.innerHTML = `
    <div class="top"><button data-close>‹ Fermer</button><span class="t">${timeStr(m.date)}</span><span style="width:60px"></span></div>
    ${m.image ? `<img class="preview-img" src="${m.image}" alt="">` : ""}
    <div class="card" style="margin-top:12px">
      <div class="hint">${info.emoji} ${info.label}${m.note ? " · " + esc(m.note) : ""}</div>
    </div>
    <h2>Aliments</h2>
    <div class="card">${m.items.map(it => `
      <div class="num-row"><div><b>${esc(it.name)}</b><div class="hint">${n0(it.quantityG)} g · P ${n0(it.protein)} · G ${n0(it.carbs)} · L ${n0(it.fat)}</div></div>
      <div style="font-weight:700">${n0(it.calories)} kcal</div></div>`).join("")}</div>
    <h2>Total</h2>
    <div class="card">
      <div class="num-row"><label>Calories</label><b>${n0(t.calories)} kcal</b></div>
      ${NUT.map(d => `<div class="num-row"><label>${d.label}</label><b>${n0(t[d.key])} ${d.unit}</b></div>`).join("")}
    </div>
    <button class="btn danger" data-del>Supprimer ce repas</button>`;
  document.body.appendChild(ov);
  ov.querySelector("[data-close]").onclick = () => ov.remove();
  ov.querySelector("[data-del]").onclick = async () => {
    await deleteMeal(m.id); ov.remove(); renderJournal(); toast("Repas supprimé");
  };
}

// ---------- Ajout d'un repas ----------
function openAddMeal() {
  const state = {
    image: null, mode: "plate", type: suggestedType(),
    hint: "", drafts: [], confidence: null, notes: "", analyzing: false,
  };
  const ov = document.createElement("div");
  ov.className = "overlay";
  document.body.appendChild(ov);

  const camInput = Object.assign(document.createElement("input"),
    { type: "file", accept: "image/*", capture: "environment", hidden: true });
  const galInput = Object.assign(document.createElement("input"),
    { type: "file", accept: "image/*", hidden: true });
  ov.append(camInput, galInput);
  camInput.onchange = () => pickImage(camInput.files[0]);
  galInput.onchange = () => pickImage(galInput.files[0]);

  async function pickImage(file) {
    if (!file) return;
    try { state.image = await fileToDataURL(file); draw(); }
    catch { toast("Impossible de lire l'image"); }
  }

  function total() { return sumNut(state.drafts); }

  async function doAnalyze() {
    if (!state.image || state.analyzing) return;
    state.analyzing = true; draw();
    try {
      const s = getSettings();
      const r = await analyze(state.image, state.mode, state.hint, s);
      state.drafts = r.items; state.confidence = r.confidence; state.notes = r.notes;
    } catch (e) {
      alert(e.message || "Analyse impossible.");
    } finally {
      state.analyzing = false; draw();
    }
  }

  async function save() {
    if (!state.drafts.length) return;
    const meal = {
      id: uuid(), date: new Date().toISOString(), type: state.type,
      note: state.hint, image: state.image, confidence: state.confidence,
      items: state.drafts.map(d => ({
        name: d.name || "Aliment", quantityG: Number(d.quantityG) || 0,
        calories: Number(d.calories) || 0, protein: Number(d.protein) || 0,
        carbs: Number(d.carbs) || 0, fat: Number(d.fat) || 0, fiber: Number(d.fiber) || 0,
        sugar: Number(d.sugar) || 0, sodium: Number(d.sodium) || 0, calcium: Number(d.calcium) || 0,
      })),
    };
    await saveMeal(meal); ov.remove(); renderJournal(); toast("Repas enregistré");
  }

  const FIELDS = [
    { key: "quantityG", label: "Quantité", unit: "g" },
    { key: "calories", label: "Calories", unit: "kcal" },
    ...NUT.map(x => ({ key: x.key, label: x.label, unit: x.unit })),
  ];

  function draw() {
    const t = total();
    ov.querySelectorAll(".dyn").forEach(e => e.remove());
    const wrap = document.createElement("div"); wrap.className = "dyn";
    wrap.innerHTML = `
      <div class="top">
        <button data-close>Annuler</button><span class="t">Nouveau repas</span>
        <button data-save ${state.drafts.length ? "" : "disabled"}>Enregistrer</button>
      </div>

      <div class="seg" id="mode-seg">
        <button data-mode="plate" class="${state.mode === 'plate' ? 'on' : ''}">🍴 Plat</button>
        <button data-mode="label" class="${state.mode === 'label' ? 'on' : ''}">🏷️ Étiquette</button>
      </div>

      <label class="field"><span class="lab">Repas</span>
        <select id="type-sel">${MEAL_TYPES.map(m =>
          `<option value="${m.key}" ${m.key === state.type ? "selected" : ""}>${m.emoji} ${m.label}</option>`).join("")}</select>
      </label>

      ${state.image ? `<img class="preview-img" src="${state.image}" alt="">` : ""}
      <div class="btn-row" style="margin-top:10px">
        <button class="btn secondary" id="btn-cam">📷 Photo</button>
        <button class="btn secondary" id="btn-gal">🖼️ Galerie</button>
      </div>

      <label class="field"><span class="lab">Précisions (facultatif)</span>
        <textarea id="hint" placeholder="ex. bol de 300 ml, marque…">${esc(state.hint)}</textarea></label>

      <button class="btn" id="btn-analyze" ${!state.image || state.analyzing ? "disabled" : ""}>
        ${state.analyzing ? '<span class="spinner"></span> Analyse en cours…' : "✨ Analyser avec l'IA"}
      </button>
      <button class="btn ghost" id="btn-manual">＋ Ajouter un aliment à la main</button>

      ${(state.drafts.length || state.notes) ? `
        <h2>Aliments (modifiables)</h2>
        ${state.confidence != null ? `<p class="hint">Confiance : ${Math.round(state.confidence * 100)} %</p>` : ""}
        ${state.notes ? `<p class="hint">${esc(state.notes)}</p>` : ""}
        <div id="drafts">${state.drafts.map((d, i) => `
          <details class="item-edit">
            <summary><span>${esc(d.name) || "Aliment"}</span><span class="kc">${n0(d.calories)} kcal</span></summary>
            <label class="field"><span class="lab">Nom</span><input type="text" data-i="${i}" data-f="name" value="${esc(d.name)}"></label>
            ${FIELDS.map(f => `<div class="num-row"><label>${f.label}</label>
              <input type="number" inputmode="decimal" data-i="${i}" data-f="${f.key}" value="${d[f.key] ?? 0}"><span class="badge">${f.unit}</span></div>`).join("")}
            <button class="btn danger" data-rm="${i}" style="margin-top:8px">Supprimer</button>
          </details>`).join("")}</div>
        <div class="card" style="display:flex;justify-content:space-between;font-weight:800">
          <span>Total</span><span>${n0(t.calories)} kcal</span></div>
      ` : ""}
    `;
    ov.appendChild(wrap);

    wrap.querySelector("[data-close]").onclick = () => ov.remove();
    wrap.querySelector("[data-save]").onclick = save;
    wrap.querySelectorAll("#mode-seg button").forEach(b =>
      b.onclick = () => { state.mode = b.dataset.mode; draw(); });
    wrap.querySelector("#type-sel").onchange = e => state.type = e.target.value;
    wrap.querySelector("#btn-cam").onclick = () => camInput.click();
    wrap.querySelector("#btn-gal").onclick = () => galInput.click();
    wrap.querySelector("#hint").oninput = e => state.hint = e.target.value;
    wrap.querySelector("#btn-analyze").onclick = doAnalyze;
    wrap.querySelector("#btn-manual").onclick = () => {
      state.drafts.push({ name: "", quantityG: 0, calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0, sodium: 0, calcium: 0 });
      draw();
    };
    wrap.querySelectorAll("[data-i]").forEach(inp =>
      inp.oninput = () => {
        const i = +inp.dataset.i, f = inp.dataset.f;
        state.drafts[i][f] = f === "name" ? inp.value : (Number(inp.value) || 0);
        const det = inp.closest("details");
        if (f === "name") det.querySelector("summary span").textContent = inp.value || "Aliment";
        if (f === "calories") det.querySelector("summary .kc").textContent = n0(inp.value) + " kcal";
        const totalSpan = wrap.querySelector(".dyn .card span:last-child") ||
          wrap.querySelectorAll(".card")[wrap.querySelectorAll(".card").length - 1]?.querySelector("span:last-child");
        if (totalSpan) totalSpan.textContent = n0(total().calories) + " kcal";
      });
    wrap.querySelectorAll("[data-rm]").forEach(btn =>
      btn.onclick = () => { state.drafts.splice(+btn.dataset.rm, 1); draw(); });
  }

  draw();
}

// ---------- Navigation ----------
function setTab(tab) {
  document.querySelectorAll("#tabbar .tab").forEach(b =>
    b.classList.toggle("on", b.dataset.tab === tab));
}
const ROUTES = { journal: renderJournal, history: renderHistory, goals: renderGoals, settings: renderSettings };
function go(tab) { window.scrollTo(0, 0); (ROUTES[tab] || renderJournal)(); }

document.querySelectorAll("#tabbar .tab").forEach(b => b.onclick = () => go(b.dataset.tab));
$("#fab").onclick = openAddMeal;

// ---------- Service worker + démarrage ----------
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () =>
    navigator.serviceWorker.register("./service-worker.js").catch(() => {}));
}
go("journal");
