//
//  VLCPlayerManager.swift
//  ZFPlayerDemo
//
//  Created by xueqooy on 2022/12/7.
//

import ZFPlayer
import MobileVLCKit

private let vlcVolumeMax: Float = 200
private let vlcVolumeMin: Float = 0

class VLCPlayerManager: NSObject, ZFPlayerMediaPlayback {
    
    var playerPrepareToPlay: ((ZFPlayerMediaPlayback, URL) -> Void)?
    
    var playerReadyToPlay: ((ZFPlayerMediaPlayback, URL) -> Void)?
    
    var playerPlayTimeChanged: ((ZFPlayerMediaPlayback, TimeInterval, TimeInterval) -> Void)?
    
    var playerBufferTimeChanged: ((ZFPlayerMediaPlayback, TimeInterval) -> Void)?
    
    var playerPlayStateChanged: ((ZFPlayerMediaPlayback, ZFPlayerPlaybackState) -> Void)?
    
    var playerLoadStateChanged: ((ZFPlayerMediaPlayback, ZFPlayerLoadState) -> Void)?
    
    var playerPlayFailed: ((ZFPlayerMediaPlayback, Any) -> Void)?
    
    var playerDidToEnd: ((ZFPlayerMediaPlayback) -> Void)?
    
    var presentationSizeChanged: ((ZFPlayerMediaPlayback, CGSize) -> Void)?
    
    
    lazy var player: VLCMediaPlayer = {
        let player = VLCMediaPlayer()
        player.delegate = self
        player.drawable = videoView.drawView
        return player
    }()
    
    private lazy var videoView: VideoView = {
        let view = VideoView(frame: .zero)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    lazy var view: ZFPlayerView = {
        let view = ZFPlayerView()
        view.playerView = videoView
        return view
    }()
    
    var volume: Float {
        set {
            let volume = vlcVolumeMax * newValue
            player.audio?.volume = Int32(volume)
        }
        get {
            guard let volume = player.audio?.volume else {
                return 0
            }
            
            return Float(volume) / vlcVolumeMax
        }
    }
    
    var isMuted: Bool {
        set {
            player.audio?.isMuted  = newValue
        }
        get {
            player.audio?.isMuted ?? false
        }
    }
    
    var rate: Float {
        set {
            player.rate = newValue
        }
        get {
            let rate = player.rate
            return rate == 0 ? 1 : rate
        }
    }
    
    var currentTime: TimeInterval {
        player.time.seconds
    }
    
    var totalTime: TimeInterval {
        media?.length.seconds ?? 0
    }
    
    var bufferTime: TimeInterval = 0
    
    var seekTime: TimeInterval = 0
    
    private(set) var isPlaying: Bool = false
    
    var scalingMode: ZFPlayerScalingMode = .aspectFit
    
    private(set) var isPreparedToPlay: Bool = false
    
    var shouldAutoPlay: Bool = true
        
    var assetURL: URL? {
        didSet {
            if let _ = oldValue {
                stop(resetAssetURL: false)
            }
            if let _ = assetURL {
                prepareToPlay()
            }
        }
    }
    
    private var media: VLCMedia?
    private var thumbnailer: VLCMediaThumbnailer?
    
    private var obs: [NSKeyValueObservation] = []

    private var isReadyToPlay: Bool = false
    
    var presentationSize: CGSize = .zero {
        didSet {
            if presentationSize == oldValue {
                return
            }
            view.presentationSize = presentationSize
            presentationSizeChanged?(self, presentationSize)
        }
    }
    
    private(set) var playState: ZFPlayerPlaybackState = .playStateUnknown {
        didSet {
            if playState == oldValue {
                return
            }
            playerPlayStateChanged?(self, playState)
        }
    }
    
    private(set) var loadState: ZFPlayerLoadState = [] {
        didSet {
            if loadState == oldValue {
                return
            }
            playerLoadStateChanged?(self, loadState)
        }
    }
    
    func prepareToPlay() {
        guard let assetURL = assetURL else {
            return
        }
        isPreparedToPlay = true
        
        addPlayerObservers()

        let media = VLCMedia(url: assetURL)
        media.delegate = self
        media.parse(options: [.parseNetwork])
        
        player.media = media
        
        let thumbnailer = VLCMediaThumbnailer(media: VLCMedia(url: assetURL), andDelegate: self)
        thumbnailer.fetchThumbnail()
        
        self.media = media
        self.thumbnailer = thumbnailer
        
        if shouldAutoPlay {
            play()
        }
        loadState = [.prepare]
        
        playerPrepareToPlay?(self, assetURL)
        playerPlayTimeChanged?(self, self.currentTime, self.totalTime)
    }
    
    func reloadPlayer() {
        seekTime = currentTime
        prepareToPlay()
    }
    
    func play() {
        if !isPreparedToPlay {
            prepareToPlay()
        } else {
            player.play()
            player.rate = self.rate
            isPlaying = true
            playState = .playStatePlaying
        }
    }
    
    func pause() {
        player.pause()
        isPlaying = false
        playState = .playStatePaused
    }
    
    func replay() {
        if player.isSeekable {
            player.position = 0
        } else if let url = assetURL {
            assetURL = url
        }
        player.play()
    }
    
    func stop() {
        stop(resetAssetURL: true)
    }
    
    func seek(toTime time: TimeInterval, completionHandler: ((Bool) -> Void)? = nil) {
        guard player.isSeekable, totalTime > 0 else {
            completionHandler?(false)
            seekTime = time
            return
        }

        player.time = VLCTime(int: Int32(time * 1000))
        completionHandler?(true)
    }
    
    private func stop(resetAssetURL: Bool) {
        media?.parseStop()
        thumbnailer?.media.parseStop()
        if resetAssetURL { assetURL = nil }
        media = nil
        thumbnailer = nil
        loadState = []
        isPlaying = false
        playState = .playStatePlayStopped
        isPreparedToPlay = false
        view.coverImageView.image = nil
        isReadyToPlay = false
        removePlayerObservers()
    }
    
    private func addPlayerObservers() {
//        let ob = player.observe(\.state, options: [.new]) { [weak self] player, change in
//            guard let newValue = change.newValue, let self = self, let assetURL = self.assetURL else { return }
//
//            if newValue == .opening {
//                if !self.isReadyToPlay {
//                    self.isReadyToPlay = true
//                    self.loadState = .playthroughOK
//                    self.playerReadyToPlay?(self, assetURL)
//                }
//                if self.seekTime > 0 {
//                    if self.shouldAutoPlay {
//                        self.pause()
//                    }
//                    self.seek(toTime: self.seekTime) { [weak self] finished in
//                        guard let self = self else { return }
//                        if finished && self.shouldAutoPlay {
//                            self.play()
//                        }
//                    }
//                    self.seekTime = 0
//                } else {
//                    if self.shouldAutoPlay && self.isPlaying {
//                        self.play()
//                    }
//                }
//                self.player.audio?.isMuted = self.isMuted
//            }
//        }
//        obs.append(ob)
    }
    
    private func removePlayerObservers() {
        obs.removeAll()
    }
    
}

extension VLCPlayerManager: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        print("player state: \(VLCMediaPlayerStateToString(player.state))")
        
