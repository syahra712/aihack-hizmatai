import React from 'react';
import { IconAlertTri, IconSearch, IconBrain, IconWind } from './Icons.jsx';
import './DemoBar.css';

const DEMOS = [
  {
    id: 'A_double_booking',
    icon: IconAlertTri,
    label: 'Double Booking',
    desc: 'BookingAgent detects slot clash → reschedules to next available provider',
    color: '#f43f5e',
    text: 'Mujhe DHA Phase 2 mein AC repair chahiye abhi, kal subah 9 baje slot book karo.',
  },
  {
    id: 'B_no_zone',
    icon: IconSearch,
    label: 'No Zone Match',
    desc: 'DiscoveryAgent finds zero providers in zone → suggests nearest alternate area',
    color: '#f59e0b',
    text: 'G-13 Islamabad mein AC technician chahiye kal subah 10 baje',
  },
  {
    id: 'C_ambiguous',
    icon: IconBrain,
    label: 'Ambiguous Input',
    desc: "IntentAgent confidence < 0.75 → asks clarifying questions in user's language",
    color: '#6366f1',
    text: 'koi repair wala chahiye ghar mein',
  },
  {
    id: 'D_full_pipeline',
    icon: IconWind,
    label: 'Full Pipeline',
    desc: 'All 6 ADK agents fire end-to-end → intent → discovery → booking → confirmation',
    color: '#00b894',
    text: 'Electrician chahiye DHA mein, urgent hai',
  },
];

export default function DemoBar({ onDemo, loading }) {
  return (
    <div className="demo-bar" role="group" aria-label="Demo scenarios for judges">
      <span className="demo-bar-label">Demo Scenarios</span>
      <div className="demo-chips">
        {DEMOS.map(({ id, icon: Icon, label, desc, color, text }) => (
          <button
            key={id}
            className="demo-chip"
            style={{ '--demo-color': color }}
            onClick={() => onDemo(text)}
            disabled={loading}
            title={desc}
            aria-label={`Demo: ${label} — ${desc}`}
          >
            <span className="demo-chip-dot" aria-hidden="true" />
            <Icon size={12} />
            <span>{label}</span>
          </button>
        ))}
      </div>
    </div>
  );
}
