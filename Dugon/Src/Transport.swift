//
//  Transport.swift
//  Dugon
//
//  Created by cong chen on 2020/4/15.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC


class Transport: NSObject,RTCPeerConnectionDelegate{
    
    var pc:RTCPeerConnection?
    
    let id:String
    
    let remoteDTLSParameters:[String:String]
    let remoteICEParameters:ICEParameters
    let remoteICECandidates:[ICECandidate]
    
    let factory:RTCPeerConnectionFactory
    
    init(factory:RTCPeerConnectionFactory,id:String,iceCandidates:[ICECandidate],iceParameters:ICEParameters,dtlsParameters:[String:String]){
        self.factory = factory
        self.id = id
        self.remoteICECandidates = iceCandidates
        self.remoteICEParameters = iceParameters
        self.remoteDTLSParameters = dtlsParameters
        super.init()
    }
    
    func initi(){
     
        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan;
        config.bundlePolicy = .maxBundle
        let constraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
        pc = factory.peerConnection(with: config, constraints: constraints, delegate: self)
               
    }
    
    
    // MARK: - RTCPeerConnectionDelegate
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case .checking:
            print("peerConnection: checking")
        case .closed:
            print("peerConnection: closed")
        case .completed:
            print("peerConnection: completed")
        case .connected:
            print("peerConnection: connected")
        case .failed:
            print("peerConnection: failed")
        case .new:
            print("peerConnection: new")
        default:
            print("peerConnection: unknown ice state")
        }
//        print("ice state \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
    
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
}
