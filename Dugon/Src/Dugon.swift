//
//  Dugon.swift
//  Dugon
//
//  Created by cong chen on 2020/4/15.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC

public struct Dugon {
//    private static var encoderFactory: RTCDefaultVideoEncoderFactory?
//    private static var decoderFactory: RTCDefaultVideoDecoderFactory?
    private static var factory: RTCPeerConnectionFactory?
    
    // TODO: add init check
    public static func initialize() {
        RTCInitializeSSL()
        RTCEnableMetrics()
        
       let  decoderFactory = RTCDefaultVideoDecoderFactory()
       let  encoderFactory = RTCDefaultVideoEncoderFactory()
        
//        RTCDefaultVideoEncoderFactory.supportedCodecs().map { (info) -> Void in
//
//            print(info.parameters)
//        }
        
//        RTCDefaultVideoDecoderFactory.supportedCodecs().map { (info) -> Void in
//        
//                    print(info.parameters)
//        }
        factory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
    }
    
    public static func createSession(sessionId: String, tokenId: String, metadata: [String: Any]) -> Session? {
        guard let factory = factory else { return nil }
        return Session(factory: factory, sessionId: sessionId, tokenId: tokenId, metadata: metadata)
    }
    
    public static func createVideoSource() -> LocalVideoSource? {
        guard let factory = factory else { return nil }
        
        let rtcSource = factory.videoSource()
        let videoTrack = factory.videoTrack(with: rtcSource, trackId: "video")
        return LocalVideoSource(track: videoTrack)
    }
    
    public static func createAudioSource() -> LocalAudioSource? {
        guard let factory = factory else { return nil }
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let rtcAudioSource = factory.audioSource(with: constraints)
        let audioTrack = factory.audioTrack(with: rtcAudioSource, trackId: "audio")
        return LocalAudioSource(track: audioTrack)
    }
}
