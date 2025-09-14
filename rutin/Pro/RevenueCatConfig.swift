import Foundation
import RevenueCat

struct RevenueCatConfig {
    // MARK: - API Keys
    static let apiKey = "appl_BTvCCfyTRmNFfWhuTsSWpHfSqCZ"
    
    // MARK: - Product Identifiers
    enum ProductIdentifiers {
        static let monthlySubscription = "com.amanbayserkeev.rutin.pro_monthly"
        static let yearlySubscription = "com.amanbayserkeev.rutin.pro_yearly"
        static let lifetimePurchase = "com.amanbayserkeev.rutin.pro_lifetime"
        
        static let allProducts = [monthlySubscription, yearlySubscription, lifetimePurchase]
    }
    
    // MARK: - Entitlements
    enum Entitlements {
        static let pro = "Pro"
    }
    
    // MARK: - Configuration
    static func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .info
        #endif
        
        Purchases.configure(withAPIKey: apiKey)
        setUserAttributes()
    }
    
    private static func setUserAttributes() {
        Purchases.shared.attribution.setAttributes(["locale": Locale.current.identifier])
    }
}

// MARK: - Pro Features Check
extension RevenueCatConfig {
    static func checkProStatus(completion: @escaping (Bool) -> Void) {
        Purchases.shared.getCustomerInfo { customerInfo, error in
            guard let customerInfo = customerInfo, error == nil else {
                completion(false)
                return
            }
            
            let hasActiveEntitlement = customerInfo.entitlements[Entitlements.pro]?.isActive == true
            let hasLifetime = customerInfo.nonSubscriptions.contains { nonSub in
                nonSub.productIdentifier == ProductIdentifiers.lifetimePurchase
            }
            
            let hasPro = hasActiveEntitlement || hasLifetime
            completion(hasPro)
        }
    }
}
