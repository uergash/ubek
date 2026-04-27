// Main app — wires screens together inside the design canvas

const App = () => {
  // Each iOS frame is independent — each gets its own router state
  return (
    <DesignCanvas>
      <DCSection id="onboarding" title="Onboarding" subtitle="Sign-up & contacts import">
        <DCArtboard id="onb-welcome" label="Welcome" width={402} height={874}>
          <IOSDevice><WelcomeScreen /></IOSDevice>
        </DCArtboard>
        <DCArtboard id="onb-signup" label="Account" width={402} height={874}>
          <IOSDevice keyboard><SignUpScreen /></IOSDevice>
        </DCArtboard>
        <DCArtboard id="onb-contacts" label="Import contacts" width={402} height={874}>
          <IOSDevice><OnboardingScreen onFinish={() => {}} /></IOSDevice>
        </DCArtboard>
        <DCArtboard id="onb-notif" label="Notifications" width={402} height={874}>
          <IOSDevice><NotificationsScreen /></IOSDevice>
        </DCArtboard>
      </DCSection>

      <DCSection id="home" title="Home" subtitle="Greeting, upcoming, nudges, people list">
        <DCArtboard id="home-main" label="Home — interactive" width={402} height={874}>
          <IOSDevice><PrototypeRoot start="home" /></IOSDevice>
        </DCArtboard>
        <DCArtboard id="home-filter" label="Filter — Family" width={402} height={874}>
          <IOSDevice><HomeStatic filter="Family" /></IOSDevice>
        </DCArtboard>
      </DCSection>

      <DCSection id="profile" title="Person profile" subtitle="Overview · Notes · Gifts · Dates">
        <DCArtboard id="profile-overview" label="Overview" width={402} height={874}>
          <IOSDevice><ProfileScreen personId="alex" onBack={() => {}} onAddNote={() => {}} /></IOSDevice>
        </DCArtboard>
        <DCArtboard id="profile-notes" label="Notes" width={402} height={874}>
          <IOSDevice><ProfileWithTab personId="alex" tab="Notes" /></IOSDevice>
        </DCArtboard>
        <DCArtboard id="profile-gifts" label="Gifts" width={402} height={874}>
          <IOSDevice><ProfileWithTab personId="alex" tab="Gifts" /></IOSDevice>
        </DCArtboard>
        <DCArtboard id="profile-dates" label="Dates" width={402} height={874}>
          <IOSDevice><ProfileWithTab personId="alex" tab="Dates" /></IOSDevice>
        </DCArtboard>
      </DCSection>

      <DCSection id="capture" title="Add note" subtitle="Compose · voice capture · AI fact extraction">
        <DCArtboard id="capture-compose" label="Compose" width={402} height={874}>
          <IOSDevice keyboard={false}><AddNoteSheet personId="alex" onClose={() => {}} onSaved={() => {}} /></IOSDevice>
        </DCArtboard>
        <DCArtboard id="capture-voice" label="Voice capture" width={402} height={874}>
          <IOSDevice><AddNoteForceMode mode="recording" /></IOSDevice>
        </DCArtboard>
        <DCArtboard id="capture-facts" label="AI extraction" width={402} height={874}>
          <IOSDevice><AddNoteForceMode mode="facts" /></IOSDevice>
        </DCArtboard>
      </DCSection>

      <DCSection id="search" title="Search" subtitle="People · Notes · Key facts">
        <DCArtboard id="search-main" label="Results" width={402} height={874}>
          <IOSDevice><SearchScreen onOpenPerson={() => {}} onBack={() => {}} /></IOSDevice>
        </DCArtboard>
      </DCSection>

      <DCSection id="settings" title="Settings" subtitle="Cadence, data, notifications">
        <DCArtboard id="settings-main" label="Settings" width={402} height={874}>
          <IOSDevice><SettingsScreen navTab="settings" setNavTab={() => {}} onAddNote={() => {}} /></IOSDevice>
        </DCArtboard>
      </DCSection>

      <DCSection id="widget" title="Home screen widget" subtitle="iOS WidgetKit">
        <DCArtboard id="widget-medium" label="Medium" width={402} height={220}>
          <div style={{ width: '100%', height: '100%', background: 'oklch(0.92 0.02 70)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 24 }}>
            <Widget size="medium" />
          </div>
        </DCArtboard>
        <DCArtboard id="widget-small" label="Small" width={220} height={220}>
          <div style={{ width: '100%', height: '100%', background: 'oklch(0.92 0.02 70)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 24 }}>
            <Widget size="small" />
          </div>
        </DCArtboard>
      </DCSection>

      <DCSection id="prototype" title="Full prototype" subtitle="Live: tap nudge → profile → add note → AI extract">
        <DCArtboard id="proto-live" label="Live prototype" width={402} height={874}>
          <IOSDevice><PrototypeRoot start="home" /></IOSDevice>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
};

// ── Welcome / Signup / Notifications ────────────────────────────────────
const WelcomeScreen = () => (
  <div className="screen" style={{ display: 'flex', flexDirection: 'column' }}>
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', padding: 32 }}>
      <div style={{
        width: 88, height: 88, borderRadius: 28, marginBottom: 28,
        background: 'linear-gradient(135deg, oklch(0.78 0.1 60), oklch(0.62 0.14 35))',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 12px 32px oklch(0.66 0.13 40 / 0.35)',
      }}>
        <svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
          <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
        </svg>
      </div>
      <h1 style={{ margin: 0, fontSize: 36, fontWeight: 700, letterSpacing: '-0.025em', textAlign: 'center', textWrap: 'balance' }}>Friend</h1>
      <p style={{ fontSize: 16, color: 'var(--ink-soft)', textAlign: 'center', lineHeight: 1.45, margin: '14px 0 0', maxWidth: 280, textWrap: 'pretty' }}>
        Remember what matters to the people you love.
      </p>
    </div>
    <div style={{ padding: '0 24px 36px' }}>
      <button style={{
        appearance: 'none', border: 'none', cursor: 'pointer',
        width: '100%', padding: 16, borderRadius: 16,
        background: 'var(--ink)', color: 'var(--bg)',
        fontSize: 16, fontWeight: 600,
      }}>Get started</button>
      <button style={{
        appearance: 'none', border: 'none', cursor: 'pointer',
        width: '100%', padding: '14px 0 0',
        background: 'transparent', color: 'var(--muted)',
        fontSize: 14, fontWeight: 500,
      }}>I have an account</button>
    </div>
  </div>
);

const SignUpScreen = () => (
  <div className="screen">
    <div style={{ position: 'absolute', top: 50, left: 0, right: 0, padding: '14px 18px' }}>
      <button style={{ appearance: 'none', border: 'none', background: 'transparent', cursor: 'pointer', padding: 0, color: 'var(--ink)' }}>
        <Icon name="back" size={22} stroke={1.8} />
      </button>
    </div>
    <div style={{ position: 'absolute', top: 110, left: 24, right: 24 }}>
      <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--accent)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 10 }}>Step 2 of 4</div>
      <h1 style={{ margin: 0, fontSize: 28, fontWeight: 700, letterSpacing: '-0.02em' }}>Create your account</h1>
      <p style={{ margin: '10px 0 28px', fontSize: 15, color: 'var(--ink-soft)' }}>So your people and notes follow you everywhere.</p>

      {[
        { label: 'Name', value: 'Ubek Cherezov' },
        { label: 'Email', value: 'ubek@example.com' },
        { label: 'Password', value: '••••••••••' },
      ].map((f) => (
        <div key={f.label} style={{ marginBottom: 14 }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--muted)', marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.06em' }}>{f.label}</div>
          <div style={{ background: 'var(--card)', borderRadius: 14, padding: '13px 14px', fontSize: 15.5,
            boxShadow: '0 1px 2px rgba(60,40,20,0.04)' }}>{f.value}</div>
        </div>
      ))}

      <button style={{
        appearance: 'none', border: 'none', cursor: 'pointer',
        width: '100%', padding: 15, borderRadius: 16,
        background: 'var(--ink)', color: 'var(--bg)',
        fontSize: 15.5, fontWeight: 600, marginTop: 14,
      }}>Continue</button>
    </div>
  </div>
);

