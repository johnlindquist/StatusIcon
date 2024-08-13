import Cocoa
import SwiftUI

@main
struct StatusBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var fileWatcher: DispatchSourceFileSystemObject?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let icon = parseCommandLineArguments()
        createStatusBarItem(icon: icon)
        setupFileWatcher()
    }
    
    func parseCommandLineArguments() -> String {
        let arguments = CommandLine.arguments
        if let iconIndex = arguments.firstIndex(of: "--icon"),
           iconIndex + 1 < arguments.count {
            return arguments[iconIndex + 1]
        }
        return "square.fill" // Default icon
    }
    
    func createStatusBarItem(icon: String) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: icon, accessibilityDescription: icon)
            button.image?.isTemplate = true
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        statusBarItem?.menu = createMenu()
    }
    
    func createMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        return menu
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)

@objc func openSettings() {
    // Placeholder for opening settings
    print("Settings menu item clicked")
}
    }
    
    @objc func statusBarButtonClicked() {
        statusBarItem?.button?.performClick(nil)
    }
    
    func setupFileWatcher() {
        let filePath = NSString(string: "~/.status").expandingTildeInPath
        let fileURL = URL(fileURLWithPath: filePath)
        
        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: filePath) {
            do {
                try "square.fill".write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Error creating file: \(error)")
                return
            }
        }
        
        let fileDescriptor = open(filePath, O_EVTONLY)
        if fileDescriptor < 0 {
            print("Error opening file")
            return
        }
        
        fileWatcher = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.main
        )
        
        fileWatcher?.setEventHandler { [weak self] in
            self?.handleFileChange(at: fileURL)
        }
        
        fileWatcher?.setCancelHandler {
            close(fileDescriptor)
        }
        
        fileWatcher?.resume()
    }
    
    func handleFileChange(at url: URL) {
        do {
            let contents = try String(contentsOf: url, encoding: .utf8)
            let trimmedContents = contents.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedContents.isEmpty {
                hideStatusBarIcon()
            } else {
                showStatusBarIcon()
                updateStatusBarIcon(with: trimmedContents)
            }
        } catch {
            print("Error reading file: \(error)")
        }
    }
    
    func hideStatusBarIcon() {
        statusBarItem?.isVisible = false
    }
    
    func showStatusBarIcon() {
        statusBarItem?.isVisible = true
    }
    
    func updateStatusBarIcon(with symbolName: String) {
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: symbolName)
            button.image?.isTemplate = true
        }
    }
}