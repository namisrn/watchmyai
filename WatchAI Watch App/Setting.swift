//
//  Setting.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI

/// Model for a Setting Item
struct SettingItem: Identifiable {
    var id = UUID()
    var title: String
    var destinationView: AnyView
}

/// Example Setting Entries
let settingItems: [SettingItem] = [
    SettingItem(title: "Version", destinationView: AnyView(VersionView())),
    SettingItem(title: "What's New", destinationView: AnyView(WhatsNewView())),
    SettingItem(title: "Auto-Update", destinationView: AnyView(AutoUpdateView())),
    SettingItem(title: "Legal Notices", destinationView: AnyView(LegalNoticesView()))
]

/// Main Settings View
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
            }
            .navigationTitle("Settings")
            .listStyle(.plain)
        }
    }
}

/// Version Information View
struct VersionView: View {
    var body: some View {
        VStack {
            Text("Version \(VersionManager.AppVersionNumber)")
                .font(.title2)
                .padding(.bottom, 5)
            Text("Build \(VersionManager.AppBuildNumber)")
                .font(.body)
        }
        .navigationTitle("Version")
        .padding()
    }
}

/// What's New View
struct WhatsNewView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Section(header: Text("Version 1.0").font(.headline)) {
                    Text("- Welcome! to WatchMyAI")
                }

            }
            .padding()
        }
        .navigationTitle("What's New")
    }
}

/// Auto-Update Instructions View
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

/// Legal Notices View
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

/// Preview Provider
#Preview {
    Setting()
}
