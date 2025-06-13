import Foundation
import SwiftUI
import Combine

class AppPreferences: ObservableObject {
    static let shared = AppPreferences()
    
    @Published private(set) var values: [String: Bool] = [:]

    private let key: CFString = "com.apple.SwiftUI.DisableSolarium" as CFString

    init(bundleIdentifiers: [String]) {
        for bundleID in bundleIdentifiers {
            let currentValue = Self.readPreference(for: bundleID)
            values[bundleID] = currentValue
        }
    }
    init() {
        let currentValue = Self.readPreference(for: "com.apple.Finder")
        values["com.apple.Finder"] = currentValue
    }

    private static func readPreference(for bundleIdentifier: String) -> Bool {
        let appID = bundleIdentifier as CFString
        if let rawValue = CFPreferencesCopyAppValue("com.apple.SwiftUI.DisableSolarium" as CFString, appID) as? Bool {
            return rawValue
        } else {
            return false
        }
    }

    private func setPreference(for bundleID: String, to newValue: Bool) {
        let appID = bundleID as CFString
        CFPreferencesSetAppValue(key, newValue as CFBoolean, appID)
        CFPreferencesAppSynchronize(appID)
    }

    func setValue(_ newValue: Bool, for bundleID: String) {
        values[bundleID] = newValue
        setPreference(for: bundleID, to: newValue)
    }

    func addBundleIdentifier(_ bundleID: String) {
        guard values[bundleID] == nil else { return }
        let currentValue = Self.readPreference(for: bundleID)
        values[bundleID] = currentValue
    }

    func reload() {
        for bundleID in values.keys {
            values[bundleID] = Self.readPreference(for: bundleID)
        }
    }

    func binding(for bundleID: String, onSet: @escaping (Bool) -> Void) -> Binding<Bool> {
        Binding(
            get: { self.values[bundleID, default: false] },
            set: { newValue in
                self.setValue(newValue, for: bundleID)
                onSet(newValue)
            }
        )
    }
    func remove(_ bundleID: String) {
        values.removeValue(forKey: bundleID)
    }
    func removeAll() {
        values.removeAll()
    }
}
