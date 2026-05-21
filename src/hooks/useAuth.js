import { useState, useEffect } from 'react';
import { auth, signInWithGoogle, signInAsGuest, logOut, onAuthStateChanged } from '../firebase.js';

export function useAuth() {
  const [user, setUser] = useState(undefined); // undefined = loading

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (u) => setUser(u));
    return unsub;
  }, []);

  return { user, signInWithGoogle, signInAsGuest, logOut };
}
