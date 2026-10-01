/**
 * Firebase Firestore Configuration & Data Service (Modular SDK v9/v10)
 * 
 * Ye file Firebase Firestore setup aur invoice save/fetch functions provide karti hai.
 * Vercel par live karne ke liye Environment Variables me Firebase keys daalein:
 * - NEXT_PUBLIC_FIREBASE_API_KEY
 * - NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN
 * - NEXT_PUBLIC_FIREBASE_PROJECT_ID
 * - NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET
 * - NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID
 * - NEXT_PUBLIC_FIREBASE_APP_ID
 * 
 * Note: Agar Firebase keys configured nahi hain, tab bhi app band nahi hoga!
 * Ye automatically browser ke LocalStorage me bill save karega taaki aap bina setup ke turant test kar sakein.
 */

import { initializeApp, getApps, getApp } from "firebase/app";
import {
  getFirestore,
  collection,
  addDoc,
  getDocs,
  doc,
  deleteDoc,
  updateDoc,
  query,
  orderBy,
  serverTimestamp,
} from "firebase/firestore";

// Firebase configuration (Environment variables + fallback)
const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || "",
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || "",
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "",
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || "",
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || "",
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || "",
};

// Check if Firebase is properly configured with valid credentials
export const isFirebaseConfigured = () => {
  return Boolean(
    firebaseConfig.apiKey &&
    firebaseConfig.apiKey !== "your_api_key_here" &&
    firebaseConfig.projectId &&
    firebaseConfig.projectId !== "your_project_id"
  );
};

// Initialize Firebase App singleton
let app = null;
let db = null;

if (typeof window !== "undefined") {
  try {
    if (isFirebaseConfigured()) {
      app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
      db = getFirestore(app);
      console.log("Firebase Firestore initialized successfully.");
    } else {
      console.info("Firebase keys not detected in .env.local — using Browser Storage mode.");
    }
  } catch (err) {
    console.warn("Firebase initialization warning:", err.message);
  }
}

export { app, db };

// LocalStorage key for offline/fallback mode
const LOCAL_STORAGE_KEY = "proforma_invoices_local";

// Helper: Get invoices from LocalStorage
const getLocalInvoices = () => {
  if (typeof window === "undefined") return [];
  try {
    const raw = localStorage.getItem(LOCAL_STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch (e) {
    console.error("Error reading localStorage:", e);
    return [];
  }
};

// Helper: Write invoices to LocalStorage
const setLocalInvoices = (invoices) => {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(invoices));
  } catch (e) {
    console.error("Error writing to localStorage:", e);
  }
};

/**
 * 1-Click Save Invoice Function
 * Firestore me document save karta hai (Collection: "invoices")
 * Agar Firebase configured nahi hai to LocalStorage me save karta hai.
 * 
 * @param {Object} invoiceData - Form se aaya hua complete invoice object
 * @returns {Promise<{success: boolean, id: string, source: string, mode: string}>}
 */
export async function saveInvoice(invoiceData) {
  const timestamp = new Date().toISOString();
  const invoicePayload = {
    ...invoiceData,
    updatedAt: timestamp,
  };

  // 1. Firebase Firestore Save (if configured)
  if (isFirebaseConfigured() && db) {
    try {
      if (invoiceData.id && !invoiceData.id.startsWith("local_")) {
        // Existing document update karein
        const docRef = doc(db, "invoices", invoiceData.id);
        const { id, ...dataToUpdate } = invoicePayload;
        await updateDoc(docRef, {
          ...dataToUpdate,
          updatedAt: serverTimestamp(),
        });
        return { success: true, id: invoiceData.id, source: "firestore", mode: "updated" };
      } else {
        // Naya document create karein
        const { id, ...dataToInsert } = invoicePayload;
        const colRef = collection(db, "invoices");
        const docRef = await addDoc(colRef, {
          ...dataToInsert,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
        return { success: true, id: docRef.id, source: "firestore", mode: "created" };
      }
    } catch (err) {
      console.warn("Firestore save failed, falling back to LocalStorage:", err);
    }
  }

  // 2. Offline / LocalStorage Fallback Save
  const existing = getLocalInvoices();
  let savedId = invoiceData.id;

  if (savedId) {
    const idx = existing.findIndex((item) => item.id === savedId);
    if (idx !== -1) {
      existing[idx] = { ...invoicePayload, id: savedId };
    } else {
      existing.unshift({ ...invoicePayload, id: savedId, createdAt: timestamp });
    }
  } else {
    savedId = `local_${Date.now()}`;
    existing.unshift({
      ...invoicePayload,
      id: savedId,
      createdAt: timestamp,
    });
  }

  setLocalInvoices(existing);
  return {
    success: true,
    id: savedId,
    source: "localStorage",
    mode: invoiceData.id ? "updated" : "created",
    note: "Saved locally in browser storage. Add Firebase keys in .env.local to sync directly with Cloud Firestore.",
  };
}

/**
 * Fetch all saved invoices (Firestore or LocalStorage)
 */
export async function getInvoices() {
  if (isFirebaseConfigured() && db) {
    try {
      const colRef = collection(db, "invoices");
      const q = query(colRef, orderBy("updatedAt", "desc"));
      const snapshot = await getDocs(q);
      const invoices = [];
      snapshot.forEach((docSnapshot) => {
        const data = docSnapshot.data();
        invoices.push({
          id: docSnapshot.id,
          ...data,
          createdAt: data.createdAt?.toDate?.() ? data.createdAt.toDate().toISOString() : data.createdAt || null,
          updatedAt: data.updatedAt?.toDate?.() ? data.updatedAt.toDate().toISOString() : data.updatedAt || null,
          source: "firestore",
        });
      });
      return invoices;
    } catch (err) {
      console.warn("Firestore fetch error, fallback to local:", err);
    }
  }

  const localList = getLocalInvoices();
  return localList.map((item) => ({ ...item, source: "localStorage" }));
}

/**
 * Delete invoice by ID
 */
export async function deleteInvoice(id) {
  if (isFirebaseConfigured() && db && !id.startsWith("local_")) {
    try {
      const docRef = doc(db, "invoices", id);
      await deleteDoc(docRef);
      return { success: true };
    } catch (err) {
      console.warn("Firestore delete failed, checking local:", err);
    }
  }

  const existing = getLocalInvoices();
  const filtered = existing.filter((item) => item.id !== id);
  setLocalInvoices(filtered);
  return { success: true };
}

export default {
  saveInvoice,
  getInvoices,
  deleteInvoice,
  isFirebaseConfigured,
  db,
  app,
};
