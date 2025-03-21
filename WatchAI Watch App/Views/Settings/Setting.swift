//
//  Setting.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI

/// Modell für ein Einstellungs-Item.
struct SettingItem: Identifiable {
    let id = UUID()
    let title: String
    let destinationView: AnyView
}

/// Beispielhafte Einstellungsoptionen.
private let settingItems: [SettingItem] = [
    SettingItem(title: "What's New", destinationView: AnyView(WhatsNewView())),
    SettingItem(title: "Auto-Update", destinationView: AnyView(AutoUpdateView())),
    SettingItem(title: "Legal Notices", destinationView: AnyView(LegalNoticesView()))
]

/// Hauptansicht der Einstellungen.
struct Setting: View {
    var body: some View {
        NavigationStack {
            List {
                // Haupteinstellungen
                Section {
                    ForEach(settingItems) { item in
                        NavigationLink(destination: item.destinationView) {
                            HStack {
                                // Icon für jede Einstellung
                                Image(systemName: iconName(for: item.title))
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                Text(item.title)
                                    .font(.system(size: 16))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                // Versionsinformationen
                Section {
                    VStack(spacing: 12) {
                        // App Icon
                        Image(systemName:"bubble.left.and.text.bubble.right")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                            .padding(.bottom, 4)
                        
                        // App Name und Version
                        VStack(spacing: 4) {
                            Text("WatchMyAI")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text("Version \(VersionManager.AppVersionNumber)")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .navigationTitle("Settings")
            .listStyle(.carousel)
        }
    }
    
    // Hilfsfunktion für Icon-Namen
    private func iconName(for title: String) -> String {
        switch title {
        case "What's New":
            return "sparkles"
        case "Auto-Update":
            return "arrow.triangle.2.circlepath"
        case "Legal Notices":
            return "doc.text"
        default:
            return "gear"
        }
    }
}

/// View: "What's New?"
struct WhatsNewView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Version Header
                HStack {
                    Text("Version 1.5")
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                    Text("March 2025")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 8)
                
                // Features
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "checkmark.shield", text: "Improved Stability: Optimizations for reliable chatting on your Apple Watch.")
                    FeatureRow(icon: "bolt", text: "Better Performance: Faster responses and extended battery life.")
                    FeatureRow(icon: "memorychip", text: "Optimized Memory: Smoother experience, especially during longer chats.")
                    FeatureRow(icon: "lock.shield", text: "Reliable Data Storage: Securely saves your conversations.")
                    FeatureRow(icon: "sparkles", text: "Enhanced UI: Smoother animations and better visual feedback.")
                    FeatureRow(icon: "arrow.up.and.down", text: "Improved Scrolling: Better chat navigation and message visibility.")
                    FeatureRow(icon: "bolt.circle", text: "Quick Actions: Faster access to common chat functions.")
                    FeatureRow(icon: "exclamationmark.circle", text: "Better Feedback: Clearer loading states and error messages.")
                }
            }
            .padding()
        }
        .navigationTitle("What's New")
    }
}

// Feature Row Component
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Ansicht: Automatische Updates.
struct AutoUpdateView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Automatic Updates")
                    .font(.headline)
                    .padding(.bottom, 5)
                Text("Ensure your app stays up to date automatically:")
                    .padding(.bottom)
                Text("1. Open the Watch app on your iPhone.")
                Text("2. Go to the App Store section.")
                Text("3. Check if 'Automatic Updates' is turned on.")
            }
            .padding()
        }
        .navigationTitle("Auto-Update")
    }
}

/// Ansicht: Rechtliche Hinweise.
struct LegalNoticesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Section {
                    Text("Privacy Policy")
                        .font(.headline)
                    Text("No personal data is collected through this app.")
                }
                Divider()
                Section {
                    Text("License")
                        .font(.headline)
                    Text("All content is copyrighted and subject to licensing terms.")
                }
                Divider()
                Section {
                    Text("Disclaimer")
                        .font(.headline)
                    Text("We are not responsible for any damages that may arise from using this app.")
                }
            }
            .padding()
        }
        .navigationTitle("Legal Notices")
    }
}

struct VersionManager {
    static let AppVersionNumber = "1.5"
}

/// Vorschau für die Settings-Ansicht.
#Preview {
    Setting()
}
