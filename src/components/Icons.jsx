import React from 'react';

const Svg = ({ size = 20, strokeWidth = 1.8, fill = 'none', className = '', ...p }) => (
  <svg
    width={size} height={size} viewBox="0 0 24 24"
    fill={fill} stroke="currentColor"
    strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round"
    aria-hidden="true" className={className} {...p}
  />
);

/* ── Brand ─────────────────────────────────────────── */
export const IconBolt = ({ size, ...p }) => (
  <Svg size={size} fill="currentColor" stroke="none" {...p}>
    <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
  </Svg>
);

/* ── Agents ─────────────────────────────────────────── */
export const IconBrain = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M9.5 2A2.5 2.5 0 0 1 12 4.5v15a2.5 2.5 0 0 1-4.96-.44 2.5 2.5 0 0 1-2.96-3.08 3 3 0 0 1-.34-5.58 2.5 2.5 0 0 1 3.32-4.43A2.5 2.5 0 0 1 9.5 2"/>
    <path d="M14.5 2A2.5 2.5 0 0 0 12 4.5v15a2.5 2.5 0 0 0 4.96-.44 2.5 2.5 0 0 0 2.96-3.08 3 3 0 0 0 .34-5.58 2.5 2.5 0 0 0-3.32-4.43A2.5 2.5 0 0 0 14.5 2"/>
  </Svg>
);

export const IconSearch = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <circle cx="11" cy="11" r="8"/>
    <path d="m21 21-4.35-4.35"/>
  </Svg>
);

export const IconBarChart = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <line x1="18" y1="20" x2="18" y2="10"/>
    <line x1="12" y1="20" x2="12" y2="4"/>
    <line x1="6"  y1="20" x2="6"  y2="14"/>
  </Svg>
);

export const IconTag = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M12 2H2v10l9.29 9.29a1 1 0 0 0 1.41 0l7-7a1 1 0 0 0 0-1.42Z"/>
    <circle cx="7" cy="7" r="1" fill="currentColor" stroke="none"/>
  </Svg>
);

export const IconCalCheck = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <rect x="3" y="4" width="18" height="18" rx="2"/>
    <line x1="16" y1="2" x2="16" y2="6"/>
    <line x1="8"  y1="2" x2="8"  y2="6"/>
    <line x1="3"  y1="10" x2="21" y2="10"/>
    <path d="m9 16 2 2 4-4"/>
  </Svg>
);

export const IconBell = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
    <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
  </Svg>
);

/* ── Chat ───────────────────────────────────────────── */
export const IconUser = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
    <circle cx="12" cy="7" r="4"/>
  </Svg>
);

export const IconArrowUp = ({ size, ...p }) => (
  <Svg size={size} strokeWidth={2.2} {...p}>
    <line x1="12" y1="19" x2="12" y2="5"/>
    <polyline points="5 12 12 5 19 12"/>
  </Svg>
);

export const IconArrowDown = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <line x1="12" y1="5" x2="12" y2="19"/>
    <polyline points="19 12 12 19 5 12"/>
  </Svg>
);

export const IconHome = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
    <polyline points="9 22 9 12 15 12 15 22"/>
  </Svg>
);

/* ── Services ───────────────────────────────────────── */
export const IconZap = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
  </Svg>
);

export const IconDrop = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M12 22a7 7 0 0 0 7-7c0-2-1-3.9-3-5.5s-3.5-4-4-6.5c-.5 2.5-2 4.9-4 6.5C6 11.1 5 13 5 15a7 7 0 0 0 7 7z"/>
  </Svg>
);

export const IconSparkles = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M12 3 13.5 7.5 18 9l-4.5 1.5L12 15l-1.5-4.5L6 9l4.5-1.5Z"/>
    <path d="M5 5 5.5 6.5 7 7l-1.5.5L5 9l-.5-1.5L3 7l1.5-.5Z"/>
    <path d="M19 15l.5 1.5 1.5.5-1.5.5L19 19l-.5-1.5-1.5-.5 1.5-.5Z"/>
  </Svg>
);

export const IconWind = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M17.7 7.7a2.5 2.5 0 1 1 1.8 4.3H2"/>
    <path d="M9.6 4.6A2 2 0 1 1 11 8H2"/>
    <path d="M12.6 19.4A2 2 0 1 0 14 16H2"/>
  </Svg>
);

export const IconHammer = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="m15 12-8.373 8.373a1 1 0 1 1-1.414-1.414L13.586 11"/>
    <path d="m17 8 2-2"/>
    <path d="m14 9 4.5-4.5a2.12 2.12 0 0 1 3 3L17 12Z"/>
  </Svg>
);

export const IconPaintbrush = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M18.37 2.63 14 7l-1.59-1.59a2 2 0 0 0-2.82 0L8 7l9 9 1.59-1.59a2 2 0 0 0 0-2.82L17 10l4.37-4.37a2.12 2.12 0 1 0-3-3Z"/>
    <path d="M9 8c-2 3-4 3.5-7 4l8 10c2-1 6-5 6-7"/>
  </Svg>
);

/* ── Booking card ────────────────────────────────────── */
export const IconHardHat = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M2 18a1 1 0 0 0 1 1h18a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1H3a1 1 0 0 0-1 1v2Z"/>
    <path d="M10 10V5a2 2 0 1 1 4 0v5"/>
    <path d="M4 15v-3a8 8 0 0 1 16 0v3"/>
  </Svg>
);

