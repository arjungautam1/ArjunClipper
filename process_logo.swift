import AppKit

let inputPath = "/Users/codewitharjun/.gemini/antigravity-ide/brain/30ef80a9-3e8b-42cf-8f8b-12fb785d135b/arjuncopy_logo_1792362946035.jpg"
guard let sourceImage = NSImage(contentsOfFile: inputPath) else {
    fatalError("Could not load source image")
}

// Crop to the central icon squircle (approx x: 132, y: 135, width: 760, height: 760)
// Note: AppKit coordinate system has (0,0) at bottom-left
// In 1024x1024:
// Menu bar is at the top (y: 980-1024 in bottom-left coordinates)
// Dock is at the bottom (y: 0-90 in bottom-left coordinates)
// So the squircle center is at y: 535, x: 512, with size ~760x760
let cropRect = NSRect(x: 132, y: 140, width: 760, height: 760)

let finalImage = NSImage(size: NSSize(width: 1024, height: 1024))
finalImage.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    fatalError("No CGContext")
}

// Apply standard macOS rounded squircle clipping mask
let clipPath = CGPath(roundedRect: CGRect(x: 40, y: 40, width: 944, height: 944), cornerWidth: 215, cornerHeight: 215, transform: nil)
ctx.addPath(clipPath)
ctx.clip()

if let rep = sourceImage.representations.first {
    rep.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024),
             from: cropRect,
             operation: .copy,
             fraction: 1.0,
             respectFlipped: false,
             hints: nil)
}

finalImage.unlockFocus()

// Save high-res master PNG
let tiff = finalImage.tiffRepresentation!
let bitmap = NSBitmapImageRep(data: tiff)!
let masterPng = bitmap.representation(using: .png, properties: [:])!
try? masterPng.write(to: URL(fileURLWithPath: "AppIcon_Master.png"))

// Generate iconset
let iconsetDir = "AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

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
    let resized = NSImage(size: NSSize(width: size, height: size))
    resized.lockFocus()
    finalImage.draw(in: NSRect(x: 0, y: 0, width: size, height: size),
                    from: NSRect(x: 0, y: 0, width: 1024, height: 1024),
                    operation: .copy,
                    fraction: 1.0)
    resized.unlockFocus()
    
    if let rTiff = resized.tiffRepresentation,
       let rBitmap = NSBitmapImageRep(data: rTiff),
       let png = rBitmap.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(name)"))
    }
}

print("Iconset created successfully.")
