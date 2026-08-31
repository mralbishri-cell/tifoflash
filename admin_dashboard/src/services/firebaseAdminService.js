import { initializeApp } from 'firebase/app';
import { getDatabase, ref, set } from 'firebase/database';

// Firebase Config linked to user's live Realtime Database
const firebaseConfig = {
  apiKey: "AIzaSyDftMnZer4Fjsq90VX2GMa3U0LUcaSyiNw",
  authDomain: "tifoflash.firebaseapp.com",
  databaseURL: "https://tifoflash-default-rtdb.europe-west1.firebasedatabase.app",
  projectId: "tifoflash",
  storageBucket: "tifoflash.firebasestorage.app",
  messagingSenderId: "554205703255",
  appId: "1:554205703255:web:f06d0efbf433cc78660712"
};

let db = null;
try {
  const app = initializeApp(firebaseConfig);
  db = getDatabase(app);
} catch (e) {
  console.warn("Firebase initialized in local simulation mode.", e);
}

export const MATCH_ID = "match_2026_final";

/**
 * Broadcast live action payload to Firebase Realtime Database
 */
export async function broadcastLiveAction(payload) {
  const matchId = MATCH_ID;
  const targetNode = `/matches/${matchId}/live_action`;

  const fullRecord = {
    action_id: payload.action_id || `act_${Date.now()}`,
    timestamp: Date.now(),
    type: payload.type, // STROBE | SOLID_COLOR | WAVE | TEXT_DISPLAY | SPONSOR_POPUP
    target_type: payload.target_type || "ALL", // SECTOR | SEAT | ALL
    target_ids: payload.target_ids || [],
    payload: {
      color_hex: payload.color_hex || "#00E676",
      flash_frequency_ms: payload.flash_frequency_ms || 150,
      duration_seconds: payload.duration_seconds || 10,
      text_char: payload.text_char || "",
      wave_delay_step_ms: payload.wave_delay_step_ms || 250,
      sponsor: payload.sponsor || null
    }
  };

  console.log(`[AdminService] Broadcasting payload to ${targetNode}:`, fullRecord);

  if (db) {
    try {
      const actionRef = ref(db, targetNode);
      await set(actionRef, fullRecord);
      return { success: true, mode: 'FIREBASE_LIVE', record: fullRecord };
    } catch (err) {
      console.error("[AdminService] Firebase Write Error:", err);
    }
  }

  // Fallback simulation mode
  return { success: true, mode: 'SIMULATION', record: fullRecord };
}
