import React, { useState, useEffect } from 'react';
import { IconShieldCheck, IconStar, IconClock, IconBriefcase, IconMapPin, IconZap, IconCheck } from './Icons.jsx';
import './ProviderPicker.css';

const SERVICE_LABELS = {
  electrician: 'Electrician', plumber: 'Plumber', cleaning: 'Cleaning',
  ac_repair: 'AC Repair', carpenter: 'Carpenter', painter: 'Painter',
  home_tutor: 'Home Tutor', beautician: 'Beautician',
};

function ScoreBar({ label, value, max = 25, color }) {
  const [width, setWidth] = useState(0);
  useEffect(() => {
    const t = setTimeout(() => setWidth((value / max) * 100), 80);
    return () => clearTimeout(t);
  }, [value, max]);
  return (
    <div className="score-bar-row">
      <span className="score-bar-label">{label}</span>
      <div className="score-bar-track" role="progressbar" aria-valuenow={value} aria-valuemax={max}>
        <div className="score-bar-fill" style={{ width: `${width}%`, background: color }} />
      </div>
      <span className="score-bar-val">{value}</span>
    </div>
  );
}

function StarRow({ rating }) {
  return (
    <span className="pp-stars" aria-label={`${rating} stars`}>
      {[1,2,3,4,5].map(n => (
        <IconStar key={n} size={11} className={n <= Math.round(rating) ? 'star-on' : 'star-off'} />
      ))}
      <span className="pp-star-val">{rating}</span>
    </span>
  );
}

function ProviderCard({ provider, rank, onSelect, loading }) {
  const [revealed, setRevealed] = useState(false);
  const isTop = rank === 0;

  useEffect(() => {
    const t = setTimeout(() => setRevealed(true), rank * 120);
    return () => clearTimeout(t);
  }, [rank]);

  const scoreEntries = [
    { label: 'Rating',      value: provider.scores.rating,     max: 25, color: '#f59e0b' },
    { label: 'Experience',  value: provider.scores.experience,  max: 15, color: '#3b82f6' },
    { label: 'Response',    value: provider.scores.response,    max: 20, color: '#10b981' },
    { label: 'Completion',  value: provider.scores.completion,  max: 20, color: '#8b5cf6' },
    { label: 'Certified',   value: provider.scores.certified,   max: 12, color: '#14b8a6' },
    { label: 'Price',       value: provider.scores.price,       max: 8,  color: '#f43f5e' },
  ];

  return (
    <div
      className={`pp-card ${isTop ? 'pp-card-top' : ''} ${revealed ? 'pp-card-in' : ''}`}
      style={{ '--rank-delay': `${rank * 120}ms` }}
      aria-label={`Provider option ${rank + 1}: ${provider.name}`}
    >
      {isTop && <div className="pp-top-badge"><IconZap size={11} /> AI Top Pick</div>}

      <div className="pp-card-head">
        <div className="pp-avatar" aria-hidden="true">
          {provider.name.slice(0, 2).toUpperCase()}
        </div>
        <div className="pp-info">
          <div className="pp-name">{provider.name}</div>
          <StarRow rating={provider.rating} />
          <div className="pp-meta-row">
            <span className="pp-meta"><IconMapPin size={11}/> {provider.area}</span>
            <span className="pp-meta"><IconBriefcase size={11}/> {provider.jobs} jobs</span>
            <span className="pp-meta"><IconClock size={11}/> ~{provider.responseTime}min</span>
          </div>
        </div>
        <div className="pp-score-circle" style={{ '--score': provider.total_score }}>
          <svg viewBox="0 0 36 36" aria-hidden="true">
            <circle cx="18" cy="18" r="15.9" fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth="2.5" />
            <circle
              cx="18" cy="18" r="15.9" fill="none"
              stroke={isTop ? '#10b981' : '#6366f1'} strokeWidth="2.5"
              strokeDasharray={`${(provider.total_score / 100) * 100} 100`}
              strokeLinecap="round" transform="rotate(-90 18 18)"
            />
          </svg>
          <span className="pp-score-num">{Math.round(provider.total_score)}</span>
        </div>
      </div>

      <div className="pp-scores">
        {scoreEntries.map(e => (
          <ScoreBar key={e.label} {...e} />
        ))}
      </div>

      <div className="pp-card-foot">
        <div className="pp-price-hint">
          <span className="pp-rate">PKR {provider.pricePerHr.toLocaleString()}/hr</span>
          {provider.certified && (
            <span className="pp-cert"><IconShieldCheck size={11}/> Certified</span>
          )}
          <span className="pp-completion">{provider.completionRate}% completion</span>
        </div>
        <button
          className={`pp-book-btn ${isTop ? 'pp-book-top' : ''}`}
          onClick={() => onSelect(provider)}
          disabled={loading}
          aria-label={`Book ${provider.name}`}
        >
          {loading ? <span className="pp-spinner" /> : <><IconCheck size={14}/> Book This</>}
        </button>
      </div>
    </div>
  );
}

export default function ProviderPicker({ top3, service, city, onSelect, loading }) {
  if (!top3?.length) return null;
  return (
    <div className="pp-wrap fade-up" role="region" aria-label="Choose a provider">
      <div className="pp-header">
        <div className="pp-header-left">
          <h3 className="pp-title">Choose Your Provider</h3>
          <p className="pp-subtitle">
            {SERVICE_LABELS[service] || service} in <strong>{city}</strong> — ranked by AI across 6 factors
          </p>
        </div>
        <div className="pp-count-badge">{top3.length} found</div>
      </div>

      <div className="pp-grid">
        {top3.map((p, i) => (
          <ProviderCard key={p.id} provider={p} rank={i} onSelect={onSelect} loading={loading} />
        ))}
      </div>

      <p className="pp-hint">Agents already ran Intent → Discovery → Ranking. Choose a provider to trigger Pricing → Booking → Followup.</p>
    </div>
  );
}
