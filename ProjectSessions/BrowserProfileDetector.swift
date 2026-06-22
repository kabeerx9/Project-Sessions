import Foundation

enum BrowserProfileDetector {
    static func profiles(for browser: Browser) -> [BrowserProfile] {
        guard let localStateURL = localStateURL(for: browser) else {
            return []
        }

        guard let data = try? Data(contentsOf: localStateURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profile = json["profile"] as? [String: Any],
              let infoCache = profile["info_cache"] as? [String: Any] else {
            print("[Project Sessions Debug] Could not detect \(browser.rawValue) profiles at \(localStateURL.path)")
            return []
        }

        return infoCache.compactMap { directoryName, value in
            guard let profileInfo = value as? [String: Any] else {
                return nil
            }

            let displayName = profileInfo["name"] as? String ?? directoryName

            return BrowserProfile(
                directoryName: directoryName,
                displayName: displayName
            )
        }
        .sorted { first, second in
            first.displayName.localizedCaseInsensitiveCompare(second.displayName) == .orderedAscending
        }
    }

    private static func localStateURL(for browser: Browser) -> URL? {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first

        switch browser {
        case .chrome:
            return applicationSupportURL?
                .appendingPathComponent("Google", isDirectory: true)
                .appendingPathComponent("Chrome", isDirectory: true)
                .appendingPathComponent("Local State")
        case .brave:
            return applicationSupportURL?
                .appendingPathComponent("BraveSoftware", isDirectory: true)
                .appendingPathComponent("Brave-Browser", isDirectory: true)
                .appendingPathComponent("Local State")
        case .edge:
            return applicationSupportURL?
                .appendingPathComponent("Microsoft Edge", isDirectory: true)
                .appendingPathComponent("Local State")
        case .safari, .firefox:
            return nil
        }
    }
}
