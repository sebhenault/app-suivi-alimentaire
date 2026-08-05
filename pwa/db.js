// Stockage local des repas via IndexedDB (fonctionne hors-ligne).

const DB_NAME = "monassiette";
const DB_VERSION = 1;
const STORE = "meals";

function open() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, DB_VERSION);
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains(STORE)) {
        const os = db.createObjectStore(STORE, { keyPath: "id" });
        os.createIndex("date", "date", { unique: false });
      }
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

function tx(db, mode) {
  return db.transaction(STORE, mode).objectStore(STORE);
}

export async function saveMeal(meal) {
  const db = await open();
  return new Promise((resolve, reject) => {
    const req = tx(db, "readwrite").put(meal);
    req.onsuccess = () => resolve(meal);
    req.onerror = () => reject(req.error);
  });
}

export async function deleteMeal(id) {
  const db = await open();
  return new Promise((resolve, reject) => {
    const req = tx(db, "readwrite").delete(id);
    req.onsuccess = () => resolve();
    req.onerror = () => reject(req.error);
  });
}

export async function allMeals() {
  const db = await open();
  return new Promise((resolve, reject) => {
    const req = tx(db, "readonly").getAll();
    req.onsuccess = () => {
      const list = req.result || [];
      list.sort((a, b) => new Date(b.date) - new Date(a.date));
      resolve(list);
    };
    req.onerror = () => reject(req.error);
  });
}

export function uuid() {
  if (crypto.randomUUID) return crypto.randomUUID();
  return "id-" + Date.now() + "-" + Math.random().toString(16).slice(2);
}
