//
//  Constants.swift
//  WatchAI Watch App
//
//  Created by Rafat Nami, Sasan on 08.01.25.
//

import Foundation

/// Eine Struktur zur Verwaltung wichtiger Konfigurationswerte und Konstanten,
/// die in der gesamten App verwendet werden.
struct Constants {

    /// Die Basis-URL für die OpenAI API-Endpunkte.
    /// Diese URL wird verwendet, um Anfragen an die OpenAI-API zu senden.
    static let apiBaseURL = "https://api.openai.com/v1/chat/completions"

    /// Das Standardmodell, das für API-Anfragen verwendet wird.
    /// Hier wird das optimierte Modell `gpt-4o-mini` genutzt, um Anfragen effizienter zu verarbeiten.
    static let defaultModel = "gpt-4o-mini"

    /// Der Timeout-Wert für Netzwerk-Anfragen in Sekunden.
    /// Wird verwendet, um sicherzustellen, dass Anfragen nicht länger als 30 Sekunden blockieren.
    static let requestTimeout: TimeInterval = 30.0
}
