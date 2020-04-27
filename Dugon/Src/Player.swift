//
//  Player.swift
//  Dugon
//
//  Created by cong chen on 2020/4/15.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC

typealias LocalVideoView = RTCCameraPreviewView
// TODO: RTCMTLVideoView
typealias RemoteVieoView = RTCMTLVideoView

public enum PlayerType {
    case local
    case remote
    // enumeration definition goes here
}

public class Player:RTCVideoViewDelegate {
    
    public var view: UIView?

    public let type: PlayerType

    public init(type: PlayerType) {
        self.type = type
    }
    
    public func initView(x:Int,y:Int,width:Int,height:Int){
        switch type {
        case .local:
            self.view = LocalVideoView(frame: CGRect(x: x, y: y, width: width, height: height))
        case .remote:
//            let remoteView = RemoteVieoView(frame: CGRect(x: x, y: y, width: width, height: height))
//            remoteView.delegate = self
//            self.view = remoteView
            self.view = RemoteVieoView(frame: CGRect(x: x, y: y, width: width, height: height))
        }
    }
    
    public func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        
    }
}
