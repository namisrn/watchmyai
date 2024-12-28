//
//  Setting.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI

struct SettingItem: Identifiable {
    var id = UUID()
    var title: String
    var destinationView: AnyView
}

// Beispielhafte Einstellungseinträge
let settingItems: [SettingItem] = [
    SettingItem(title: "Version",  destinationView: AnyView(VersionView())),
    SettingItem(title: "What's New", destinationView: AnyView(WhatsNewView())),
    SettingItem(title: "Auto-Update",  destinationView: AnyView(AutoUpdateView())),
    SettingItem(title: "Legal Notices",  destinationView: AnyView(LegalNoticesView())),
]

struct Setting: View {
    
    @ObservedObject var viewModel = ViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(settingItems) { item in
                    NavigationLink(destination: item.destinationView) {
                        VStack(alignment: .leading) {
                            Text(item.title)
                        }
                    }
                    .listItemTint(.blue)
                    .padding(EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5))
                }
            }
            .navigationTitle("Setting")
        }
        .listStyle(.plain)
    }
}

struct VersionView: View {
    var body: some View {
        NavigationStack {
            Text("Version \(VersionManager.AppVersionNumber)  Build \(VersionManager.AppBuildNumber)")
        }
        .edgesIgnoringSafeArea(.all)
        .navigationTitle("Version")
    }
}

struct WhatsNewView: View {
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 10){
                Section(header: Text("Version 2.2:")){
                    Text("- New: Gemini is now availabe for everyone")
                    Text("- Bug Fix")
                }
                Section(header: Text("Version 2.1:")){
                    Text("- New: the newest GPT-4o Model")
                }
                Section(header: Text("Version 2.0:")){
                    Text("- New: iOS-App")
                    Text("- New: Save your Chats")
                    Text("- New: Message Design in Watch")
                }
                Divider()
                Section(header: Text("Version 1.9:")){
                    Text("- New: Updated GPT 3.5 Turbo")
                    Text("- Minor improvement")
                }
                Divider()
                Section(header: Text("Version 1.6:")){
                    Text("- New: Updated GPT 3.5 Turbo")
                    Text("- Minor improvement")
                }
                Divider()
                Section(header: Text("Version 1.5:")){
                    Text("- New: Widgets and Complications")
                    Text("- Minor UI-improvement")
                }
                Divider()
                Section(header: Text("Version 1.4:")){
                    Text("- New Chat Design")
                    Text("- Add Stack Stack")
                    Text("- UI-improvement and Bug Fixing")
                }
                Divider()
                Section(header: Text("Version 1.3:")){
                    Text("- improvement and Bug fixing")
                }
                Divider()
                Section(header: Text("Version 1.2:")){
                    Text("- Asynchronous Requests: Chat more smoothly with faster message loading.")
                    Text("- Haptic Feedback: Get a vibration alert when GPT's reply arrives.")
                    Text("- Connection Error Handling")
                    Text("- TryAgain Button for Incomplete Responses")
                }
            }
            .padding()
        }
        .navigationTitle("What's New")
    }
}

struct AutoUpdateView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Automatische Updates").font(.headline).padding(.bottom)
                Text("To ensure your app stays up to date automatically:")
                    .padding(.bottom)
                
                Text("1. open the Watch app on your iPhone.").padding(.top)
                Text("2. go to the App Store section.").padding(.top)
                Text("3. check if 'Automatic Updates' is turned on.").padding(.top)
            }
            .padding()
        }
        .navigationTitle("Auto-Update")
    }
}

struct LegalNoticesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy").font(.headline)
                Text("No personal data is collected through this app.")
                
                Divider()
                Text("License").font(.headline)
                Text("All content is copyrighted and subject to licensing terms.")
                
                Divider()
                Text("Disclaimer").font(.headline)
                Text("We are not responsible for any damages that may arise from using this app.")
            }
            .padding()
        }
        .navigationTitle("Legal Notices")
    }
}

#Preview {
    Setting()
}
