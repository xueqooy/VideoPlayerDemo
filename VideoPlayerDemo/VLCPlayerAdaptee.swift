//
//  VLCPlayerAdaptee.swift
//  VideoPlayerPractice
//
//  Created by xueqooy on 2022/11/30.
//

import Foundation
import MobileVLCKit

class VLCPlayerAdaptee: NSObject, PlayerAdaptee {
    var positionUpdater: ((CGFloat) -> Void)?
    var thumbnailUpdater: ((UIImage?) -> Void)?

    let player: VLCMediaPlayer = VLCMediaPlayer()
    weak var media: VLCMedia?
    
    var isPlaying: Bool {
        player.isPlaying
    }
    
    var thumbnailer: VLCMediaThumbnailer?
    
    private var ob: NSKeyValueObservation?
    
    override init() {
        super.init()
        
        ob = player.observe(\.position, options: [.new]) { [weak self] player, change in
            self?.positionUpdater?(CGFloat(change.newValue ?? 0.0))
        }
        
        
        player.delegate = self
    }
    
    deinit {
        ob?.invalidate()
    }
    
    func setupUI(playerView: UIView, thumbnailUpdater: @escaping (UIImage?) -> Void, positionUpdater: @escaping (CGFloat) -> Void) {
    
        player.drawable = playerView
        self.positionUpdater = positionUpdater
        self.thumbnailUpdater = thumbnailUpdater
    }
    
    func prepareVideo(networkURL: URL) {
        let media = VLCMedia(url: networkURL)
        self.media = media
        player.media = media
               
        let thumbnailer = VLCMediaThumbnailer(media: VLCMedia(url: networkURL), andDelegate: self)
        thumbnailer.fetchThumbnail()
        self.thumbnailer = thumbnailer
    }
    
    func prepareVideo(filePath: String) {
        
        let media = VLCMedia(path: filePath)
        self.media = media
        player.media = media
               
        let thumbnailer = VLCMediaThumbnailer(media: VLCMedia(path: filePath), andDelegate: self)
        thumbnailer.fetchThumbnail()
        self.thumbnailer = thumbnailer
    }
    
    func playOrPause() {
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }
    
    func updatePosition(_ position: CGFloat) {
        player.position = Float(position)
    }
    
    func reset() {
        thumbnailer = nil
        thumbnailUpdater?(nil)
        player.media = nil
    }
    
}

extension VLCPlayerAdaptee: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        if player.state == .stopped {
            self.positionUpdater?(1.0)
            
            if let url = player.media?.url {
                player.media = VLCMedia(url: url)
            }
        }
    }
}

extension VLCPlayerAdaptee: VLCMediaThumbnailerDelegate {
    func mediaThumbnailerDidTimeOut(_ mediaThumbnailer: VLCMediaThumbnailer) {
        thumbnailer = nil
    }
    
    func mediaThumbnailer(_ mediaThumbnailer: VLCMediaThumbnailer, didFinishThumbnail thumbnail: CGImage) {
        thumbnailer = nil
        thumbnailUpdater?(UIImage(cgImage: thumbnail))
    }
}
