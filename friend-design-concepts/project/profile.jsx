// Person profile — Overview / Notes / Gifts / Dates tabs

const ProfileScreen = ({ personId, onBack, onAddNote, initialTab = 'Overview' }) => {
  const p = window.PEOPLE.find((x) => x.id === personId);
  const [tab, setTab] = React.useState(initialTab);

  return (
    <div className="screen">
      {/* Top bar */}
      <div style={{
        position: 'absolute', top: 50, left: 0, right: 0, zIndex: 5,
        display: 'flex', justifyContent: 'space-between', padding: '8px 16px',
      }}>
        <button onClick={onBack} style={{
          appearance: 'none', border: 'none', background: 'rgba(255,255,255,0.7)',
          backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)',
          width: 36, height: 36, borderRadius: '50%',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer', boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
        }}>
          <window.Icon name="back" size={18} stroke={2} />
        </button>
        <button style={{
          appearance: 'none', border: 'none', background: 'rgba(255,255,255,0.7)',
          backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)',
          height: 36, padding: '0 14px', borderRadius: 999,
          display: 'flex', alignItems: 'center', gap: 5,
          cursor: 'pointer', boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
          color: 'var(--ink-soft)', fontSize: 13, fontWeight: 500,
        }}>
          Edit
        </button>
      </div>

      <div className="scroll-area scroll-hide" style={{ paddingTop: 96, paddingBottom: 40 }}>
        {/* Header */}
        <div style={{ padding: '0 22px 18px', display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
          <window.Avatar person={p} size={92} />
          <h1 style={{ margin: '14px 0 4px', fontSize: 26, fontWeight: 700, letterSpacing: '-0.02em' }}>{p.name}</h1>
          <div style={{ fontSize: 13.5, color: 'var(--muted)', display: 'flex', alignItems: 'center', gap: 6 }}>
            <window.HealthDot state={window.healthFor(p)} size={7} />
            {p.relation} · {window.lastInteractionLabel(p.lastDays)}
          </div>

          {/* Quick actions */}
          <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
            <button onClick={onAddNote} style={qaBtn(true)}>
              <window.Icon name="note" size={16} stroke={2} /> Add note
            </button>
            <button style={qaBtn(false)}>
              <window.Icon name="event" size={16} stroke={2} /> Add date
            </button>
            <button style={qaBtn(false)}>
              <window.Icon name="gift" size={16} stroke={2} /> Gift
            </button>
          </div>
        </div>

        {/* Tab bar */}
        <div style={{
          display: 'flex', padding: '0 22px', gap: 22,
          borderBottom: '1px solid var(--hairline)', marginBottom: 18,
        }}>
          {['Overview', 'Notes', 'Gifts', 'Dates'].map((t) => (
            <button key={t} onClick={() => setTab(t)} style={{
              appearance: 'none', border: 'none', background: 'transparent',
              padding: '10px 0', fontSize: 14, fontWeight: 600, cursor: 'pointer',
              color: tab === t ? 'var(--ink)' : 'var(--muted)',
              borderBottom: tab === t ? '2px solid var(--accent)' : '2px solid transparent',
              marginBottom: -1,
            }}>{t}</button>
          ))}
        </div>

        <div className="fade-in" style={{ padding: '0 22px' }} key={tab}>
          {tab === 'Overview' && <OverviewTab person={p} />}
          {tab === 'Notes' && <NotesTab person={p} onAddNote={onAddNote} />}
          {tab === 'Gifts' && <GiftsTab person={p} />}
          {tab === 'Dates' && <DatesTab person={p} />}
        </div>
      </div>
    </div>
  );
};

const qaBtn = (primary) => ({
  appearance: 'none', border: 'none', cursor: 'pointer',
  display: 'inline-flex', alignItems: 'center', gap: 5,
  padding: '9px 14px', borderRadius: 999,
  fontSize: 13.5, fontWeight: 600,
  background: primary ? 'var(--ink)' : 'var(--chip-bg)',
  color: primary ? 'var(--bg)' : 'var(--ink)',
});

