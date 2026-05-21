import { useState, useEffect } from 'react';
import { IconX, IconShieldCheck, IconLock, IconCreditCard } from './Icons.jsx';
import './PaymentSheet.css';

function CardForm({ amount, onSuccess }) {
  const [cardNum, setCardNum]   = useState('');
  const [expiry, setExpiry]     = useState('');
  const [cvc, setCvc]           = useState('');
  const [name, setName]         = useState('');
  const [busy, setBusy]         = useState(false);
  const [err, setErr]           = useState(null);

  const formatCard = (v) => {
    const digits = v.replace(/\D/g, '').slice(0, 16);
    return digits.replace(/(.{4})/g, '$1 ').trim();
  };

  const formatExpiry = (v) => {
    const digits = v.replace(/\D/g, '').slice(0, 4);
    if (digits.length >= 3) return digits.slice(0, 2) + '/' + digits.slice(2);
    return digits;
  };

  const validate = () => {
    const digits = cardNum.replace(/\s/g, '');
    if (digits.length < 16) return 'Enter a valid 16-digit card number';
    if (expiry.length < 5) return 'Enter expiry as MM/YY';
    if (cvc.length < 3) return 'Enter a 3-digit CVC';
    if (!name.trim()) return 'Enter cardholder name';
    return null;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const validationErr = validate();
    if (validationErr) { setErr(validationErr); return; }
    setBusy(true);
    setErr(null);
    await new Promise(r => setTimeout(r, 1800));
    setBusy(false);
    onSuccess({
      id: `pi_demo_${Date.now()}`,
      status: 'succeeded',
      last4: cardNum.replace(/\s/g, '').slice(-4),
    });
  };

  return (
    <form onSubmit={handleSubmit} className="checkout-form">
      <div className="pay-field">
        <label className="pay-label">Card Number</label>
        <div className="pay-input-wrap">
          <IconCreditCard size={16} className="pay-input-icon" />
          <input
            className="pay-input"
            placeholder="4242 4242 4242 4242"
            value={cardNum}
            onChange={(e) => setCardNum(formatCard(e.target.value))}
            maxLength={19}
            inputMode="numeric"
            autoComplete="cc-number"
          />
        </div>
      </div>

      <div className="pay-field-row">
        <div className="pay-field pay-field-half">
          <label className="pay-label">Expiry</label>
          <input
            className="pay-input"
            placeholder="MM/YY"
            value={expiry}
            onChange={(e) => setExpiry(formatExpiry(e.target.value))}
            maxLength={5}
            inputMode="numeric"
            autoComplete="cc-exp"
          />
        </div>
        <div className="pay-field pay-field-half">
          <label className="pay-label">CVC</label>
          <input
            className="pay-input"
            placeholder="123"
            value={cvc}
            onChange={(e) => setCvc(e.target.value.replace(/\D/g, '').slice(0, 4))}
            maxLength={4}
            inputMode="numeric"
            autoComplete="cc-csc"
          />
        </div>
      </div>

      <div className="pay-field">
        <label className="pay-label">Cardholder Name</label>
        <input
          className="pay-input"
          placeholder="Ahmed Khan"
          value={name}
          onChange={(e) => setName(e.target.value)}
          autoComplete="cc-name"
        />
      </div>

      {err && <div className="pay-error" role="alert">{err}</div>}

      <button
        type="submit"
        className={`pay-submit-btn ${busy ? 'pay-submit-busy' : ''}`}
        disabled={busy}
      >
        {busy
          ? <><span className="pay-spinner" /> Processing…</>
          : <><IconLock size={14} /> Pay PKR {amount.toLocaleString()}</>
        }
      </button>

      <div className="pay-secure-row">
        <IconShieldCheck size={12} />
        <span>Sandbox mode · No real charges · Demo payment</span>
      </div>

      <div className="pay-test-card">
        <span className="pay-test-label">Try test card</span>
        <code>4242 4242 4242 4242</code>
        <span className="pay-test-sep">·</span>
        <code>12/34</code>
        <span className="pay-test-sep">·</span>
        <code>Any CVC</code>
      </div>
    </form>
  );
}

function SuccessView({ amount, providerName, last4 }) {
  return (
    <div className="pay-success fade-up">
      <div className="pay-success-ring">
        <IconShieldCheck size={34} />
      </div>
      <p className="pay-success-title">Payment confirmed!</p>
      <p className="pay-success-amount">PKR {amount.toLocaleString()}</p>
      <p className="pay-success-sub">
        Paid to {providerName} · Card ending {last4 || '4242'}
        <br />Sandbox mode — no real money charged.
      </p>
    </div>
  );
}

export default function PaymentSheet({ open, onClose, booking, onPaymentSuccess }) {
  const [paid, setPaid]       = useState(false);
  const [last4, setLast4]     = useState('');

  const amount       = booking?.pricing?.total || 0;
  const providerName = booking?.booking?.provider?.name || 'Provider';

  useEffect(() => {
    if (!open) {
      setTimeout(() => { setPaid(false); setLast4(''); }, 420);
    }
  }, [open]);

  const handleSuccess = (result) => {
    setPaid(true);
    setLast4(result.last4);
    onPaymentSuccess?.(result);
  };

  return (
    <>
      {open && <div className="sheet-backdrop payment-backdrop" onClick={onClose} aria-hidden="true" />}

      <div className={`bottom-sheet payment-sheet ${open ? 'sheet-open' : ''}`} role="dialog" aria-label="Payment" aria-modal="true">
        <div className="sheet-handle" aria-hidden="true" />

        <div className="sheet-header">
          <span className="sheet-title">{paid ? 'Payment Confirmed' : `Pay PKR ${amount.toLocaleString()}`}</span>
          <button className="sheet-close" onClick={onClose} aria-label="Close payment"><IconX size={14} /></button>
        </div>

        <div className="sheet-body pay-sheet-body">
          {!paid && (
            <div className="pay-summary-card">
              <div className="pay-summary-left">
                <p className="pay-summary-service">{booking?.booking?.service?.replace('_', ' ')}</p>
                <p className="pay-summary-provider">{providerName}</p>
              </div>
              <div className="pay-summary-right">
                <p className="pay-summary-amount">PKR {amount.toLocaleString()}</p>
                <p className="pay-summary-note">Estimate</p>
              </div>
            </div>
          )}

          {paid ? (
            <SuccessView amount={amount} providerName={providerName} last4={last4} />
          ) : (
            <CardForm amount={amount} onSuccess={handleSuccess} />
          )}
        </div>
      </div>
    </>
  );
}
