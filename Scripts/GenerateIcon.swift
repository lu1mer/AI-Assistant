// Optional design source for the bundled 1024px AppIcon. Run with Swift on macOS.
import AppKit
import ImageIO
import UniformTypeIdentifiers

let size = 1024
guard let canvas = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    throw CocoaError(.fileWriteUnknown)
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: canvas, flipped: false)
let rect = NSRect(x: 0, y: 0, width: size, height: size)
let top = NSColor(srgbRed: 0.48, green: 0.40, blue: 1, alpha: 1)
let bottom = NSColor(srgbRed: 0.25, green: 0.21, blue: 0.82, alpha: 1)
NSGradient(starting: bottom, ending: top)?.draw(in: rect, angle: 90)
let star = NSBezierPath()
star.move(to: NSPoint(x: 512, y: 810))
star.curve(to: NSPoint(x: 810, y: 512), controlPoint1: NSPoint(x: 550, y: 582), controlPoint2: NSPoint(x: 582, y: 550))
star.curve(to: NSPoint(x: 512, y: 214), controlPoint1: NSPoint(x: 582, y: 474), controlPoint2: NSPoint(x: 550, y: 442))
star.curve(to: NSPoint(x: 214, y: 512), controlPoint1: NSPoint(x: 474, y: 442), controlPoint2: NSPoint(x: 442, y: 474))
star.curve(to: NSPoint(x: 512, y: 810), controlPoint1: NSPoint(x: 442, y: 550), controlPoint2: NSPoint(x: 474, y: 582))
star.close()
NSColor.white.setFill()
star.fill()
NSGraphicsContext.restoreGraphicsState()
let url = URL(fileURLWithPath: "Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
guard let image = canvas.makeImage(), let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { throw CocoaError(.fileWriteUnknown) }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