// ── Overview ────────────────────────────────────────────────────────────
const OverviewTab = ({ person }) => (
  <>
    <window.SectionHeader title="Key facts" action="See all" />
    <div className="scroll-hide" style={{ display: 'flex', gap: 8, overflowX: 'auto', marginLeft: -4, paddingLeft: 4, marginBottom: 22 }}>
      {person.keyFacts.map((f) => <window.FactChip key={f}>{f}</window.FactChip>)}
    </div>

    {person.upcoming && (
      <>
        <window.SectionHeader title="Coming up" />
        <window.Card style={{ marginBottom: 22, display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{
            width: 50, height: 50, borderRadius: 14,
            background: 'var(--accent-soft)', color: 'var(--accent)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <window.Icon name={person.upcoming.kind === 'birthday' ? 'cake' : person.upcoming.kind === 'anniversary' ? 'ring' : 'star'} size={22} stroke={1.7} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11.5, color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.06em', fontWeight: 600 }}>{person.upcoming.label}</div>
            <div style={{ fontSize: 16, fontWeight: 600, marginTop: 2 }}>{person.upcoming.date}</div>
          </div>
          <div style={{
            background: 'var(--ink)', color: 'var(--bg)',
            fontSize: 12, fontWeight: 600, padding: '5px 11px', borderRadius: 999,
          }}>
            in {person.upcoming.daysAway} days
          </div>
        </window.Card>
      </>
    )}

    <window.SectionHeader title="Recent interactions" />
    <window.Card style={{ marginBottom: 22, position: 'relative', paddingTop: 38 }}>
      <div style={{
        position: 'absolute', top: 14, left: 14,
        display: 'inline-flex', alignItems: 'center', gap: 5,
        fontSize: 10.5, fontWeight: 600, color: 'var(--accent)',
        background: 'var(--accent-soft)', padding: '3px 8px', borderRadius: 999,
        letterSpacing: '0.06em', textTransform: 'uppercase',
      }}>
        <window.Icon name="sparkle" size={10} stroke={2} /> Summary
      </div>
      <p style={{ margin: 0, fontSize: 14.5, lineHeight: 1.55, color: 'var(--ink-soft)', textWrap: 'pretty' }}>
        {person.summary || 'You haven’t logged any interactions yet. Add a note to start building a picture.'}
      </p>
    </window.Card>

    <window.SectionHeader title="Latest" action="See all" />
    {person.notes[0] && <NoteCard note={person.notes[0]} />}
  </>
);

// ── Notes ───────────────────────────────────────────────────────────────
const NoteCard = ({ note }) => (
  <window.Card style={{ marginBottom: 10 }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
      <div style={{
        width: 26, height: 26, borderRadius: '50%',
        background: 'var(--accent-soft)', color: 'var(--accent-deep)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <window.Icon name={window.interactionIcon(note.type)} size={13} stroke={1.9} />
      </div>
      <span style={{ fontWeight: 600, fontSize: 13 }}>{note.type}</span>
      <span style={{ fontSize: 12.5, color: 'var(--muted)' }}>· {note.date}</span>
    </div>
    <p style={{ margin: 0, fontSize: 14, lineHeight: 1.5, color: 'var(--ink-soft)', textWrap: 'pretty' }}>{note.text}</p>
    {note.facts.length > 0 && (
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 12 }}>
        {note.facts.map((f) => <window.FactChip key={f}>{f}</window.FactChip>)}
      </div>
    )}
  </window.Card>
);

const NotesTab = ({ person, onAddNote }) => (
  <>
    <button onClick={onAddNote} style={{
      appearance: 'none', border: '1.5px dashed var(--hairline)', background: 'transparent',
      width: '100%', padding: '14px', borderRadius: 16,
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      color: 'var(--accent)', fontWeight: 600, fontSize: 14, marginBottom: 14, cursor: 'pointer',
    }}>
      <window.Icon name="plus" size={16} stroke={2.2} /> New note for {person.name.split(' ')[0]}
    </button>
    {person.notes.length === 0 && (
      <div style={{ textAlign: 'center', color: 'var(--muted)', padding: 30, fontSize: 14 }}>
        No notes yet. Tap above to capture your first.
      </div>
    )}
    {person.notes.map((n) => <NoteCard key={n.id} note={n} />)}
  </>
);

// ── Gifts ───────────────────────────────────────────────────────────────
const GiftsTab = ({ person }) => (
  <>
    <window.SectionHeader title="Wishlist" action="Add" />
    {person.gifts.wishlist.length === 0 && (
      <div style={{ color: 'var(--muted)', fontSize: 14, padding: 12, marginBottom: 14 }}>No ideas yet.</div>
    )}
    {person.gifts.wishlist.map((g) => (
      <window.Card key={g.id} style={{ marginBottom: 10, display: 'flex', gap: 12, alignItems: 'flex-start' }}>
        <div style={{
          width: 38, height: 38, borderRadius: 12,
          background: 'var(--accent-soft)', color: 'var(--accent)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
        }}>
          <window.Icon name="gift" size={18} stroke={1.7} />
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 600, fontSize: 14.5 }}>{g.name}</div>
          {g.note && <div style={{ fontSize: 13, color: 'var(--muted)', marginTop: 3, lineHeight: 1.4 }}>{g.note}</div>}
          <button style={{
            appearance: 'none', border: 'none', background: 'transparent',
            color: 'var(--accent)', fontSize: 13, fontWeight: 600, padding: 0, marginTop: 8, cursor: 'pointer',
          }}>Mark as given →</button>
        </div>
      </window.Card>
    ))}

    {person.gifts.gifted.length > 0 && (
      <>
        <window.SectionHeader title={`Gifted (${person.gifts.gifted.length})`} />
        {person.gifts.gifted.map((g) => (
          <window.Card key={g.id} style={{ marginBottom: 10, display: 'flex', gap: 12, alignItems: 'center' }}>
            <div style={{
              width: 38, height: 38, borderRadius: 12, background: 'var(--card-soft)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18,
            }}>🎁</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 14 }}>{g.name}</div>
              <div style={{ fontSize: 12.5, color: 'var(--muted)' }}>{g.occasion} · {g.date}</div>
            </div>
            <span style={{
              fontSize: 11, fontWeight: 600,
              background: 'oklch(0.95 0.06 145)', color: 'oklch(0.4 0.1 145)',
              padding: '4px 10px', borderRadius: 999,
            }}>Loved it</span>
          </window.Card>
        ))}
      </>
    )}
  </>
);

