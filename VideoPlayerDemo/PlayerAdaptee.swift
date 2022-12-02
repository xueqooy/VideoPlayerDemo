//
//  PlayerAdaptee.swift
//  VideoPlayerPractice
//
//  Created by xueqooy on 2022/11/30.
//

import UIKit

protocol PlayerAdaptee {
    var isPlaying: Bool { get }
    func setupUI(playerView: UIView, thumbnailUpdater: @escaping (UIImage?) -> Void, positionUpdater: @escaping (CGFloat) -> Void)
    func prepareVideo(filePath: String)
    func prepareVideo(networkURL: URL)
    func playOrPause()
    func reset()
    func updatePosition(_ position: CGFloat)
}
