// Home screen — greeting, upcoming, nudges, people list

const HomeScreen = ({ onOpenPerson, onAddNote, navTab, setNavTab }) => {
  const [filter, setFilter] = React.useState('All');
  const filters = ['All', 'Family', 'Friends', 'College Friends', 'Climbing', 'Work'];

  const upcoming = window.PEOPLE.filter((p) => p.upcoming).sort((a, b) => a.upcoming.daysAway - b.upcoming.daysAway);
  const nudges = window.NUDGES.map((n) => ({ ...n, person: window.PEOPLE.find((p) => p.id === n.personId) }));

  const filtered = window.PEOPLE.filter((p) => {
    if (filter === 'All') return true;
    if (filter === 'Family' || filter === 'Friends') return p.relation === filter.replace(/s$/, '');
    return p.groups.includes(filter);
  }).sort((a, b) => {
    const order = { red: 0, yellow: 1, green: 2 };
    return order[window.healthFor(a)] - order[window.healthFor(b)];
  });

  return (
    <div className="screen">
      <div className="scroll-area scroll-hide" style={{ paddingBottom: 120 }}>
        {/* Greeting */}
        <div style={{ padding: '14px 22px 16px' }}>
          <div style={{ fontSize: 13, color: 'var(--muted)', fontWeight: 500, marginBottom: 4 }}>Friday, April 24</div>
          <h1 style={{ margin: 0, fontSize: 30, fontWeight: 700, letterSpacing: '-0.02em' }}>
            Good morning,<br/>Ubek.
          </h1>
        </div>

        {/* Upcoming horizontal scroll */}
        <window.SectionHeader title="Upcoming" />
        <div style={{
          display: 'flex', gap: 12, overflowX: 'auto', padding: '0 22px 4px',
          marginBottom: 22, scrollSnapType: 'x mandatory',
        }} className="scroll-hide">
          {upcoming.map((p) => (
            <div key={p.id}
              onClick={() => onOpenPerson(p.id)}
              style={{
                flex: '0 0 auto', width: 158, scrollSnapAlign: 'start',
                background: 'var(--card)', borderRadius: 20, padding: 14,
                boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 6px 22px rgba(60,40,20,0.04)',
                cursor: 'pointer',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <window.Avatar person={p} size={40} />
                <div style={{
                  background: 'var(--accent-soft)', color: 'var(--accent-deep)',
                  fontSize: 11, fontWeight: 600, padding: '3px 8px', borderRadius: 999,
                }}>
                  {p.upcoming.daysAway === 0 ? 'Today' : `${p.upcoming.daysAway}d`}
                </div>
              </div>
              <div style={{ marginTop: 14, fontWeight: 600, fontSize: 15, lineHeight: 1.2 }}>{p.name.split(' ')[0]}</div>
              <div style={{ fontSize: 12.5, color: 'var(--muted)', marginTop: 3, display: 'flex', alignItems: 'center', gap: 5 }}>
                <window.Icon name={p.upcoming.kind === 'birthday' ? 'cake' : p.upcoming.kind === 'anniversary' ? 'ring' : 'star'} size={13} stroke={1.7} />
                {p.upcoming.label} · {p.upcoming.date}
              </div>
            </div>
          ))}
        </div>

        {/* Nudges */}
        <div style={{ padding: '0 22px' }}>
          <window.SectionHeader title="Reach out" action={`${nudges.length} new`} />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 24 }}>
            {nudges.map((n) => (
              <div key={n.personId}
                onClick={() => onOpenPerson(n.personId)}
                style={{
                  background: 'var(--card)', borderRadius: 20, padding: 14,
                  boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 6px 22px rgba(60,40,20,0.04)',
                  display: 'flex', gap: 12, alignItems: 'flex-start', cursor: 'pointer',
                  position: 'relative', overflow: 'hidden',
                }}
              >
                <window.Avatar person={n.person} size={42} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
                    <span style={{ fontWeight: 600, fontSize: 14.5 }}>{n.person.name.split(' ')[0]}</span>
                    <span style={{
                      fontSize: 10, fontWeight: 600, color: 'var(--accent)',
                      background: 'var(--accent-soft)', padding: '2px 7px', borderRadius: 999,
                      letterSpacing: '0.04em', textTransform: 'uppercase',
                    }}>
                      <window.Icon name="sparkle" size={9} stroke={2} /> suggested
                    </span>
                  </div>
                  <div style={{ fontSize: 14, lineHeight: 1.4, color: 'var(--ink-soft)' }}>{n.text}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* People list */}
        <div style={{ padding: '0 22px' }}>
          <div style={{
            background: 'var(--chip-bg)', borderRadius: 14,
            display: 'flex', alignItems: 'center', gap: 8,
            padding: '10px 14px', marginBottom: 14,
          }}>
            <window.Icon name="search" size={17} color="var(--muted)" stroke={1.8} />
            <span style={{ color: 'var(--muted)', fontSize: 15 }}>Search people, notes, gifts</span>
          </div>

          <div className="scroll-hide" style={{ display: 'flex', gap: 8, overflowX: 'auto', marginBottom: 16, marginLeft: -4, paddingLeft: 4 }}>
            {filters.map((f) => (
              <window.Chip key={f} active={filter === f} onClick={() => setFilter(f)}>{f}</window.Chip>
            ))}
          </div>

          <div style={{
            background: 'var(--card)', borderRadius: 20, overflow: 'hidden',
            boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 6px 22px rgba(60,40,20,0.04)',
          }}>
            {filtered.map((p, i) => {
              const h = window.healthFor(p);
              return (
                <div key={p.id} onClick={() => onOpenPerson(p.id)}
                  style={{
                    display: 'flex', alignItems: 'center', gap: 12,
                    padding: '12px 16px',
                    borderBottom: i < filtered.length - 1 ? '1px solid var(--hairline)' : 'none',
                    cursor: 'pointer',
                  }}
                >
                  <window.Avatar person={p} size={42} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 600, fontSize: 15.5, lineHeight: 1.2 }}>{p.name}</div>
                    <div style={{ fontSize: 12.5, color: 'var(--muted)', marginTop: 2 }}>
                      {p.relation} · {window.lastInteractionLabel(p.lastDays)}
                    </div>
                  </div>
                  <window.HealthDot state={h} />
                </div>
              );
            })}
          </div>
        </div>
      </div>

      <window.TabBar active={navTab} onChange={setNavTab} onAdd={onAddNote} />
    </div>
  );
};

window.HomeScreen = HomeScreen;
