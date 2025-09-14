import Foundation
import UserNotifications
import SwiftUI
import SwiftData

@Observable @MainActor
class NotificationManager {
    static let shared = NotificationManager()
    
    var permissionStatus: Bool = false
    
    private var _notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(_notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    var notificationsEnabled: Bool {
        get { _notificationsEnabled }
        set { _notificationsEnabled = newValue }
    }
    
    private init() {
        self._notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        
        Task {
            permissionStatus = await checkNotificationStatus()
        }
    }
    
    // MARK: - Authorization
    
    func ensureAuthorization() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        if settings.authorizationStatus == .authorized {
            permissionStatus = true
            return true
        }
        
        if settings.authorizationStatus == .notDetermined {
            let options: UNAuthorizationOptions = [.alert, .sound]
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: options)) ?? false
            
            permissionStatus = granted
            return granted
        }
        
        return settings.authorizationStatus == .authorized
    }
    
    func checkNotificationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleNotifications(for habit: Habit) async -> Bool {
        guard notificationsEnabled, await ensureAuthorization() else {
            cancelNotifications(for: habit)
            return false
        }
        
        guard let reminderTimes = habit.reminderTimes, !reminderTimes.isEmpty else {
            cancelNotifications(for: habit)
            return false
        }
        
        cancelNotifications(for: habit)
        
        for (timeIndex, reminderTime) in reminderTimes.enumerated() {
            let calendar = Calendar.userPreferred
            let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
            
            for (dayIndex, isActive) in habit.activeDays.enumerated() where isActive {
                let weekday = calendar.systemWeekdayFromOrdered(index: dayIndex)
                
                var dateComponents = DateComponents()
                dateComponents.hour = components.hour
                dateComponents.minute = components.minute
                dateComponents.weekday = weekday
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
                let content = UNMutableNotificationContent()
                content.title = "notifications_habit_time".localized
                content.body = "notifications_dont_forget".localized(with: habit.title)
                content.sound = .default
                
                let request = UNNotificationRequest(
                    identifier: "\(habit.uuid.uuidString)-\(weekday)-\(timeIndex)",
                    content: content,
                    trigger: trigger
                )
                
                try? await UNUserNotificationCenter.current().add(request)
            }
        }
        
        return true
    }
    
    func cancelNotifications(for habit: Habit) {
        let identifiers: [String] = (0..<5).flatMap { timeIndex in
            (1...7).map { weekday in
                "\(habit.uuid.uuidString)-\(weekday)-\(timeIndex)"
            }
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    func updateAllNotifications(modelContext: ModelContext) async {
        guard notificationsEnabled else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            return
        }
        
        let isAuthorized = await ensureAuthorization()
        
        if !isAuthorized {
            await MainActor.run {
                notificationsEnabled = false
            }
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            return
        }
        
        let descriptor = FetchDescriptor<Habit>()
        let allHabits = (try? modelContext.fetch(descriptor)) ?? []
        
        let habitsWithReminders = allHabits.filter { habit in
            guard let reminderTimes = habit.reminderTimes else { return false }
            return !reminderTimes.isEmpty
        }
        
        for habit in habitsWithReminders {
            _ = await scheduleNotifications(for: habit)
        }
    }
}

// MARK: - Free Tier Limitations

extension NotificationManager {
    /// Limit reminders to free tier when losing Pro access
    func limitRemindersForFreeTier(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Habit>()
        guard let allHabits = try? modelContext.fetch(descriptor) else { return }
        
        var changedHabitsCount = 0
        
        for habit in allHabits {
            if let reminderTimes = habit.reminderTimes, reminderTimes.count > 2 {
                // Keep only first 2 reminders (but user can effectively use only 1 due to UI restrictions)
                let limitedReminders = Array(reminderTimes.prefix(2))
                habit.reminderTimes = limitedReminders
                changedHabitsCount += 1
            }
        }
        
        if changedHabitsCount > 0 {
            try? modelContext.save()
            await updateAllNotifications(modelContext: modelContext)
        }
    }
}