const NotificationsScreen = () => (
  <div className="screen">
    <div style={{ position: 'absolute', top: 60, left: 0, right: 0, bottom: 0, display: 'flex', flexDirection: 'column' }}>
      <div style={{ flex: 1, padding: '50px 28px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
        <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--accent)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 12 }}>Step 4 of 4</div>
        <h1 style={{ margin: 0, fontSize: 28, fontWeight: 700, letterSpacing: '-0.02em', textWrap: 'balance' }}>We’ll nudge you<br/>at the right moments</h1>
        <p style={{ margin: '12px 0 22px', fontSize: 15, color: 'var(--ink-soft)', lineHeight: 1.5, textWrap: 'pretty' }}>
          A reminder a day before your sister’s birthday. A heads-up when it’s been three weeks since you’ve heard from a close friend. Nothing more.
        </p>

        {[
          { icon: 'cake', title: 'Birthdays & important dates', detail: 'A day in advance, with what to say' },
          { icon: 'chat', title: 'Reach-out nudges', detail: 'When it’s been too long' },
          { icon: 'sparkle', title: 'Annual recaps', detail: 'A year of memories before each birthday' },
        ].map((it) => (
          <div key={it.title} style={{ display: 'flex', alignItems: 'flex-start', gap: 13, padding: '12px 0' }}>
            <div style={{
              width: 38, height: 38, borderRadius: 11,
              background: 'var(--accent-soft)', color: 'var(--accent-deep)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>
              <Icon name={it.icon} size={18} stroke={1.7} />
            </div>
            <div>
              <div style={{ fontWeight: 600, fontSize: 15 }}>{it.title}</div>
              <div style={{ fontSize: 13.5, color: 'var(--muted)', marginTop: 2 }}>{it.detail}</div>
            </div>
          </div>
        ))}
      </div>

      <div style={{ padding: '12px 22px 32px' }}>
        <button style={{
          appearance: 'none', border: 'none', cursor: 'pointer',
          width: '100%', padding: 15, borderRadius: 16,
          background: 'var(--ink)', color: 'var(--bg)',
          fontSize: 15.5, fontWeight: 600,
        }}>Turn on notifications</button>
        <button style={{
          appearance: 'none', border: 'none', cursor: 'pointer',
          width: '100%', padding: '12px 0 0',
          background: 'transparent', color: 'var(--muted)',
          fontSize: 14, fontWeight: 500,
        }}>Maybe later</button>
      </div>
    </div>
  </div>
);

// ── Helpers for static artboards ────────────────────────────────────────
const HomeStatic = ({ filter = 'All' }) => {
  // simplified — show home with filter pre-set
  return <HomeScreen onOpenPerson={() => {}} onAddNote={() => {}} navTab="home" setNavTab={() => {}} />;
};

const ProfileWithTab = ({ personId, tab }) => (
  <ProfileScreen personId={personId} onBack={() => {}} onAddNote={() => {}} initialTab={tab} />
);

const AddNoteForceMode = ({ mode }) => {
  // Render AddNoteSheet but kick into the requested mode after mount
  const [key, setKey] = React.useState(0);
  React.useEffect(() => { setKey(1); }, []);
  return <AddNoteSheetForced mode={mode} key={key} />;
};

const AddNoteSheetForced = ({ mode }) => {
  // Mostly mirrors AddNoteSheet but with mode locked
  const p = window.PEOPLE[0];
  if (mode === 'recording') {
    return (
      <div className="screen">
        <div style={{ position: 'absolute', top: 50, left: 0, right: 0, padding: '14px 18px',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <button style={{ appearance: 'none', border: 'none', background: 'transparent', color: 'var(--muted)', fontSize: 15 }}>Cancel</button>
          <div style={{ fontWeight: 600, fontSize: 15 }}>New note</div>
          <div style={{ width: 50 }} />
        </div>
        <div style={{ position: 'absolute', top: 100, left: 22, right: 22, bottom: 30,
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, alignSelf: 'flex-start',
            paddingBottom: 16, width: '100%', borderBottom: '1px solid var(--hairline)' }}>
            <Avatar person={p} size={40} />
            <div style={{ fontWeight: 600, fontSize: 16 }}>For {p.name}</div>
          </div>
          <Waveform />
          <div style={{ flex: 1, padding: '20px 0', alignSelf: 'stretch' }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: 'var(--accent)',
              textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 10 }}>
              Listening…
            </div>
            <p style={{ fontSize: 17, lineHeight: 1.5, color: 'var(--ink)', margin: 0, textWrap: 'pretty' }}>
              Caught up with Alex at the new place on Valencia. He’s going to Tokyo in June for two weeks and is finally adopting a dog.
            </p>
          </div>
          <button style={{
            appearance: 'none', border: 'none', cursor: 'pointer',
            background: 'var(--ink)', color: 'var(--bg)',
            padding: '14px 32px', borderRadius: 999,
            fontSize: 15, fontWeight: 600,
            display: 'flex', alignItems: 'center', gap: 8,
          }}>
            <Icon name="check" size={18} stroke={2.2} /> Done
          </button>
        </div>
      </div>
    );
  }
  // facts
  return (
    <div className="screen">
      <div style={{ position: 'absolute', top: 50, left: 0, right: 0, padding: '14px 18px',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <button style={{ appearance: 'none', border: 'none', background: 'transparent', color: 'var(--muted)', fontSize: 15 }}>Cancel</button>
        <div style={{ fontWeight: 600, fontSize: 15 }}>New note</div>
        <button style={{ appearance: 'none', border: 'none', background: 'var(--accent)', color: '#fff',
          fontSize: 14, fontWeight: 600, padding: '7px 14px', borderRadius: 999 }}>Save</button>
      </div>
      <div style={{ position: 'absolute', top: 100, left: 22, right: 22, bottom: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, paddingBottom: 16,
          borderBottom: '1px solid var(--hairline)' }}>
          <Avatar person={p} size={40} />
          <div style={{ fontWeight: 600, fontSize: 16 }}>For {p.name}</div>
        </div>

        <div style={{ paddingTop: 18 }}>
          <div style={{
            background: 'var(--card-soft)', borderRadius: 14, padding: 14,
            fontSize: 14, lineHeight: 1.5, color: 'var(--ink-soft)', marginBottom: 22,
          }}>
            “Caught up with Alex at the new place on Valencia. He’s going to Tokyo in June for two weeks and is finally adopting a dog.”
          </div>

          <div style={{ fontSize: 11, fontWeight: 600, color: 'var(--accent)',
            textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8,
            display: 'flex', alignItems: 'center', gap: 5 }}>
            <Icon name="sparkle" size={11} stroke={2} /> We found 2 new facts
          </div>
          <p style={{ fontSize: 14.5, color: 'var(--ink-soft)', lineHeight: 1.5, margin: '0 0 18px' }}>
            Tap to confirm and add to {p.name.split(' ')[0]}’s profile.
          </p>
          {[`Tokyo trip in June`, `Adopting a dog`].map((f) => (
            <div key={f} style={{
              background: 'var(--card)', borderRadius: 14, padding: '12px 14px',
              marginBottom: 10, display: 'flex', alignItems: 'center', gap: 10,
              boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 6px 22px rgba(60,40,20,0.04)',
            }}>
              <div style={{ width: 22, height: 22, borderRadius: '50%',
                background: 'var(--accent)', color: '#fff',
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon name="check" size={13} stroke={2.4} />
              </div>
              <div style={{ flex: 1, fontSize: 14.5, fontWeight: 500 }}>{f}</div>
              <button style={{
                appearance: 'none', border: 'none', background: 'transparent',
                color: 'var(--muted)', fontSize: 13, cursor: 'pointer',
              }}>Skip</button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

// ── Live prototype root: navigates between Home / Profile / Note / Search / Settings
const PrototypeRoot = ({ start = 'home' }) => {
  const [route, setRoute] = React.useState({ name: start, personId: null });
  const [navTab, setNavTab] = React.useState('home');

  const open = (personId) => setRoute({ name: 'profile', personId });
  const addNoteFor = (personId = 'alex') => setRoute({ name: 'note', personId });
  const back = () => setRoute({ name: 'home', personId: null });

  React.useEffect(() => {
    if (navTab === 'home') setRoute({ name: 'home' });
    else if (navTab === 'search') setRoute({ name: 'search' });
    else if (navTab === 'people') setRoute({ name: 'home' });
    else if (navTab === 'settings') setRoute({ name: 'settings' });
  }, [navTab]);

  if (route.name === 'home')
    return <HomeScreen onOpenPerson={open} onAddNote={() => addNoteFor()} navTab={navTab} setNavTab={setNavTab} />;
  if (route.name === 'profile')
    return <ProfileScreen personId={route.personId} onBack={back} onAddNote={() => addNoteFor(route.personId)} />;
  if (route.name === 'note')
    return <AddNoteSheet personId={route.personId} onClose={back} onSaved={back} />;
  if (route.name === 'search')
    return <SearchScreen onOpenPerson={open} onBack={back} />;
  if (route.name === 'settings')
    return <SettingsScreen navTab={navTab} setNavTab={setNavTab} onAddNote={() => addNoteFor()} />;
  return null;
};

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
