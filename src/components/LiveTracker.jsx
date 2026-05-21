import React, { useState, useEffect } from 'react';
import { IconCheck, IconClock, IconMapPin, IconHardHat, IconZap, IconStar } from './Icons.jsx';
import './LiveTracker.css';

const STAGES = [
  { key: 'confirmed', label: 'Confirmed',      icon: IconCheck,   desc: 'Booking confirmed & paid', color: '#10b981' },
  { key: 'assigned',  label: 'Provider Notified', icon: IconZap,  desc: 'Provider has been notified', color: '#6366f1' },
  { key: 'enroute',   label: 'En Route',        icon: IconMapPin,  desc: 'Provider is heading to you', color: '#3b82f6' },
  { key: 'arrived',   label: 'Arrived',         icon: IconHardHat, desc: 'Provider has arrived',     color: '#f59e0b' },
  { key: 'working',   label: 'In Progress',     icon: IconClock,   desc: 'Service is underway',      color: '#8b5cf6' },
  { key: 'completed', label: 'Completed',       icon: IconStar,    desc: 'Service completed!',       color: '#10b981' },
];

const AUTO_DELAYS = [0, 3000, 7000, 12000, 18000, 25000];

export default function LiveTracker({ active = false, providerName }) {
  const [currentStage, setCurrentStage] = useState(0);
  const [eta, setEta] = useState(12);

  useEffect(() => {
    if (!active) return;
    const timers = AUTO_DELAYS.slice(1).map((delay, i) =>
      setTimeout(() => setCurrentStage(i + 1), delay)
    );
    return () => timers.forEach(clearTimeout);
  }, [active]);

  useEffect(() => {
    if (currentStage < 2 || currentStage >= 5) return;
    const interval = setInterval(() => {
      setEta(prev => Math.max(0, prev - 1));
    }, 2500);
    return () => clearInterval(interval);
  }, [currentStage]);

  if (!active) return null;

  return (
    <div className="lt-wrap" role="region" aria-label="Live booking tracker">
      <div className="lt-header">
        <div className="lt-pulse" aria-hidden="true" />
        <span className="lt-live-badge">LIVE</span>
        <span className="lt-header-text">Tracking your booking</span>
        {currentStage >= 2 && currentStage < 5 && (
          <span className="lt-eta">~{eta} min</span>
        )}
      </div>

      <div className="lt-timeline">
        {STAGES.map((stage, i) => {
          const done = i < currentStage;
          const isCurrent = i === currentStage;
          const Icon = stage.icon;

          return (
            <div
              key={stage.key}
              className={`lt-step ${done ? 'lt-done' : ''} ${isCurrent ? 'lt-current' : ''}`}
              style={{ '--stage-color': stage.color }}
            >
              <div className="lt-step-line-wrap">
                {i > 0 && (
                  <div className={`lt-connector ${done ? 'lt-connector-done' : ''}`}>
                    {done && <div className="lt-connector-fill" />}
                  </div>
                )}
              </div>

              <div className={`lt-icon ${done ? 'lt-icon-done' : ''} ${isCurrent ? 'lt-icon-active' : ''}`}>
                {done ? <IconCheck size={12} /> : <Icon size={13} />}
              </div>

              <div className="lt-step-text">
                <span className={`lt-step-label ${isCurrent ? 'lt-label-active' : ''}`}>
                  {stage.label}
                </span>
                {isCurrent && (
                  <span className="lt-step-desc fade-in">{stage.desc}</span>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {currentStage === 5 && (
        <div className="lt-complete fade-up">
          <IconStar size={14} className="lt-complete-icon" />
          <span>Service completed! Rate {providerName} to help others.</span>
        </div>
      )}
    </div>
  );
}
