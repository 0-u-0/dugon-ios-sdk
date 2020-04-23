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
    
    static public func initTransport(videoSouce:VideoSource,audioSource:AudioSource){
        /*
         peerConnectionWithConfiguration:config
         constraints:constraints
            delegate:self];
         **/
        let config = RTCConfiguration()
        //        RTCCertificate *pcert = [RTCCertificate generateCertificateWithParams:@{
        //          @"expires" : @100000,
        //          @"name" : @"RSASSA-PKCS1-v1_5"
        //        }];
        //        config.iceServers = [];
        //        config.certificate = pcert;
        config.sdpSemantics = RTCSdpSemantics.unifiedPlan;
        
        let constraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
   
//        let t = Transport()
//        let pc = factory!.peerConnection(with: config, constraints: constraints, delegate: t)
//
//        let initConfig = RTCRtpTransceiverInit()
//        initConfig.direction = RTCRtpTransceiverDirection.sendOnly
//
//        let transceiver =   pc.addTransceiver(with: videoSouce.track, init: initConfig)
//        let transceiver2 =   pc.addTransceiver(with: audioSource.track, init: initConfig)
//
//
//        let constraints2 = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
//
//        pc.offer(for: constraints2) { (sdp, error) in
//            if(error == nil){
//                print(sdp!.sdp)
//               let sdpObj = Sdp.parse(sdpStr: sdp!.sdp)
//                print(sdpObj.toString())
//            }
//        }
    }
    
}
