import SwiftUI
import CloudKit

struct CloudKitSyncView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var cloudKitStatus: CloudKitStatus = .checking
    @State private var lastSyncTime: Date?
    @State private var isSyncing: Bool = false
    
    private enum CloudKitStatus {
        case checking, available, unavailable, restricted, error(String)
        
        var statusInfo: (text: String, color: Color, icon: String) {
            switch self {
            case .checking:
                return ("icloud_checking_status".localized, .secondary, "icloud.fill")
            case .available:
                return ("icloud_sync_active".localized, .green, "checkmark.icloud.fill")
            case .unavailable:
                return ("icloud_not_signed_in".localized, .orange, "person.icloud.fill")
            case .restricted:
                return ("icloud_restricted".localized, .red, "exclamationmark.icloud.fill")
            case .error(let message):
                return (message, .red, "xmark.icloud.fill")
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    
                    Image("3d_cloud_progradient")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                    
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
            
            Section {
                HStack {
                    statusIcon(cloudKitStatus.statusInfo.icon)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("icloud_sync_status".localized)
                            .font(.headline)
                        
                        Text(cloudKitStatus.statusInfo.text)
                            .font(.subheadline)
                            .foregroundStyle(cloudKitStatus.statusInfo.color)
                    }
                    
                    Spacer()
                    
                    if case .checking = cloudKitStatus {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            
            if case .available = cloudKitStatus {
                Section {
                    Button {
                        forceiCloudSync()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath.icloud.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(#colorLiteral(red: 0.3411764706, green: 0.6235294118, blue: 1, alpha: 1)),
                                            Color(#colorLiteral(red: 0.0, green: 0.3803921569, blue: 0.7647058824, alpha: 1))
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 30, height: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("icloud_force_sync".localized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.blue)
                                
                                Text("icloud_force_sync_desc".localized)
                                    .font(.footnote)
                                    .foregroundStyle(Color(UIColor.secondaryLabel))
                            }
                            
                            Spacer()
                            
                            if isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isSyncing)
                    
                    if let lastSyncTime = lastSyncTime {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.secondary)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("icloud_last_sync".localized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(formatSyncTime(lastSyncTime))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                } header: {
                    Text("icloud_manual_sync".localized)
                } footer: {
                    Text("icloud_manual_sync_footer".localized)
                }
            }
            
            Section("icloud_how_sync_works".localized) {
                SyncInfoRow(
                    icon: "icloud.and.arrow.up.fill",
                    title: "icloud_automatic_backup".localized,
                    description: "icloud_automatic_backup_desc".localized
                )
                
                SyncInfoRow(
                    icon: "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill",
                    title: "icloud_cross_device_sync".localized,
                    description: "icloud_cross_device_sync_desc".localized
                )
                
                SyncInfoRow(
                    icon: "lock.icloud.fill",
                    title: "icloud_private_secure".localized,
                    description: "icloud_private_secure_desc".localized
                )
            }
            
            if case .unavailable = cloudKitStatus {
                Section {
                    HStack {
                        troubleshootingIcon()
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("icloud_signin_required".localized)
                                .font(.subheadline)
                            
                            Text("icloud_signin_steps".localized)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("icloud_troubleshooting".localized)
                }
            }
        }
        .navigationTitle("icloud_sync".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLastSyncTime()
            checkCloudKitStatus()
        }
    }
    
    // MARK: - Private Methods
    
    private func forceiCloudSync() {
        isSyncing = true
        
        Task {
            do {
                try modelContext.save()
                
                // Wait for automatic CloudKit sync
                try await Task.sleep(nanoseconds: 3_000_000_000)
                
                let container = CKContainer(identifier: "iCloud.com.amanbayserkeev.rutin")
                let accountStatus = try await container.accountStatus()
                
                guard accountStatus == .available else {
                    throw CloudKitError.accountNotAvailable
                }
                
                await MainActor.run {
                    let now = Date()
                    lastSyncTime = now
                    UserDefaults.standard.set(now, forKey: "lastSyncTime")
                    isSyncing = false
                    HapticManager.shared.play(.success)
                }
            } catch {
                await MainActor.run {
                    isSyncing = false
                    HapticManager.shared.play(.error)
                }
            }
        }
    }
    
    private func loadLastSyncTime() {
        if let savedTime = UserDefaults.standard.object(forKey: "lastSyncTime") as? Date {
            lastSyncTime = savedTime
        }
    }
    
    private func formatSyncTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "icloud_today_at".localized(with: formatter.string(from: date))
        } else if calendar.isDateInYesterday(date) {
            return "icloud_yesterday_at".localized(with: formatter.string(from: date))
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
    
    @ViewBuilder
    private func statusIcon(_ iconName: String) -> some View {
        switch iconName {
        case "icloud.fill":
            Image(systemName: iconName)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(#colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)),
                            Color(#colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1))
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 30)
            
        case "checkmark.icloud.fill":
            Image(systemName: iconName)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(#colorLiteral(red: 0.1960784314, green: 0.8431372549, blue: 0.2941176471, alpha: 1)),
                            Color(#colorLiteral(red: 0.1333333333, green: 0.5882352941, blue: 0.1333333333, alpha: 1))
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 30)
            
        case "person.icloud.fill":
            Image(systemName: iconName)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(#colorLiteral(red: 1, green: 0.8, blue: 0.0, alpha: 1)),
                            Color(#colorLiteral(red: 0.8, green: 0.5, blue: 0.0, alpha: 1))
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 30)
            
        case "exclamationmark.icloud.fill":
            Image(systemName: iconName)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(#colorLiteral(red: 1, green: 0.4, blue: 0.4, alpha: 1)),
                            Color(#colorLiteral(red: 0.8, green: 0.2, blue: 0.2, alpha: 1))
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 30)
            
        case "xmark.icloud.fill":
            Image(systemName: iconName)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(#colorLiteral(red: 1, green: 0.3, blue: 0.3, alpha: 1)),
                            Color(#colorLiteral(red: 0.7, green: 0.1, blue: 0.1, alpha: 1))
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 30)
            
        default:
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func troubleshootingIcon() -> some View {
        Image(systemName: "wrench.adjustable.fill")
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(#colorLiteral(red: 0.5019607843, green: 0.5019607843, blue: 0.5019607843, alpha: 1)),
                        Color(#colorLiteral(red: 0.3019607843, green: 0.3019607843, blue: 0.3019607843, alpha: 1))
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 30, height: 30)
    }
    
    private func checkCloudKitStatus() {
        Task {
            await checkAccountStatus()
        }
    }
    
    @MainActor
    private func checkAccountStatus() async {
        do {
            let container = CKContainer(identifier: "iCloud.com.amanbayserkeev.rutin")
            let accountStatus = try await container.accountStatus()
            
            switch accountStatus {
            case .available:
                do {
                    let database = container.privateCloudDatabase
                    _ = try await database.allRecordZones()
                    cloudKitStatus = .available
                } catch {
                    cloudKitStatus = .error("icloud_database_error".localized)
                }
                
            case .noAccount:
                cloudKitStatus = .unavailable
                
            case .restricted:
                cloudKitStatus = .restricted
                
            case .couldNotDetermine:
                cloudKitStatus = .error("icloud_status_unknown".localized)
                
            case .temporarilyUnavailable:
                cloudKitStatus = .error("icloud_temporarily_unavailable".localized)
                
            @unknown default:
                cloudKitStatus = .error("icloud_unknown_error".localized)
            }
        } catch {
            cloudKitStatus = .error("icloud_check_failed".localized)
        }
    }
}

enum CloudKitError: Error {
    case accountNotAvailable
}

struct SyncInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            iconWithGradient(icon)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func iconWithGradient(_ iconName: String) -> some View {
        switch iconName {
        case "icloud.and.arrow.up.fill":
            Image(systemName: iconName)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(#colorLiteral(red: 0.1960784314, green: 0.8431372549, blue: 0.2941176471, alpha: 1)),
                            Color(#colorLiteral(red: 0.1333333333, green: 0.5882352941, blue: 0.1333333333, alpha: 1))
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 30)
            
        case "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill":
            Image(systemName: iconName)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(#colorLiteral(red: 0.3411764706, green: 0.6235294118, blue: 1, alpha: 1)),
                            Color(#colorLiteral(red: 0.0, green: 0.3803921569, blue: 0.7647058824, alpha: 1))
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 30)
            
        case "lock.icloud.fill":
            Image(systemName: iconName)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(#colorLiteral(red: 1, green: 0.5843137255, blue: 0.0, alpha: 1)),
                            Color(#colorLiteral(red: 0.8549019608, green: 0.2470588235, blue: 0.1176470588, alpha: 1))
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 30)
            
        default:
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
