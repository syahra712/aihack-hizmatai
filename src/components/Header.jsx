import React from 'react';
import {
  IconBolt, IconBrain, IconSearch, IconBarChart, IconTag,
  IconCalCheck, IconBell, IconPlus, IconMicroscope, IconActivity,
} from './Icons.jsx';
import './Header.css';

const AGENT_STEPS = [
  { key: 'IntentAgent',    icon: IconBrain,    label: 'Intent'    },
  { key: 'DiscoveryAgent', icon: IconSearch,   label: 'Discovery' },
  { key: 'RankingAgent',   icon: IconBarChart, label: 'Ranking'   },
  { key: 'PricingAgent',   icon: IconTag,      label: 'Pricing'   },
  { key: 'BookingAgent',   icon: IconCalCheck, label: 'Booking'   },
  { key: 'FollowupAgent',  icon: IconBell,     label: 'Followup'  },
];

export default function Header({ traceCount, onToggleTrace, showTrace, activeAgent, onNewChat, bookingCount, onShowHistory, user, onSignIn, onSignOut }) {
  const activeIdx = AGENT_STEPS.findIndex(s => s.key === activeAgent);

  return (
    <header className="header" role="banner">
      {activeAgent && <div className="header-progress-bar" aria-hidden="true" />}
      <div className="header-inner">

        {/* Brand */}
        <div className="brand">
          <div className="brand-logo" aria-hidden="true">
            <IconBolt size={20} />
          </div>
          <div>
            <h1 className="brand-name">HizmatAI</h1>
            <p className="brand-tagline">Pakistan's Agentic Home Services</p>
          </div>
        </div>

        {/* Agent pipeline */}
        <nav className="header-center" aria-label="Agent pipeline">
          <ol className="agents-row">
            {AGENT_STEPS.map(({ key, icon: Icon, label }, i) => {
              const isActive   = activeAgent === key;
              const isDone     = activeIdx > i;
              return (
                <React.Fragment key={key}>
                  <li className={`agent-pill ${isActive ? 'agent-active' : ''} ${isDone ? 'agent-done' : ''}`} title={key}>
                    <span className="agent-pill-icon"><Icon size={13} /></span>
                    <span className="agent-pill-label">{label}</span>
                    {isActive && <span className="agent-running-dot" aria-hidden="true" />}
                  </li>
                  {i < AGENT_STEPS.length - 1 && (
                    <li className={`pipeline-arrow ${isDone ? 'arrow-done' : ''}`} aria-hidden="true">›</li>
                  )}
                </React.Fragment>
              );
            })}
          </ol>
        </nav>

        {/* Controls */}
        <div className="header-right">
          <button className="hdr-btn" onClick={onNewChat} aria-label="New conversation">
            <IconPlus size={15} />
            <span className="hdr-btn-label">New Chat</span>
          </button>

          {traceCount > 0 && (
            <button
              className={`hdr-btn ${showTrace ? 'hdr-btn-active' : ''}`}
              onClick={onToggleTrace}
              aria-pressed={showTrace}
              aria-label="Toggle agent trace"
            >
              <IconMicroscope size={15} />
              <span className="hdr-btn-label">Trace</span>
              <span className="trace-badge" aria-label={`${traceCount} agents`}>{traceCount}</span>
            </button>
          )}

          {bookingCount > 0 && (
            <button className="hdr-btn bookings-pill" onClick={onShowHistory} aria-label={`View ${bookingCount} past bookings`}>
              <IconActivity size={13} />
              <span>{bookingCount} bookings</span>
            </button>
          )}

          <div className="status-pill status-pill-real" aria-label="Real backend status">
            <span className="status-dot" aria-hidden="true" />
            <span>Real Backend</span>
          </div>

          {user && !user.isAnonymous ? (
            <div className="auth-user-wrap">
              {user.photoURL
                ? <img className="auth-avatar" src={user.photoURL} alt={user.displayName || 'User'} referrerPolicy="no-referrer" />
                : <div className="auth-avatar auth-avatar-initial">{(user.displayName || user.email || 'U')[0].toUpperCase()}</div>
              }
              <span className="auth-name">{user.displayName?.split(' ')[0] || 'You'}</span>
              <button className="hdr-btn auth-signout-btn" onClick={onSignOut} aria-label="Sign out">Sign out</button>
            </div>
          ) : (
            <button className="hdr-btn auth-signin-btn" onClick={onSignIn} aria-label="Sign in">
              Sign In
            </button>
          )}
        </div>
      </div>
    </header>
  );
}
