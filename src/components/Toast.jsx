import React from 'react';
import './Toast.css';

const TYPE_ICONS = { success: '✅', error: '❌', info: 'ℹ️', warning: '⚠️' };

export default function ToastContainer({ toasts, onDismiss }) {
  if (!toasts.length) return null;
  return (
    <div className="toast-container">
      {toasts.map(t => (
        <div key={t.id} className={`toast toast-${t.type} fade-up`} onClick={() => onDismiss(t.id)}>
          <span className="toast-icon">{TYPE_ICONS[t.type] || 'ℹ️'}</span>
          <span className="toast-msg">{t.message}</span>
          <button className="toast-close" onClick={(e) => { e.stopPropagation(); onDismiss(t.id); }}>×</button>
        </div>
      ))}
    </div>
  );
}
