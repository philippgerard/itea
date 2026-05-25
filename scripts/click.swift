// Synthesizes a left-click at the given absolute screen coordinates using
// Quartz Event Services. Built-in macOS — no extra deps.
//
// Usage:  swift scripts/click.swift X Y
//
// Requires the parent process (Terminal, cmux, etc.) to have Accessibility
// permission (System Settings → Privacy & Security → Accessibility).

import Cocoa

guard CommandLine.arguments.count == 3,
      let x = Double(CommandLine.arguments[1]),
      let y = Double(CommandLine.arguments[2]) else {
    FileHandle.standardError.write("usage: swift click.swift X Y\n".data(using: .utf8)!)
    exit(1)
}

let point = CGPoint(x: x, y: y)

guard
    let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                       mouseCursorPosition: point, mouseButton: .left),
    let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                     mouseCursorPosition: point, mouseButton: .left)
else {
    FileHandle.standardError.write("failed to create mouse events\n".data(using: .utf8)!)
    exit(2)
}

down.post(tap: .cghidEventTap)
usleep(50_000)
up.post(tap: .cghidEventTap)
