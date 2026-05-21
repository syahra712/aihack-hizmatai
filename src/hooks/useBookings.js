import { useState, useEffect, useRef, useCallback } from 'react';
import {
  collection, addDoc, updateDoc, getDocs, doc,
  query, orderBy, limit, serverTimestamp,
} from 'firebase/firestore';
import { db } from '../firebase.js';

// Falls back to localStorage when user is not signed in (guest/anonymous without uid)
function localLoad() {
  try { return JSON.parse(localStorage.getItem('hizmat_bookings') || '[]'); }
  catch { return []; }
}

export function useBookings(uid) {
  const [bookings, setBookings] = useState(localLoad);
  const [loading, setLoading]   = useState(false);
  const prevUidRef = useRef(null);

  // Guest-to-authenticated migration + load from Firestore when uid is available
  useEffect(() => {
    if (!uid) { setBookings(localLoad()); return; }

    const wasGuest = prevUidRef.current === null;
    prevUidRef.current = uid;

    const ref = collection(db, 'users', uid, 'bookings');

    const migrateAndLoad = async () => {
      setLoading(true);
      try {
        if (wasGuest) {
          const localBookings = localLoad();
          if (localBookings.length > 0) {
            await Promise.all(localBookings.map(b => addDoc(ref, {
              ...b,
              _createdAt: serverTimestamp(),
            })));
            localStorage.removeItem('hizmat_bookings');
          }
        }
        const snap = await getDocs(query(ref, orderBy('_createdAt', 'desc'), limit(20)));
        setBookings(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      } catch {
        setBookings(localLoad());
      } finally {
        setLoading(false);
      }
    };

    migrateAndLoad();
  }, [uid]);

  const saveBooking = useCallback(async (booking) => {
    const entry = {
      booking_id: booking.booking_id,
      provider:   booking.provider.name,
      service:    booking.service,
      city:       booking.city,
      slot:       booking.slot,
      total:      booking.pricing.total,
      status:     'unpaid',
      _createdAt: serverTimestamp(),
    };

    if (uid) {
      const ref = collection(db, 'users', uid, 'bookings');
      const docRef = await addDoc(ref, entry);
      setBookings(prev => [{ id: docRef.id, ...entry, _createdAt: new Date() }, ...prev].slice(0, 20));
    } else {
      const updated = [{ ...entry, _createdAt: new Date().toISOString() }, ...bookings].slice(0, 20);
      localStorage.setItem('hizmat_bookings', JSON.stringify(updated));
      setBookings(updated);
    }
  }, [uid, bookings]);

  const updateStatus = useCallback(async (bookingId, status) => {
    if (uid) {
      const snap = await getDocs(collection(db, 'users', uid, 'bookings'));
      const match = snap.docs.find(d => d.data().booking_id === bookingId);
      if (match) await updateDoc(doc(db, 'users', uid, 'bookings', match.id), { status });
    }
    setBookings(prev => {
      const updated = prev.map(b => b.booking_id === bookingId ? { ...b, status } : b);
      if (!uid) localStorage.setItem('hizmat_bookings', JSON.stringify(updated));
      return updated;
    });
  }, [uid]);

  return { bookings, loading, saveBooking, updateStatus };
}
