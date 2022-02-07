import AppKit

struct AirDropTask {
    let onExecutionEnd: () -> Void
    let itemsToSend: [Any]
}

extension AirDropTask {
    struct MissingServiceError: Error {}
    struct UnsupportedItemsError: Error {}

    func execute() throws -> Void {
        guard let service = NSSharingService(named: .sendViaAirDrop) else {
            throw MissingServiceError()
        }

        if !service.canPerform(withItems: itemsToSend) {
            throw UnsupportedItemsError()
        }
    
        let delegate = DefaultSharingServiceDelegate(onSharingEnd: onExecutionEnd)
        service.delegate = delegate
        service.perform(withItems: itemsToSend)
    }
}

private class DefaultSharingServiceDelegate: NSObject, NSSharingServiceDelegate {
    private let onSharingEnd: () -> Void

    init(onSharingEnd: @escaping () -> Void) {
        self.onSharingEnd = onSharingEnd
    }

    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        onSharingEnd()
    }

    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        onSharingEnd()
    }

    func sharingService(_ sharingService: NSSharingService, sourceFrameOnScreenForShareItem item: Any) -> NSRect {
        return NSRect(x: 0, y: 0, width: 400, height: 100)
    }

    func sharingService(_ sharingService: NSSharingService, sourceWindowForShareItems items: [Any], sharingContentScope: UnsafeMutablePointer<NSSharingService.SharingContentScope>) -> NSWindow? {
        let airDropMenuWindow = NSWindow(
            contentRect: .init(origin: .zero, size: .init(width: 1, height: 1)),
            styleMask: [.closable],
            backing: .buffered,
            defer: false
        )

        airDropMenuWindow.center()
        airDropMenuWindow.level = .popUpMenu

        return airDropMenuWindow
    }
}
