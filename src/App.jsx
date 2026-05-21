import React, { useState, useRef, useCallback, useEffect } from 'react';
import { runPhase1, runPhase2, runDemoScenario, cancelBooking, clearSession } from './agents/backendApi.js';
import { IconHome, IconArrowUp, IconBrain, IconX, IconMicroscope, IconActivity, IconPlus } from './components/Icons.jsx';
import { useAuth } from './hooks/useAuth.js';
import { useBookings } from './hooks/useBookings.js';
import Header from './components/Header.jsx';
import AuthModal from './components/AuthModal.jsx';
import ChatWindow from './components/ChatWindow.jsx';
import AgentTrace from './components/AgentTrace.jsx';
import HeroSuggestions from './components/HeroSuggestions.jsx';
import BookingCard from './components/BookingCard.jsx';
import ProviderPicker from './components/ProviderPicker.jsx';
import DemoBar from './components/DemoBar.jsx';
import BookingHistory from './components/BookingHistory.jsx';
import PaymentSheet from './components/PaymentSheet.jsx';
import ToastContainer from './components/Toast.jsx';
import './App.css';

function QuickReplies({ replies, onSelect, loading }) {
  if (!replies || replies.length === 0) return null;
  return (
    <div className="quick-replies fade-in" role="group" aria-label="Quick reply options">
      {replies.map((r, i) => (
        <button
          key={i}
          className={`qr-chip qr-type-${r.type || 'default'}`}
          onClick={() => onSelect(r)}
          disabled={loading}
          aria-label={r.label}
        >
          {r.label}
        </button>
      ))}
    </div>
  );
}

function BottomNav({ onTab, showTrace, traceCount, bookingCount }) {
  return (
    <nav className="bottom-nav" role="navigation" aria-label="App navigation">
      <button
        className={`tab-btn ${!showTrace ? 'tab-active' : ''}`}
        onClick={() => onTab('home')}
        aria-label="Chat"
        aria-current={!showTrace ? 'page' : undefined}
      >
        <span className="tab-btn-icon"><IconHome size={22} /></span>
        <span className="tab-btn-label">Chat</span>
      </button>

      <button
        className={`tab-btn ${showTrace ? 'tab-active' : ''}`}
        onClick={() => onTab('trace')}
        aria-label={`Agent trace${traceCount ? ` — ${traceCount} steps` : ''}`}
        aria-current={showTrace ? 'page' : undefined}
      >
        <span className="tab-btn-icon">
          <IconMicroscope size={22} />
          {traceCount > 0 && <span className="tab-badge tab-badge-indigo" aria-hidden="true">{traceCount}</span>}
        </span>
        <span className="tab-btn-label">Trace</span>
      </button>

      <button
        className="tab-btn"
        onClick={() => onTab('history')}
        aria-label={`Bookings${bookingCount ? ` — ${bookingCount}` : ''}`}
      >
        <span className="tab-btn-icon">
          <IconActivity size={22} />
          {bookingCount > 0 && <span className="tab-badge" aria-hidden="true">{bookingCount}</span>}
        </span>
        <span className="tab-btn-label">Bookings</span>
      </button>

      <button className="tab-btn" onClick={() => onTab('new')} aria-label="New chat">
        <span className="tab-btn-icon"><IconPlus size={22} /></span>
        <span className="tab-btn-label">New</span>
      </button>
    </nav>
  );
}

const SAMPLE_PROMPTS = [
  { label: "Roman Urdu", text: "Bhai mujhe Karachi mein bijli wala chahiye abhi, koi acha ustad bhejo" },
  { label: "Urdu",       text: "کراچی میں پلمبر چاہیے کل صبح 10 بجے" },
  { label: "English",    text: "I need a house cleaning service in Lahore tomorrow at 3pm" },
  { label: "Mixed",      text: "AC repair karwani hai, Islamabad mein — کوئی اچھا ملے؟" },
];

