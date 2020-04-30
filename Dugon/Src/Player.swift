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

#if RTC_SUPPORTS_METAL
typealias RemoteVieoView = RTCMTLVideoView
#else
typealias RemoteVieoView = RTCEAGLVideoView
#endif

public enum PlayerType {
    case local
    case remote
    // enumeration definition goes here
}

public class Player: RTCVideoViewDelegate {
    public var view: UIView

    public let type: PlayerType

    public init(type: PlayerType, x: Int, y: Int, width: Int, height: Int) {
        self.type = type
        
        let frame = CGRect(x: x, y: y, width: width, height: height)        
        switch type {
        case .local:
            self.view = LocalVideoView(frame: frame)
        case .remote:
            self.view = RemoteVieoView(frame: frame)
            #if !RTC_SUPPORTS_METAL
            if let v = self.view as? RTCEAGLVideoView {
                v.delegate = self
            }
            #endif
        }
    }
    
    public func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        //TODO: save size
        //        if (videoView == _remoteVideoView) {
        //          _remoteVideoSize = size;
        //        }
        if let v = self.view as? RTCEAGLVideoView {
            v.setNeedsLayout()
        }
    }
}
