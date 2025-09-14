import SwiftUI

struct EmptyStateView: View {
    @State private var isAnimating = false
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 30
    @State private var hintOpacity: Double = 0
    @State private var hintOffset: CGFloat = 30
    @ObservedObject private var colorManager = AppColorManager.shared
    
    private var isCompactHeight: Bool {
        UIScreen.main.bounds.height <= 667
    }
    
    private var imageSize: CGFloat {
        isCompactHeight ? 120 : 160
    }
    
    private var topPadding: CGFloat {
        isCompactHeight ? 20 : 60
    }
    
    private var verticalSpacing: CGFloat {
        isCompactHeight ? 24 : 40
    }
    
    var body: some View {
        VStack(spacing: verticalSpacing) {
            Image("rutinBlank")
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .scaleEffect(isAnimating ? 1.15 : 0.9)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
            
            VStack(spacing: isCompactHeight ? 12 : 16) {
                Text("empty_view_largetitle".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
                
                Text("empty_view_title3".localized)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .minimumScaleFactor(0.7)
                    .lineLimit(3)
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOffset)
            }
            
            HStack(spacing: 8) {
                Text("empty_view_tap".localized)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "plus")
                    .foregroundStyle(colorManager.selectedColor.color)
                    .frame(width: 26, height: 26)
                
                Text("empty_view_to_create_habit".localized)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .minimumScaleFactor(0.8)
            .lineLimit(1)
            .padding(.top, isCompactHeight ? 12 : 20)
            .opacity(hintOpacity)
            .offset(y: hintOffset)
            
            if !isCompactHeight {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, topPadding)
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).delay(0.8)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
            
            withAnimation(.easeOut(duration: 1.5).delay(1.6)) {
                subtitleOpacity = 1.0
                subtitleOffset = 0
            }
            
            withAnimation(.easeOut(duration: 1.2).delay(2.4)) {
                hintOpacity = 1.0
                hintOffset = 0
            }
        }
    }
}
