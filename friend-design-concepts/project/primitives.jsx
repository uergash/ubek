// Shared visual primitives for the Friend app.
// Uses CSS variables defined in friend.css.

const Avatar = ({ person, size = 44, ring = false }) => (
  <div
    style={{
      width: size, height: size, borderRadius: '50%',
      background: window.avatarBg(person.avatarHue),
      color: '#fff',
      fontWeight: 600, fontSize: size * 0.36,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      flexShrink: 0,
      letterSpacing: '0.02em',
      boxShadow: ring ? '0 0 0 3px var(--bg), 0 0 0 4px var(--accent)' : 'none',
    }}
  >
    {window.initials(person.name)}
  </div>
);

const HealthDot = ({ state, size = 8 }) => {
  const colors = {
    green: 'var(--health-green)',
    yellow: 'var(--health-yellow)',
    red: 'var(--health-red)',
  };
  return (
    <span
      style={{
        width: size, height: size, borderRadius: '50%',
        background: colors[state],
        display: 'inline-block',
        flexShrink: 0,
      }}
    />
  );
};

const Chip = ({ children, active = false, onClick, icon }) => (
  <button
    onClick={onClick}
    style={{
      appearance: 'none', border: 'none',
      background: active ? 'var(--ink)' : 'var(--chip-bg)',
      color: active ? 'var(--bg)' : 'var(--ink)',
      borderRadius: 999,
      padding: '7px 13px',
      fontSize: 13, fontWeight: 500,
      whiteSpace: 'nowrap',
      display: 'inline-flex', alignItems: 'center', gap: 6,
      cursor: 'pointer',
      letterSpacing: '-0.005em',
      flexShrink: 0,
    }}
  >
    {icon}
    {children}
  </button>
);

const FactChip = ({ children }) => (
  <span
    style={{
      background: 'var(--accent-soft)',
      color: 'var(--accent-deep)',
      borderRadius: 999,
      padding: '7px 13px',
      fontSize: 13, fontWeight: 500,
      whiteSpace: 'nowrap',
      display: 'inline-flex', alignItems: 'center', gap: 6,
      flexShrink: 0,
      letterSpacing: '-0.005em',
    }}
  >
    <svg width="11" height="11" viewBox="0 0 12 12" fill="none">
      <path d="M6 1l1.4 3.2L11 5l-3 2.4L8.7 11 6 9.2 3.3 11 4 7.4 1 5l3.6-.8L6 1z" fill="currentColor" opacity="0.85"/>
    </svg>
    {children}
  </span>
);

const Card = ({ children, style = {}, onClick, padded = true }) => (
  <div
    onClick={onClick}
    style={{
      background: 'var(--card)',
      borderRadius: 20,
      padding: padded ? 16 : 0,
      boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 6px 22px rgba(60,40,20,0.04)',
      cursor: onClick ? 'pointer' : 'default',
      ...style,
    }}
  >
    {children}
  </div>
);

