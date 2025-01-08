//
//  Logger.swift
//  WatchAI Watch App
//
//  Created by Rafat Nami, Sasan on 08.01.25.
//

import Foundation
import os

final class Logger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.yourapp.WatchAI"

    static func logInfo(_ message: String) {
        os_log(.info, log: OSLog(subsystem: subsystem, category: "INFO"), "%{public}@", message)
    }

    static func logError(_ error: Error) {
        os_log(.error, log: OSLog(subsystem: subsystem, category: "ERROR"), "%{public}@", error.localizedDescription)
    }
}
