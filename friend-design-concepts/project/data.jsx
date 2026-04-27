// Mock data + helpers shared across screens.

const PEOPLE = [
  {
    id: 'alex',
    name: 'Alex Rivera',
    relation: 'Friend',
    avatarHue: 22,
    lastDays: 21,
    frequency: 14, // desired contact frequency in days
    groups: ['College Friends'],
    keyFacts: [
      'Has a dog named Milo',
      'Training for a triathlon',
      'Works at Stripe',
      'Loves single-origin coffee',
      'Brother lives in Lisbon',
    ],
    upcoming: { kind: 'birthday', label: 'Birthday', date: 'May 14', daysAway: 20 },
    summary:
      'Last time you talked in March, Alex mentioned he was deep into triathlon training and that Milo had recovered from surgery. He’s been quietly thinking about leaving Stripe — feeling restless after four years.',
    notes: [
      { id: 'n1', date: 'Mar 28', type: 'Coffee', text: 'Caught up at Reveille. Milo is fully recovered after the knee surgery — Alex called it “the best $4k I’ve ever spent.” He’s six weeks out from the Oakland triathlon and still hasn’t fixed his bike fit.', facts: ['Milo recovered from surgery', 'Oakland triathlon in May'] },
      { id: 'n2', date: 'Mar 12', type: 'Call',  text: 'Quick call on his walk home. Mentioned his brother is moving back from Lisbon in the fall and they’re thinking about a road trip up the coast in October.', facts: ['Brother moving back from Lisbon'] },
      { id: 'n3', date: 'Feb 24', type: 'Text',  text: 'Sent him the new La Marzocco recommendation. He said he’d been eyeing the Linea Mini for a year.', facts: ['Wants Linea Mini espresso'] },
    ],
    gifts: {
      wishlist: [
        { id: 'g1', name: 'Linea Mini espresso machine', note: 'He’s been talking about it for over a year' },
        { id: 'g2', name: 'Bike fit session at Above Category', note: 'Mentioned his hips are stiff after long rides' },
      ],
      gifted: [
        { id: 'g3', name: 'Hario V60 + Origin beans', occasion: 'Birthday 2025', date: 'May 14, 2025', reaction: 'loved' },
      ],
    },
    dates: [
      { kind: 'birthday', label: 'Birthday', date: 'May 14', remind: true },
      { kind: 'anniversary', label: 'Started at Stripe', date: 'Sep 02', remind: false },
      { kind: 'custom', label: 'Oakland Triathlon', date: 'May 18', remind: true },
    ],
  },
  {
    id: 'priya',
    name: 'Priya Shah',
    relation: 'Family',
    avatarHue: 320,
    lastDays: 5,
    frequency: 10,
    groups: ['Family'],
    keyFacts: ['Twins turn 3 in June', 'Just moved to Berkeley', 'Reading more fiction lately'],
    upcoming: { kind: 'custom', label: 'Twins’ birthday', date: 'Jun 04', daysAway: 41 },
    summary: 'Priya and Devan just finished the move to Berkeley last weekend. The twins start preschool in August. She’s been reading more fiction — you sent her Orbital.',
    notes: [
      { id: 'n1', date: 'Apr 19', type: 'Call', text: 'Long Sunday call. House is mostly unpacked. The twins keep asking when Grandma is visiting.', facts: ['Moved to Berkeley'] },
      { id: 'n2', date: 'Apr 02', type: 'Text', text: 'Sent her Orbital. She said she’s reading more fiction lately to balance the day job.', facts: ['Reading more fiction'] },
    ],
    gifts: { wishlist: [{ id: 'g1', name: 'Twin balance bikes', note: 'For their June birthday' }], gifted: [] },
    dates: [
      { kind: 'birthday', label: 'Birthday', date: 'Aug 22', remind: true },
      { kind: 'custom', label: 'Twins’ birthday', date: 'Jun 04', remind: true },
    ],
  },
  {
    id: 'mom',
    name: 'Mom',
    relation: 'Family',
    avatarHue: 12,
    lastDays: 3,
    frequency: 7,
    groups: ['Family'],
    keyFacts: ['Garden is her happy place', 'New knee in January'],
    upcoming: { kind: 'birthday', label: 'Birthday', date: 'Jul 09', daysAway: 76 },
    summary: 'Knee is healing well — she walked to the farmers market on Saturday. The tomatoes are in.',
    notes: [{ id: 'n1', date: 'Apr 21', type: 'Call', text: 'Knee is at 95%. She walked to the market and back.', facts: [] }],
    gifts: { wishlist: [], gifted: [] },
    dates: [{ kind: 'birthday', label: 'Birthday', date: 'Jul 09', remind: true }],
  },
  {
    id: 'sam',
    name: 'Sam Okafor',
    relation: 'Friend',
    avatarHue: 220,
    lastDays: 38,
    frequency: 21,
    groups: ['College Friends'],
    keyFacts: ['Just got engaged to Dani', 'Wedding next April in Sintra', 'Deep into fermentation'],
    upcoming: { kind: 'custom', label: 'Engagement party', date: 'May 03', daysAway: 9 },
    summary: 'Sam proposed to Dani in Lisbon on St. Patrick’s. Engagement party May 3rd. He’s been making koji at home and threatening to bring you a jar.',
    notes: [{ id: 'n1', date: 'Mar 17', type: 'Text', text: 'PROPOSED. She said yes. They’re thinking Sintra in April 2027.', facts: ['Engaged to Dani', 'Wedding in Sintra'] }],
    gifts: { wishlist: [], gifted: [] },
    dates: [
      { kind: 'birthday', label: 'Birthday', date: 'Nov 11', remind: true },
      { kind: 'custom', label: 'Engagement party', date: 'May 03', remind: true },
    ],
  },
  {
    id: 'jules',
    name: 'Jules Tan',
    relation: 'Friend',
    avatarHue: 150,
    lastDays: 11,
    frequency: 14,
    groups: ['Climbing'],
    keyFacts: ['New climbing project at Bishop', 'Switched to PT full-time'],
    upcoming: null,
    summary: '',
    notes: [{ id: 'n1', date: 'Apr 13', type: 'Event', text: 'Climbed at Dogpatch. She’s working a V6 at Bishop next month.', facts: [] }],
    gifts: { wishlist: [], gifted: [] },
    dates: [{ kind: 'birthday', label: 'Birthday', date: 'Oct 30', remind: true }],
  },
  {
    id: 'theo',
    name: 'Theo Nguyen',
    relation: 'Colleague',
    avatarHue: 280,
    lastDays: 64,
    frequency: 30,
    groups: ['Work'],
    keyFacts: ['Left to start a company', 'Working on AI for nurses'],
    upcoming: null,
    summary: 'Theo left in February to start something in clinical AI. Last raise round was tough.',
    notes: [{ id: 'n1', date: 'Feb 19', type: 'Coffee', text: 'Last day at Notion. He’s starting something in clinical AI — wants nurses, not doctors.', facts: ['Left Notion to start a company'] }],
    gifts: { wishlist: [], gifted: [] },
    dates: [],
  },
  {
    id: 'eli',
    name: 'Eli Marsh',
    relation: 'Friend',
    avatarHue: 50,
    lastDays: 8,
    frequency: 21,
    groups: ['College Friends'],
    keyFacts: ['Daughter Mae just turned 1'],
    upcoming: null,
    summary: '',
    notes: [],
    gifts: { wishlist: [], gifted: [] },
    dates: [],
  },
  {
    id: 'noor',
    name: 'Noor Hassan',
    relation: 'Friend',
    avatarHue: 195,
    lastDays: 16,
    frequency: 21,
    groups: ['Climbing'],
    keyFacts: ['Doing a Whole30', 'Adopted a cat — Pepper'],
    upcoming: null,
    summary: '',
    notes: [],
    gifts: { wishlist: [], gifted: [] },
    dates: [],
  },
];

