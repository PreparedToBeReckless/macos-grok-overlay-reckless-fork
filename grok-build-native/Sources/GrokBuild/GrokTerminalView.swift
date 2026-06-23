import AppKit

/// Terminal view that reliably accepts keyboard, paste, and dictation input.
final class GrokTerminalView: LocalProcessTerminalView {
    private var scrollAccumulator: CGFloat = 0
    private let scrollLineThreshold: CGFloat = 5.0
    private let alternateScrollLineThreshold: CGFloat = 12.0

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override func scrollWheel(with event: NSEvent) {
        let delta = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.deltaY
        guard delta != 0 else { return }

        if terminal.isCurrentBufferAlternate {
            scrollAccumulator += delta
            while scrollAccumulator >= alternateScrollLineThreshold {
                sendKeyUp()
                scrollAccumulator -= alternateScrollLineThreshold
            }
            while scrollAccumulator <= -alternateScrollLineThreshold {
                sendKeyDown()
                scrollAccumulator += alternateScrollLineThreshold
            }
            return
        }

        if !event.hasPreciseScrollingDeltas {
            let velocity = scrollingVelocity(for: abs(delta))
            if delta > 0 {
                scrollUp(lines: velocity)
            } else {
                scrollDown(lines: velocity)
            }
            return
        }

        scrollAccumulator += delta
        while scrollAccumulator >= scrollLineThreshold {
            scrollUp(lines: 1)
            scrollAccumulator -= scrollLineThreshold
        }
        while scrollAccumulator <= -scrollLineThreshold {
            scrollDown(lines: 1)
            scrollAccumulator += scrollLineThreshold
        }
    }

    private func scrollingVelocity(for delta: CGFloat) -> Int {
        if delta > 9 {
            return max(terminal.rows / 2, 5)
        }
        if delta > 5 {
            return 4
        }
        if delta > 1 {
            return 2
        }
        return 1
    }

    override func insertText(_ string: Any, replacementRange: NSRange) {
        let text: String?
        switch string {
        case let value as String:
            text = value
        case let value as NSString:
            text = value as String
        case let value as NSAttributedString:
            text = value.string
        default:
            text = nil
        }
        guard let text else { return }
        send(txt: text)
    }

    @objc func pasteAsPlainText(_ sender: Any) {
        paste(sender)
    }
}