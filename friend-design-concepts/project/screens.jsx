// Add Note sheet, Search, Onboarding, Widget, Settings stub

// ── Add Note Sheet ──────────────────────────────────────────────────────
const AddNoteSheet = ({ personId, onClose, onSaved }) => {
  const p = window.PEOPLE.find((x) => x.id === personId) || window.PEOPLE[0];
  const [type, setType] = React.useState('Coffee');
  const [text, setText] = React.useState('');
  const [mode, setMode] = React.useState('compose'); // compose | recording | facts
  const [transcript, setTranscript] = React.useState('');

  // Simulate transcription
  React.useEffect(() => {
    if (mode !== 'recording') return;
    const phrases = [
      'Caught up with ',
      `Caught up with ${p.name.split(' ')[0]} at `,
      `Caught up with ${p.name.split(' ')[0]} at the new place on Valencia. `,
      `Caught up with ${p.name.split(' ')[0]} at the new place on Valencia. He’s going to Tokyo `,
      `Caught up with ${p.name.split(' ')[0]} at the new place on Valencia. He’s going to Tokyo in June for two weeks `,
      `Caught up with ${p.name.split(' ')[0]} at the new place on Valencia. He’s going to Tokyo in June for two weeks and is finally adopting a dog.`,
    ];
    let i = 0;
    const id = setInterval(() => {
      setTranscript(phrases[i]);
      if (++i >= phrases.length) clearInterval(id);
    }, 700);
    return () => clearInterval(id);
  }, [mode, p]);

  const types = [
    { id: 'Call', icon: 'phone' },
    { id: 'Coffee', icon: 'coffee' },
    { id: 'Text', icon: 'chat' },
    { id: 'Event', icon: 'event' },
    { id: 'Other', icon: 'note' },
  ];

  return (
    <div className="screen">
      {/* Top */}
      <div style={{ position: 'absolute', top: 50, left: 0, right: 0, padding: '14px 18px',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center', zIndex: 5 }}>
        <button onClick={onClose} style={{
          appearance: 'none', border: 'none', background: 'transparent',
          color: 'var(--muted)', fontSize: 15, fontWeight: 500, cursor: 'pointer',
        }}>Cancel</button>
        <div style={{ fontWeight: 600, fontSize: 15 }}>New note</div>
        <button onClick={() => setMode('facts')} style={{
          appearance: 'none', border: 'none',
          background: text || transcript ? 'var(--accent)' : 'var(--hairline)',
          color: text || transcript ? '#fff' : 'var(--muted)',
          fontSize: 14, fontWeight: 600, padding: '7px 14px', borderRadius: 999,
          cursor: text || transcript ? 'pointer' : 'default',
        }}>Save</button>
      </div>

      <div style={{ position: 'absolute', top: 100, left: 0, right: 0, bottom: 0, padding: '0 22px' }}>
        {/* Person header */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, paddingBottom: 16,
          borderBottom: '1px solid var(--hairline)' }}>
          <window.Avatar person={p} size={40} />
          <div style={{ fontWeight: 600, fontSize: 16 }}>For {p.name}</div>
          <div style={{ marginLeft: 'auto', fontSize: 13, color: 'var(--accent)', fontWeight: 600 }}>Change</div>
        </div>

        {mode === 'compose' && (
          <>
            <div className="scroll-hide" style={{ display: 'flex', gap: 8, overflowX: 'auto', margin: '14px -22px', padding: '0 22px' }}>
              {types.map((t) => (
                <button key={t.id} onClick={() => setType(t.id)} style={{
                  appearance: 'none', border: 'none', cursor: 'pointer',
                  display: 'inline-flex', alignItems: 'center', gap: 6,
                  padding: '8px 14px', borderRadius: 999,
                  background: type === t.id ? 'var(--ink)' : 'var(--chip-bg)',
                  color: type === t.id ? 'var(--bg)' : 'var(--ink)',
                  fontWeight: 500, fontSize: 13.5, flexShrink: 0,
                }}>
                  <window.Icon name={t.icon} size={14} stroke={2} />
                  {t.id}
                </button>
              ))}
            </div>

            <textarea
              value={text}
              onChange={(e) => setText(e.target.value)}
              placeholder={`What did you and ${p.name.split(' ')[0]} talk about?`}
              style={{
                width: '100%', minHeight: 220,
                appearance: 'none', border: 'none', outline: 'none',
                background: 'transparent', resize: 'none',
                fontSize: 16, lineHeight: 1.5, color: 'var(--ink)',
                fontFamily: 'inherit', padding: 0,
              }}
            />

            {/* Mic */}
            <div style={{ position: 'absolute', bottom: 30, left: 0, right: 0,
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
              <button onClick={() => { setMode('recording'); setTranscript(''); }} style={{
                appearance: 'none', border: 'none', cursor: 'pointer',
                width: 64, height: 64, borderRadius: '50%',
                background: 'var(--accent)', color: '#fff',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: '0 6px 20px oklch(0.66 0.13 40 / 0.4)',
              }}>
                <window.Icon name="mic" size={26} stroke={2} />
              </button>
              <div style={{ fontSize: 12.5, color: 'var(--muted)' }}>Hold to talk · or tap</div>
            </div>
          </>
        )}

        {mode === 'recording' && (
          <div style={{ position: 'absolute', top: 100, left: 22, right: 22, bottom: 30,
            display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'space-between' }}>
            <Waveform />
            <div style={{ flex: 1, padding: '20px 0', overflow: 'auto', alignSelf: 'stretch' }}>
              <div style={{ fontSize: 11, fontWeight: 600, color: 'var(--accent)',
                textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 10 }}>
                Listening…
              </div>
              <p style={{ fontSize: 17, lineHeight: 1.5, color: 'var(--ink)', margin: 0, textWrap: 'pretty' }}>
                {transcript || <span style={{ color: 'var(--muted)' }}>Start talking…</span>}
              </p>
            </div>
            <button onClick={() => setMode('facts')} style={{
              appearance: 'none', border: 'none', cursor: 'pointer',
              background: 'var(--ink)', color: 'var(--bg)',
              padding: '14px 32px', borderRadius: 999,
              fontSize: 15, fontWeight: 600,
              display: 'flex', alignItems: 'center', gap: 8,
            }}>
              <window.Icon name="check" size={18} stroke={2.2} /> Done
            </button>
          </div>
        )}

        {mode === 'facts' && (
          <div style={{ paddingTop: 24 }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: 'var(--accent)',
              textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8,
              display: 'flex', alignItems: 'center', gap: 5 }}>
              <window.Icon name="sparkle" size={11} stroke={2} /> We found 2 new facts
            </div>
            <p style={{ fontSize: 14.5, color: 'var(--ink-soft)', lineHeight: 1.5, margin: '0 0 18px' }}>
              Tap to confirm and add to {p.name.split(' ')[0]}’s profile.
            </p>
            {[`Tokyo trip in June`, `Adopting a dog`].map((f, i) => (
              <div key={f} style={{
                background: 'var(--card)', borderRadius: 14, padding: '12px 14px',
                marginBottom: 10, display: 'flex', alignItems: 'center', gap: 10,
                boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 6px 22px rgba(60,40,20,0.04)',
              }}>
                <div style={{ width: 22, height: 22, borderRadius: '50%',
                  background: 'var(--accent)', color: '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <window.Icon name="check" size={13} stroke={2.4} />
                </div>
                <div style={{ flex: 1, fontSize: 14.5, fontWeight: 500 }}>{f}</div>
                <button style={{
                  appearance: 'none', border: 'none', background: 'transparent',
                  color: 'var(--muted)', fontSize: 13, cursor: 'pointer',
                }}>Skip</button>
              </div>
            ))}
            <button onClick={onSaved} style={{
              appearance: 'none', border: 'none', cursor: 'pointer',
              background: 'var(--ink)', color: 'var(--bg)',
              width: '100%', padding: 14, borderRadius: 16,
              fontSize: 15, fontWeight: 600, marginTop: 12,
            }}>
              Save note
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

const Waveform = () => {
  const [t, setT] = React.useState(0);
  React.useEffect(() => {
    let raf;
    const tick = () => { setT((x) => x + 0.1); raf = requestAnimationFrame(tick); };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, []);
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 4, height: 90, paddingTop: 30 }}>
      {Array.from({ length: 28 }).map((_, i) => {
        const h = 14 + Math.abs(Math.sin(t + i * 0.45)) * 50 + Math.abs(Math.sin(t * 1.7 + i * 0.2)) * 18;
        return <div key={i} style={{
          width: 4, height: h, borderRadius: 4,
          background: `oklch(${0.66 - i * 0.005} 0.13 40)`,
          transition: 'height 80ms',
        }} />;
      })}
    </div>
  );
};

// ── Search ──────────────────────────────────────────────────────────────
const SearchScreen = ({ onOpenPerson, onBack }) => {
  const [q, setQ] = React.useState('triathlon');

  const peopleHits = window.PEOPLE.filter((p) =>
    p.name.toLowerCase().includes(q.toLowerCase()) ||
    p.keyFacts.some((f) => f.toLowerCase().includes(q.toLowerCase()))
  );
  const noteHits = window.PEOPLE.flatMap((p) => p.notes
    .filter((n) => n.text.toLowerCase().includes(q.toLowerCase()))
    .map((n) => ({ person: p, note: n })));
  const factHits = window.PEOPLE.flatMap((p) => p.keyFacts
    .filter((f) => f.toLowerCase().includes(q.toLowerCase()))
    .map((f) => ({ person: p, fact: f })));

  const highlight = (text) => {
    if (!q) return text;
    const re = new RegExp(`(${q})`, 'ig');
    const parts = text.split(re);
    return parts.map((part, i) =>
      part.toLowerCase() === q.toLowerCase()
        ? <mark key={i} style={{ background: 'var(--accent-soft)', color: 'var(--accent-deep)', padding: '0 2px', borderRadius: 3 }}>{part}</mark>
        : part
    );
  };

  return (
    <div className="screen">
      <div className="scroll-area scroll-hide" style={{ paddingTop: 60, paddingBottom: 100, padding: '60px 22px 100px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 18 }}>
          <button onClick={onBack} style={{
            appearance: 'none', border: 'none', background: 'transparent',
            cursor: 'pointer', padding: 0, color: 'var(--ink)',
          }}>
            <window.Icon name="back" size={22} stroke={1.8} />
          </button>
          <div style={{
            flex: 1, background: 'var(--chip-bg)', borderRadius: 14,
            display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px',
          }}>
            <window.Icon name="search" size={16} color="var(--muted)" stroke={2} />
            <input
              autoFocus value={q} onChange={(e) => setQ(e.target.value)}
              style={{ flex: 1, border: 'none', outline: 'none', background: 'transparent', fontSize: 15, color: 'var(--ink)', fontFamily: 'inherit' }}
            />
            {q && <button onClick={() => setQ('')} style={{ appearance: 'none', border: 'none', background: 'transparent', cursor: 'pointer', color: 'var(--muted)' }}><window.Icon name="close" size={16} stroke={2} /></button>}
          </div>
        </div>

        {peopleHits.length > 0 && <>
          <window.SectionHeader title={`People (${peopleHits.length})`} />
          <window.Card padded={false} style={{ marginBottom: 22 }}>
            {peopleHits.map((p, i) => (
              <div key={p.id} onClick={() => onOpenPerson(p.id)} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px',
                borderBottom: i < peopleHits.length - 1 ? '1px solid var(--hairline)' : 'none',
                cursor: 'pointer',
              }}>
                <window.Avatar person={p} size={40} />
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600, fontSize: 15 }}>{highlight(p.name)}</div>
                  <div style={{ fontSize: 12.5, color: 'var(--muted)' }}>{p.relation}</div>
                </div>
                <window.Icon name="chevron" size={16} color="var(--muted)" />
              </div>
            ))}
          </window.Card>
        </>}

        {noteHits.length > 0 && <>
          <window.SectionHeader title={`Notes (${noteHits.length})`} />
          <div style={{ marginBottom: 22 }}>
            {noteHits.map(({ person, note }) => (
              <div key={person.id + note.id} onClick={() => onOpenPerson(person.id)}
                style={{ background: 'var(--card)', borderRadius: 16, padding: 14, marginBottom: 8, cursor: 'pointer',
                  boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 6px 22px rgba(60,40,20,0.04)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                  <window.Avatar person={person} size={22} />
                  <span style={{ fontWeight: 600, fontSize: 13 }}>{person.name}</span>
                  <span style={{ color: 'var(--muted)', fontSize: 12 }}>· {note.date}</span>
                </div>
                <div style={{ fontSize: 13.5, color: 'var(--ink-soft)', lineHeight: 1.45 }}>
                  …{highlight(note.text.slice(Math.max(0, note.text.toLowerCase().indexOf(q.toLowerCase()) - 30), note.text.toLowerCase().indexOf(q.toLowerCase()) + 90))}…
                </div>
              </div>
            ))}
          </div>
        </>}

        {factHits.length > 0 && <>
          <window.SectionHeader title={`Key facts (${factHits.length})`} />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {factHits.map(({ person, fact }, i) => (
              <div key={i} onClick={() => onOpenPerson(person.id)} style={{
                background: 'var(--card)', borderRadius: 14, padding: '10px 14px',
                display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer',
                boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 6px 22px rgba(60,40,20,0.04)',
              }}>
                <window.Avatar person={person} size={28} />
                <div style={{ fontSize: 13.5 }}>{highlight(fact)}</div>
                <span style={{ marginLeft: 'auto', fontSize: 12, color: 'var(--muted)' }}>{person.name.split(' ')[0]}</span>
              </div>
            ))}
          </div>
        </>}

        {peopleHits.length + noteHits.length + factHits.length === 0 && (
          <div style={{ textAlign: 'center', color: 'var(--muted)', padding: 40 }}>No matches.</div>
        )}
      </div>
    </div>
  );
};

// ── Onboarding (single screen — import contacts) ────────────────────────
const OnboardingScreen = ({ onFinish }) => {
  const contacts = [
    { name: 'Alex Rivera', subtitle: 'Birthday May 14', hue: 22 },
    { name: 'Priya Shah', subtitle: 'Birthday Aug 22', hue: 320 },
    { name: 'Mom', subtitle: '', hue: 12 },
    { name: 'Sam Okafor', subtitle: 'Birthday Nov 11', hue: 220 },
    { name: 'Jules Tan', subtitle: 'Birthday Oct 30', hue: 150 },
    { name: 'Theo Nguyen', subtitle: '', hue: 280 },
    { name: 'Eli Marsh', subtitle: '', hue: 50 },
    { name: 'Noor Hassan', subtitle: '', hue: 195 },
  ];
  const [picked, setPicked] = React.useState(new Set(['Alex Rivera', 'Priya Shah', 'Mom', 'Sam Okafor']));
  const toggle = (n) => {
    const s = new Set(picked);
    s.has(n) ? s.delete(n) : s.add(n);
    setPicked(s);
  };

  return (
    <div className="screen">
      <div style={{ position: 'absolute', top: 60, left: 0, right: 0, bottom: 0,
        display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '20px 24px 16px' }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--accent)',
            textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 10 }}>
            Step 3 of 4
          </div>
          <h1 style={{ margin: 0, fontSize: 28, fontWeight: 700, letterSpacing: '-0.02em', textWrap: 'balance' }}>
            Start with people<br/>you already know
          </h1>
          <p style={{ margin: '10px 0 0', fontSize: 15, color: 'var(--ink-soft)', lineHeight: 1.45 }}>
            Pick a few from your contacts. We’ll bring over their name, photo, and birthday.
          </p>
        </div>

        <div style={{ flex: 1, overflow: 'auto', padding: '4px 16px 0' }} className="scroll-hide">
          {contacts.map((c) => {
            const on = picked.has(c.name);
            return (
              <div key={c.name} onClick={() => toggle(c.name)} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '11px 8px', cursor: 'pointer',
              }}>
                <window.Avatar person={{ name: c.name, avatarHue: c.hue }} size={42} />
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600, fontSize: 15 }}>{c.name}</div>
                  {c.subtitle && <div style={{ fontSize: 12.5, color: 'var(--muted)' }}>{c.subtitle}</div>}
                </div>
                <div style={{
                  width: 24, height: 24, borderRadius: '50%',
                  border: on ? 'none' : '1.5px solid var(--hairline)',
                  background: on ? 'var(--accent)' : 'transparent',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: '#fff',
                }}>
                  {on && <window.Icon name="check" size={14} stroke={2.5} />}
                </div>
              </div>
            );
          })}
        </div>

        <div style={{ padding: '16px 22px 30px',
          borderTop: '1px solid var(--hairline)', background: 'var(--bg)' }}>
          <button onClick={onFinish} style={{
            appearance: 'none', border: 'none', cursor: 'pointer',
            width: '100%', padding: 15, borderRadius: 16,
            background: 'var(--ink)', color: 'var(--bg)',
            fontSize: 15.5, fontWeight: 600,
          }}>
            Add {picked.size} {picked.size === 1 ? 'person' : 'people'}
          </button>
          <button onClick={onFinish} style={{
            appearance: 'none', border: 'none', cursor: 'pointer',
            width: '100%', padding: '12px 0 0',
            background: 'transparent', color: 'var(--muted)',
            fontSize: 14, fontWeight: 500,
          }}>
            Skip for now
          </button>
        </div>
      </div>
    </div>
  );
};

