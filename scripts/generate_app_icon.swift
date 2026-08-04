import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: generate_app_icon.swift <output.png>\n", stderr)
    exit(EXIT_FAILURE)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: bitmapInfo
) else {
    fputs("Could not create the icon drawing context.\n", stderr)
    exit(EXIT_FAILURE)
}

let deepNavy = CGColor(red: 0.015, green: 0.075, blue: 0.16, alpha: 1)
let oceanBlue = CGColor(red: 0.0, green: 0.36, blue: 0.50, alpha: 1)
let teal = CGColor(red: 0.0, green: 0.72, blue: 0.70, alpha: 1)
let warmGold = CGColor(red: 1.0, green: 0.68, blue: 0.18, alpha: 1)

context.drawLinearGradient(
    CGGradient(colorsSpace: colorSpace, colors: [deepNavy, oceanBlue] as CFArray, locations: [0, 1])!,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: []
)

context.setShadow(offset: CGSize(width: 0, height: -10), blur: 22, color: CGColor(gray: 0, alpha: 0.35))
context.setLineCap(.round)
context.setLineJoin(.round)
context.setLineWidth(72)
context.setStrokeColor(warmGold)
context.move(to: CGPoint(x: 235, y: 770))
context.addLine(to: CGPoint(x: 512, y: 225))
context.addLine(to: CGPoint(x: 789, y: 770))
context.strokePath()

context.setShadow(offset: .zero, blur: 0, color: nil)
context.setLineWidth(48)
context.setStrokeColor(teal)
context.move(to: CGPoint(x: 355, y: 555))
context.addLine(to: CGPoint(x: 669, y: 555))
context.strokePath()

context.setFillColor(warmGold)
for point in [CGPoint(x: 235, y: 770), CGPoint(x: 512, y: 225), CGPoint(x: 789, y: 770)] {
    context.fillEllipse(in: CGRect(x: point.x - 24, y: point.y - 24, width: 48, height: 48))
}

guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
      ) else {
    fputs("Could not create the PNG destination.\n", stderr)
    exit(EXIT_FAILURE)
}

CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fputs("Could not write the PNG file.\n", stderr)
    exit(EXIT_FAILURE)
}
