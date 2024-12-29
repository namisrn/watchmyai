//
//  Menu.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI

/// Represents a menu item with navigation details.
struct MenuItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    let destination: AnyView
}

/// List of available menu items with destinations.
private let menuItems: [MenuItem] = [
    MenuItem(
        title: "New Chat",
        subtitle: "Start a new conversation",
        iconName: "plus.bubble",
        destination: AnyView(NewChat())
    ),
    MenuItem(
        title: "Archive",
        subtitle: "Saved chats",
        iconName: "archivebox",
        destination: AnyView(Archive())
    ),
    MenuItem(
        title: "Settings",
        subtitle: "Info and privacy",
        iconName: "gear",
        destination: AnyView(Setting())
    )
]

/// Main menu view for navigation.
struct Menu: View {
    var body: some View {
        NavigationStack {
            List(menuItems) { item in
                NavigationLink(destination: item.destination) {
                    MenuRow(item: item)
                }
                .listItemTint(.blue)
            }
            .navigationTitle("WatchMyAI")
            .listStyle(.carousel)
        }
    }
}

/// Represents a row in the menu displaying icon, title, and subtitle.
struct MenuRow: View {
    let item: MenuItem
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: item.iconName)
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            Spacer()
            
                Text(item.title)
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text(item.subtitle)
                    .font(.footnote)
                    .foregroundColor(.gray)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    Menu()
}
