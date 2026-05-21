import React, { useState } from 'react';
import {
  IconHardHat, IconCalendar, IconPhone, IconMapPin,
  IconShieldCheck, IconStar, IconCopy, IconCheck,
  IconBell, IconClock, IconDollarSign, IconAlertTri, IconX,
  IconCreditCard,
} from './Icons.jsx';
import LiveTracker from './LiveTracker.jsx';
import './BookingCard.css';

function StarRating({ value }) {
  return (
    <span className="star-rating" aria-label={`Rating: ${value} out of 5`}>
      {[1,2,3,4,5].map(n => (
        <IconStar key={n} size={11} className={n <= Math.round(value) ? 'star-on' : 'star-off'} />
      ))}
      <span className="star-value">{value}</span>
    </span>
  );
}

export default function BookingCard({ data, onCancel, onToast, onPay, paid = false }) {
  if (!data?.booking) return null;
  const { booking, pricing, followup } = data;
  const [copied,     setCopied    ] = useState(false);
  const [cancelStep, setCancelStep] = useState(0);
  const bd = pricing?.output?.breakdown;

  const copyId = () => {
    navigator.clipboard.writeText(booking.booking_id);
    setCopied(true);
    onToast?.('Booking ID copied!', 'success');
    setTimeout(() => setCopied(false), 2200);
  };

  return (
    <div className="booking-card bounce-in" role="region" aria-label={`Booking ${booking.booking_id}`}>
      <div className="bc-ambient" aria-hidden="true" />

      {/* ── Header ── */}
      <div className="bc-header">
        <div className="bc-check-ring" aria-hidden="true">
          <IconCheck size={22} strokeWidth={2.8} />
        </div>
        <div className="bc-header-text">
          <p className="bc-title">{paid ? 'Paid & Confirmed' : 'Payment Pending'}</p>
          <button className="bc-id-btn" onClick={copyId} aria-label="Copy booking ID">
            <span className="bc-id-text">{booking.booking_id}</span>
            {copied
              ? <IconCheck size={12} style={{ color: 'var(--emerald)' }} />
              : <IconCopy  size={12} />
            }
          </button>
        </div>
        <div className="bc-total" aria-label={`Total estimate PKR ${booking.pricing.total.toLocaleString()}`}>
          <p className="bc-total-label">Estimate</p>
          <p className="bc-total-amt">PKR {booking.pricing.total.toLocaleString()}</p>
        </div>
      </div>

      <div className="bc-body">

        {/* ── Provider ── */}
        <div className="bc-provider-card">
          <div className="bc-provider-avatar" aria-hidden="true">
            <IconHardHat size={20} />
          </div>
          <div className="bc-provider-info">
            <div className="bc-provider-name">{booking.provider.name}</div>
            <div className="bc-provider-meta">
              <StarRating value={booking.provider.rating} />
              {booking.provider.certified && (
                <span className="bc-certified">
                  <IconShieldCheck size={11} /> Certified
                </span>
              )}
            </div>
          </div>
        </div>

        {/* ── Details grid ── */}
        <div className="bc-details-grid">
          <div className="bc-detail">
            <IconMapPin size={14} className="bc-detail-icon" />
            <div>
              <p className="bc-detail-label">Area</p>
              <p className="bc-detail-val">{booking.provider.area}</p>
            </div>
          </div>
          <div className="bc-detail">
            <IconCalendar size={14} className="bc-detail-icon" />
            <div>
              <p className="bc-detail-label">Date</p>
              <p className="bc-detail-val">{booking.slot.date}</p>
            </div>
          </div>
          <div className="bc-detail">
            <IconClock size={14} className="bc-detail-icon" />
            <div>
              <p className="bc-detail-label">Time</p>
              <p className="bc-detail-val">{booking.slot.time}</p>
            </div>
          </div>
          <div className="bc-detail">
            <IconPhone size={14} className="bc-detail-icon" />
            <div>
              <p className="bc-detail-label">Contact</p>
              <p className="bc-detail-val">{booking.provider.phone}</p>
            </div>
          </div>
        </div>

        {/* ── Price breakdown ── */}
        {bd && (
          <div className="bc-pricing">
            <div className="bc-pricing-header">
              <IconDollarSign size={13} />
              <span>Price Breakdown</span>
            </div>
            <div className="bc-price-rows">
              <div className="bc-price-row">
                <span>Labor ({bd.labor.hours}h × PKR {bd.labor.rate.toLocaleString()})</span>
                <span>PKR {bd.labor.total.toLocaleString()}</span>
              </div>
              <div className="bc-price-row">
                <span>Visit fee</span>
                <span>PKR {bd.visit_fee.toLocaleString()}</span>
              </div>
              <div className="bc-price-row">
                <span>Materials estimate</span>
                <span>PKR {bd.materials_estimate.toLocaleString()}</span>
              </div>
              {bd.urgency_surcharge > 0 && (
                <div className="bc-price-row bc-price-urgent">
                  <span>Urgency surcharge</span>
                  <span>PKR {bd.urgency_surcharge.toLocaleString()}</span>
                </div>
              )}
              <div className="bc-price-row">
                <span>GST (5%)</span>
                <span>PKR {bd.tax_gst.toLocaleString()}</span>
              </div>
              <div className="bc-price-row">
                <span>Platform fee</span>
                <span>PKR {bd.platform_fee.toLocaleString()}</span>
              </div>
              <div className="bc-price-row bc-price-total">
                <span>Total Estimate</span>
                <span>PKR {booking.pricing.total.toLocaleString()}</span>
              </div>
            </div>
          </div>
        )}

        {/* ── Payment methods ── */}
        <div className="bc-payments" aria-label="Accepted payment methods">
          {booking.pricing.payment_methods.map(m => (
            <span key={m} className="pay-badge">{m}</span>
          ))}
        </div>

        {/* ── Followup reminders ── */}
        {followup?.reminders_scheduled?.length > 0 && (
          <div className="bc-followup">
            <div className="bc-followup-header">
              <IconBell size={13} />
              <span>Reminders Scheduled</span>
            </div>
            <ul className="bc-reminders" aria-label="Scheduled reminders">
              {followup.reminders_scheduled.map((r, i) => (
                <li key={i} className="bc-reminder">
                  <span className="bc-reminder-trigger">{r.trigger}</span>
                  <span className="bc-reminder-msg">{r.message}</span>
                </li>
              ))}
            </ul>
            {followup.dispute_channel && (
              <p className="bc-dispute">
                Support / Dispute: <strong>{followup.dispute_channel}</strong>
              </p>
            )}
          </div>
        )}

        {/* ── Live Tracker — shown after payment ── */}
        <LiveTracker active={paid} providerName={booking.provider.name} />

        {/* ── Actions ── */}
        <div className="bc-actions">

          {/* Pay Now */}
          {paid ? (
            <div className="bc-paid-badge" aria-label="Payment complete">
              <IconCheck size={14} />
              <span>Paid · PKR {booking.pricing.total.toLocaleString()}</span>
            </div>
          ) : (
            <button
              className="bc-pay-btn"
              onClick={() => onPay?.(data)}
              aria-label={`Pay PKR ${booking.pricing.total.toLocaleString()}`}
            >
              <IconCreditCard size={14} />
              <span>Pay PKR {booking.pricing.total.toLocaleString()}</span>
            </button>
          )}

          {/* Cancel */}
          {cancelStep === 1 ? (
            <div className="bc-cancel-confirm" role="alert">
              <div className="bc-cancel-warning">
                <IconAlertTri size={15} />
                <span>Cancel this booking?</span>
              </div>
              <div className="bc-cancel-btns">
                <button className="bc-btn-yes" onClick={() => onCancel?.(booking.booking_id)}>
                  Yes, cancel
                </button>
                <button className="bc-btn-keep" onClick={() => setCancelStep(0)}>
                  Keep it
                </button>
              </div>
            </div>
          ) : (
            <button className="bc-cancel-btn" onClick={() => setCancelStep(1)} aria-label="Cancel booking">
              <IconX size={13} />
              <span>Cancel Booking</span>
            </button>
          )}
        </div>

      </div>
    </div>
  );
}
