import Cocoa
import SwiftUI
import Carbon

typealias EventHandlerRef = OpaquePointer
typealias EventHotKeyRef = OpaquePointer

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
    var eventHandler: EventHandlerRef?
    var hotKeyRef: EventHotKeyRef?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let icon = parseCommandLineArguments()
        createStatusBarItem(icon: icon)
        setupFileWatcher()
        setupHotKey()
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
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        return menu
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
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

    func setupHotKey() {
        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.id = 1
        gMyHotKeyID.signature = OSType(fourCharCode: "MYHT")

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)

        // Install handler
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            let appDelegate = unsafeBitCast(userData, to: AppDelegate.self)
            appDelegate.toggleStatusBarIcon()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)

        // Register hot key (Cmd+4)
        RegisterEventHotKey(UInt32(kVK_ANSI_4), UInt32(cmdKey), gMyHotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func toggleStatusBarIcon() {
        if let isVisible = statusBarItem?.isVisible {
            statusBarItem?.isVisible = !isVisible
        }
    }

    func cleanupHotKey() {
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        cleanupHotKey()
    }
}