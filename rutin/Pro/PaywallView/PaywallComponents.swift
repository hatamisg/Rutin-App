import SwiftUI
import RevenueCat

struct PaywallHeaderSection: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "laurel.leading")
                    .font(.system(size: 62))
                    .foregroundStyle(ProGradientColors.proGradient)
                Spacer()
                
                Text("rutin Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ProGradientColors.proGradient)
                
                Spacer()
                
                Image(systemName: "laurel.trailing")
                    .font(.system(size: 62))
                    .foregroundStyle(ProGradientColors.proGradient)
            }
        }
    }
}

struct PaywallFeaturesSection: View {
    var body: some View {
        VStack(spacing: 20) {
            ForEach(ProFeature.allFeatures, id: \.id) { feature in
                FeatureRow(feature: feature)
            }
        }
    }
}
