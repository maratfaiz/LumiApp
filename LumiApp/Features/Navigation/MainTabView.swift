import SwiftData
import SwiftUI

enum LumiTab: Hashable {
    case catalog, home, profile
}

/// 3-tab navigation (F5): Курсы / Луми / Профиль, rendered with the
/// design's custom bar — the "Луми" tab is a raised gradient disc, the
/// visual anchor of the whole app, which a plain `TabView` can't express.
///
/// The bar lives *inside* each tab's `NavigationStack`, so it shows on the
/// three root screens only and disappears on pushed detail screens, exactly
/// as specified in the design.
struct MainTabView: View {
    @State private var selected: LumiTab = .home
    @Query private var progresses: [UserProgress]

    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 19
    @AppStorage("reminderMinute") private var reminderMinute = 0

    var body: some View {
        ZStack {
            LumiBackground()

            tab(.catalog) {
                NavigationStack {
                    CourseListView()
                        .safeAreaInset(edge: .bottom, spacing: 0) { LumiTabBar(selected: $selected) }
                }
            }
            tab(.home) {
                NavigationStack {
                    HomeView()
                        .safeAreaInset(edge: .bottom, spacing: 0) { LumiTabBar(selected: $selected) }
                }
            }
            tab(.profile) {
                NavigationStack {
                    ProfileView()
                        .safeAreaInset(edge: .bottom, spacing: 0) { LumiTabBar(selected: $selected) }
                }
            }
        }
        .onAppear {
            if let progress = progresses.first {
                StreakEngine.applyAutomaticFreezeIfDue(on: progress)
            }
            if remindersEnabled {
                NotificationScheduler.reschedule(
                    hour: reminderHour,
                    minute: reminderMinute,
                    lastActiveDate: progresses.first?.lastActiveDate
                )
            }
            WidgetSync.refresh()
        }
    }

    /// Keeps every tab alive (so each `NavigationStack` remembers where the
    /// user was) while only the selected one is visible and interactive.
    @ViewBuilder
    private func tab<Content: View>(_ value: LumiTab, @ViewBuilder content: () -> Content) -> some View {
        let isSelected = selected == value
        content()
            .opacity(isSelected ? 1 : 0)
            .allowsHitTesting(isSelected)
            .accessibilityHidden(!isSelected)
            .zIndex(isSelected ? 1 : 0)
    }
}

struct LumiTabBar: View {
    @Binding var selected: LumiTab

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            sideTab(icon: "icon-tab-courses", fallback: "book.fill", label: "Курсы", tab: .catalog)
                .frame(maxWidth: .infinity)

            homeTab
                .frame(maxWidth: .infinity)

            sideTab(icon: "icon-tab-profile", fallback: "person.fill", label: "Профиль", tab: .profile)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 6)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(LumiColor.bgCard.opacity(0.92))
        .overlay(Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1), alignment: .top)
    }

    private var homeTab: some View {
        let isActive = selected == .home
        return Button {
            selected = .home
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(isActive ? AnyShapeStyle(LumiGradient.primary) : AnyShapeStyle(Color.white.opacity(0.08)))
                        .frame(width: 52, height: 52)
                        .overlay(Circle().stroke(LumiColor.bgCard, lineWidth: 3))
                        .shadow(color: isActive ? LumiColor.purple2.opacity(0.55) : .clear, radius: 10, y: 6)
                    Image(systemName: "sparkle")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isActive ? Color.white : LumiColor.textSecondary)
                }
                Text("Луми")
                    .font(.lumi(11, weight: .black))
                    .foregroundStyle(isActive ? Color.white : LumiColor.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .offset(y: -14)
        .accessibilityLabel("Луми, главный экран")
    }

    private func sideTab(icon: String, fallback: String, label: String, tab: LumiTab) -> some View {
        let isActive = selected == tab
        return Button {
            selected = tab
        } label: {
            VStack(spacing: 3) {
                LumiIcon(name: icon, size: 20, fallbackSystemImage: fallback)
                Text(label).font(.lumi(10, weight: .bold))
            }
            .foregroundStyle(isActive ? LumiColor.purpleLight : LumiColor.textDim)
            .padding(.top, 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