export default function App() {
  const [messages,       setMessages      ] = useState([]);
  const [input,          setInput         ] = useState('');
  const [loading,        setLoading       ] = useState(false);
  const [agentTrace,     setAgentTrace    ] = useState([]);
  const [lastBooking,    setLastBooking   ] = useState(null);
  const [showTrace,      setShowTrace     ] = useState(false);
  const [activeAgent,    setActiveAgent   ] = useState(null);
  const [toasts,         setToasts        ] = useState([]);
  const [showHistory,    setShowHistory   ] = useState(false);
  const [showPayment,    setShowPayment   ] = useState(false);
  const [paymentData,    setPaymentData   ] = useState(null);
  const { user, signInWithGoogle, signInAsGuest, logOut } = useAuth();
  const { bookings: bookingHistory, saveBooking: saveBookingToHistory, updateStatus: updateBookingStatus } = useBookings(user?.uid);
  const [showAuthModal, setShowAuthModal] = useState(false);

  // Phase 1 results — waiting for user to pick a provider
  const [pendingPhase1,  setPendingPhase1 ] = useState(null); // { top3, intent, agent_trace }
  const [phase2Loading,  setPhase2Loading ] = useState(false);

  // Conversational quick replies — shown above input after AI asks a question
  const [quickReplies,   setQuickReplies  ] = useState([]); // [{ label, value, type, provider? }]
  // Context for pending Phase2 retry (conflict / alt-provider flow)
  const [pendingPhase2,  setPendingPhase2 ] = useState(null); // { provider, intent, trace }

  // Multi-turn context — carries service/city between messages
  const [convContext,    setConvContext   ] = useState({});

  // Session ID — persists across turns, reset on New Chat
  const [sessionId, setSessionId] = useState(() => {
    const stored = localStorage.getItem('hizmat_session_id');
    if (stored) return stored;
    const id = crypto.randomUUID();
    localStorage.setItem('hizmat_session_id', id);
    return id;
  });


  const textareaRef   = useRef(null);
  const chatColumnRef = useRef(null);
  const bottomAnchorRef = useRef(null);

  const addToast = useCallback((message, type = 'success') => {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, message, type }]);
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 3500);
  }, []);

  const dismissToast = useCallback((id) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  }, []);

  const addMessage = useCallback((role, content, meta = {}) => {
    setMessages(prev => [...prev, { id: Date.now() + Math.random(), role, content, meta, ts: new Date() }]);
  }, []);

  const autoResize = () => {
    const ta = textareaRef.current;
    if (!ta) return;
    ta.style.height = 'auto';
    ta.style.height = Math.min(ta.scrollHeight, 120) + 'px';
  };


  // ── Phase 2: user picked a provider ─────────────────────────
  const handleProviderPick = useCallback(async (provider) => {
    if (!pendingPhase1) return;
    const { intent, agent_trace } = pendingPhase1;
    setPendingPhase1(null);
    setPhase2Loading(true);
    setQuickReplies([]);

    addMessage('user', `→ Selected: ${provider.name} (score: ${provider.total_score})`);

    try {
      const result = await runPhase2(
        provider, intent, agent_trace, sessionId, user?.uid,
        (trace) => setAgentTrace([...trace]),
        (name)  => setActiveAgent(name),
      );
      setActiveAgent(null);
      addMessage('assistant', result.user_message, { status: result.status });

      if (result.booking) {
        setLastBooking({ booking: result.booking, pricing: result.pricing, followup: result.followup });
        saveBookingToHistory(result.booking);
        addToast(`Booking confirmed! ID: ${result.booking.booking_id}`, 'success');
      }
      if (result.status === 'slot_taken' && result.quick_replies?.length) {
        setPendingPhase2({ provider, intent, trace: result.agent_trace || agent_trace });
        setQuickReplies(result.quick_replies);
      }
      if (result.agent_trace?.length) setAgentTrace(result.agent_trace);
    } catch {
      addMessage('assistant', 'Something went wrong during booking. Please try again.', { status: 'failed' });
      addToast('Booking failed. Please try again.', 'error');
    } finally {
      setActiveAgent(null);
      setPhase2Loading(false);
    }
  }, [pendingPhase1, sessionId, addMessage, addToast, saveBookingToHistory]);

  // ── Main send handler ────────────────────────────────────────
  const handleSend = useCallback(async (text) => {
    const msg = (text || input).trim();
    if (!msg || loading || phase2Loading) return;
    setInput('');
    if (textareaRef.current) textareaRef.current.style.height = 'auto';
    setAgentTrace([]);
    setPendingPhase1(null);
    setPendingPhase2(null);
    setQuickReplies([]);
    addMessage('user', msg);
    setLoading(true);
    setShowTrace(true);

    try {
      const result = await runPhase1(
        msg, sessionId, user?.uid,
        (trace) => setAgentTrace([...trace]),
        (name)  => setActiveAgent(name),
      );
      setActiveAgent(null);

      // Update memory bubble context
      if (result.intent) {
        setConvContext(prev => ({
          ...prev,
          service_type: result.intent.service_type || prev.service_type,
          zone:         result.intent.zone         || prev.zone,
          city:         result.intent.city         || prev.city,
          is_urgent:    result.intent.is_urgent ?? prev.is_urgent,
        }));
      }

      if (result.status === 'providers_ready') {
        const intro = result.user_message || (() => {
          const label = result.intent.service_type?.replace('_', ' ') || 'service';
          if (result.intent.language === 'roman_urdu')
            return `AI ne ${result.top3.length} ${label} providers dhoondh liye — score ke hisaab se rank ho gaye. Apna provider chunein:`;
          if (result.intent.language === 'urdu')
            return `${result.intent.city} میں ${result.top3.length} ${label} ملے۔ اپنا انتخاب کریں:`;
          return `Found **${result.top3.length}** ${label} providers ranked by AI. Pick your provider to confirm:`;
        })();
        addMessage('assistant', intro, { status: 'providers_ready' });
        setPendingPhase1({ top3: result.top3, intent: result.intent, agent_trace: result.agent_trace });
        if (result.agent_trace?.length) setAgentTrace(result.agent_trace);
      } else {
        addMessage('assistant', result.user_message, { status: result.status });
        if (result.quick_replies?.length) setQuickReplies(result.quick_replies);
        if (result.agent_trace?.length) setAgentTrace(result.agent_trace);
      }
    } catch {
      addMessage('assistant', 'Something went wrong. Please try again.', { status: 'failed' });
      addToast('Something went wrong. Please try again.', 'error');
    } finally {
      setActiveAgent(null);
      setLoading(false);
    }
  }, [input, loading, phase2Loading, addMessage, addToast]);

  // ── Quick reply click handler (must come after handleSend) ───
  const handleQuickReply = useCallback(async (reply) => {
    setQuickReplies([]);

    if (reply.type === 'alt_provider' && pendingPhase2) {
      const { intent, trace } = pendingPhase2;
      setPendingPhase2(null);
      addMessage('user', `Switch to ${reply.provider.name}`);
      setPhase2Loading(true);
      try {
        const result = await runPhase2(
          reply.provider, intent, trace, sessionId, user?.uid,
          (tr) => setAgentTrace([...tr]),
          (name) => setActiveAgent(name),
        );
        setActiveAgent(null);
        addMessage('assistant', result.user_message, { status: result.status });
        if (result.booking) {
          setLastBooking({ booking: result.booking, pricing: result.pricing, followup: result.followup });
          saveBookingToHistory(result.booking);
          addToast(`Booking confirmed! ID: ${result.booking.booking_id}`, 'success');
        }
        if (result.quick_replies?.length) setQuickReplies(result.quick_replies);
        if (result.agent_trace?.length) setAgentTrace(result.agent_trace);
      } catch {
        addMessage('assistant', 'Something went wrong switching providers. Please try again.', { status: 'failed' });
      } finally { setActiveAgent(null); setPhase2Loading(false); }
      return;
    }

    if (reply.type === 'alt_time' && pendingPhase2) {
      const { provider, intent, trace } = pendingPhase2;
      setPendingPhase2(null);
      addMessage('user', `Try ${reply.label.replace('🕐 ', '')}`);
      setPhase2Loading(true);
      try {
        const updatedIntent = { ...intent, preferred_time: reply.value };
        const result = await runPhase2(
          provider, updatedIntent, trace, sessionId, user?.uid,
          (tr) => setAgentTrace([...tr]),
          (name) => setActiveAgent(name),
        );
        setActiveAgent(null);
        addMessage('assistant', result.user_message, { status: result.status });
        if (result.booking) {
          setLastBooking({ booking: result.booking, pricing: result.pricing, followup: result.followup });
          saveBookingToHistory(result.booking);
          addToast(`Booking confirmed! ID: ${result.booking.booking_id}`, 'success');
        }
        if (result.quick_replies?.length) setQuickReplies(result.quick_replies);
        if (result.agent_trace?.length) setAgentTrace(result.agent_trace);
      } catch {
        addMessage('assistant', 'Could not rebook that slot. Please try again.', { status: 'failed' });
      } finally { setActiveAgent(null); setPhase2Loading(false); }
      return;
    }

    // Everything else — treat as typed message
    handleSend(reply.value);
  }, [pendingPhase2, sessionId, addMessage, addToast, saveBookingToHistory, handleSend]);

  const handleCancelBooking = useCallback((bookingId) => {
    cancelBooking(bookingId);
    setLastBooking(null);
    updateBookingStatus(bookingId, 'cancelled');
    addToast(`Booking ${bookingId} cancelled.`, 'info');
    addMessage('assistant', `Booking **${bookingId}** has been cancelled. Feel free to book again! 🙏`);
  }, [addToast, addMessage, updateBookingStatus]);

  const handleClearChat = useCallback(() => {
    fetch(`http://localhost:8000/session/${sessionId}`, { method: 'DELETE' }).catch(() => {});
    clearSession(sessionId);
    const newId = crypto.randomUUID();
    localStorage.setItem('hizmat_session_id', newId);
    setSessionId(newId);
    setMessages([]);
    setAgentTrace([]);
    setLastBooking(null);
    setPendingPhase1(null);
    setPendingPhase2(null);
    setQuickReplies([]);
    setShowTrace(false);
    setActiveAgent(null);
    setConvContext({});
    setInput('');
    setTimeout(() => textareaRef.current?.focus(), 50);
  }, [sessionId]);

  const handleClearContext = useCallback(() => {
    fetch(`http://localhost:8000/session/${sessionId}`, { method: 'DELETE' }).catch(() => {});
    setConvContext({});
    addToast('Memory cleared — agent starts fresh next turn.', 'info');
  }, [sessionId, addToast]);

  const handlePrefill = useCallback((text) => {
    setInput(text);
    setTimeout(() => {
      const ta = textareaRef.current;
      if (!ta) return;
      ta.focus();
      ta.setSelectionRange(text.length, text.length);
      autoResize();
    }, 50);
  }, []);

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSend(); }
  };

  useEffect(() => { textareaRef.current?.focus(); }, []);

  // Auto-scroll to bottom whenever BookingCard or ProviderPicker appears
  useEffect(() => {
    if (!lastBooking && !pendingPhase1) return;
    const el = chatColumnRef.current;
    if (!el) return;
    setTimeout(() => {
      bottomAnchorRef.current?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }, 80);
  }, [lastBooking, pendingPhase1]);

  const isProcessing = loading || phase2Loading;

  return (
    <div className="app-root">
      <div className="bg-orbs" aria-hidden="true">
        <div className="orb orb1" /><div className="orb orb2" /><div className="orb orb3" />
      </div>

      <Header
        traceCount={agentTrace.length}
        onToggleTrace={() => setShowTrace(v => !v)}
        showTrace={showTrace}
        activeAgent={activeAgent}
        onNewChat={handleClearChat}
        bookingCount={bookingHistory.length}
        onShowHistory={() => setShowHistory(true)}
        user={user}
        onSignIn={() => setShowAuthModal(true)}
        onSignOut={logOut}
      />

      <main className="main-layout">
        <div className={`chat-column ${showTrace && agentTrace.length ? 'with-trace' : ''}`} ref={chatColumnRef}>

          {messages.length === 0 && (
            <>
              <HeroSuggestions
                prompts={SAMPLE_PROMPTS}
                onSelect={(t) => handleSend(t)}
                onPrefill={handlePrefill}
              />
              <DemoBar onDemo={(text) => handleSend(text)} loading={isProcessing} />
            </>
          )}

          <ChatWindow messages={messages} loading={loading} scrollRef={chatColumnRef} />

          {/* Provider picker — shown between chat and input after Phase 1 */}
          {pendingPhase1 && !loading && (
            <ProviderPicker
              top3={pendingPhase1.top3}
              service={pendingPhase1.intent.service_type}
              city={pendingPhase1.intent.city}
              onSelect={handleProviderPick}
              loading={phase2Loading}
            />
          )}

          {lastBooking && (
            <BookingCard
              data={lastBooking}
              onCancel={handleCancelBooking}
              onToast={addToast}
              onPay={(data) => { setPaymentData(data); setShowPayment(true); setShowTrace(false); }}
              paid={bookingHistory.some(b => b.booking_id === lastBooking?.booking?.booking_id && b.status === 'paid')}
            />
          )}

          {/* Scroll anchor — keeps BookingCard / ProviderPicker visible above input */}
          <div ref={bottomAnchorRef} style={{ height: 1 }} />

          <div className="input-bar">
            {/* Conversational quick replies — shown after AI asks a question */}
            {quickReplies.length > 0 && !isProcessing && (
              <QuickReplies
                replies={quickReplies}
                onSelect={handleQuickReply}
                loading={isProcessing}
              />
            )}
            {/* Memory bubble — shows what the agent remembers across turns */}
            {(convContext.service_type || convContext.zone) && (
              <div className="memory-bar fade-in" role="status" aria-label="Agent memory">
                <IconBrain size={12} className="memory-bar-icon" />
                <span className="memory-bar-label">Remembering:</span>
                {convContext.service_type && (
                  <span className="memory-chip">{convContext.service_type.replace('_', ' ')}</span>
                )}
                {convContext.zone && (
                  <span className="memory-chip">{convContext.zone}</span>
                )}
                {convContext.is_urgent && (
                  <span className="memory-chip memory-chip-urgent">urgent</span>
                )}
                <button
                  className="memory-clear"
                  onClick={handleClearContext}
                  title="Clear agent memory"
                  aria-label="Clear memory"
                >
                  <IconX size={10} />
                </button>
              </div>
            )}

            {/* Demo bar visible during chat too */}
            {messages.length > 0 && (
              <DemoBar onDemo={(text) => handleSend(text)} loading={isProcessing} />
            )}
            <div className="input-wrap">
              <span className="input-icon" aria-hidden="true"><IconHome size={18} /></span>
              <textarea
                ref={textareaRef}
                className="chat-input"
                rows={1}
                placeholder="Koi bhi service maangein… (Roman Urdu / English / اردو)"
                value={input}
                onChange={e => { setInput(e.target.value); autoResize(); }}
                onKeyDown={handleKeyDown}
                disabled={isProcessing}
                aria-label="Type your service request"
              />
              <button
                className={`send-btn ${isProcessing ? 'loading' : ''}`}
                onClick={() => handleSend()}
                disabled={isProcessing}
                aria-label={isProcessing ? 'Processing…' : 'Send message'}
              >
                {isProcessing ? <span className="spinner" /> : <IconArrowUp size={18} aria-hidden="true" />}
              </button>
            </div>
            <p className="input-hint">Enter to send · Shift+Enter for newline · Roman Urdu, اردو &amp; English</p>
          </div>
        </div>

        {showTrace && agentTrace.length > 0 && (
          <aside className="trace-column fade-in">
            <AgentTrace trace={agentTrace} activeAgent={activeAgent} />
          </aside>
        )}
      </main>

      {showHistory && (
        <BookingHistory
          history={bookingHistory}
          onClose={() => setShowHistory(false)}
        />
      )}

      <PaymentSheet
        open={showPayment}
        onClose={() => setShowPayment(false)}
        booking={paymentData}
        onPaymentSuccess={(intent) => {
          const bookingId = paymentData?.booking?.booking_id;
          if (bookingId) {
            updateBookingStatus(bookingId, 'paid');
          }
          addToast(`Payment confirmed! PKR ${paymentData?.pricing?.total?.toLocaleString()}`, 'success');
          setTimeout(() => setShowPayment(false), 1800);
        }}
      />

      {/* ── Mobile: Agent Trace bottom sheet ─────────── */}
      {agentTrace.length > 0 && (
        <>
          {showTrace && (
            <div
              className="sheet-backdrop"
              onClick={() => setShowTrace(false)}
              aria-hidden="true"
            />
          )}
          <div className={`bottom-sheet ${showTrace ? 'sheet-open' : ''}`} role="dialog" aria-label="Agent trace" aria-modal="true">
            <div className="sheet-handle" aria-hidden="true" />
            <div className="sheet-header">
              <span className="sheet-title">Agent Trace</span>
              <button className="sheet-close" onClick={() => setShowTrace(false)} aria-label="Close trace">
                <IconX size={14} />
              </button>
            </div>
            <div className="sheet-body">
              <AgentTrace trace={agentTrace} activeAgent={activeAgent} />
            </div>
          </div>
        </>
      )}

      {/* ── Mobile bottom navigation bar ─────────────── */}
      <BottomNav
        onTab={(tab) => {
          if (tab === 'home')    setShowTrace(false);
          if (tab === 'trace')  setShowTrace(v => !v);
          if (tab === 'history') setShowHistory(true);
          if (tab === 'new')    handleClearChat();
        }}
        showTrace={showTrace}
        traceCount={agentTrace.length}
        bookingCount={bookingHistory.length}
      />

      <ToastContainer toasts={toasts} onDismiss={dismissToast} />

      {showAuthModal && (
        <AuthModal
          onGoogleSignIn={signInWithGoogle}
          onGuestSignIn={signInAsGuest}
          onClose={() => setShowAuthModal(false)}
        />
      )}
    </div>
  );
}
