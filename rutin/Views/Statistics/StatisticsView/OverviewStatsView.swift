import SwiftUI

struct CardColors {
    
    static func completionRate(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark
            ? Color(#colorLiteral(red: 0.6627380788, green: 0.6627506256, blue: 0.8563500881, alpha: 1))
            : Color(#colorLiteral(red: 0.2627380788, green: 0.2627506256, blue: 0.4563500881, alpha: 1))
    }

    static func activeDays(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark
            ? Color(#colorLiteral(red: 0.9803726077, green: 0.4384494722, blue: 0.4061130285, alpha: 1))
            : Color(#colorLiteral(red: 0.8303726077, green: 0.2884494722, blue: 0.2561130285, alpha: 1))
    }

    static func habitsDone(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark
            ? Color(#colorLiteral(red: 0.4411377907, green: 0.7888615131, blue: 0.2720118761, alpha: 1))
            : Color(#colorLiteral(red: 0.3411377907, green: 0.6388615131, blue: 0.1220118761, alpha: 1))
    }

    static func activeHabits(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark
            ? Color(#colorLiteral(red: 0.433128655, green: 0.6248013973, blue: 0.8752619624, alpha: 1))
            : Color(#colorLiteral(red: 0.333128655, green: 0.5248013973, blue: 0.7252619624, alpha: 1))
    }
    
    // MARK: - Convenience Methods
    
    static func color(for card: InfoCard, colorScheme: ColorScheme) -> Color {
        switch card {
        case .completionRate:
            return completionRate(for: colorScheme)
        case .activeDays:
            return activeDays(for: colorScheme)
        case .habitsDone:
            return habitsDone(for: colorScheme)
        case .activeHabits:
            return activeHabits(for: colorScheme)
        }
    }
}

struct OverviewStatsView: View {
    let habits: [Habit]
    
    @State private var statsData: MotivatingOverviewStats = MotivatingOverviewStats()
    @State private var selectedInfoCard: InfoCard? = nil
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    var body: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                StatCardInteractive(
                    title: "overall_completion".localized,
                    value: "\(Int(overallCompletionRate * 100))%",
                    onTap: { selectedInfoCard = .completionRate },
                    cardColor: CardColors.completionRate(for: colorScheme),
                    icon3DAsset: "CardInfo_completion_rate",
                    iconSize: 46
                )
                StatCardInteractive(
                    title: "active_days_total".localized,
                    value: "\(totalActiveDays)",
                    onTap: { selectedInfoCard = .activeDays },
                    cardColor: CardColors.activeDays(for: colorScheme),
                    icon3DAsset: "CardInfo_active_days"
                )
                StatCardInteractive(
                    title: "completed_total".localized,
                    value: "\(totalCompletedHabits)",
                    onTap: { selectedInfoCard = .habitsDone },
                    cardColor: CardColors.habitsDone(for: colorScheme),
                    icon3DAsset: "CardInfo_habits_done"
                )
                StatCardInteractive(
                    title: "active_habits".localized,
                    value: "\(activeHabitsCount)",
                    onTap: { selectedInfoCard = .activeHabits },
                    cardColor: CardColors.activeHabits(for: colorScheme),
                    icon3DAsset: "CardInfo_active_habits"
                )
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 0)
        .sheet(item: $selectedInfoCard) { card in
            CardInfoView(card: card)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Computed Properties
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 160), spacing: 16),
            GridItem(.adaptive(minimum: 160), spacing: 16)
        ]
    }
    
    private var totalCompletedHabits: Int {
        habits.reduce(0) { total, habit in
            total + (habit.completions?.filter { $0.value >= habit.goal }.count ?? 0)
        }
    }
    
    private var totalActiveDays: Int {
        var activeDaysSet: Set<String> = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for habit in habits {
            guard let completions = habit.completions else { continue }
            
            for completion in completions {
                if completion.value > 0 && habit.isActiveOnDate(completion.date) {
                    let dateKey = dateFormatter.string(from: completion.date)
                    activeDaysSet.insert(dateKey)
                }
            }
        }
        
        return activeDaysSet.count
    }
    
    private var overallCompletionRate: Double {
        var totalProgress = 0.0
        var totalPossibleProgress = 0.0
        
        for habit in habits.filter({ !$0.isArchived }) {
            guard let completions = habit.completions else { continue }
            
            for completion in completions {
                if habit.isActiveOnDate(completion.date) {
                    let progress = completion.value
                    let goal = habit.goal
                    
                    if goal > 0 {
                        totalProgress += min(Double(progress), Double(goal))
                        totalPossibleProgress += Double(goal)
                    }
                }
            }
        }
        
        return totalPossibleProgress > 0 ? totalProgress / totalPossibleProgress : 0.0
    }
    
    private var activeHabitsCount: Int {
        habits.filter { !$0.isArchived }.count
    }
}

// MARK: - Supporting Models

struct MotivatingOverviewStats {
    let habitsCompleted: Int          // Number of completed habits (any progress >= goal)
    let activeDays: Int               // Days with at least one action
    let completionRate: Double        // Average completion rate (0.0 to 1.0)
    let activeHabitsCount: Int        // Number of non-archived habits
    
    init(habitsCompleted: Int = 0, activeDays: Int = 0, completionRate: Double = 0.0, activeHabitsCount: Int = 0) {
        self.habitsCompleted = habitsCompleted
        self.activeDays = activeDays
        self.completionRate = completionRate
        self.activeHabitsCount = activeHabitsCount
    }
}

// MARK: - Info Models

enum InfoCard: String, Identifiable {
    case habitsDone = "overall_completion"
    case activeDays = "active_days_total"
    case completionRate = "completed_total"
    case activeHabits = "active_habits"
    
    var id: String { rawValue }
}

// MARK: - StatCardInteractive

struct StatCardInteractive: View {
    let title: String
    let value: String
    let onTap: () -> Void
    let cardColor: Color
    let icon3DAsset: String
    let iconSize: CGFloat
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    private static let defaultIconSize: CGFloat = 40
    
    init(
        title: String,
        value: String,
        onTap: @escaping () -> Void,
        cardColor: Color,
        icon3DAsset: String,
        iconSize: CGFloat = StatCardInteractive.defaultIconSize
    ) {
        self.title = title
        self.value = value
        self.onTap = onTap
        self.cardColor = cardColor
        self.icon3DAsset = icon3DAsset
        self.iconSize = iconSize
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playSelection()
            onTap()
        }) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(cardColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .padding(.top, 8)
                    .padding(.horizontal, 12)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                
                
                Spacer(minLength: 8)
                
                HStack(spacing: 12) {
                    Image(icon3DAsset)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                    
                    Spacer()
                    
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(cardColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
            .frame(height: 120)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardColor.opacity(0.15))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        Color.primary.opacity(0.1),
                        lineWidth: 0.3
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Info Views

struct CardInfoView: View {
    let card: InfoCard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer()
                        Image(cardIllustration)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: cardImageSize.width, height: cardImageSize.height)
                        Spacer()
                    }
                    .padding(.top, 0)
                    .padding(.bottom, 20)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("what_it_shows".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(cardDescription)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("how_its_calculated".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(calculationDescription)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("example".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(exampleDescription)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle(cardTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("button_done".localized) {
                        dismiss()
                    }
                    .foregroundStyle(cardColor)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var cardIllustration: String {
        switch card {
        case .habitsDone: return "CardInfo_habits_done"
        case .activeDays: return "CardInfo_active_days"
        case .completionRate: return "CardInfo_completion_rate"
        case .activeHabits: return "CardInfo_active_habits"
        }
    }
    
    private var cardImageSize: CGSize {
        return CGSize(width: 200, height: 160)
    }
    
    private var cardColor: Color {
        CardColors.color(for: card, colorScheme: colorScheme)
    }
    
    private var cardTitle: String {
        switch card {
        case .habitsDone: return "completed_total".localized
        case .activeDays: return "active_days_total".localized
        case .completionRate: return "overall_completion".localized
        case .activeHabits: return "active_habits".localized
        }
    }
    
    private var cardDescription: String {
        switch card {
        case .habitsDone:
            return "completed_total_description".localized
        case .activeDays:
            return "active_days_total_description".localized
        case .completionRate:
            return "overall_completion_description".localized
        case .activeHabits:
            return "active_habits_description".localized
        }
    }
    
    private var calculationDescription: String {
        switch card {
        case .habitsDone:
            return "completed_total_calculation".localized
        case .activeDays:
            return "active_days_total_calculation".localized
        case .completionRate:
            return "overall_completion_calculation".localized
        case .activeHabits:
            return "active_habits_calculation".localized
        }
    }
    
    private var exampleDescription: String {
        switch card {
        case .habitsDone:
            return "completed_total_example".localized
        case .activeDays:
            return "active_days_total_example".localized
        case .completionRate:
            return "overall_completion_example".localized
        case .activeHabits:
            return "active_habits_example".localized
        }
    }
}
