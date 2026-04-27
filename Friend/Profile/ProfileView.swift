import SwiftUI

@MainActor
struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    var onAddNote: (Person) -> Void

    enum Tab: String, CaseIterable {
        case overview = "Overview"
        case notes = "Notes"
        case reminders = "Reminders"
        case gifts = "Gifts"
        case dates = "Dates"
    }
    @State private var tab: Tab
    @State private var showingAddGift = false
    @State private var showingAddDate = false
    @State private var showingAddReminder = false
    @State private var showingEdit = false
    @State private var profileDefaultFrequency: Int = 21

    init(personId: UUID, initialTab: Tab = .overview, onAddNote: @escaping (Person) -> Void) {
        _viewModel = State(initialValue: ProfileViewModel(personId: personId))
        _tab = State(initialValue: initialTab)
        self.onAddNote = onAddNote
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if let person = viewModel.person {
                ScrollView {
                    VStack(spacing: 0) {
                        header(person: person)
                        tabBar
                        tabContent(person: person)
                            .padding(.horizontal, 22)
                            .padding(.top, 18)
                            .padding(.bottom, 60)
                            // Horizontal swipe to advance between tabs.
                            // simultaneousGesture lets the parent ScrollView
                            // keep handling vertical scroll without conflict.
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 30)
                                    .onEnded { value in
                                        let h = value.translation.width
                                        let v = value.translation.height
                                        // Only act when the swipe is dominantly horizontal.
                                        guard abs(h) > abs(v) * 1.5 else { return }
                                        if h < -50 { advanceTab(by: 1) }
                                        else if h > 50 { advanceTab(by: -1) }
                                    }
                            )
                    }
                }
                .scrollIndicators(.hidden)
            } else if viewModel.isLoading {
                ProgressView().tint(Color.muted)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { backButton }
            ToolbarItem(placement: .topBarTrailing) { editButton }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .friendNoteSaved)) { notif in
            // Refetch when a note for this person is saved from the AddNote sheet.
            if AppEvents.personId(from: notif) == viewModel.personId {
                Task { await viewModel.load() }
            }
        }
        .sheet(isPresented: $showingAddGift) {
            AddGiftSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddDate) {
            AddDateSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingEdit) {
            EditPersonSheet(
                viewModel: viewModel,
                profileDefaultFrequency: profileDefaultFrequency
            ) {
                // Person was deleted — pop back so we don't sit on a stale profile.
                dismiss()
            }
        }
        .task {
            // Pick up the account-level default once so the edit sheet's
            // override picker can show "Use default (21d)".
            if let p = try? await SupabaseService.shared.fetchProfile() {
                profileDefaultFrequency = p.defaultContactFrequencyDays
            }
        }
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.accent)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.card))
                .overlay(Circle().stroke(Color.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var editButton: some View {
        Button {
            showingEdit = true
        } label: {
            Text("Edit")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.card))
                .overlay(Capsule().stroke(Color.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("profile_edit")
    }

    // ─── Header ────────────────────────────────────────────────────────────
    private func header(person: Person) -> some View {
        let freq = 21 // Phase 8 swaps in actual profile default
        let healthState = person.healthState(profileDefault: freq)
        return VStack(spacing: 0) {
            AvatarView(person: person, size: 92)
                .padding(.top, 22)
            Text(person.name)
                .font(.system(size: 26, weight: .bold))
                .tracking(-0.52)
                .padding(.top, 14)
            HStack(spacing: 6) {
                HealthDotView(state: healthState, size: 7)
                Text("\(person.relation) · \(lastInteractionLabel(person.daysSinceLastInteraction()))")
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.muted)
            }
            .padding(.top, 4)

            HStack(spacing: 10) {
                quickActionButton(label: "Add note", icon: "doc.text", primary: true) {
                    onAddNote(person)
                }
                quickActionButton(label: "Add date", icon: "calendar", primary: false) {
                    showingAddDate = true
                }
                quickActionButton(label: "Gift", icon: "gift", primary: false) {
                    showingAddGift = true
                }
            }
            .padding(.top, 18)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 18)
    }

    @ViewBuilder
    private func quickActionButton(label: String, icon: String, primary: Bool, action: @escaping () -> Void) -> some View {
        let labelView = HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold))
            Text(label)
        }
        if primary {
            Button(action: action) { labelView }
                .buttonStyle(AccentPrimaryButton())
        } else {
            Button(action: action) { labelView }
                .buttonStyle(AccentSecondaryButton())
        }
    }

    // ─── Tab bar ───────────────────────────────────────────────────────────
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 22) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Button { tab = t } label: {
                        Text(t.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(tab == t ? Color.ink : Color.muted)
                            .padding(.vertical, 10)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(tab == t ? Color.accent : .clear)
                                    .frame(height: 2)
                                    .offset(y: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 22)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.hairline).frame(height: 1)
        }
    }

    /// Advance the tab by `delta` (e.g. +1 = next, -1 = previous), clamped
    /// to the valid range so swiping at the ends doesn't wrap.
    private func advanceTab(by delta: Int) {
        let cases = Tab.allCases
        guard let i = cases.firstIndex(of: tab) else { return }
        let next = max(0, min(cases.count - 1, i + delta))
        guard next != i else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            tab = cases[next]
        }
    }

    // ─── Tab content ───────────────────────────────────────────────────────
    @ViewBuilder
    private func tabContent(person: Person) -> some View {
        switch tab {
        case .overview:
            OverviewTabView(viewModel: viewModel)
        case .notes:
            NotesTabView(viewModel: viewModel, onAddNote: { onAddNote(person) })
        case .reminders:
            RemindersTabView(viewModel: viewModel, onAdd: { showingAddReminder = true })
        case .gifts:
            GiftsTabView(viewModel: viewModel, onAdd: { showingAddGift = true })
        case .dates:
            DatesTabView(viewModel: viewModel, onAdd: { showingAddDate = true })
        }
    }
}
