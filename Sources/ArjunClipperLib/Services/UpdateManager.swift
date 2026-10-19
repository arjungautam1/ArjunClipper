import Foundation
import AppKit

public struct UpdateInfo: Codable {
    public let version: String
    public let build: Int
    public let releaseNotes: String
    public let downloadUrl: String
}

public final class UpdateManager {
    public static let shared = UpdateManager()
    
    public var currentVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0"
    }
    
    private let primaryVersionURL = URL(string: "https://raw.githubusercontent.com/arjungautam1/ArjunClipper/main/version.json")!
    private let fallbackVersionURL = URL(string: "https://arjunclipper.vercel.app/version.json")!
    
    private init() {}
    
    public func checkForUpdates(silent: Bool = false) {
        fetchUpdateInfo(from: primaryVersionURL) { [weak self] result in
            switch result {
            case .success(let info):
                self?.handleUpdateInfo(info, silent: silent)
            case .failure:
                // Try fallback URL
                guard let self = self else { return }
                self.fetchUpdateInfo(from: self.fallbackVersionURL) { fallbackResult in
                    switch fallbackResult {
                    case .success(let info):
                        self.handleUpdateInfo(info, silent: silent)
                    case .failure(let error):
                        if !silent {
                            DispatchQueue.main.async {
                                self.showErrorAlert(message: "Unable to check for updates: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fetchUpdateInfo(from url: URL, completion: @escaping (Result<UpdateInfo, Error>) -> Void) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 8.0)
        request.setValue("ArjunClipper/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "UpdateManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty response"])))
                return
            }
            do {
                let info = try JSONDecoder().decode(UpdateInfo.self, from: data)
                completion(.success(info))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func handleUpdateInfo(_ info: UpdateInfo, silent: Bool) {
        let hasNewVersion = isVersion(info.version, greaterThan: currentVersion)
        
        DispatchQueue.main.async {
            if hasNewVersion {
                self.showUpdateAvailableAlert(info: info)
            } else if !silent {
                self.showUpToDateAlert()
            }
        }
    }
    
    private func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
        return v1.compare(v2, options: .numeric) == .orderedDescending
    }
    
    private func showUpToDateAlert() {
        let alert = NSAlert()
        alert.messageText = "You're Up to Date!"
        alert.informativeText = "ArjunClipper v\(currentVersion) is currently the newest version available."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
    
    private func showUpdateAvailableAlert(info: UpdateInfo) {
        let alert = NSAlert()
        alert.messageText = "ArjunClipper v\(info.version) is Available!"
        alert.informativeText = "A new version of ArjunClipper is ready to install.\n\nRelease Notes:\n\(info.releaseNotes)\n\nWould you like to update and restart now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Update & Restart")
        alert.addButton(withTitle: "Later")
        
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            performUpdateAndRestart(downloadUrlString: info.downloadUrl)
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
    
    public func performUpdateAndRestart(downloadUrlString: String) {
        guard let url = URL(string: downloadUrlString) else {
            showErrorAlert(message: "Invalid update download URL.")
            return
        }
        
        // Show non-blocking downloading indicator dialog
        let progressAlert = NSAlert()
        progressAlert.messageText = "Downloading ArjunClipper Update..."
        progressAlert.informativeText = "Please wait while the latest update is being downloaded and verified."
        progressAlert.alertStyle = .informational
        progressAlert.addButton(withTitle: "Cancel")
        
        let targetDMG = "/tmp/ArjunClipper_Update.dmg"
        try? FileManager.default.removeItem(atPath: targetDMG)
        
        var downloadTask: URLSessionDownloadTask?
        downloadTask = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showErrorAlert(message: "Download failed: \(error.localizedDescription)")
                }
                return
            }
            guard let tempURL = tempURL else { return }
            
            do {
                try FileManager.default.moveItem(at: tempURL, to: URL(fileURLWithPath: targetDMG))
                DispatchQueue.main.async {
                    self.applyUpdateAndRelaunch()
                }
            } catch {
                DispatchQueue.main.async {
                    self.showErrorAlert(message: "Failed to save update: \(error.localizedDescription)")
                }
            }
        }
        downloadTask?.resume()
    }
    
    private func applyUpdateAndRelaunch() {
        let scriptPath = "/tmp/arjunclipper_updater.sh"
        let scriptContent = """
        #!/usr/bin/env bash
        set -e
        # Wait 1.5 seconds for previous ArjunClipper process to quit completely
        sleep 1.5
        
        MOUNT_POINT="/tmp/arjunclipper_update_mount"
        rm -rf "$MOUNT_POINT"
        mkdir -p "$MOUNT_POINT"
        
        # Attach downloaded DMG quietly
        hdiutil attach "/tmp/ArjunClipper_Update.dmg" -nobrowse -mountpoint "$MOUNT_POINT" -quiet
        
        if [ -d "$MOUNT_POINT/ArjunClipper.app" ]; then
            rm -rf "/Applications/ArjunClipper.app"
            cp -R "$MOUNT_POINT/ArjunClipper.app" "/Applications/ArjunClipper.app"
            hdiutil detach "$MOUNT_POINT" -force -quiet || true
            rm -rf "$MOUNT_POINT" "/tmp/ArjunClipper_Update.dmg"
            
            # Reset quarantine and launch services
            xattr -dr com.apple.quarantine "/Applications/ArjunClipper.app" 2>/dev/null || true
            open -n "/Applications/ArjunClipper.app"
        fi
        rm -f "/tmp/arjunclipper_updater.sh"
        """
        
        do {
            try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            let perms = [FileAttributeKey.posixPermissions: 0o755]
            try FileManager.default.setAttributes(perms, ofItemAtPath: scriptPath)
            
            // Execute updater script in background detached from current process
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [scriptPath]
            try process.run()
            
            // Quit current app so updater can swap the bundle and relaunch
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        } catch {
            showErrorAlert(message: "Failed to execute updater: \(error.localizedDescription)")
        }
    }
}
