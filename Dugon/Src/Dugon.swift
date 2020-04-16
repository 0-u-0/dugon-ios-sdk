//
//  Dugon.swift
//  Dugon
//
//  Created by cong chen on 2020/4/15.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC


public struct Dugon{
    static private var encoderFactory:RTCDefaultVideoEncoderFactory?
    static private var decoderFactory:RTCDefaultVideoDecoderFactory?
    static private var factory:RTCPeerConnectionFactory?
    
    //TODO: add init check
    static public func initialize(){
        RTCInitializeSSL()
        RTCEnableMetrics()
        
        decoderFactory = RTCDefaultVideoDecoderFactory();
        encoderFactory = RTCDefaultVideoEncoderFactory();
        factory = RTCPeerConnectionFactory.init(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
    }
    
   static public func createVideoSource()  -> VideoSouce {
        let rtcSource = factory!.videoSource()
        let videoTrack = factory!.videoTrack(with: rtcSource, trackId: "abc")
        return VideoSouce(source: rtcSource, track: videoTrack)
   }
    
}
