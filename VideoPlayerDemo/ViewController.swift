//
//  ViewController.swift
//  VideoPlayerPractice
//
//  Created by xueqooy on 2022/11/29.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var networkVideoSwitch: UISwitch!
    
    private var playerAdapter: PlayerAdapter?
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var formatSelectionButton: UIButton!
    
    @IBOutlet weak var playerView: UIView!
    
    @IBOutlet weak var videoPositionSlider: UISlider!
    
    private var lastPosition: CGFloat = 0
        
    static func instantiate(playerAdatper: PlayerAdapter) -> ViewController {
        let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "ViewController") as! ViewController
        viewController.playerAdapter = playerAdatper
        return viewController
    }
    
    deinit {
        playerAdapter?.reset()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let menu = UIMenu(children: VideoFormat.allCases.map { format in
            return UIAction(title: format.rawValue) { [weak self] _ in
                self?.prepareVideo(format: format)
            }
        })
        formatSelectionButton.menu = menu
        
        playerAdapter?.setupUI(playerView: playerView, thumbnailUpdater: { [weak self] image in
            self?.thumbnailImageView.image = image
        }, positionUpdater: { [weak self] positon in
            if self?.lastPosition == positon { return }
            
            self?.lastPosition = positon
            self?.videoPositionSlider.value = Float(positon)
        })
        
        prepareVideo(format: VideoFormat.allCases.first ?? .mp4 )
//        prepareVideo(format: .mov)

        print("intialized")
    }


    func prepareVideo(format: VideoFormat) {
        videoPositionSlider.value = 0
        
        if networkVideoSwitch.isOn {
            guard var networkURL = format.networkURL else {
                let alert = UIAlertController(title: "network URL not found", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                print("network URL not found")
                
                playerAdapter?.reset()
                return
            }
            #if IJK_DEMO && canImport(IJKMediaFramework)
            // https need link IJKFrameworkWithSSL
            networkURL = URL(string: networkURL.absoluteString.replacingOccurrences(of: "https://", with: "http://")) ?? networkURL
            #else
            if playerAdapter?.player == .AVKit {
                // AVKit need secure connection.
                networkURL = URL(string: networkURL.absoluteString.replacingOccurrences(of: "http://", with: "https://")) ?? networkURL
            }
            #endif
            
            playerAdapter?.reset()
            playerAdapter?.prepareVideo(networkURL: networkURL)
        } else {
            guard let filePath = format.filepath else {
                let alert = UIAlertController(title: "video file not found", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                print("file not found")
                
                playerAdapter?.reset()
                return
            }
            
            playerAdapter?.reset()
            playerAdapter?.prepareVideo(filePath: filePath)
        }
    }
    
    
    @IBAction func positionSliderChangeBegan(_ sender: UISlider) {
        if playerAdapter?.isPlaying == true {
            playerAdapter?.playOrPause()
        }
    }
    
    @IBAction func positionSliderChangeEnded(_ sender: UISlider) {
        playerAdapter?.updatePosition(CGFloat(sender.value))
        
        if playerAdapter?.isPlaying == false {
            playerAdapter?.playOrPause()
        }
    }
    @IBAction func networkURLSwitchAction(_ sender: Any) {
        prepareVideo(format: VideoFormat(rawValue: formatSelectionButton.title(for: .normal)!)!)
    }
    
    @IBAction func playOrPause(_ sender: Any) {
        playerAdapter?.playOrPause()
    }
}

