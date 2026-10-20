import UIKit
import AVFoundation

enum MediaFiles {
    static var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("SkesteMedia", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func url(for fileName: String) -> URL? {
        let url = directory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let name = "image_\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func storeVideo(from sourceURL: URL) -> String? {
        let ext = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension.lowercased()
        let name = "video_\(UUID().uuidString).\(ext)"
        let destination = directory.appendingPathComponent(name)
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destination)
            return name
        } catch {
            return nil
        }
    }
}

enum AssetResolver {
    static func image(named name: String) -> UIImage? {
        guard !name.isEmpty else { return nil }
        if let image = UIImage(named: name) {
            return image
        }
        let extensions = ["jpg", "jpeg", "png", "heic", "webp"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Media"),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        return nil
    }

    static func image(for media: MediaItem) -> UIImage? {
        if let fileName = media.fileName, let url = MediaFiles.url(for: fileName) {
            return UIImage(contentsOfFile: url.path)
        }
        return image(named: media.assetName)
    }

    static func videoURL(for media: MediaItem) -> URL? {
        if let fileName = media.fileName, let url = MediaFiles.url(for: fileName) {
            return url
        }
        let name = media.assetName
        guard !name.isEmpty else { return nil }
        for ext in ["mp4", "mov", "m4v"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Media") {
                return url
            }
        }
        return nil
    }

    static func avatar(for user: User?) -> UIImage? {
        guard let user else { return nil }
        if let fileName = user.avatarFileName, let url = MediaFiles.url(for: fileName) {
            return UIImage(contentsOfFile: url.path)
        }
        return image(named: user.avatarAsset)
    }

    static func avatar(named name: String) -> UIImage? {
        image(named: name)
    }
}

final class VideoThumbnailLoader {
    static let shared = VideoThumbnailLoader()
    private let cache = NSCache<NSString, UIImage>()

    func thumbnail(for url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString as NSString
        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 1200, height: 1600)
            let time = CMTime(seconds: 0.2, preferredTimescale: 600)
            let image: UIImage?
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                image = UIImage(cgImage: cgImage)
            } else {
                image = nil
            }
            if let image {
                self.cache.setObject(image, forKey: key)
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}

