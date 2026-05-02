import SwiftUI

@MainActor
struct StoriesView: View {
    @State private var viewModel = StoriesViewModel()
    @State private var showingAdd = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !viewModel.hasLoaded {
                    loadingState
                } else {
                    header
                    if !viewModel.selfFacts.isEmpty {
                        selfFactsSection
                    }
                    storiesSection
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 140)
        }
        .scrollIndicators(.hidden)
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .friendStoryChanged)) { _ in
            Task { await viewModel.load() }
        }
        .sheet(isPresented: $showingAdd) {
            AddStoryView()
        }
    }

    // ─── Header ────────────────────────────────────────────────────────────
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("STORIES")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.88)
                .foregroundStyle(Color.muted)
            Text("What's new with you")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 22)
    }

    // ─── About-you facts ──────────────────────────────────────────────────
    private var selfFactsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ABOUT YOU RIGHT NOW")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.88)
                .foregroundStyle(Color.accent)
                .padding(.horizontal, 22)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(viewModel.selfFacts.prefix(8))) { fact in
                        Menu {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteFact(fact) }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        } label: {
                            Text(fact.text)
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundStyle(Color.ink)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.chipBg))
                        }
                    }
                }
                .padding(.horizontal, 22)
            }
        }
    }

    // ─── Stories list ─────────────────────────────────────────────────────
    @ViewBuilder
    private var storiesSection: some View {
        let visible = viewModel.showArchived ? viewModel.archivedStories : viewModel.activeStories
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.showArchived ? "ARCHIVED" : "ACTIVE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.88)
                    .foregroundStyle(Color.muted)
                Spacer()
                Button {
                    viewModel.showArchived.toggle()
                } label: {
                    Text(viewModel.showArchived ? "Show active" : "Show archived")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Color.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)

            if visible.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(visible) { story in
                        StoryCardView(story: story)
                            .padding(.horizontal, 22)
                            .contextMenu {
                                if story.archivedAt == nil {
                                    Button {
                                        Task { await viewModel.archive(story) }
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                } else {
                                    Button {
                                        Task { await viewModel.unarchive(story) }
                                    } label: {
                                        Label("Unarchive", systemImage: "tray.and.arrow.up")
                                    }
                                }
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(story) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    // ─── Empty + loading ──────────────────────────────────────────────────
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: viewModel.showArchived ? "archivebox" : "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(Color.muted)
            Text(viewModel.showArchived ? "No archived stories" : "No stories yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.ink)
            Text(viewModel.showArchived
                 ? "Stories you archive will live here."
                 : "Jot something down — a story you want to remember to tell, a small win, a funny moment.")
                .font(.system(size: 14))
                .foregroundStyle(Color.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if !viewModel.showArchived {
                Button { showingAdd = true } label: {
                    Text("New story")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appBackground)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.accent))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var loadingState: some View {
        ProgressView()
            .tint(Color.muted)
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
    }
}
