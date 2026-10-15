import CoreImage
import CoreGraphics

struct MagnifierLensConfig: Codable, Equatable, Hashable {
    var enabled = false
    var radius: Double = 120
    var magnification: Double = 2.0
    var glassBlurEdge: Double = 8
    var glassOpacity: Double = 0.15
    var borderWidth: Double = 2.5
    var borderOpacity: Double = 0.5
    var motionBlurAmount: Double = 0
    var followsCursor = true

    static let `default` = MagnifierLensConfig()

    var clamped: MagnifierLensConfig {
        var next = self
        next.radius = max(40, min(radius, 400))
        next.magnification = max(1.2, min(magnification, 5))
        next.glassBlurEdge = max(0, min(glassBlurEdge, 30))
        next.glassOpacity = max(0, min(glassOpacity, 0.5))
        next.borderWidth = max(0, min(borderWidth, 10))
        next.borderOpacity = max(0, min(borderOpacity, 1))
        next.motionBlurAmount = max(0, min(motionBlurAmount, 30))
        return next
    }
}

enum MagnifierLensRenderer {
    static func render(source: CIImage, focusX: CGFloat, focusY: CGFloat,
                       canvas: CGSize, config: MagnifierLensConfig,
                       velocity: CGPoint = .zero) -> CIImage {
        let cfg = config.clamped
        guard cfg.enabled, !source.extent.isEmpty else { return source }

        let scale = min(canvas.width, canvas.height) / 1080
        let r = cfg.radius * scale
        let center = CGPoint(x: canvas.width * focusX, y: canvas.height * focusY)
        let mag = CGFloat(cfg.magnification)

        let magnifiedRegion = CGRect(x: center.x - r / mag, y: center.y - r / mag,
                                     width: 2 * r / mag, height: 2 * r / mag)
        let cropped = source.cropped(to: magnifiedRegion)
        let scaleT = CGAffineTransform(translationX: -magnifiedRegion.midX, y: -magnifiedRegion.midY)
            .concatenating(CGAffineTransform(scaleX: mag, y: mag))
            .concatenating(CGAffineTransform(translationX: center.x, y: center.y))
        var lens = cropped.transformed(by: scaleT)

        if cfg.motionBlurAmount > 0 {
            let speed = hypot(velocity.x, velocity.y)
            if speed > 0.001 {
                let blurRadius = min(cfg.motionBlurAmount * scale, speed * CGFloat(cfg.motionBlurAmount) * scale * 0.5)
                let angle = atan2(velocity.y, velocity.x)
                lens = lens.applyingFilter("CIMotionBlur", parameters: [
                    kCIInputRadiusKey: blurRadius,
                    "inputAngle": angle
                ])
            }
        }

        let lensRect = CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)
        let circleMask = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": CIVector(x: center.x, y: center.y),
            "inputRadius0": r - CGFloat(cfg.glassBlurEdge) * scale,
            "inputRadius1": r,
            "inputColor0": CIColor.white,
            "inputColor1": CIColor(red: 1, green: 1, blue: 1, alpha: 0)
        ])!.outputImage!

        lens = lens.applyingFilter("CIBlendWithAlphaMask", parameters: [
            kCIInputBackgroundImageKey: CIImage.empty(),
            kCIInputMaskImageKey: circleMask
        ]).cropped(to: lensRect.insetBy(dx: -CGFloat(cfg.glassBlurEdge) * scale, dy: -CGFloat(cfg.glassBlurEdge) * scale))

        if cfg.glassOpacity > 0 {
            let glassHighlight = CIFilter(name: "CIRadialGradient", parameters: [
                "inputCenter": CIVector(x: center.x - r * 0.25, y: center.y + r * 0.25),
                "inputRadius0": 0,
                "inputRadius1": r * 0.8,
                "inputColor0": CIColor(red: 1, green: 1, blue: 1, alpha: cfg.glassOpacity),
                "inputColor1": CIColor(red: 1, green: 1, blue: 1, alpha: 0)
            ])!.outputImage!.cropped(to: lensRect)

            let innerMask = CIFilter(name: "CIRadialGradient", parameters: [
                "inputCenter": CIVector(x: center.x, y: center.y),
                "inputRadius0": 0,
                "inputRadius1": r,
                "inputColor0": CIColor.white,
                "inputColor1": CIColor(red: 1, green: 1, blue: 1, alpha: 0)
            ])!.outputImage!

            let maskedHighlight = glassHighlight.applyingFilter("CIBlendWithAlphaMask", parameters: [
                kCIInputBackgroundImageKey: CIImage.empty(),
                kCIInputMaskImageKey: innerMask
            ]).cropped(to: lensRect)

            lens = maskedHighlight.composited(over: lens)
        }

        if cfg.borderWidth > 0, cfg.borderOpacity > 0 {
            let bw = CGFloat(cfg.borderWidth) * scale
            let outer = SceneRenderer.roundedMask(in: lensRect, radius: r)
            let inner = SceneRenderer.roundedMask(in: lensRect.insetBy(dx: bw, dy: bw), radius: r - bw)
            let ring = outer.applyingFilter("CISourceOutCompositing", parameters: [kCIInputBackgroundImageKey: inner])
                .applyingFilter("CIColorMatrix", parameters: [
                    "inputAVector": CIVector(x: 0, y: 0, z: 0, w: cfg.borderOpacity)
                ])
            lens = ring.composited(over: lens)
        }

        return lens.composited(over: source)
    }
}
