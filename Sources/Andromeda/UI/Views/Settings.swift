//
//  Settings.swift
//  Andromeda
//
//  Created by WithAndromeda on 11/23/24.
//

#if os(macOS)
import SwiftUI

struct PrivacySettings: Codable {
    var enableJavaScript: Bool
    var allowThirdPartyCookies: Bool
    var historyRetentionPeriod: Int
    var siteRules: [SiteRule]
    
    static let `default` = PrivacySettings(
        enableJavaScript: true,
        allowThirdPartyCookies: false,
        historyRetentionPeriod: 30,
        siteRules: []
    )
}

class SettingsManager: ObservableObject {
    @Published var privacySettings: PrivacySettings {
        didSet {
            saveSettings()
        }
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "privacySettings"),
           let settings = try? JSONDecoder().decode(PrivacySettings.self, from: data) {
            self.privacySettings = settings
        } else {
            self.privacySettings = .default
        }
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(privacySettings) {
            UserDefaults.standard.set(encoded, forKey: "privacySettings")
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    let closeAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                PrivacyView(settings: settingsManager)
                    .tabItem {
                        Label("Privacy", systemImage: "lock.shield")
                    }
                
                SiteRulesView(settings: settingsManager)
                    .tabItem {
                        Label("Site Rules", systemImage: "list.bullet")
                    }
            }
            .padding()
            .frame(width: 500, height: 350)
            
            HStack {
                Spacer()
                Button("Close", action: closeAction)
                    .keyboardShortcut(.defaultAction)
                    .padding(.trailing)
                    .padding(.bottom)
            }
        }
    }
}

struct PrivacyView: View {
    @ObservedObject var settings: SettingsManager
    
    private let retentionPeriods = [
        1: "1 day",
        7: "1 week",
        30: "30 days",
        90: "90 days",
        365: "1 year",
        -1: "Never"
    ]
    
    var body: some View {
        Form {
            Section(header: Text("Browser Privacy").bold()) {
                Toggle("Enable JavaScript", isOn: $settings.privacySettings.enableJavaScript)
                Toggle("Allow Third-Party Cookies", isOn: $settings.privacySettings.allowThirdPartyCookies)
                
                Picker("Delete History", selection: $settings.privacySettings.historyRetentionPeriod) {
                    ForEach(Array(retentionPeriods.keys.sorted()), id: \.self) { days in
                        Text(retentionPeriods[days] ?? "")
                            .tag(days)
                    }
                }
            }
            .padding()
        }
    }
}

struct SiteRulesView: View {
    @ObservedObject var settings: SettingsManager
    @State private var showingAddRule = false
    @State private var newPattern = ""
    @State private var newAllowJS: Bool?
    @State private var newAllowCookies: Bool?
    
    var body: some View {
        VStack {
            List {
                ForEach(settings.privacySettings.siteRules) { rule in
                    VStack(alignment: .leading) {
                        Text(rule.pattern)
                            .font(.headline)
                        if let js = rule.allowJavaScript {
                            Text("JavaScript: \(js ? "Allowed" : "Blocked")")
                                .font(.caption)
                        }
                        if let cookies = rule.allowThirdPartyCookies {
                            Text("Third-party Cookies: \(cookies ? "Allowed" : "Blocked")")
                                .font(.caption)
                        }
                    }
                }
                .onDelete { indexSet in
                    settings.privacySettings.siteRules.remove(atOffsets: indexSet)
                }
            }
            
            Button("Add Rule") {
                showingAddRule = true
            }
        }
        .sheet(isPresented: $showingAddRule) {
            Form {
                TextField("URL Pattern (e.g. *://example.com/*)", text: $newPattern)
                
                Picker("JavaScript", selection: .init(
                    get: { newAllowJS == nil ? 0 : (newAllowJS! ? 1 : 2) },
                    set: { newAllowJS = $0 == 0 ? nil : ($0 == 1) }
                )) {
                    Text("Use Default").tag(0)
                    Text("Allow").tag(1)
                    Text("Block").tag(2)
                }
                
                Picker("Third-party Cookies", selection: .init(
                    get: { newAllowCookies == nil ? 0 : (newAllowCookies! ? 1 : 2) },
                    set: { newAllowCookies = $0 == 0 ? nil : ($0 == 1) }
                )) {
                    Text("Use Default").tag(0)
                    Text("Allow").tag(1)
                    Text("Block").tag(2)
                }
                
                Button("Add") {
                    let rule = SiteRule(
                        pattern: newPattern,
                        allowJavaScript: newAllowJS,
                        allowThirdPartyCookies: newAllowCookies
                    )
                    settings.privacySettings.siteRules.append(rule)
                    showingAddRule = false
                    newPattern = ""
                    newAllowJS = nil
                    newAllowCookies = nil
                }
                .disabled(newPattern.isEmpty)
                
                Button("Cancel") {
                    showingAddRule = false
                }
            }
            .padding()
            .frame(width: 400, height: 300)
        }
    }
}
#endif