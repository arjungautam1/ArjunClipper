import Foundation

public final class ClippingStore: ObservableObject {
    public static let shared = ClippingStore()
    
    @Published public private(set) var clippings: [Clipping] = []
    
    private let queue = DispatchQueue(label: "com.arjun.arjunclipper.clippingstore", qos: .userInitiated)
    private let storageURL: URL
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ArjunClipper", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let targetURL = dir.appendingPathComponent("clippings.json")
        
        // Migrate existing ArjunCopy history if available
        let oldDir = appSupport.appendingPathComponent("ArjunCopy", isDirectory: true)
        let oldURL = oldDir.appendingPathComponent("clippings.json")
        if !FileManager.default.fileExists(atPath: targetURL.path) && FileManager.default.fileExists(atPath: oldURL.path) {
            try? FileManager.default.copyItem(at: oldURL, to: targetURL)
        }
        
        self.storageURL = targetURL
        load()
    }
    
    public func add(content: String, sourceAppName: String?, sourceBundleId: String?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Check sequential duplicates if enabled
            if PreferencesManager.shared.filter.ignoreSequentialDuplicates,
               let first = self.clippings.first, first.content == content {
                return
            }
            
            // If already present earlier in history, bring it to the top (MRU behavior like Flycut)
            var current = self.clippings
            if let existingIndex = current.firstIndex(where: { $0.content == content }) {
                let existing = current.remove(at: existingIndex)
                let updated = Clipping(
                    id: existing.id,
                    content: existing.content,
                    timestamp: Date(),
                    sourceAppName: sourceAppName ?? existing.sourceAppName,
                    sourceBundleId: sourceBundleId ?? existing.sourceBundleId,
                    isPinned: existing.isPinned
                )
                current.insert(updated, at: 0)
            } else {
                let newClip = Clipping(
                    content: content,
                    timestamp: Date(),
                    sourceAppName: sourceAppName,
                    sourceBundleId: sourceBundleId,
                    isPinned: false
                )
                current.insert(newClip, at: 0)
            }
            
            // Apply historyLimit eviction, preserving pinned items
            let limit = PreferencesManager.shared.historyLimit
            if current.count > limit {
                var pruned: [Clipping] = []
                var unpinnedCount = 0
                
                for clip in current {
                    if clip.isPinned {
                        pruned.append(clip)
                    } else if unpinnedCount < limit {
                        pruned.append(clip)
                        unpinnedCount += 1
                    }
                }
                current = pruned
            }
            
            DispatchQueue.main.async {
                self.clippings = current
                self.save()
            }
        }
    }
    
    public func togglePin(id: UUID) {
        queue.async { [weak self] in
            guard let self = self else { return }
            var current = self.clippings
            if let index = current.firstIndex(where: { $0.id == id }) {
                current[index].isPinned.toggle()
                DispatchQueue.main.async {
                    self.clippings = current
                    self.save()
                }
            }
        }
    }
    
    public func delete(id: UUID) {
        queue.async { [weak self] in
            guard let self = self else { return }
            var current = self.clippings
            current.removeAll { $0.id == id }
            DispatchQueue.main.async {
                self.clippings = current
                self.save()
            }
        }
    }
    
    public func clearAllUnpinned() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let kept = self.clippings.filter { $0.isPinned }
            DispatchQueue.main.async {
                self.clippings = kept
                self.save()
            }
        }
    }
    
    public func filtered(query: String) -> [Clipping] {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return clippings
        }
        return clippings.filter {
            $0.content.localizedCaseInsensitiveContains(query) ||
            ($0.sourceAppName?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(clippings)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Failed to save clippings: \(error)")
        }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path),
              let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([Clipping].self, from: data) else {
            return
        }
        self.clippings = decoded
    }
}
