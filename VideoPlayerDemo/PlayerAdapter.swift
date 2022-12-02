//
//  PlayerAdapter.swift
//  VideoPlayerPractice
//
//  Created by xueqooy on 2022/11/30.
//

import UIKit

/**
 由于IJKPlayer包含的ffmpeg版本和MobileVLC的版本冲突，故将IJKPlayer单独作为一个Target
 */

enum Player: String, CaseIterable {
    #if IJK_DEMO
    case IJKPlayer
    #else
    case AVKit, VLCKit
    #endif
    
    var rawValue: String {
        switch self {
        #if IJK_DEMO
        case .IJKPlayer:
            return "IJKPlayer"
        #else
        case .AVKit:
            return "AVKit"
        case .VLCKit:
            return "VLCKit"
        #endif
        }
    }
}

class PlayerAdapter: PlayerAdaptee {
    
    let player: Player
    var adaptee: PlayerAdaptee
    
    var isPlaying: Bool {
        adaptee.isPlaying
    }
    
    init(player: Player) {
        self.player = player
        
        switch player {
        #if IJK_DEMO
        case .IJKPlayer:
            adaptee = IJKPlayerAdaptee()
        #else
        case .AVKit:
            adaptee = AVKitPlayerAdaptee()
        case .VLCKit:
            adaptee = VLCPlayerAdaptee()
        #endif
        }
    }
    
    func setupUI(playerView: UIView, thumbnailUpdater: @escaping (UIImage?) -> Void, positionUpdater: @escaping (CGFloat) -> Void) {
        adaptee.setupUI(playerView: playerView, thumbnailUpdater: thumbnailUpdater, positionUpdater: positionUpdater)
    }
    
    func prepareVideo(networkURL: URL) {
        adaptee.prepareVideo(networkURL: networkURL)
    }
    
    func prepareVideo(filePath: String) {
        adaptee.prepareVideo(filePath: filePath)
    }
    
    func updatePosition(_ position: CGFloat) {
        adaptee.updatePosition(position)
    }
    
    func playOrPause() {
        adaptee.playOrPause()
    }

    func reset() {
        adaptee.reset()
    }

}
