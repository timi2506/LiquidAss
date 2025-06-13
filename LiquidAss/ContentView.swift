//
//  ContentView.swift
//  LiquidAss
//
//  Created by Tim on 12.06.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    var body: some View {
        PreferencesView()
    }
}

struct PreferencesView: View {
    @StateObject var prefs = AppPreferences.shared
    @State var timerState: TimerState = .none
    @Namespace var namespace
    @State var failedID: BundleID?
    @State var searchText = ""
    @StateObject var globalManager = SolariumPreference()
    @StateObject var pathManager = SearchPathManager.shared
    @State var dropTargeted = false
    @State var forceID: BundleID?
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Choose All Apps which you want to force-disable Liquid Glass for")
                    .multilineTextAlignment(.leading)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding()
                List {
                    Section("Global") {
                        Toggle("Disable Liquid Glass Globally", isOn: $globalManager.isDisabled)
                            .toggleStyle(.switch)
                        Text("Disabled Liquid Glass for EVERY App on your Mac regardless of whether its ignored or removed from this List.")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Section(searchText.isEmpty ? "All Apps" : "Filtering by: \(searchText)") {
                        ForEach(prefs.values.keys.sorted(), id: \.self) { bundleID in
                            let app = BundleIDConstructedApp(bundleID: bundleID, applicationName: applicationName(for: bundleID))
                            if searchText.isEmpty || app.contains(searchText) {
                                HStack(alignment: .center) {
                                    Image(nsImage: (getIcon(bundleID: app.bundleID) ?? NSImage(systemSymbolName: "questionmark", accessibilityDescription: nil))!)
                                    VStack(alignment: .leading) {
                                        Text(app.applicationName ?? "Unknown Name")
                                            .lineLimit(1)
                                        Text(bundleID)
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Button("Remove from List", role: .destructive) {
                                        prefs.remove(bundleID)
                                    }
                                    Toggle("", isOn: prefs.binding(for: bundleID, onSet: {_ in
                                        let success = terminateApp(bundleIdentifier: bundleID)
                                        if !success {
                                            failedID = BundleID(bundleID: bundleID)
                                        }
                                    }))
                                    .toggleStyle(.switch)
                                    .frame(width: 45)
                                }
                                .contextMenu {
                                    Button("Ignore App from List") {
                                        pathManager.ignoredIDs.append(bundleID)
                                    }
                                    Button("EXPERIMENTAL: Force Liquid Glass") {
                                        forceID = BundleID(bundleID: bundleID)
                                    }
                                }
                            }
                        }
                    }
                    .disabled(globalManager.isDisabled)
                }
                .listStyle(DefaultListStyle())
                .scrollIndicators(.never)
                .cornerRadius(15)
                .padding(.horizontal)
                .popover(item: $failedID) { value in
                    Form {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Manual Termination Required")
                                Text("You need to manually terminate the Application for Changes to take affect")
                                    .multilineTextAlignment(.leading)
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            Button("Dismiss") {
                                failedID = nil
                            }
                        }
                        Section("App Info") {
                            HStack(alignment: .center) {
                                Image(nsImage: (getIcon(bundleID: value.bundleID) ?? NSImage(systemSymbolName: "questionmark", accessibilityDescription: nil))!)
                                VStack(alignment: .leading) {
                                    Text(applicationName(for: value.bundleID) ?? "Unknown Name")
                                        .lineLimit(1)
                                    Text(value.bundleID)
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                        Section("Possible Commands") {
                            Text("The following Command is most likely gonna work to terminate this App from Terminal, If it does not work you need to terminate the App from Activity Monitor. If you don't see the changes after terminating, try terminating again until it works, it might take 2-3 tries.")
                                .multilineTextAlignment(.leading)
                                .font(.caption)
                                .foregroundStyle(.gray)
                            if let appName = applicationName(for: value.bundleID) {
                                let command = "killall \"\(appName)\""
                                HStack {
                                    TextField("Command", text: .constant(command))
                                        .textFieldStyle(.plain)
                                    Spacer()
                                    Button("Copy") {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(command, forType: .string)
                                    }
                                    Button("Open Terminal") {
                                        let terminalURL = URL(string: "file:///System/Applications/Utilities/Terminal.app")!
                                        NSWorkspace.shared.open(terminalURL)
                                    }
                                }
                            } else {
                                Text("Command unavailable because the App Name for \"\(value.bundleID)\" couldn't be found")
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(.gray)
                                
                            }
                        }
                        .interactiveDismissDisabled(true)
                    }
                    .formStyle(.grouped)
                }
                .popover(item: $forceID) { value in
                    Form {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Experimentally Forcing Liquid Glass")
                                Text("Experimentally Forcing Liquid Glass works by Setting the User Default \"com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck\" to TRUE which will make SwiftUI Force Liquid Glass on the App, it is Experimental because unlike Force-disabling Liquid Glass, where we can just set the User Default using CFPreferences, we have to set it using defaults because issues occured when testing this with CFPreferences.")
                                    .multilineTextAlignment(.leading)
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            Button("Dismiss") {
                                forceID = nil
                            }
                        }
                        Section("App Info") {
                            HStack(alignment: .center) {
                                Image(nsImage: (getIcon(bundleID: value.bundleID) ?? NSImage(systemSymbolName: "questionmark", accessibilityDescription: nil))!)
                                VStack(alignment: .leading) {
                                    Text(applicationName(for: value.bundleID) ?? "Unknown Name")
                                        .lineLimit(1)
                                    Text(value.bundleID)
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                        VStack(alignment: .leading) {
                            Toggle("Force Liquid Glass", isOn: forceStatusBinding(for: value.bundleID))
                            Text("This uses a very experimental way of getting and setting the Force User Default, after changing you need to quit the App to allow changes to apply and if it didnt work you can always manually run the following Command: \n\ndefaults write \(value.bundleID) com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck -bool TRUE\n\n(Replace TRUE with FALSE if you want to disable Force Liquid Glass Instead)\n\nAlso make sure Force Disabling Liquid Glass is turned off because otherwise this will have no effect.")
                                .multilineTextAlignment(.leading)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                    .formStyle(.grouped)
                    .interactiveDismissDisabled(true)
                }
                    HStack {
                        Text("To add Custom Search Paths or Choose Apps go to Settings by pressing CMD + ,")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Spacer()
                        Button("Refresh") {
                            refresh()
                        }
                    }
                    
                .padding()
            }
        }
        .overlay {
            if dropTargeted {
                VStack(alignment: .center) {
                    Image(systemName: "arrow.down.app.dashed")
                        .font(.system(size: 75))
                        .bold()
                    Text("Drop to Add")
                        .font(.largeTitle)
                        .bold()
                }
                .padding(100)
                .background(
                    RoundedRectangle(cornerRadius: 35)
                        .foregroundStyle(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 35)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
            }
        }
        .animation(.default, value: dropTargeted)
        .onAppear {
            startTimer()
            ensureAccessibilityPermissionWithAlert()
            pathManager.searchPaths()
        }
        .searchable(text: $searchText, prompt: "Filter by Apps or Bundle ID")
        .toolbar {
            ToolbarItem(placement: .status) {
                GlassEffectContainer {
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(timerState.foregroundStyle())
                            .padding(7.5)
                            .glassEffect(.regular.interactive(timerState == .waiting))
                            .glassEffectUnion(id: "timerUnion", namespace: namespace)
                            .glassEffectTransition(.matchedGeometry)
                        Button("Toggle AutoRefresh") {
                            switch timerState {
                            case .running:
                                stopTimer()
                            case .stopped:
                                startTimer()
                            case .none:
                                startTimer()
                            case .waiting:
                                break
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(7.5)
                        .glassEffect(.regular.interactive(true))
                        .glassEffectUnion(id: "timerUnion", namespace: namespace)
                        .glassEffectTransition(.matchedGeometry)
                    }
                }
            }
        }
        .onOpenURL { url in
            pathManager.addApp(url)
            pathManager.searchPaths()
        }
    }
    @State var timer: Timer?
    @State var timerTime: Int = 5
    
    func startTimer() {
        timer?.invalidate()
        withAnimation {
            timerState = .waiting
        }
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true, block: { _ in
            withAnimation {
                timerState = .running
            }
            refresh()
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if timerState == .waiting {
                withAnimation {
                    timerState = .stopped
                }
            }
        }
    }
    func stopTimer() {
        withAnimation {
            timerState = .stopped
        }
        timer?.invalidate()
    }
    func refresh() {
        prefs.reload()
        globalManager.refresh()
    }
    func execute(_ command: String) -> String? {
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        process.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}

enum TimerState {
    case running
    case stopped
    case none
    case waiting
    
    func foregroundStyle() -> AnyShapeStyle {
        switch self {
        case .running:
            return AnyShapeStyle(.green)
        case .stopped:
            return AnyShapeStyle(.red)
        case .none:
            return AnyShapeStyle(.gray)
        case .waiting:
            return AnyShapeStyle(.orange)
        }
    }
}

func getIcon(bundleID: String) -> NSImage? {
    guard let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: bundleID)
    else { return nil }
    
    return getIcon(file: path)
}

func getIcon(file path: String) -> NSImage? {
    guard FileManager.default.fileExists(atPath: path)
    else { return nil }
    
    return NSWorkspace.shared.icon(forFile: path)
}

func applicationName(for bundleIdentifier: String) -> String? {
    guard let cfURLs = LSCopyApplicationURLsForBundleIdentifier(bundleIdentifier as CFString, nil)?.takeRetainedValue() as? [URL],
          let url = cfURLs.first else {
        return nil
    }
    
    let bundle = Bundle(url: url)
    return bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
}

func terminateApp(bundleIdentifier: String) -> Bool {
    let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
    var success = false
    
    for app in apps {
        if !app.terminate() {
            if app.forceTerminate() {
                success = true
            }
        } else {
            success = true
        }
    }
    
    return success
}

import AppKit
import ApplicationServices

func ensureAccessibilityPermissionWithAlert() {
    guard !AXIsProcessTrusted() else {
        print("Accessibility permission already granted.")
        return
    }
    
    let alert = NSAlert()
    alert.messageText = "Accessibility Permission Required"
    alert.informativeText = """
    This app needs Accessibility permission to quit other applications automatically. \
    Without this, you'll need to quit apps manually.
    
    To grant permission, click 'Open Settings', then check the box next to this app in the list.
    """
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Open Settings")
    alert.addButton(withTitle: "Cancel")
    
    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
        // Open the Accessibility privacy settings
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct BundleID: Identifiable {
    var id: String { bundleID }
    var bundleID: String
}

struct BundleIDConstructedApp: Identifiable {
    var id: String { bundleID }
    var bundleID: String
    var applicationName: String?
    
    func contains(_ string: String) -> Bool {
        var bool = false
        let check = self.applicationName ?? ""
        if check.lowercased().contains(string.lowercased()) {
            bool = true
        }
        if self.bundleID.contains(string.lowercased()) {
            bool = true
        }
        return bool
    }
}

import Foundation

let forceKey = "com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck"

func readForceStatus(for bundleID: String) -> Bool? {
    let task = Process()
    task.launchPath = "/usr/bin/defaults"
    task.arguments = ["read", bundleID, forceKey]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = Pipe()
    
    do {
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        else {
            return nil
        }
        
        return output == "1" || output == "true"
    } catch {
        print("Failed to read defaults: \(error)")
        return nil
    }
}

func setForceStatus(for bundleID: String, to value: Bool) {
    let task = Process()
    task.launchPath = "/usr/bin/defaults"
    task.arguments = ["write", bundleID, forceKey, "-bool", value ? "TRUE" : "FALSE"]
    
    do {
        try task.run()
        task.waitUntilExit()
    } catch {
        print("Failed to write defaults: \(error)")
    }
}

func toggleForceStatus(for bundleID: String) {
    let current = readForceStatus(for: bundleID) ?? false
    setForceStatus(for: bundleID, to: !current)
}

func forceStatusBinding(for bundleID: String) -> Binding<Bool> {
    Binding(
        get: { readForceStatus(for: bundleID) ?? false },
        set: { newValue in setForceStatus(for: bundleID, to: newValue) }
    )
}
