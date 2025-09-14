import SwiftUI

struct GoalSection: View {
    @Binding var selectedType: HabitType
    @Binding var countGoal: Int
    @Binding var hours: Int
    @Binding var minutes: Int
    @FocusState.Binding var isFocused: Bool
    
    @State private var countText: String = ""
    @State private var timeDate: Date = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date()) ?? Date()
    
    var body: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .withIOSSettingsIcon(lightColors: [
                        Color(#colorLiteral(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)),
                        Color(#colorLiteral(red: 0.2, green: 0.6, blue: 0.3, alpha: 1))
                    ], fontSize: 17)
                    .symbolEffect(.bounce, options: .repeat(1), value: selectedType)
                
                Text("daily_goal".localized)
                
                Spacer()
                
                Picker("", selection: $selectedType.animation(.easeInOut(duration: 0.4))) {
                    Text("count".localized).tag(HabitType.count)
                    Text("time".localized).tag(HabitType.time)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 170)
            }
            
            if selectedType == .count {
                HStack(spacing: 12) {
                    Image(systemName: "number")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(#colorLiteral(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)),
                                    Color(#colorLiteral(red: 0.1, green: 0.5, blue: 0.2, alpha: 1))
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 30, height: 30)
                    
                    TextField("goalsection_enter_count".localized, text: $countText)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .multilineTextAlignment(.leading)
                        .onChange(of: countText) { _, newValue in
                            if let number = Int(newValue), number > 0 {
                                countGoal = min(number, 999999)
                            }
                        }
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(#colorLiteral(red: 0.4, green: 0.7, blue: 0.95, alpha: 1)),
                                    Color(#colorLiteral(red: 0.12, green: 0.35, blue: 0.6, alpha: 1))
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 30, height: 30)
                    
                    Text("goalsection_choose_time".localized)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $timeDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .onChange(of: timeDate) { _, _ in
                            updateHoursAndMinutesFromTimeDate()
                        }
                }
            }
        }
        .onAppear {
            initializeValues()
        }
        .onChange(of: selectedType) { _, newValue in
            resetFieldsForType(newValue)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateHoursAndMinutesFromTimeDate() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: timeDate)
        hours = components.hour ?? 0
        minutes = components.minute ?? 0
    }
    
    private func updateTimeDateFromHoursAndMinutes() {
        timeDate = Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: Date()) ?? Date()
    }
    
    private func initializeValues() {
        if selectedType == .count {
            if countGoal <= 0 {
                countGoal = 1
            }
            countText = String(countGoal)
        } else {
            if hours == 0 && minutes == 0 {
                hours = 1
                minutes = 0
            }
            updateTimeDateFromHoursAndMinutes()
        }
    }
    
    private func resetFieldsForType(_ type: HabitType) {
        if type == .count {
            if countGoal <= 0 {
                countGoal = 1
            }
            countText = String(countGoal)
        } else {
            if hours == 0 && minutes == 0 {
                hours = 1
                minutes = 0
            }
            updateTimeDateFromHoursAndMinutes()
        }
    }
}
