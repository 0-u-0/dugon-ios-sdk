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
    
    static public func createSession(sessionId:String,tokenId:String,metadata:[String:Any]) -> Session?{
        guard let factory = factory else {return nil}
        return Session(factory:factory ,sessionId: sessionId, tokenId: tokenId, metadata: metadata)
    }
    
    static public func createVideoSource()  -> VideoSource? {
        guard let factory = factory else {return nil}
        
        let rtcSource = factory.videoSource()
        let videoTrack = factory.videoTrack(with: rtcSource, trackId: "video")
        return VideoSource(source: rtcSource, track: videoTrack)
    }
    
    static public func createAudioSource() -> AudioSource?{
        guard let factory = factory else {return nil}

        let constraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
        let rtcAudioSource = factory.audioSource(with: constraints)
        let audioTrack = factory.audioTrack(with: rtcAudioSource, trackId: "audio")
        return AudioSource(source: rtcAudioSource, track: audioTrack)
    }
    
    
}
