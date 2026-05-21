import React, { useEffect, useRef, useState } from 'react';
import { IconBolt, IconUser, IconArrowDown } from './Icons.jsx';
import './ChatWindow.css';

const STATUS_META = {
  confirmed:            { color: '#10b981', label: 'Booking Confirmed' },
  clarification_needed: { color: '#f59e0b', label: 'Clarification Needed' },
  no_provider:          { color: '#6366f1', label: 'No Provider Available' },
  slot_taken:           { color: '#f59e0b', label: 'Slot Unavailable' },
  failed:               { color: '#f43f5e', label: 'Request Failed' },
};

function formatTime(ts) {
  if (!ts) return '';
  return new Date(ts).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

function parseInline(text) {
  return text.split(/(\*\*[^*]+\*\*|\*[^*]+\*)/g).map((part, i) => {
    if (part.startsWith('**') && part.endsWith('**')) return <strong key={i}>{part.slice(2,-2)}</strong>;
    if (part.startsWith('*')  && part.endsWith('*'))  return <strong key={i}>{part.slice(1,-1)}</strong>;
    return part;
  });
}

function RichText({ text }) {
  const lines = text.split('\n');
  const elements = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (line.startsWith('- ') || line.startsWith('• ')) {
      const items = [];
      while (i < lines.length && (lines[i].startsWith('- ') || lines[i].startsWith('• '))) {
        items.push(<li key={i}>{parseInline(lines[i].slice(2))}</li>);
        i++;
      }
      elements.push(<ul key={`ul-${i}`} className="msg-list">{items}</ul>);
    } else if (line.trim() === '') {
      elements.push(<br key={`br-${i}`} />);
      i++;
    } else {
      elements.push(<p key={`p-${i}`} className="bubble-line">{parseInline(line)}</p>);
      i++;
    }
  }
  return <>{elements}</>;
}

function UserBubble({ msg }) {
  return (
    <div className="msg-row user fade-up">
      <div className="msg-meta user-meta">
        <time className="msg-time">{formatTime(msg.ts)}</time>
      </div>
      <div className="bubble user-bubble" role="article" aria-label="Your message">
        {msg.content}
      </div>
      <div className="avatar user-avatar" aria-hidden="true">
        <IconUser size={15} />
      </div>
    </div>
  );
}

function AssistantBubble({ msg }) {
  const meta = msg.meta?.status ? STATUS_META[msg.meta.status] : null;
  return (
    <div className="msg-row assistant fade-up">
      <div className="avatar ai-avatar" aria-hidden="true">
        <IconBolt size={14} />
      </div>
      <div className="bubble ai-bubble" role="article" aria-label="AI response">
        {meta && (
          <div className="status-chip" style={{ '--chip-color': meta.color }}>
            <span className="status-chip-dot" />
            {meta.label}
          </div>
        )}
        <div className="bubble-text"><RichText text={msg.content} /></div>
      </div>
      <div className="msg-meta ai-meta">
        <time className="msg-time">{formatTime(msg.ts)}</time>
      </div>
    </div>
  );
}

function TypingIndicator() {
  return (
    <div className="msg-row assistant fade-in" aria-live="polite" aria-label="AI is typing">
      <div className="avatar ai-avatar" aria-hidden="true">
        <IconBolt size={14} />
      </div>
      <div className="bubble ai-bubble typing-bubble">
        <div className="typing-dots" aria-hidden="true">
          <span /><span /><span />
        </div>
        <span className="typing-label">Orchestrating agents…</span>
      </div>
    </div>
  );
}

export default function ChatWindow({ messages, loading, scrollRef }) {
  const endRef = useRef(null);
  const [showScrollBtn, setShowScrollBtn] = useState(false);
  // Track whether user is near bottom so we don't force-scroll mid-read
  const isNearBottomRef = useRef(true);

  const scrollToBottom = (instant = false) =>
    endRef.current?.scrollIntoView({ behavior: instant ? 'instant' : 'smooth' });

  // Auto-scroll on new messages — only if user was already near bottom
  useEffect(() => {
    if (isNearBottomRef.current) scrollToBottom();
  }, [messages, loading]);

  // Attach scroll listener to the outer .chat-column container
  useEffect(() => {
    const el = scrollRef?.current;
    if (!el) return;
    const onScroll = () => {
      const fromBottom = el.scrollHeight - el.scrollTop - el.clientHeight;
      isNearBottomRef.current = fromBottom < 100;
      setShowScrollBtn(fromBottom > 160);
    };
    el.addEventListener('scroll', onScroll, { passive: true });
    return () => el.removeEventListener('scroll', onScroll);
  }, [scrollRef]);

  if (messages.length === 0 && !loading) return null;

  return (
    <div className="chat-window-wrap">
      <div className="chat-window" role="log" aria-live="polite" aria-label="Conversation">
        {messages.map(msg =>
          msg.role === 'user'
            ? <UserBubble      key={msg.id} msg={msg} />
            : <AssistantBubble key={msg.id} msg={msg} />
        )}
        {loading && <TypingIndicator />}
        <div ref={endRef} />
      </div>

      {showScrollBtn && (
        <button
          className="scroll-to-bottom fade-in"
          onClick={() => { isNearBottomRef.current = true; scrollToBottom(); }}
          aria-label="Scroll to latest message"
        >
          <IconArrowDown size={16} />
        </button>
      )}
    </div>
  );
}
