import SwiftUI
import AppKit

public struct PreferencesView: View {
    @ObservedObject var prefs = PreferencesManager.shared
    @ObservedObject var store = ClippingStore.shared
    
    @State private var selectedTab = 0
    @State private var newExcludedApp = ""
    @State private var customRegexInput = ""
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            displayLimitsTab
                .tabItem {
                    Label("Display & Storage", systemImage: "slider.horizontal.3")
                }
                .tag(0)
            
            copyControlTab
                .tabItem {
                    Label("Copy Controls", systemImage: "shield.checkered")
                }
                .tag(1)
            
            appExclusionTab
                .tabItem {
                    Label("App Exclusions", systemImage: "app.badge.xmark")
                }
                .tag(2)
            
            maintenanceTab
                .tabItem {
                    Label("Data", systemImage: "externaldrive")
                }
                .tag(3)
        }
        .padding(20)
        .frame(width: 540, height: 440)
    }
    
    // MARK: - Tab 1: Display & Storage Limits
    private var displayLimitsTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Display & Storage Control")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("History Capacity (To Remember):")
                    Spacer()
                    Text("\(prefs.historyLimit) items")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { Double(prefs.historyLimit) },
                        set: { prefs.historyLimit = Int($0) }
                    ),
                    in: 10...1000,
                    step: 10
                )
                Text("Standard legacy default was 100 max. ArjunClipper supports up to 1,000 items with memory safety.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Menu Show Count (In Dropdown):")
                    Spacer()
                    Text("\(prefs.displayLimit) items")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { Double(prefs.displayLimit) },
                        set: { prefs.displayLimit = Int($0) }
                    ),
                    in: 5...60,
                    step: 5
                )
                Text("Controls how many items are rendered directly in the menu bar dropdown.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Preview Text Truncation:")
                    Spacer()
                    Text("\(prefs.previewLength) chars")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { Double(prefs.previewLength) },
                        set: { prefs.previewLength = Int($0) }
                    ),
                    in: 20...100,
                    step: 5
                )
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Toggle("Show \"Arjun\" name next to icon in Menu Bar", isOn: Binding(
                get: { prefs.showMenuBarTitle },
                set: {
                    prefs.showMenuBarTitle = $0
                    MenuBarController.shared.updateStatusButton()
                }
            ))
            .padding(.horizontal, 4)
            
            Spacer()
        }
    }
    
    // MARK: - Tab 2: Copy Control & Filters
    private var copyControlTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What to Copy (Rules & Security)")
                    .font(.headline)
                
                GroupBox(label: Text("AI Tools Formatting (ChatGPT, Claude, Gemini)")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Auto-clean AI Markdown artifacts (**bold**, `code`, etc.)", isOn: $prefs.cleanAIMarkdown)
                        Text("Automatically removes raw asterisks like **word** and copies rich bold formatting directly so pasting into Google Docs, Word, or LinkedIn is clean and properly formatted.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(6)
                }
                
                GroupBox(label: Text("Sensitive Data Protection")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Ignore password managers (Transient / Concealed types)", isOn: $prefs.filter.ignoreTransientPasteboardTypes)
                        Toggle("Block private keys (PEM, RSA, OpenSSH)", isOn: $prefs.filter.blockPrivateKeys)
                        Toggle("Block credit card numbers", isOn: $prefs.filter.blockCreditCardNumbers)
                        Toggle("Block API keys & JWT bearer tokens", isOn: $prefs.filter.blockApiKeysAndTokens)
                    }
                    .padding(6)
                }
                
                GroupBox(label: Text("Content Cleanliness")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Ignore whitespace-only clippings", isOn: $prefs.filter.ignoreWhitespaceOnly)
                        Toggle("Ignore sequential identical copies", isOn: $prefs.filter.ignoreSequentialDuplicates)
                    }
                    .padding(6)
                }
                
                GroupBox(label: Text("Size Bounds")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Minimum length:")
                            Spacer()
                            TextField("Min", value: $prefs.filter.minLength, formatter: NumberFormatter())
                                .frame(width: 80)
                            Text("chars")
                        }
                        HStack {
                            Text("Maximum length:")
                            Spacer()
                            TextField("Max", value: $prefs.filter.maxLength, formatter: NumberFormatter())
                                .frame(width: 80)
                            Text("chars")
                        }
                    }
                    .padding(6)
                }
            }
        }
    }
    
    // MARK: - Tab 3: App Exclusions
    private var appExclusionTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Excluded Applications")
                .font(.headline)
            Text("Clipboard content copied while inside these applications will be ignored automatically.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            List {
                ForEach(Array(prefs.filter.excludedAppNames.sorted()), id: \.self) { appName in
                    HStack {
                        Image(systemName: "shield.slash.fill")
                            .foregroundColor(.orange)
                        Text(appName)
                        Spacer()
                        Button(action: {
                            prefs.filter.excludedAppNames.remove(appName)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .frame(maxHeight: 200)
            .border(Color(NSColor.separatorColor), width: 1)
            
            HStack {
                TextField("Add application name (e.g., Terminal, KeePassXC)", text: $newExcludedApp)
                Button("Add") {
                    let trimmed = newExcludedApp.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        prefs.filter.excludedAppNames.insert(trimmed)
                        newExcludedApp = ""
                    }
                }
                .disabled(newExcludedApp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Tab 4: Maintenance
    private var maintenanceTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Management")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Saved Clippings:")
                        .font(.subheadline)
                    Text("\(store.clippings.count) items (\(store.clippings.filter { $0.isPinned }.count) pinned)")
                        .font(.title3)
                        .bold()
                }
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Button(role: .destructive, action: {
                store.clearAllUnpinned()
            }) {
                Label("Clear All Unpinned Clippings", systemImage: "trash")
            }
            .padding(.top, 4)
            
            Divider()
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Software Updates")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ArjunClipper for Mac")
                            .font(.subheadline)
                            .bold()
                        Text("Version \(UpdateManager.shared.currentVersion) (Universal Binary)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        UpdateManager.shared.checkForUpdates(silent: false)
                    }) {
                        Label("Check for Updates…", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            Spacer()
        }
    }
}

public final class PreferencesWindowController: NSWindowController {
    public static let shared = PreferencesWindowController()
    
    private init() {
        let hostingView = NSHostingView(rootView: PreferencesView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 440),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "ArjunClipper Preferences"
        window.contentView = hostingView
        window.center()
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
