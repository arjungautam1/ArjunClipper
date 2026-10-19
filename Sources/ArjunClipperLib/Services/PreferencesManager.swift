import Foundation

public final class PreferencesManager: ObservableObject {
    public static let shared = PreferencesManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let historyLimit = "arjunclipper_historyLimit"
        static let displayLimit = "arjunclipper_displayLimit"
        static let previewLength = "arjunclipper_previewLength"
        static let filter = "arjunclipper_filter"
        static let launchAtLogin = "arjunclipper_launchAtLogin"
        static let showMenuBarTitle = "arjunclipper_showMenuBarTitle"
        static let cleanAIMarkdown = "arjunclipper_cleanAIMarkdown"
    }
    
    @Published public var historyLimit: Int {
        didSet { defaults.set(historyLimit, forKey: Keys.historyLimit) }
    }
    
    @Published public var displayLimit: Int {
        didSet { defaults.set(displayLimit, forKey: Keys.displayLimit) }
    }
    
    @Published public var previewLength: Int {
        didSet { defaults.set(previewLength, forKey: Keys.previewLength) }
    }
    
    @Published public var cleanAIMarkdown: Bool {
        didSet { defaults.set(cleanAIMarkdown, forKey: Keys.cleanAIMarkdown) }
    }
    
    @Published public var filter: CopyFilter {
        didSet {
            if let data = try? JSONEncoder().encode(filter) {
                defaults.set(data, forKey: Keys.filter)
            }
        }
    }
    
    @Published public var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }
    
    @Published public var showMenuBarTitle: Bool {
        didSet {
            defaults.set(showMenuBarTitle, forKey: Keys.showMenuBarTitle)
        }
    }
    
    private init() {
        // Default history capacity: 100 (configurable up to 2000)
        let savedHistory = defaults.integer(forKey: Keys.historyLimit)
        self.historyLimit = savedHistory > 0 ? savedHistory : 100
        
        // Default menu show limit: 20 (configurable 5 to 100)
        let savedDisplay = defaults.integer(forKey: Keys.displayLimit)
        self.displayLimit = savedDisplay > 0 ? savedDisplay : 20
        
        // Default character preview length: 45 chars
        let savedPreview = defaults.integer(forKey: Keys.previewLength)
        self.previewLength = savedPreview > 0 ? savedPreview : 45
        
        // Load or initialize filters
        if let data = defaults.data(forKey: Keys.filter),
           let decoded = try? JSONDecoder().decode(CopyFilter.self, from: data) {
            self.filter = decoded
        } else {
            self.filter = CopyFilter()
        }
        
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        
        if defaults.object(forKey: Keys.showMenuBarTitle) != nil {
            self.showMenuBarTitle = defaults.bool(forKey: Keys.showMenuBarTitle)
        } else {
            self.showMenuBarTitle = false
        }
        
        if defaults.object(forKey: Keys.cleanAIMarkdown) != nil {
            self.cleanAIMarkdown = defaults.bool(forKey: Keys.cleanAIMarkdown)
        } else {
            self.cleanAIMarkdown = true
        }
    }
}