// ── Settings stub ───────────────────────────────────────────────────────
const SettingsScreen = ({ navTab, setNavTab, onAddNote }) => (
  <div className="screen">
    <div className="scroll-area scroll-hide" style={{ paddingTop: 60, paddingBottom: 120, padding: '60px 22px 120px' }}>
      <h1 style={{ margin: '12px 0 22px', fontSize: 28, fontWeight: 700, letterSpacing: '-0.02em' }}>Settings</h1>

      <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px',
        background: 'var(--card)', borderRadius: 18, marginBottom: 20,
        boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 6px 22px rgba(60,40,20,0.04)' }}>
        <div style={{
          width: 50, height: 50, borderRadius: '50%',
          background: 'linear-gradient(135deg, oklch(0.78 0.1 60), oklch(0.66 0.13 40))',
          color: '#fff', fontSize: 18, fontWeight: 600,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>U</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontWeight: 600, fontSize: 16 }}>Ubek Cherezov</div>
          <div style={{ fontSize: 13, color: 'var(--muted)' }}>ubek@example.com</div>
        </div>
      </div>

      {[
        { title: 'Reach-out cadence', items: [
          { label: 'Default frequency', detail: 'Every 3 weeks', icon: 'event' },
          { label: 'Quiet hours', detail: '9pm – 8am', icon: 'note' },
        ]},
        { title: 'Data', items: [
          { label: 'Imported contacts', detail: '8 people', icon: 'people' },
          { label: 'Use voice transcription', detail: 'On', icon: 'mic' },
          { label: 'Send notes to Claude for summaries', detail: 'On', icon: 'sparkle' },
        ]},
        { title: 'Notifications', items: [
          { label: 'Birthdays & dates', detail: '1 day before', icon: 'cake' },
          { label: 'Reach-out nudges', detail: 'On', icon: 'chat' },
          { label: 'Widget refresh', detail: 'Every hour', icon: 'home' },
        ]},
      ].map((g) => (
        <div key={g.title} style={{ marginBottom: 22 }}>
          <window.SectionHeader title={g.title} />
          <window.Card padded={false}>
            {g.items.map((it, i) => (
              <div key={it.label} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '13px 16px',
                borderBottom: i < g.items.length - 1 ? '1px solid var(--hairline)' : 'none',
              }}>
                <div style={{
                  width: 30, height: 30, borderRadius: 9,
                  background: 'var(--accent-soft)', color: 'var(--accent-deep)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <window.Icon name={it.icon} size={15} stroke={1.8} />
                </div>
                <div style={{ flex: 1, fontSize: 14.5, fontWeight: 500 }}>{it.label}</div>
                <div style={{ fontSize: 13, color: 'var(--muted)' }}>{it.detail}</div>
                <window.Icon name="chevron" size={15} color="var(--muted)" />
              </div>
            ))}
          </window.Card>
        </div>
      ))}
    </div>
    <window.TabBar active={navTab} onChange={setNavTab} onAdd={onAddNote} />
  </div>
);