final class AlpineArtworkView: UIView {
    /// Glow, upper sky, lower sky — electric night grades.
    private let palettes: [(UIColor, UIColor, UIColor)] = [
        (UIColor(hex: "FF4FD8"), UIColor(hex: "2A1260"), UIColor(hex: "140A3A")),
        (UIColor(hex: "4CD7F6"), UIColor(hex: "141A5E"), UIColor(hex: "0C0A30")),
        (UIColor(hex: "B7F36B"), UIColor(hex: "1E2A5E"), UIColor(hex: "0D1030")),
        (UIColor(hex: "FFD447"), UIColor(hex: "2E1A5E"), UIColor(hex: "160C38")),
        (UIColor(hex: "FFFFFF"), UIColor(hex: "221A5E"), UIColor(hex: "100A32"))
    ]
    private var seedValue: UInt64 = 7
    private(set) var accentColor: UIColor = UIColor(hex: "FF4FD8")

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
        contentMode = .redraw
        backgroundColor = UIColor(hex: "0B0A24")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(seed: String) {
        seedValue = StableHash.of(seed)
        let palette = palettes[Int(seedValue % UInt64(palettes.count))]
        accentColor = palette.0
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), rect.width > 0, rect.height > 0 else { return }
        let palette = palettes[Int(seedValue % UInt64(palettes.count))]
        let colors = [palette.2.cgColor, palette.1.cgColor, UIColor(hex: "0B0A24").cgColor] as CFArray
        let locations: [CGFloat] = [0, 0.45, 1]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
            context.drawLinearGradient(gradient, start: CGPoint(x: rect.maxX, y: 0), end: CGPoint(x: rect.minX, y: rect.maxY), options: [])
        }

        var random = LCG(seed: seedValue)
        for _ in 0..<34 {
            let x = CGFloat(random.nextUnit()) * rect.width
            let y = CGFloat(random.nextUnit()) * rect.height * 0.66
            let size = 0.7 + CGFloat(random.nextUnit()) * 1.6
            let starColor: UIColor
            switch Int(random.nextUnit() * 10) {
            case 0: starColor = Palette.pink
            case 1: starColor = Palette.cyan
            default: starColor = .white
            }
            context.setFillColor(starColor.withAlphaComponent(0.12 + CGFloat(random.nextUnit()) * 0.4).cgColor)
            context.fillEllipse(in: CGRect(x: x, y: y, width: size, height: size))
        }

        let sunRadius = rect.width * (0.075 + CGFloat(random.nextUnit()) * 0.035)
        let sunCenter = CGPoint(x: rect.width * (0.25 + CGFloat(random.nextUnit()) * 0.5), y: rect.height * (0.22 + CGFloat(random.nextUnit()) * 0.12))
        let glowColors = [palette.0.withAlphaComponent(0.55).cgColor, palette.0.withAlphaComponent(0).cgColor] as CFArray
        if let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: glowColors, locations: [0, 1]) {
            context.drawRadialGradient(glow,
                                       startCenter: sunCenter, startRadius: sunRadius * 0.7,
                                       endCenter: sunCenter, endRadius: sunRadius * 4.6,
                                       options: [])
        }
        context.setFillColor(palette.0.withAlphaComponent(0.95).cgColor)
        context.fillEllipse(in: CGRect(x: sunCenter.x - sunRadius, y: sunCenter.y - sunRadius, width: sunRadius * 2, height: sunRadius * 2))

        let farPath = UIBezierPath()
        farPath.move(to: CGPoint(x: 0, y: rect.height * 0.66))
        farPath.addLine(to: CGPoint(x: rect.width * 0.16, y: rect.height * 0.48))
        farPath.addLine(to: CGPoint(x: rect.width * 0.31, y: rect.height * 0.61))
        farPath.addLine(to: CGPoint(x: rect.width * 0.52, y: rect.height * 0.39))
        farPath.addLine(to: CGPoint(x: rect.width * 0.71, y: rect.height * 0.59))
        farPath.addLine(to: CGPoint(x: rect.width * 0.86, y: rect.height * 0.47))
        farPath.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.63))
        farPath.addLine(to: CGPoint(x: rect.width, y: rect.height))
        farPath.addLine(to: CGPoint(x: 0, y: rect.height))
        farPath.close()
        context.setFillColor(shade(palette.1, 0.55).withAlphaComponent(0.9).cgColor)
        context.addPath(farPath.cgPath)
        context.fillPath()

        let midPath = UIBezierPath()
        midPath.move(to: CGPoint(x: 0, y: rect.height * 0.76))
        midPath.addLine(to: CGPoint(x: rect.width * 0.22, y: rect.height * 0.55))
        midPath.addLine(to: CGPoint(x: rect.width * 0.42, y: rect.height * 0.73))
        midPath.addLine(to: CGPoint(x: rect.width * 0.66, y: rect.height * 0.51))
        midPath.addLine(to: CGPoint(x: rect.width * 0.84, y: rect.height * 0.68))
        midPath.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.56))
        midPath.addLine(to: CGPoint(x: rect.width, y: rect.height))
        midPath.addLine(to: CGPoint(x: 0, y: rect.height))
        midPath.close()
        context.setFillColor(shade(palette.2, 0.7).withAlphaComponent(0.94).cgColor)
        context.addPath(midPath.cgPath)
        context.fillPath()

        let nearPath = UIBezierPath()
        nearPath.move(to: CGPoint(x: 0, y: rect.height * 0.89))
        nearPath.addLine(to: CGPoint(x: rect.width * 0.24, y: rect.height * 0.69))
        nearPath.addLine(to: CGPoint(x: rect.width * 0.39, y: rect.height * 0.82))
        nearPath.addLine(to: CGPoint(x: rect.width * 0.55, y: rect.height * 0.72))
        nearPath.addLine(to: CGPoint(x: rect.width * 0.72, y: rect.height * 0.88))
        nearPath.addLine(to: CGPoint(x: rect.width * 0.9, y: rect.height * 0.74))
        nearPath.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.84))
        nearPath.addLine(to: CGPoint(x: rect.width, y: rect.height))
        nearPath.addLine(to: CGPoint(x: 0, y: rect.height))
        nearPath.close()
        context.setFillColor(UIColor(hex: "070518").withAlphaComponent(0.96).cgColor)
        context.addPath(nearPath.cgPath)
        context.fillPath()

        // Aurora ribbons across the sky.
        context.setLineCap(.round)
        context.setStrokeColor(Palette.cyan.withAlphaComponent(0.09).cgColor)
        context.setLineWidth(rect.height * 0.11)
        context.move(to: CGPoint(x: -20, y: rect.height * 0.34))
        context.addCurve(to: CGPoint(x: rect.width + 20, y: rect.height * 0.2),
                         control1: CGPoint(x: rect.width * 0.28, y: rect.height * 0.24),
                         control2: CGPoint(x: rect.width * 0.72, y: rect.height * 0.44))
        context.strokePath()
        context.setStrokeColor(Palette.magenta.withAlphaComponent(0.08).cgColor)
        context.setLineWidth(rect.height * 0.07)
        context.move(to: CGPoint(x: -20, y: rect.height * 0.47))
        context.addCurve(to: CGPoint(x: rect.width + 20, y: rect.height * 0.3),
                         control1: CGPoint(x: rect.width * 0.34, y: rect.height * 0.36),
                         control2: CGPoint(x: rect.width * 0.7, y: rect.height * 0.52))
        context.strokePath()
    }

    private func shade(_ color: UIColor, _ factor: CGFloat) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return color }
        return UIColor(red: red * factor, green: green * factor, blue: blue * factor, alpha: alpha)
    }
}

private struct LCG {
    private var state: UInt64
    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B9 : seed
    }
    mutating func nextUnit() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) & 0xFFFFFFFF) / Double(UInt32.max)
    }
}

