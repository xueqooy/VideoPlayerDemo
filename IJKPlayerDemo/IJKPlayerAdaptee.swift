//
//  IJKPlayerAdaptee.swift
//  VideoPlayerPractice
//
//  Created by xueqooy on 2022/12/1.
//

import Foundation
import IJKMediaFramework

class IJKPlayerAdaptee: PlayerAdaptee {
    var positionUpdater: ((CGFloat) -> Void)?
    var thumbnailUpdater: ((UIImage?) -> Void)?
    
    var playerController: IJKMediaPlayback?
    var obs = [NSObjectProtocol]()
    
    var timerUpdateTimer: Timer?
    
    private weak var containerView: UIView?
    
    deinit {
        timerUpdateTimer?.invalidate()
    }
    
    var isPlaying: Bool {
        playerController?.isPlaying() ?? false
    }
    
    func setupUI(playerView: UIView, thumbnailUpdater: @escaping (UIImage?) -> Void, positionUpdater: @escaping (CGFloat) -> Void) {
        containerView = playerView

        self.positionUpdater = positionUpdater
        self.thumbnailUpdater = thumbnailUpdater
    }
    
    func prepareVideo(filePath: String) {
        prepare(url: URL(filePath: filePath))
    }
    
    func prepareVideo(networkURL: URL) {
        prepare(url: networkURL)
    }
    
    func playOrPause() {
        if isPlaying {
            playerController?.pause()
        } else {
            playerController?.play()
        }
    }
    
    func updatePosition(_ position: CGFloat) {
        guard let playerController = playerController else { return }
        
        playerController.currentPlaybackTime = playerController.duration * position
    }
    
    func reset() {
        playerController?.stop()
        playerController = nil
        thumbnailUpdater?(nil)
    }
    
    private func prepare(url: URL) {
        let opt = IJKFFOptions.byDefault()
        // 丢弃一些视频帧，否则可能导致音画不同步
        opt?.setPlayerOptionIntValue(5, forKey: "framedrop")
        playerController = IJKFFMoviePlayerController(contentURL: url, with: opt)
        playerController?.shouldAutoplay = false
        playerController?.scalingMode = .aspectFit

        obs.forEach { ob in
            NotificationCenter.default.removeObserver(ob)
        }
        
        obs.append(NotificationCenter.default.addObserver(forName: .IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: nil, queue: .main) { [ weak self] _ in
            guard let self = self else { return }
            
            if self.timerUpdateTimer == nil {
                self.timerUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self] timer in
                    guard let self = self, let playerController = self.playerController else { return }
                
                    if playerController.playbackState == .playing && playerController.duration > 0 {
                        let position = playerController.currentPlaybackTime / playerController.duration
                        self.positionUpdater?(position)
                    }
                })
            }
        })
    
        obs.append(NotificationCenter.default.addObserver(forName: .IJKMPMoviePlayerPlaybackStateDidChange, object: nil, queue: .main) { [ weak self] _ in
            guard let self = self, let playerController = self.playerController else { return }

            if playerController.playbackState == .stopped {
                self.positionUpdater?(0)
            }
        })
        
        guard let containerView = containerView else {
            return
        }
        containerView.subviews.forEach({ view in
            if view is UIImageView { return } // ignore thumbImageView
            view.removeFromSuperview()
        })
        playerController!.view.frame = containerView.bounds
        containerView.addSubview(playerController!.view)
        
        playerController?.prepareToPlay()
        
        thumbnailUpdater?(playerController?.thumbnailImageAtCurrentTime() ?? UIImage())
    }
}

