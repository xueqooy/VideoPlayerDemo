//
//  VideoFormat.swift
//  VideoPlayerDemo
//
//  Created by xueqooy on 2022/12/8.
//

import Foundation

enum VideoFormat: String, CaseIterable {
    case mp4, mov, avi, mkv, flv, webm, rmvb, wmv
    
    var rawValue: String {
        switch self {
        case .mp4:
            return "mp4"
        case .mov:
            return "mov"
        case .avi:
            return "avi"
        case .mkv:
            return "mkv"
        case .flv:
            return "flv"
        case .webm:
            return "webm"
        case .rmvb:
            return "rmvb"
        case .wmv:
            return "wmv"
        }
    }
    
    var filepath: String? {
        return Bundle.main.path(forResource: "sample", ofType: rawValue)
    }
    
    var networkURL :URL? {
        if let networkURLString = Self.netowrkSamples[rawValue], !networkURLString.isEmpty {
            return URL(string: networkURLString)
        }
        return nil
    }
    
    static private let netowrkSamples: [String: String] = {
        let path = Bundle.main.path(forResource: "networkSamples", ofType: "plist")
        return NSDictionary(contentsOfFile: path!) as! [String : String]
    }()
}