final class VideoSurfaceView: UIView {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private let playerLayer = AVPlayerLayer()
    private(set) var hasVideo = false
    var isMuted: Bool {
        get { player?.isMuted ?? true }
        set { player?.isMuted = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func configure(media: MediaItem) {
        reset()
        guard media.kind == .video, let url = AssetResolver.videoURL(for: media) else {
            hasVideo = false
            return
        }
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        queue.isMuted = true
        let loop = AVPlayerLooper(player: queue, templateItem: item)
        player = queue
        looper = loop
        playerLayer.player = queue
        hasVideo = true
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func reset() {
        player?.pause()
        looper?.disableLooping()
        playerLayer.player = nil
        player = nil
        looper = nil
        hasVideo = false
    }

    deinit {
        player?.pause()
    }
}

final class MediaPreviewView: UIView {
    private let artwork = AlpineArtworkView()
    private let imageView = UIImageView()
    private let videoSurface = VideoSurfaceView()
    private let playBadge = UIView()
    private let playIcon = UIImageView()
    private let shade = CAGradientLayer()
    private var media: MediaItem?
    private var thumbnailTask: UUID?
    private var playbackRequested = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = UIColor(hex: "120E32")

        artwork.translatesAutoresizingMaskIntoConstraints = false
        addSubview(artwork)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        videoSurface.translatesAutoresizingMaskIntoConstraints = false
        videoSurface.isUserInteractionEnabled = false
        addSubview(videoSurface)

        shade.colors = [UIColor.clear.cgColor, UIColor(hex: "060607").withAlphaComponent(0.12).cgColor, UIColor(hex: "060607").withAlphaComponent(0.7).cgColor]
        shade.locations = [0, 0.52, 1]
        layer.addSublayer(shade)

        playBadge.translatesAutoresizingMaskIntoConstraints = false
        playBadge.backgroundColor = UIColor(hex: "060607").withAlphaComponent(0.46)
        playBadge.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        playBadge.layer.borderWidth = 1
        playBadge.layer.cornerRadius = 23
        addSubview(playBadge)

        playIcon.translatesAutoresizingMaskIntoConstraints = false
        playIcon.image = UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
        playIcon.tintColor = .white
        playIcon.contentMode = .scaleAspectFit
        playBadge.addSubview(playIcon)

        NSLayoutConstraint.activate([
            artwork.leadingAnchor.constraint(equalTo: leadingAnchor),
            artwork.trailingAnchor.constraint(equalTo: trailingAnchor),
            artwork.topAnchor.constraint(equalTo: topAnchor),
            artwork.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            videoSurface.leadingAnchor.constraint(equalTo: leadingAnchor),
            videoSurface.trailingAnchor.constraint(equalTo: trailingAnchor),
            videoSurface.topAnchor.constraint(equalTo: topAnchor),
            videoSurface.bottomAnchor.constraint(equalTo: bottomAnchor),
            playBadge.widthAnchor.constraint(equalToConstant: 46),
            playBadge.heightAnchor.constraint(equalToConstant: 46),
            playBadge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            playBadge.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            playIcon.centerXAnchor.constraint(equalTo: playBadge.centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: playBadge.centerYAnchor),
            playIcon.widthAnchor.constraint(equalToConstant: 18),
            playIcon.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shade.frame = bounds
    }

    func configure(with media: MediaItem?, allowsPlayback: Bool = false) {
        self.media = media
        playbackRequested = allowsPlayback
        imageView.image = nil
        videoSurface.reset()
        playBadge.isHidden = true
        guard let media else {
            artwork.configure(seed: "skeste")
            return
        }
        artwork.configure(seed: media.assetName + media.id)
        playBadge.isHidden = media.kind != .video

        if media.kind == .image {
            imageView.image = AssetResolver.image(for: media)
            return
        }

        if allowsPlayback, AssetResolver.videoURL(for: media) != nil {
            videoSurface.configure(media: media)
            videoSurface.play()
            playBadge.isHidden = true
        }

        let token = UUID()
        thumbnailTask = token
        if let url = AssetResolver.videoURL(for: media) {
            VideoThumbnailLoader.shared.thumbnail(for: url) { [weak self] image in
                guard let self, self.thumbnailTask == token, let image else { return }
                self.imageView.image = image
            }
        }
    }

    func setPlaybackActive(_ active: Bool) {
        playbackRequested = active
        guard let media, media.kind == .video, AssetResolver.videoURL(for: media) != nil else { return }
        if active {
            if !videoSurface.hasVideo {
                videoSurface.configure(media: media)
            }
            videoSurface.play()
            playBadge.isHidden = true
        } else {
            videoSurface.pause()
            playBadge.isHidden = false
        }
    }

    func setPlayBadge(hidden: Bool) {
        playBadge.isHidden = hidden
    }

    func setImageContentMode(_ mode: UIView.ContentMode) {
        imageView.contentMode = mode
    }
}
