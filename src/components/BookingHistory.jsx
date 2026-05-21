import React, { useState } from 'react';
import { IconX, IconCalendar, IconMapPin, IconClock, IconActivity, IconCheck, IconCreditCard } from './Icons.jsx';
import './BookingHistory.css';

const SERVICE_EMOJI = {
  electrician: '⚡', plumber: '🔧', cleaning: '🧹', ac_repair: '❄️',
  carpenter: '🪚', painter: '🎨', home_tutor: '📚', beautician: '💅',
};

const STATUS_CONFIG = {
  paid:      { label: 'Paid',      className: 'bh-status-paid' },
  unpaid:    { label: 'Unpaid',    className: 'bh-status-unpaid' },
  cancelled: { label: 'Cancelled', className: 'bh-status-cancelled' },
};

const FILTERS = [
  { key: 'all',       label: 'All' },
  { key: 'paid',      label: 'Paid' },
  { key: 'unpaid',    label: 'Unpaid' },
  { key: 'cancelled', label: 'Cancelled' },
];

export default function BookingHistory({ history, onClose }) {
  const [filter, setFilter] = useState('all');

  const filtered = filter === 'all' ? history : history.filter(b => (b.status || 'unpaid') === filter);

  const counts = {
    all: history.length,
    paid: history.filter(b => b.status === 'paid').length,
    unpaid: history.filter(b => !b.status || b.status === 'unpaid').length,
    cancelled: history.filter(b => b.status === 'cancelled').length,
  };

  return (
    <div className="bh-overlay" role="dialog" aria-modal="true" aria-label="Booking history" onClick={e => { if (e.target === e.currentTarget) onClose(); }}>
      <div className="bh-drawer slide-right">
        <div className="bh-head">
          <div className="bh-head-left">
            <IconActivity size={16} />
            <h3>Booking History</h3>
            {history.length > 0 && <span className="bh-count">{history.length}</span>}
          </div>
          <button className="bh-close" onClick={onClose} aria-label="Close history">
            <IconX size={15} />
          </button>
        </div>

        {history.length > 0 && (
          <div className="bh-filters">
            {FILTERS.map(f => (
              <button
                key={f.key}
                className={`bh-filter-btn ${filter === f.key ? 'bh-filter-active' : ''}`}
                onClick={() => setFilter(f.key)}
              >
                {f.label}
                {counts[f.key] > 0 && <span className="bh-filter-count">{counts[f.key]}</span>}
              </button>
            ))}
          </div>
        )}

        {history.length === 0 ? (
          <div className="bh-empty">
            <p>No bookings yet. Book your first service!</p>
          </div>
        ) : filtered.length === 0 ? (
          <div className="bh-empty">
            <p>No {filter} bookings.</p>
          </div>
        ) : (
          <ul className="bh-list">
            {filtered.map((b, i) => {
              const status = b.status || 'unpaid';
              const cfg = STATUS_CONFIG[status] || STATUS_CONFIG.unpaid;
              return (
                <li key={b.booking_id} className={`bh-item fade-up ${status === 'cancelled' ? 'bh-item-cancelled' : ''}`} style={{ animationDelay: `${i * 40}ms` }}>
                  <div className="bh-emoji" aria-hidden="true">
                    {SERVICE_EMOJI[b.service] || '🔨'}
                  </div>
                  <div className="bh-item-info">
                    <div className="bh-item-top">
                      <span className="bh-provider">{b.provider}</span>
                      <span className={`bh-status ${cfg.className}`}>{cfg.label}</span>
                    </div>
                    <div className="bh-item-price">
                      <span className={`bh-total ${status === 'cancelled' ? 'bh-total-strike' : ''}`}>PKR {b.total?.toLocaleString()}</span>
                    </div>
                    <div className="bh-item-meta">
                      <span><IconMapPin size={10}/> {b.city}</span>
                      <span><IconCalendar size={10}/> {new Date(b.slot?.date || b._createdAt).toLocaleDateString()}</span>
                      {b.slot?.time && <span><IconClock size={10}/> {b.slot.time}</span>}
                    </div>
                    <div className="bh-id">{b.booking_id}</div>
                  </div>
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </div>
  );
}