export const IconCalendar = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <rect x="3" y="4" width="18" height="18" rx="2"/>
    <line x1="16" y1="2" x2="16" y2="6"/>
    <line x1="8"  y1="2" x2="8"  y2="6"/>
    <line x1="3"  y1="10" x2="21" y2="10"/>
  </Svg>
);

export const IconPhone = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 3.07 9.8 19.79 19.79 0 0 1 .22 1.18 2 2 0 0 1 2.18 0h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L6.27 7.91a16 16 0 0 0 6.72 6.72l1.06-1.06a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92Z"/>
  </Svg>
);

export const IconMapPin = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/>
    <circle cx="12" cy="10" r="3"/>
  </Svg>
);

export const IconShield = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z"/>
  </Svg>
);

export const IconShieldCheck = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z"/>
    <path d="m9 12 2 2 4-4"/>
  </Svg>
);

export const IconStar = ({ size, ...p }) => (
  <Svg size={size} fill="currentColor" stroke="none" {...p}>
    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
  </Svg>
);

export const IconCopy = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <rect x="9" y="9" width="13" height="13" rx="2"/>
    <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
  </Svg>
);

export const IconCheck = ({ size, ...p }) => (
  <Svg size={size} strokeWidth={2.5} {...p}>
    <polyline points="20 6 9 17 4 12"/>
  </Svg>
);

export const IconClock = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <circle cx="12" cy="12" r="10"/>
    <polyline points="12 6 12 12 16 14"/>
  </Svg>
);

export const IconDollarSign = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <line x1="12" y1="1" x2="12" y2="23"/>
    <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>
  </Svg>
);

/* ── UI Controls ─────────────────────────────────────── */
export const IconPlus = ({ size, ...p }) => (
  <Svg size={size} strokeWidth={2} {...p}>
    <line x1="12" y1="5" x2="12" y2="19"/>
    <line x1="5"  y1="12" x2="19" y2="12"/>
  </Svg>
);

export const IconX = ({ size, ...p }) => (
  <Svg size={size} strokeWidth={2} {...p}>
    <line x1="18" y1="6"  x2="6"  y2="18"/>
    <line x1="6"  y1="6"  x2="18" y2="18"/>
  </Svg>
);

export const IconChevDown = ({ size, ...p }) => (
  <Svg size={size} {...p}><polyline points="6 9 12 15 18 9"/></Svg>
);

export const IconChevUp = ({ size, ...p }) => (
  <Svg size={size} {...p}><polyline points="18 15 12 9 6 15"/></Svg>
);

export const IconAlertTri = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="m10.29 3.86-8.47 14.47A1 1 0 0 0 2.82 20h18.36a1 1 0 0 0 .86-1.67L13.71 3.86a1.65 1.65 0 0 0-3.42 0Z"/>
    <line x1="12" y1="9"  x2="12" y2="13"/>
    <line x1="12" y1="17" x2="12.01" y2="17"/>
  </Svg>
);

export const IconDatabase = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <ellipse cx="12" cy="5" rx="9" ry="3"/>
    <path d="M3 5v14c0 1.66 4.03 3 9 3s9-1.34 9-3V5"/>
    <path d="M3 12c0 1.66 4.03 3 9 3s9-1.34 9-3"/>
  </Svg>
);

export const IconMicroscope = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M6 18h8"/>
    <path d="M3 22h18"/>
    <path d="M14 22a7 7 0 1 0 0-14h-1"/>
    <path d="M9 14v-3"/>
    <path d="M9 3v2"/>
    <path d="M7 3h4a2 2 0 0 1 2 2v1a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Z"/>
  </Svg>
);

export const IconWifi = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M5 12.55a11 11 0 0 1 14.08 0"/>
    <path d="M1.42 9a16 16 0 0 1 21.16 0"/>
    <path d="M8.53 16.11a6 6 0 0 1 6.95 0"/>
    <line x1="12" y1="20" x2="12.01" y2="20"/>
  </Svg>
);

export const IconMessagesSquare = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M14 9a2 2 0 0 1-2 2H6l-4 4V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2Z"/>
    <path d="M18 9h2a2 2 0 0 1 2 2v11l-4-4h-6a2 2 0 0 1-2-2v-1"/>
  </Svg>
);

export const IconActivity = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
  </Svg>
);

export const IconBriefcase = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <rect x="2" y="7" width="20" height="14" rx="2"/>
    <path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/>
    <line x1="12" y1="12" x2="12" y2="12"/>
    <path d="M2 12h20"/>
  </Svg>
);

export const IconBookOpen = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/>
    <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/>
  </Svg>
);

export const IconScissors = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <circle cx="6" cy="6" r="3"/>
    <circle cx="6" cy="18" r="3"/>
    <line x1="20" y1="4" x2="8.12" y2="15.88"/>
    <line x1="14.47" y1="14.48" x2="20" y2="20"/>
    <line x1="8.12" y1="8.12" x2="12" y2="12"/>
  </Svg>
);

export const IconLock = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
    <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
  </Svg>
);

export const IconCreditCard = ({ size, ...p }) => (
  <Svg size={size} {...p}>
    <rect x="1" y="4" width="22" height="16" rx="2" ry="2"/>
    <line x1="1" y1="10" x2="23" y2="10"/>
  </Svg>
);
