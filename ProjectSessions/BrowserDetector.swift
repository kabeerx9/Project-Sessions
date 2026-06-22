import AppKit

enum BrowserDetector {
    static var installedSupportedBrowsers: [Browser] {
        let installedBrowsers = Browser.allCases.filter { browser in
            isInstalled(browser)
        }

        if installedBrowsers.isEmpty {
            print("[Project Sessions Debug] Could not detect installed supported browsers. Falling back to Safari.")
            return [.safari]
        }

        return installedBrowsers
    }

    static func isInstalled(_ browser: Browser) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleIdentifier) != nil
    }
}
