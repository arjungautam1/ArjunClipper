import AppKit

func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    
    let scale = size / 1024.0
    
    // 1. App Icon Rounded Rect Background (Squircle)
    let squircleRect = CGRect(x: 100 * scale, y: 100 * scale, width: 824 * scale, height: 824 * scale)
    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: 185 * scale, cornerHeight: 185 * scale, transform: nil)
    
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()
    
    // Background gradient: Deep Indigo to Violet
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.12, green: 0.15, blue: 0.32, alpha: 1.0).cgColor,
        NSColor(red: 0.28, green: 0.12, blue: 0.48, alpha: 1.0).cgColor,
        NSColor(red: 0.45, green: 0.18, blue: 0.65, alpha: 1.0).cgColor
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.5, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 0, y: 924 * scale), end: CGPoint(x: 0, y: 100 * scale), options: [])
    }
    ctx.restoreGState()
    
    // 2. Clipboard Board Body
    let boardRect = CGRect(x: 230 * scale, y: 180 * scale, width: 564 * scale, height: 620 * scale)
    let boardPath = CGPath(roundedRect: boardRect, cornerWidth: 42 * scale, cornerHeight: 42 * scale, transform: nil)
    
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12 * scale), blur: 30 * scale, color: NSColor.black.withAlphaComponent(0.45).cgColor)
    ctx.addPath(boardPath)
    ctx.setFillColor(NSColor(red: 0.96, green: 0.97, blue: 1.0, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()
    
    // 3. Clipboard Clip at Top
    let clipRect = CGRect(x: 372 * scale, y: 740 * scale, width: 280 * scale, height: 110 * scale)
    let clipPath = CGPath(roundedRect: clipRect, cornerWidth: 26 * scale, cornerHeight: 26 * scale, transform: nil)
    
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -4 * scale), blur: 12 * scale, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    ctx.addPath(clipPath)
    
    let clipColors = [
        NSColor(red: 0.88, green: 0.72, blue: 0.35, alpha: 1.0).cgColor, // Warm Gold
        NSColor(red: 1.00, green: 0.88, blue: 0.55, alpha: 1.0).cgColor
    ] as CFArray
    if let clipGrad = CGGradient(colorsSpace: colorSpace, colors: clipColors, locations: [0.0, 1.0]) {
        ctx.clip()
        ctx.drawLinearGradient(clipGrad, start: CGPoint(x: 0, y: 850 * scale), end: CGPoint(x: 0, y: 740 * scale), options: [])
    }
    ctx.restoreGState()
    
    // 4. Stylized "A" Monogram on Clipboard
    let aRect = CGRect(x: 280 * scale, y: 260 * scale, width: 464 * scale, height: 420 * scale)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 320 * scale, weight: .black),
        .foregroundColor: NSColor(red: 0.35, green: 0.20, blue: 0.75, alpha: 0.90),
        .paragraphStyle: paragraphStyle
    ]
    
    NSString(string: "A").draw(in: aRect, withAttributes: attrs)
    
    // 5. Subtle horizontal text line accents
    let line1 = CGRect(x: 340 * scale, y: 240 * scale, width: 344 * scale, height: 16 * scale)
    let line2 = CGRect(x: 390 * scale, y: 200 * scale, width: 244 * scale, height: 14 * scale)
    let linePath1 = CGPath(roundedRect: line1, cornerWidth: 8 * scale, cornerHeight: 8 * scale, transform: nil)
    let linePath2 = CGPath(roundedRect: line2, cornerWidth: 7 * scale, cornerHeight: 7 * scale, transform: nil)
    ctx.setFillColor(NSColor(red: 0.60, green: 0.65, blue: 0.82, alpha: 0.40).cgColor)
    ctx.addPath(linePath1)
    ctx.fillPath()
    ctx.addPath(linePath2)
    ctx.fillPath()
    
    image.unlockFocus()
    return image
}

let fileManager = FileManager.default
let iconsetDir = "AppIcon.iconset"
try? fileManager.removeItem(atPath: iconsetDir)
try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in sizes {
    let img = renderIcon(size: size)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let dest = "\(iconsetDir)/\(name)"
        try? png.write(to: URL(fileURLWithPath: dest))
    }
}

print("Generated iconset successfully.")
