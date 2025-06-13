//
//  LiquidAssApp.swift
//  LiquidAss
//
//  Created by Tim on 12.06.25.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct LiquidAssApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        Settings {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @StateObject var pathManager = SearchPathManager.shared
    @State var addFolder = false
    @State var importApp = false
    var body: some View {
        List {
            Section(content: {
                ForEach(pathManager.paths, id: \.self) { path in
                    HStack {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                        VStack(alignment: .leading) {
                            Text(URL(fileURLWithPath: path).lastPathComponent)
                            Text(path)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    }
                }
                .onDelete {
                    pathManager.paths.remove(atOffsets: $0)
                }
                if pathManager.paths.isEmpty {
                    Text("No Search Paths added")
                        .foregroundStyle(.gray)
                }
            }, header: {
                HStack {
                    Text("Search Paths")
                    Spacer()
                    Button("Add", systemImage: "plus") { addFolder.toggle() }
                        .labelStyle(.iconOnly)
                }
            })
            Section(content: {
                ForEach(pathManager.customBundleIDs, id: \.self) { bundleID in
                    HStack {
                        Image(nsImage: getIcon(bundleID: bundleID) ?? NSImage(systemSymbolName: "questionmark", accessibilityDescription: nil)!)
                        VStack(alignment: .leading) {
                            Text(applicationName(for: bundleID) ?? "Unknown Name")
                            Text(bundleID)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    }
                }
                .onDelete {
                    pathManager.customBundleIDs.remove(atOffsets: $0)
                }
                if pathManager.customBundleIDs.isEmpty {
                    Text("No Custom Apps")
                        .foregroundStyle(.gray)
                }
            }, header: {
                HStack {
                    Text("Custom Individual Apps")
                    Spacer()
                    Button("Add", systemImage: "plus") { importApp.toggle() }
                        .labelStyle(.iconOnly)
                }
            })
            Section(content: {
                ForEach(pathManager.ignoredIDs, id: \.self) { bundleID in
                    HStack {
                        Image(nsImage: getIcon(bundleID: bundleID) ?? NSImage(systemSymbolName: "questionmark", accessibilityDescription: nil)!)
                        VStack(alignment: .leading) {
                            Text(applicationName(for: bundleID) ?? "Unknown Name")
                            Text(bundleID)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    }
                }
                .onDelete {
                    pathManager.ignoredIDs.remove(atOffsets: $0)
                }
                if pathManager.ignoredIDs.isEmpty {
                    Text("No Ignored Apps")
                        .foregroundStyle(.gray)
                }
            }, header: {
                HStack {
                    Text("Ignored Apps")
                    Spacer()
                }
            }, footer: {
                Text("To add Apps to the Ignore List, right click them in the main UI and press \"Ignore\"")
                    .font(.caption)
                    .foregroundStyle(.gray)
            })
        }
        .listStyle(.inset)
        .fileImporter(isPresented: $addFolder, allowedContentTypes: [.folder], onCompletion: { result in
            switch result {
            case .success(let success):
                    pathManager.appendURL(success)
            case .failure(let failure):
                print(failure)
            }
        })
        .fileImporter(isPresented: $importApp, allowedContentTypes: [.application], onCompletion: { result in
            switch result {
            case .success(let success):
                pathManager.addApp(success)
            case .failure(let failure):
                print(failure)
            }
        })
    }
}
