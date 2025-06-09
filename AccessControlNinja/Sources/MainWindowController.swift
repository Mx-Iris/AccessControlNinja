import AppKit

final class MainWindowController: NSWindowController {
    static let shared = MainWindowController()

    lazy var mainViewController = MainViewController()

    override var windowNibName: NSNib.Name? { "" }

    init() {
        super.init(window: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadWindow() {
        window = NSWindow(contentViewController: mainViewController)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.title = "AccessControlNinja for Xcode"
        window?.center()
        window?.styleMask.remove(.resizable)
        window?.titlebarAppearsTransparent = true
        window?.setFrameAutosaveName("Main Window")
    }
}