        guard let assetURL = self.assetURL else { return }
        
        switch player.state {
        case .opening:
            if !isReadyToPlay {
                isReadyToPlay = true
                loadState = .playthroughOK
                playerReadyToPlay?(self, assetURL)
            }
            if self.seekTime > 0 {
                if shouldAutoPlay {
                    pause()
                }
                seek(toTime: self.seekTime) { [weak self] finished in
                    guard let self = self else { return }
                    if finished && self.shouldAutoPlay {
                        self.play()
                    }
                }
                seekTime = 0
            } else {
                if shouldAutoPlay && isPlaying {
                    play()
                }
            }
        case .ended:
            pause()
            seek(toTime: 0)
        default: break
        }

    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        playerPlayTimeChanged?(self, currentTime, totalTime)
    }
}

extension VLCPlayerManager: VLCMediaDelegate {
    func mediaMetaDataDidChange(_ aMedia: VLCMedia) {
    }
    
    func mediaDidFinishParsing(_ aMedia: VLCMedia) {
        playerPlayTimeChanged?(self, currentTime, totalTime)
    }
}

extension VLCPlayerManager: VLCMediaThumbnailerDelegate {
    func mediaThumbnailerDidTimeOut(_ mediaThumbnailer: VLCMediaThumbnailer) {
        if mediaThumbnailer === thumbnailer {
            thumbnailer = nil
        }
    }
    
    func mediaThumbnailer(_ mediaThumbnailer: VLCMediaThumbnailer, didFinishThumbnail thumbnail: CGImage) {
        if mediaThumbnailer === thumbnailer {
            thumbnailer = nil
            view.coverImageView.image = UIImage(cgImage: thumbnail)
        }
    }
    
    
}

private extension VLCTime {
    var seconds: TimeInterval {
        (value ?? NSNumber(value: 0)).doubleValue / 1000
    }
}


private class VideoView: UIView {
    
    let drawView: UIView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isUserInteractionEnabled = false
        
        addSubview(drawView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        drawView.frame = bounds
    }
}
