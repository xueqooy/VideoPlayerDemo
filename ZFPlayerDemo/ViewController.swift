//
//  ViewController.swift
//  ZFPlayerDemo
//
//  Created by xueqooy on 2022/12/6.
//

import UIKit
import ZFPlayer

enum Player: String, CaseIterable {
    case VLCKit, AVKit
        
    var rawValue: String {
        switch self {
        case .AVKit:
            return "AVKit"
        case .VLCKit:
            return "VLCKit"
        }
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var networkVideoSwitch: UISwitch!
    
    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var formatSelectionButton: UIButton!
    @IBOutlet weak var playerSelectionButton: UIButton!
    
    var playerController: ZFPlayerController?
    var vlcPlayerManager: ZFPlayerMediaPlayback?
    
    var player: Player = .VLCKit
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let formatMenu = UIMenu(children: VideoFormat.allCases.map { format in
            return UIAction(title: format.rawValue) { [weak self] _ in
                self?.prepareVideo(format: format)
            }
        })
        formatSelectionButton.menu = formatMenu
        
        let playerMenu = UIMenu(children: Player.allCases.map { player in
            return UIAction(title: player.rawValue) { [weak self] _ in
                self?.usePlayer(player)
            }
        })
        playerSelectionButton.menu = playerMenu
        
        usePlayer(Player.allCases.first ?? .VLCKit)
        prepareVideo(format: VideoFormat.allCases.first ?? .mp4 )

        print("intialized")
    }
    
    func usePlayer(_ player: Player) {
        self.player = player
        playerContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        let playerMananger: ZFPlayerMediaPlayback
        switch player {
        case .AVKit:
            let avPlayerManager = ZFAVPlayerManager()
            playerMananger = avPlayerManager
        case .VLCKit:
            let vlcPlayerManager = VLCPlayerManager()
            playerMananger = vlcPlayerManager
        }
        playerMananger.shouldAutoPlay = false
        
        let playerController = ZFPlayerController(playerManager: playerMananger, containerView: playerContainerView)
        let controlView = ZFPlayerControlView()
        controlView.controlViewAppearedCallback = { [weak controlView] _ in
            guard let controlView = controlView else { return }
            controlView.superview?.bringSubviewToFront(controlView)
        }
        playerController.controlView = controlView
        
        self.vlcPlayerManager = playerMananger
        self.playerController = playerController
    }
    
    func prepareVideo(format: VideoFormat) {
        if networkVideoSwitch.isOn {
            guard var networkURL = format.networkURL else {
                let alert = UIAlertController(title: "network URL not found", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                print("network URL not found")
                
                return
            }
            
            if player == .AVKit {
                // AVKit need secure connection.
                networkURL = URL(string: networkURL.absoluteString.replacingOccurrences(of: "http://", with: "https://")) ?? networkURL
            }
            
            playerController?.assetURL = networkURL
        } else {
            guard let filePath = format.filepath else {
                let alert = UIAlertController(title: "video file not found", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                print("file not found")
                
                playerController?.assetURL = nil
                return
            }
                    
            playerController?.assetURL = URL(filePath: filePath)
        }
    }

    @IBAction func networkURLSwitchAction(_ sender: UISwitch) {
        prepareVideo(format: VideoFormat(rawValue: formatSelectionButton.title(for: .normal)!)!)
    }
    
}