const SectionHeader = ({ title, action }) => (
  <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '0 4px', marginBottom: 10 }}>
    <h3 style={{ margin: 0, fontSize: 13, fontWeight: 600, color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
      {title}
    </h3>
    {action && <span style={{ fontSize: 13, color: 'var(--accent)', fontWeight: 500 }}>{action}</span>}
  </div>
);

// Tiny inline icons (24px stroke). Hand-drawn but kept simple.
const Icon = ({ name, size = 22, color = 'currentColor', stroke = 1.7 }) => {
  const s = { width: size, height: size, fill: 'none', stroke: color, strokeWidth: stroke, strokeLinecap: 'round', strokeLinejoin: 'round' };
  switch (name) {
    case 'home':
      return <svg viewBox="0 0 24 24" {...s}><path d="M3 11l9-7 9 7v9a2 2 0 0 1-2 2h-4v-6h-6v6H5a2 2 0 0 1-2-2v-9z"/></svg>;
    case 'search':
      return <svg viewBox="0 0 24 24" {...s}><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>;
    case 'plus':
      return <svg viewBox="0 0 24 24" {...s}><path d="M12 5v14M5 12h14"/></svg>;
    case 'people':
      return <svg viewBox="0 0 24 24" {...s}><circle cx="9" cy="8" r="3.5"/><circle cx="17" cy="9" r="2.5"/><path d="M3 19c0-3 2.7-5 6-5s6 2 6 5"/><path d="M15 19c0-2 1.5-3.5 4-3.5s2 1 2 3.5"/></svg>;
    case 'settings':
      return <svg viewBox="0 0 24 24" {...s}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33 1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>;
    case 'cake':
      return <svg viewBox="0 0 24 24" {...s}><path d="M5 11h14v9H5z"/><path d="M3 20h18"/><path d="M9 7v4M12 5v6M15 7v4"/><circle cx="9" cy="6" r="0.5" fill={color}/><circle cx="12" cy="4" r="0.5" fill={color}/><circle cx="15" cy="6" r="0.5" fill={color}/></svg>;
    case 'ring':
      return <svg viewBox="0 0 24 24" {...s}><circle cx="12" cy="15" r="6"/><path d="M9 9l3-5 3 5"/></svg>;
    case 'star':
      return <svg viewBox="0 0 24 24" {...s}><path d="M12 3l2.6 5.8 6.4.7-4.8 4.4 1.4 6.3L12 17l-5.6 3.2 1.4-6.3L3 9.5l6.4-.7L12 3z"/></svg>;
    case 'gift':
      return <svg viewBox="0 0 24 24" {...s}><path d="M4 11h16v9H4z"/><path d="M2 7h20v4H2z"/><path d="M12 7v13"/><path d="M12 7s-2.5-4-5-4-2 3 0 4M12 7s2.5-4 5-4 2 3 0 4"/></svg>;
    case 'note':
      return <svg viewBox="0 0 24 24" {...s}><path d="M5 4h10l4 4v12H5z"/><path d="M15 4v4h4"/><path d="M8 12h8M8 16h5"/></svg>;
    case 'phone':
      return <svg viewBox="0 0 24 24" {...s}><path d="M22 17v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a1 1 0 0 1 1 .8l1 4a1 1 0 0 1-.3 1L7 9.4a14 14 0 0 0 7.6 7.6l1.6-1.7a1 1 0 0 1 1-.3l4 1a1 1 0 0 1 .8 1z"/></svg>;
    case 'coffee':
      return <svg viewBox="0 0 24 24" {...s}><path d="M4 8h13v6a5 5 0 0 1-10 0V8z" /><path d="M17 9h2a3 3 0 0 1 0 6h-2"/><path d="M7 4v2M11 4v2M15 4v2"/></svg>;
    case 'chat':
      return <svg viewBox="0 0 24 24" {...s}><path d="M4 4h16v12H8l-4 4z"/></svg>;
    case 'event':
      return <svg viewBox="0 0 24 24" {...s}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>;
    case 'mic':
      return <svg viewBox="0 0 24 24" {...s}><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></svg>;
    case 'chevron':
      return <svg viewBox="0 0 24 24" {...s}><path d="M9 6l6 6-6 6"/></svg>;
    case 'back':
      return <svg viewBox="0 0 24 24" {...s}><path d="M15 6l-6 6 6 6"/></svg>;
    case 'close':
      return <svg viewBox="0 0 24 24" {...s}><path d="M6 6l12 12M18 6L6 18"/></svg>;
    case 'check':
      return <svg viewBox="0 0 24 24" {...s}><path d="M5 12l4 4L19 6"/></svg>;
    case 'sparkle':
      return <svg viewBox="0 0 24 24" {...s}><path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l3 3M15 15l3 3M18 6l-3 3M9 15l-3 3"/></svg>;
    default: return null;
  }
};

const interactionIcon = (type) => ({
  Call: 'phone', Coffee: 'coffee', Text: 'chat', Event: 'event', Other: 'note',
})[type] || 'note';

const TabBar = ({ active, onChange, onAdd }) => (
  <div
    style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      paddingBottom: 28,
      background: 'linear-gradient(to top, var(--bg) 60%, transparent)',
      display: 'flex', justifyContent: 'space-around', alignItems: 'center',
      paddingTop: 10, paddingLeft: 20, paddingRight: 20,
    }}
  >
    {[
      { id: 'home', icon: 'home', label: 'Home' },
      { id: 'search', icon: 'search', label: 'Search' },
      { id: 'add', icon: 'plus', label: '', primary: true },
      { id: 'people', icon: 'people', label: 'People' },
      { id: 'settings', icon: 'settings', label: 'Settings' },
    ].map((t) => {
      if (t.primary) {
        return (
          <button key={t.id} onClick={onAdd}
            style={{
              appearance: 'none', border: 'none', cursor: 'pointer',
              width: 52, height: 52, borderRadius: '50%',
              background: 'var(--accent)', color: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 16px oklch(0.66 0.13 40 / 0.4)',
              marginTop: -10,
            }}
          >
            <Icon name="plus" size={24} stroke={2.4} />
          </button>
        );
      }
      const is = active === t.id;
      return (
        <button key={t.id} onClick={() => onChange(t.id)}
          style={{
            appearance: 'none', border: 'none', background: 'transparent',
            display: 'flex', flexDirection: 'column', alignItems: 'center',
            color: is ? 'var(--ink)' : 'var(--muted)',
            cursor: 'pointer', gap: 2, padding: 4,
          }}
        >
          <Icon name={t.icon} size={22} stroke={is ? 2 : 1.6} />
          <span style={{ fontSize: 10.5, fontWeight: 500 }}>{t.label}</span>
        </button>
      );
    })}
  </div>
);

Object.assign(window, {
  Avatar, HealthDot, Chip, FactChip, Card, SectionHeader, Icon, TabBar, interactionIcon,
});
