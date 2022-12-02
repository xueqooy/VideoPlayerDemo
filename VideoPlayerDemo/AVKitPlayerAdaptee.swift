//
//  AVKitPlayerAdaptee.swift
//  VideoPlayerPractice
//
//  Created by xueqooy on 2022/11/30.
//

import Foundation
import AVKit

class AVKitPlayerAdaptee: PlayerAdaptee {
    var positionUpdater: ((CGFloat) -> Void)?
    
    let player = AVPlayer()
    let playerController = AVPlayerViewController()
    
    var isPlaying: Bool {
        player.timeControlStatus == .playing
    }
    
    private var ob: NSObjectProtocol?
    
    init() {
        player.actionAtItemEnd = .pause
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(1.0)), queue: .main) { [weak self] time in
            guard let self = self, let item = self.player.currentItem else { return }
            let position = CGFloat(time.seconds) / CGFloat(item.duration.seconds)
            self.positionUpdater?(position)
        }
        
        ob = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) {  [weak self] _ in
            self?.player.seek(to: CMTime.zero)
        }
    }
    
    deinit {
        if let ob = ob {
            NotificationCenter.default.removeObserver(ob)

        }
    }
    
    func setupUI(playerView: UIView, thumbnailUpdater: @escaping (UIImage?) -> Void, positionUpdater: @escaping (CGFloat) -> Void) {
        playerView.addSubview(playerController.view)
        playerController.view.frame = playerView.bounds
        
        self.positionUpdater = positionUpdater
    }
    
    func prepareVideo(filePath: String) {        
        playerController.player = player
        
        let item = AVPlayerItem(url: URL(filePath: filePath))
        player.replaceCurrentItem(with: item)
    }
    
    func prepareVideo(networkURL: URL) {
        playerController.player = player
        
        let item = AVPlayerItem(url: networkURL)
        player.replaceCurrentItem(with: item)
    }
    
    func playOrPause() {
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }
    
    func updatePosition(_ position: CGFloat) {
        guard let item = player.currentItem else { return }
        
        player.seek(to: CMTime(seconds: item.duration.seconds * position, preferredTimescale: CMTimeScale(1)) )
    }
    
    func reset() {
        playerController.player = nil
        player.replaceCurrentItem(with: nil)

    }
}
