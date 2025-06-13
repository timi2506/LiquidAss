import Foundation
import CoreFoundation
import Combine

class SolariumPreference: ObservableObject {
    @Published var isDisabled: Bool {
        didSet {
            setSolariumDisabled(isDisabled)
        }
    }
    
    init() {
        self.isDisabled = Self.readSolariumDisabled()
    }

    func refresh() {
        self.isDisabled = Self.readSolariumDisabled()
    }
    
    static func readSolariumDisabled() -> Bool {
        guard let value = CFPreferencesCopyValue(
            "com.apple.SwiftUI.DisableSolarium" as CFString,
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        ) as? Bool else {
            return false
        }
        return value
    }
    
    private func setSolariumDisabled(_ disabled: Bool) {
        CFPreferencesSetValue(
            "com.apple.SwiftUI.DisableSolarium" as CFString,
            disabled as CFBoolean,
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
        CFPreferencesSynchronize(
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
    }
}