// ── Widget ──────────────────────────────────────────────────────────────
const Widget = ({ size = 'medium' }) => {
  const dates = window.PEOPLE.filter((p) => p.upcoming).slice(0, 2);
  const nudge = { person: window.PEOPLE.find((p) => p.id === 'alex'), text: 'Ask how the triathlon went' };

  if (size === 'small') {
    const p = dates[0].person || window.PEOPLE[0];
    return (
      <div style={widgetWrap(160)}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <window.Icon name="cake" size={14} color="var(--accent)" stroke={1.8} />
          <span style={{ fontSize: 11, fontWeight: 600, color: 'var(--accent)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>In {dates[0].upcoming.daysAway} days</span>
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
          <window.Avatar person={dates[0]} size={36} />
          <div style={{ fontWeight: 600, fontSize: 17, marginTop: 8, lineHeight: 1.15 }}>{dates[0].name}</div>
          <div style={{ fontSize: 12, color: 'var(--muted)' }}>{dates[0].upcoming.label} · {dates[0].upcoming.date}</div>
        </div>
      </div>
    );
  }

  return (
    <div style={widgetWrap(338, 160)}>
      <div style={{ display: 'flex', height: '100%', gap: 14 }}>
        <div style={{ flex: 1, borderRight: '1px solid var(--hairline)', paddingRight: 14, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div style={{ fontSize: 10.5, fontWeight: 600, color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.07em' }}>Upcoming</div>
          {dates.map((d) => (
            <div key={d.id} style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <window.Avatar person={d} size={28} />
              <div style={{ minWidth: 0 }}>
                <div style={{ fontWeight: 600, fontSize: 12.5, lineHeight: 1.2 }}>{d.name.split(' ')[0]}</div>
                <div style={{ fontSize: 10.5, color: 'var(--muted)' }}>{d.upcoming.label} · {d.upcoming.daysAway}d</div>
              </div>
            </div>
          ))}
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div style={{ fontSize: 10.5, fontWeight: 600, color: 'var(--accent)', textTransform: 'uppercase', letterSpacing: '0.07em' }}>Reach out</div>
          <div>
            <window.Avatar person={nudge.person} size={28} />
            <div style={{ fontWeight: 600, fontSize: 12.5, marginTop: 6 }}>{nudge.person.name.split(' ')[0]}</div>
            <div style={{ fontSize: 11, color: 'var(--ink-soft)', lineHeight: 1.3, marginTop: 2 }}>{nudge.text}</div>
          </div>
        </div>
      </div>
    </div>
  );
};

const widgetWrap = (w, h = w) => ({
  width: w, height: h, borderRadius: 22, padding: 14,
  background: 'var(--card)',
  boxShadow: '0 6px 22px rgba(60,40,20,0.08), 0 1px 2px rgba(60,40,20,0.05)',
  display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
});

Object.assign(window, { AddNoteSheet, SearchScreen, OnboardingScreen, SettingsScreen, Widget });
