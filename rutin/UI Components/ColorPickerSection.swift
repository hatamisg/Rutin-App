import SwiftUI

struct ColorPickerSection: View {
    @Binding var selectedColor: HabitIconColor
    @State private var customColor = HabitIconColor.customColor
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ProManager.self) private var proManager
    
    var columnsCount: Int = 7
    var buttonSize: CGFloat = 32
    var spacing: CGFloat = 12
    var showCustomPicker: Bool = true
    var onProRequired: (() -> Void)? = nil
    var enableProLocks: Bool = true
    
    private let freeColors: Set<HabitIconColor> = [
        .primary, .celestial, .brown, .red, .orange
    ]
    
    private enum DesignConstants {
        static let selectedBorderScale: CGFloat = 0.9
        static let selectedButtonScale: CGFloat = 1.1
        static let lockIconScale: CGFloat = 0.5
        static let customPickerLockScale: CGFloat = 0.35
        static let lockedOpacity: Double = 0.8
        static let animationDuration: Double = 0.2
    }
    
    private var colorColumns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: columnsCount)
    }
    
    var body: some View {
        LazyVGrid(columns: colorColumns, spacing: spacing) {
            ForEach(colorManager.getAvailableColors().filter { $0 != .colorPicker }, id: \.self) { color in
                colorButton(for: color)
            }
            
            if showCustomPicker {
                customColorPicker
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func colorButton(for color: HabitIconColor) -> some View {
        let isLocked = enableProLocks && !proManager.isPro && !freeColors.contains(color)
        let isSelected = selectedColor == color && !isLocked
        
        return Button {
            if isLocked {
                onProRequired?()
            } else {
                selectedColor = color
                HapticManager.shared.playSelection()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(color.adaptiveGradient(for: colorScheme))
                    .frame(width: buttonSize, height: buttonSize)
                    .opacity(isLocked ? DesignConstants.lockedOpacity : 1.0)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                            .frame(
                                width: buttonSize * DesignConstants.selectedBorderScale,
                                height: buttonSize * DesignConstants.selectedBorderScale
                            )
                            .opacity(isSelected ? 1 : 0)
                            .animation(.easeInOut(duration: DesignConstants.animationDuration), value: isSelected)
                    )
                
                if isLocked {
                    lockOverlay
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: color, isLocked: isLocked))
        .scaleEffect(isSelected ? DesignConstants.selectedButtonScale : 1.0)
        .animation(.easeInOut(duration: DesignConstants.animationDuration), value: isSelected)
    }
    
    private var customColorPicker: some View {
        let isLocked = enableProLocks && !proManager.isPro
        
        return ZStack {
            ColorPicker("", selection: $customColor)
                .labelsHidden()
                .disabled(isLocked)
                .onChange(of: customColor) { _, newColor in
                    if !isLocked {
                        HabitIconColor.customColor = newColor
                        selectedColor = .colorPicker
                        HapticManager.shared.playSelection()
                    }
                }
                .accessibilityLabel(customPickerAccessibilityLabel(isLocked: isLocked))
            
            if isLocked {
                Button {
                    onProRequired?()
                } label: {
                    customPickerLockOverlay
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var lockOverlay: some View {
        Circle()
            .fill(.clear)
            .frame(width: buttonSize, height: buttonSize)
            .overlay(
                Image(systemName: "lock.fill")
                    .font(.system(size: buttonSize * DesignConstants.lockIconScale, weight: .medium))
                    .foregroundStyle(.white)
            )
    }
    
    private var customPickerLockOverlay: some View {
        Circle()
            .fill(.clear)
            .frame(width: buttonSize, height: buttonSize)
            .overlay(
                Image(systemName: "lock.fill")
                    .font(.system(size: buttonSize * DesignConstants.customPickerLockScale, weight: .medium))
                    .foregroundStyle(.white)
            )
    }
    
    private func accessibilityLabel(for color: HabitIconColor, isLocked: Bool) -> String {
        if isLocked {
            return "Pro color: \(color.rawValue)"
        } else {
            return "\(color.rawValue.localized) color"
        }
    }
    
    private func customPickerAccessibilityLabel(isLocked: Bool) -> String {
        if isLocked {
            return "Pro feature: Custom color picker"
        } else {
            return "custom_color_picker".localized
        }
    }
}

// MARK: - Extensions

extension ColorPickerSection {
    static func forIconPicker(selectedColor: Binding<HabitIconColor>) -> ColorPickerSection {
        ColorPickerSection(
            selectedColor: selectedColor,
            columnsCount: 8,
            buttonSize: 32,
            spacing: 12,
            showCustomPicker: true,
            onProRequired: nil,
            enableProLocks: false
        )
    }
    
    static func forAppColorPicker(
        selectedColor: Binding<HabitIconColor>,
        onProRequired: (() -> Void)? = nil
    ) -> ColorPickerSection {
        ColorPickerSection(
            selectedColor: selectedColor,
            columnsCount: 8,
            buttonSize: 32,
            spacing: 12,
            showCustomPicker: true,
            onProRequired: onProRequired,
            enableProLocks: true
        )
    }
}
