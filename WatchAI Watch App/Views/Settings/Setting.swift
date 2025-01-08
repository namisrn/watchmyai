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
                ForEach(settingItems) { item in
                    NavigationLink(destination: item.destinationView) {
                        Text(item.title)
                            .font(.headline)
                            .padding(.vertical, 5)
                    }
                    .padding(.vertical, 10)
                }
                
                /// Ansicht: Versionsinformationen.
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            Text("WatchMyAI")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Version \(VersionManager.AppVersionNumber)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Settings")
            .listStyle(.carousel)
        }
    }
}

/// Ansicht: "Was gibt's Neues?".
struct WhatsNewView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 5) {
                Section(header: Text("Version 1.3").font(.headline)) {
                    Text("- Bug fixes and improvements")
                }
            }
            .padding()
        }
        .navigationTitle("What's New")
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
    static let AppVersionNumber = "1.3"
}

/// Vorschau für die Settings-Ansicht.
#Preview {
    Setting()
}
