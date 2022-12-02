//
//  PlayerListViewController.swift
//  VideoPlayerPractice
//
//  Created by xueqooy on 2022/11/30.
//

import UIKit

class PlayerListViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Player.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let player = Player.allCases[indexPath.row]
        
        var contentConfig = UIListContentConfiguration.cell()
        contentConfig.text = player.rawValue
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.contentConfiguration = contentConfig
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let label = UILabel()
        label.numberOfLines = 0
    #if IJK_DEMO
        label.text = "\n    AVKit和VLCKit播放器demo请选择VideoPlayerDemo Target"
    #else
        label.text = "\n    IJK播放器demo请选择IJKPlayerDemo Target"
    #endif
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textColor = .lightGray
        return label
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let player = Player.allCases[indexPath.row]
        let playerAdapter = PlayerAdapter(player: player)
        
        let viewController = ViewController.instantiate(playerAdatper: playerAdapter)
        viewController.title = player.rawValue
        
        navigationController?.pushViewController(viewController, animated: true)
        
    }
}
