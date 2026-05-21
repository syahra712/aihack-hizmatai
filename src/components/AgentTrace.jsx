import React, { useState } from 'react';
import {
  IconBrain, IconSearch, IconBarChart, IconTag,
  IconCalCheck, IconBell, IconChevDown, IconChevUp, IconMicroscope, IconDatabase,
} from './Icons.jsx';
import './AgentTrace.css';

const AGENT_META = {
  ContextAgent:   { Icon: IconDatabase, color: '#ec4899', desc: 'Recalls context from prior turns' },
  IntentAgent:    { Icon: IconBrain,    color: '#6366f1', desc: 'Parses multilingual input'   },
  DiscoveryAgent: { Icon: IconSearch,   color: '#3b82f6', desc: 'Finds available providers'   },
  RankingAgent:   { Icon: IconBarChart, color: '#f59e0b', desc: 'Scores & ranks by 6 factors' },
  PricingAgent:   { Icon: IconTag,      color: '#10b981', desc: 'Generates price quote'        },
  BookingAgent:   { Icon: IconCalCheck, color: '#14b8a6', desc: 'Confirms & writes booking'   },
  FollowupAgent:  { Icon: IconBell,     color: '#8b5cf6', desc: 'Schedules reminders'          },
};

function TraceNode({ entry, index, expanded, onToggle, isLast }) {
  const meta = AGENT_META[entry.agent] || { Icon: IconMicroscope, color: '#94a3b8', desc: '' };
  const { Icon } = meta;

  return (
    <div className="trace-node slide-in" style={{ '--agent-color': meta.color, animationDelay: `${index * 55}ms` }}>
      {/* Connecting line */}
      {!isLast && <div className="trace-connector" aria-hidden="true" />}

      <div className="trace-header" onClick={onToggle} role="button" aria-expanded={expanded} tabIndex={0}
        onKeyDown={e => e.key === 'Enter' && onToggle()}>
        <div className="trace-icon">
          <Icon size={16} />
        </div>
        <div className="trace-info">
          <div className="trace-name">{entry.agent}</div>
          <div className="trace-decision">{entry.decision}</div>
        </div>
        <time className="trace-time">{new Date(entry.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}</time>
        <span className="trace-chevron" aria-hidden="true">
          {expanded ? <IconChevUp size={13} /> : <IconChevDown size={13} />}
        </span>
      </div>

      {expanded && (
        <div className="trace-body fade-in">
          <p className="trace-desc">{meta.desc}</p>
          <div className="trace-reasoning">
            <span className="tb-label">Reasoning</span>
            <span>{entry.reasoning}</span>
          </div>
          {entry.raw?.output && (
            <details className="trace-raw">
              <summary>Raw output</summary>
              <pre>{JSON.stringify(entry.raw.output, null, 2)}</pre>
            </details>
          )}
        </div>
      )}
    </div>
  );
}

function RunningNode({ agentName }) {
  const meta = AGENT_META[agentName] || { Icon: IconMicroscope, color: '#94a3b8' };
  const { Icon } = meta;
  return (
    <div className="trace-node trace-node-running" style={{ '--agent-color': meta.color }}>
      <div className="trace-header" style={{ cursor: 'default' }}>
        <div className="trace-icon running-icon">
          <Icon size={16} />
        </div>
        <div className="trace-info">
          <div className="trace-name">{agentName}</div>
          <div className="trace-decision running-text">
            <span className="running-dots" aria-hidden="true"><span /><span /><span /></span>
            Processing…
          </div>
        </div>
        <span className="running-badge" aria-label="Agent running">running</span>
      </div>
    </div>
  );
}

export default function AgentTrace({ trace, activeAgent }) {
  const [expanded, setExpanded] = useState({ 0: true });
  const toggle = i => setExpanded(p => ({ ...p, [i]: !p[i] }));
  const showRunning = activeAgent && !trace.find(e => e.agent === activeAgent);

  return (
    <section className="trace-panel" aria-label="Agent trace">
      <div className="trace-panel-header">
        <div className="trace-panel-title">
          <IconMicroscope size={16} />
          <h3>Agent Trace</h3>
        </div>
        <span className="trace-count" aria-label={`${trace.length} agents fired`}>{trace.length} fired</span>
      </div>

      <div className="trace-timeline" role="list">
        {trace.map((entry, i) => (
          <div key={i} role="listitem">
            <TraceNode
              entry={entry} index={i}
              expanded={!!expanded[i]} onToggle={() => toggle(i)}
              isLast={i === trace.length - 1 && !showRunning}
            />
          </div>
        ))}
        {showRunning && (
          <div role="listitem">
            <RunningNode agentName={activeAgent} />
          </div>
        )}
      </div>
    </section>
  );
}
