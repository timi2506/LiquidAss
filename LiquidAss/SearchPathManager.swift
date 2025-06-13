import SwiftUI
import Combine

class SearchPathManager: ObservableObject {
    static let shared = SearchPathManager()
    var prefs = AppPreferences.shared
    @Published var paths: [String] = [
        "/Applications"
    ] {
        didSet { searchPaths() }
    }
    @Published var customBundleIDs: [String] = [
        "com.apple.Finder"
    ] {
        didSet { searchPaths() }
    }
    @Published var ignoredIDs: [String] = []{
        didSet { searchPaths() }
    }
    
    func searchPaths() {
        prefs.removeAll()
        for path in paths {
            for id in extractBundleIdentifiers(in: path) {
                if applicationName(for: id) != nil, !ignoredIDs.contains(id) {
                    prefs.addBundleIdentifier(id)
                }
            }
        }
        for customBundleId in customBundleIDs {
            if applicationName(for: customBundleId) != nil, !ignoredIDs.contains(customBundleId) {
                prefs.addBundleIdentifier(customBundleId)
            }
        }
        
    }
    
    func appendPath(_ path: String) {
        if !paths.contains(path) {
            paths.append(path)
        }
    }
    func appendURL(_ folderURL: URL) {
        appendPath(folderURL.path())
    }
    func addApp(_ app: URL) {
        app.startAccessingSecurityScopedResource()
        if let id = extractBundleID(for: app) {
            customBundleIDs.append(
                id
            )
        }
        app.stopAccessingSecurityScopedResource()
    }
    func extractBundleID(for fileURL: URL) -> String? {
        let infoPlistURL = fileURL.appendingPathComponent("Contents/Info.plist")
        if let infoPlistData = try? Data(contentsOf: infoPlistURL),
           let plist = try? PropertyListSerialization.propertyList(from: infoPlistData, options: [], format: nil),
           let infoDict = plist as? [String: Any],
           let bundleID = infoDict["CFBundleIdentifier"] as? String {
            return bundleID
        } else {
            return nil
        }
    }
    func extractBundleIdentifiers(in folderURL: URL) -> [String] {
        let fileManager = FileManager.default
        var bundleIdentifiers: [String] = []
        
        guard let directoryEnumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        
        for case let fileURL as URL in directoryEnumerator {
            guard fileURL.pathExtension == "app" else { continue }
            
            let infoPlistURL = fileURL.appendingPathComponent("Contents/Info.plist")
            if let infoPlistData = try? Data(contentsOf: infoPlistURL),
               let plist = try? PropertyListSerialization.propertyList(from: infoPlistData, options: [], format: nil),
               let infoDict = plist as? [String: Any],
               let bundleID = infoDict["CFBundleIdentifier"] as? String {
                bundleIdentifiers.append(bundleID)
            }
        }
        
        return bundleIdentifiers
    }

    func extractBundleIdentifiers(in path: String) -> [String] {
        return extractBundleIdentifiers(in: URL(fileURLWithPath: path))
    }
}