// ── Dates ───────────────────────────────────────────────────────────────
const DatesTab = ({ person }) => (
  <window.Card padded={false}>
    {person.dates.length === 0 && (
      <div style={{ padding: 24, textAlign: 'center', color: 'var(--muted)', fontSize: 14 }}>No dates saved.</div>
    )}
    {person.dates.map((d, i) => (
      <div key={i} style={{
        display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px',
        borderBottom: i < person.dates.length - 1 ? '1px solid var(--hairline)' : 'none',
      }}>
        <div style={{
          width: 38, height: 38, borderRadius: 12,
          background: 'var(--accent-soft)', color: 'var(--accent)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <window.Icon name={d.kind === 'birthday' ? 'cake' : d.kind === 'anniversary' ? 'ring' : 'star'} size={18} stroke={1.7} />
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontWeight: 600, fontSize: 14.5 }}>{d.label}</div>
          <div style={{ fontSize: 13, color: 'var(--muted)' }}>{d.date}</div>
        </div>
        <Toggle on={d.remind} />
      </div>
    ))}
  </window.Card>
);

const Toggle = ({ on }) => (
  <div style={{
    width: 44, height: 26, borderRadius: 999,
    background: on ? 'var(--accent)' : 'var(--hairline)',
    position: 'relative', transition: 'background 200ms',
  }}>
    <div style={{
      position: 'absolute', top: 2, left: on ? 20 : 2,
      width: 22, height: 22, borderRadius: '50%', background: '#fff',
      transition: 'left 200ms', boxShadow: '0 1px 3px rgba(0,0,0,0.15)',
    }} />
  </div>
);

window.ProfileScreen = ProfileScreen;