const NUDGES = [
  { personId: 'alex', text: 'Ask Alex how the Oakland triathlon went last Sunday.' },
  { personId: 'theo', text: 'Two months since you talked. Theo’s clinical AI thing — check in?' },
];

// ── helpers ────────────────────────────────────────────────────────────────
function healthFor(p) {
  const ratio = p.lastDays / p.frequency;
  if (ratio < 0.85) return 'green';
  if (ratio < 1.25) return 'yellow';
  return 'red';
}

function lastInteractionLabel(d) {
  if (d <= 1) return 'Yesterday';
  if (d < 7) return `${d} days ago`;
  if (d < 14) return '1 week ago';
  if (d < 28) return `${Math.round(d / 7)} weeks ago`;
  if (d < 60) return '1 month ago';
  return `${Math.round(d / 30)} months ago`;
}

function initials(name) {
  return name.split(' ').slice(0, 2).map((s) => s[0]).join('').toUpperCase();
}

function avatarBg(hue) {
  return `linear-gradient(135deg, oklch(0.86 0.07 ${hue}) 0%, oklch(0.74 0.11 ${(hue + 30) % 360}) 100%)`;
}

window.PEOPLE = PEOPLE;
window.NUDGES = NUDGES;
window.healthFor = healthFor;
window.lastInteractionLabel = lastInteractionLabel;
window.initials = initials;
window.avatarBg = avatarBg;
