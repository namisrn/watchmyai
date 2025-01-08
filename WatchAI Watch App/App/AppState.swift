//
//  AppState.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 08.01.25.
//

import Foundation

/// Klasse zur Verwaltung globaler App-States (z.B. Fehler, Ladezustände).
final class AppState: ObservableObject {
    @Published var isDataStorageFailed: Bool = false
    @Published var alertMessage: String? = nil
}
