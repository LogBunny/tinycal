import SwiftUI

@main
struct MenuBarCalendarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView() // No main window needed
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    private let calendar = Calendar.current
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Set up the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 500)
        popover.behavior = .transient
        
        // Create the SwiftUI view and host it
        let calendarView = CalendarView()
        popover.contentViewController = NSHostingController(rootView: calendarView)
        
        // Initial title setup
        updateStatusItemTitle()
        
        // Configure the status item button
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }
    
    // Update the menubar title with date and task count
    private func updateStatusItemTitle() {
        if let hostingController = popover.contentViewController as? NSHostingController<CalendarView> {
            let tasks = hostingController.rootView.tasks
            let today = calendar.startOfDay(for: Date())
            let taskCount = tasks[today]?.count ?? 0
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            statusItem.button?.title = "\(formatter.string(from: Date())) (\(taskCount))"
        }
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                updateStatusItemTitle() // Update title when popover opens
            }
        }
    }
}
