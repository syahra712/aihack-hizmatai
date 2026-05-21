import React from 'react';
import {
  IconZap, IconDrop, IconSparkles, IconWind, IconHammer, IconPaintbrush,
  IconBrain, IconSearch, IconBarChart, IconTag, IconCalCheck, IconBell,
  IconBookOpen, IconScissors,
} from './Icons.jsx';
import './HeroSuggestions.css';

const SERVICE_CARDS = [
  { icon: IconZap,        label: 'Electrician', color: '#f59e0b', prefill: 'I need an electrician in ' },
  { icon: IconDrop,       label: 'Plumber',     color: '#3b82f6', prefill: 'I need a plumber in '     },
  { icon: IconSparkles,   label: 'Cleaning',    color: '#10b981', prefill: 'I need house cleaning in ' },
  { icon: IconWind,       label: 'AC Repair',   color: '#06b6d4', prefill: 'I need AC repair in '      },
  { icon: IconHammer,     label: 'Carpenter',   color: '#8b5cf6', prefill: 'I need a carpenter in '   },
  { icon: IconPaintbrush, label: 'Painter',     color: '#f43f5e', prefill: 'I need a painter in '     },
  { icon: IconBookOpen,   label: 'Home Tutor',  color: '#a78bfa', prefill: 'I need a home tutor in '  },
  { icon: IconScissors,   label: 'Beautician',  color: '#ec4899', prefill: 'I need a beautician in '  },
];

const AGENT_FLOW = [
  { icon: IconBrain,    label: 'Intent'    },
  { icon: IconSearch,   label: 'Discovery' },
  { icon: IconBarChart, label: 'Ranking'   },
  { icon: IconTag,      label: 'Pricing'   },
  { icon: IconCalCheck, label: 'Booking'   },
  { icon: IconBell,     label: 'Followup'  },
];

const SAMPLE_PROMPTS = [
  { label: 'Roman Urdu', text: 'Bhai mujhe Karachi mein bijli wala chahiye abhi, koi acha ustad bhejo' },
  { label: 'Urdu',       text: 'کراچی میں پلمبر چاہیے کل صبح 10 بجے' },
  { label: 'English',    text: 'I need a house cleaning service in Lahore tomorrow at 3pm' },
  { label: 'Mixed',      text: 'AC repair karwani hai, Islamabad mein — کوئی اچھا ملے؟' },
];

export default function HeroSuggestions({ prompts = SAMPLE_PROMPTS, onSelect, onPrefill }) {
  return (
    <section className="hero fade-up" aria-label="Welcome">

      <div className="hero-badge" aria-hidden="true">🇵🇰 Built for Pakistan</div>

      <h2 className="hero-title">
        Ghar ki koi bhi zaroorat?
        <br />
        <span className="hero-gradient">HizmatAI pe chhod do.</span>
      </h2>

      <p className="hero-sub">
        6 specialised AI agents find, rank, price &amp; confirm the best service
        provider near you — in seconds, in your language.
      </p>

      {/* Service grid */}
      <div className="services-grid" role="list" aria-label="Service categories">
        {SERVICE_CARDS.map(({ icon: Icon, label, color, prefill }) => (
          <button
            key={label}
            role="listitem"
            className="service-card"
            style={{ '--clr': color }}
            onClick={() => onPrefill?.(prefill)}
            aria-label={`Book a ${label}`}
          >
            <span className="svc-icon-wrap" style={{ color }}>
              <Icon size={26} />
            </span>
            <span className="svc-label">{label}</span>
            <span className="svc-hint" aria-hidden="true">tap to book →</span>
          </button>
        ))}
      </div>

      {/* Sample prompts */}
      <div className="prompts-section">
        <p className="prompts-heading">Or try a sample request</p>
        <ul className="prompts-list" role="list">
          {prompts.map((p, i) => (
            <li key={i}>
              <button className="prompt-chip" onClick={() => onSelect(p.text)}>
                <span className="prompt-lang">{p.label}</span>
                <span className="prompt-text">"{p.text}"</span>
              </button>
            </li>
          ))}
        </ul>
      </div>

      {/* Agent pipeline visual */}
      <div className="agents-flow" aria-label="AI agent pipeline" role="list">
        {AGENT_FLOW.map(({ icon: Icon, label }, i, arr) => (
          <React.Fragment key={label}>
            <div className="flow-node" role="listitem">
              <span className="flow-icon"><Icon size={13} /></span>
              <span>{label}</span>
            </div>
            {i < arr.length - 1 && <span className="flow-arrow" aria-hidden="true">›</span>}
          </React.Fragment>
        ))}
      </div>

    </section>
  );
}
