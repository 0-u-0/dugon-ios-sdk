//
//  Subscriber.swift
//  Dugon
//
//  Created by cong chen on 2020/4/21.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC

class Subscriber: Transport {
    var receivers = [Receiver]()
    
    var remoteSenders = [String: RemoteSender]()
    
    let asyncQueue = DispatchQueue(label: "subscriber.queue")
    
    var isDtls: Bool = false
    
    var currentMid = 0
    // follow sdp stupid mid's order
    
    public var onDtls: ((_ algorithm: String, _ hash: String, _ role: String) -> Void)?
    public var onMedia: ((_ source: MediaSource, _ receiver: Receiver) -> Void)?
    public var onUnsubscribed: ((_ recever: Receiver) -> Void)?
    
    override init(factory: RTCPeerConnectionFactory, id: String, iceCandidates: [ICECandidate], iceParameters: ICEParameters, dtlsParameters: [String: String]) {
        super.init(factory: factory, id: id, iceCandidates: iceCandidates, iceParameters: iceParameters, dtlsParameters:
            dtlsParameters)
    }
    
    func subscribe(receiver: Receiver) {
        asyncQueue.async {
             self._subscribe(receiver: receiver)
         }
    }
    
    private func _subscribe(receiver: Receiver) {
        guard let pc = pc else { return }
        
        receiver.media.direction = "sendonly"
//        receiver.media.rtps[0].fmtp["profile-level-id"] = "42e034";
        let remoteSdp = generateRemoteSdp()
        print(remoteSdp.sdp)
        pc.setRemoteDescription(remoteSdp) { error in
            guard error == nil else {
                // TODO:
                print(error.debugDescription)
                return
            }
            let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            pc.answer(for: constraints) { answer, error in
                if error == nil, let answer = answer {
                    print(answer.sdp)
                    pc.setLocalDescription(answer) { error in
                        if error != nil {
                            // TODO:
                            print(error.debugDescription)
                        }
                        if let transceiver = pc.transceivers.first(where: { $0.mid == receiver.mid }) {
                            if let track = transceiver.receiver.track {
                                guard let onMedia = self.onMedia else { return }
                                if track.kind == "audio", let audioTrack = track as? RTCAudioTrack {
                                    onMedia(RemoteAudioSource(track: audioTrack), receiver)
                                } else if track.kind == "video", let videoTrack = track as? RTCVideoTrack {
                                    onMedia(RemoteVideoSource(track: videoTrack), receiver)
                                }
//                                onTrack(track,receiver)
                            }
                        }
                        if !self.isDtls {
                            self.isDtls = true
                            let session = Sdp.parse(sdpStr: answer.sdp)
                            let media = session.medias[0]
                            guard let fingerprint = media.fingerprint else { return }
                            
                            guard let onDtls = self.onDtls else { return } // TODO: error
                            onDtls(fingerprint.algorithm, fingerprint.hash, "active")
                        }
                    }
                }
            }
        }
    }
    
    func getReceiver(id: String) -> Receiver? {
        return receivers.first(where: { $0.id == id && $0.available })
    }
    
    func getReceiver(senderId: String) -> Receiver? {
        return receivers.first(where: { $0.senderId == senderId && $0.available })
    }
    
    func unsubscribers(tokenId: String) {
        for receiver in receivers {
            if receiver.tokenId == tokenId {
                unsubscriber(receiverId: receiver.id)
            }
        }
    }
    
    func unsubscriber(receiverId: String) {
        if let receiver = getReceiver(id: receiverId) {
            asyncQueue.async {
                self._unsubscriber(receiver: receiver)
            }
        }
    }
    
    func unsubscriber(senderId: String) {
        if let receiver = getReceiver(senderId: senderId) {
            asyncQueue.async {
                self._unsubscriber(receiver: receiver)
            }
        }
    }
    
    func _unsubscriber(receiver: Receiver) {
        guard let pc = pc else { return }
        receiver.media.direction = "inactive"
        let remoteSdp = generateRemoteSdp()
        
        pc.setRemoteDescription(remoteSdp) { error in
            guard error == nil else {
                // TODO:
                print(error.debugDescription)
                return
            }
            let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            pc.answer(for: constraints) { answer, error in
                if error == nil, let answer = answer {
                    print(answer.sdp)
                    pc.setLocalDescription(answer) { error in
                        if error != nil {
                            // TODO:
                            print(error.debugDescription)
                        }
                        
                        guard let onUnsubscribed = self.onUnsubscribed else { return } // TODO: error
                        onUnsubscribed(receiver)
                    }
                }
            }
        }
    }
    
    func addReceiver(senderId: String, tokenId: String, receiverId: String, codec: Codec, metadata: [String: String]) -> Receiver {
        let mid = String(currentMid)
        currentMid += 1
        
        let media = Media.create(mid: mid, codec: codec, iceParameters: remoteICEParameters, iceCandidates: remoteICECandidates, msidAppdata: receiverId)
        let receiver = Receiver(mid: mid, senderId: senderId, tokenId: tokenId, receiverId: receiverId, codec: codec, metadata: metadata, media: media)
        
        receivers.append(receiver)
        return receiver
    }
    
    func generateRemoteSdp() -> RTCSessionDescription {
        let sdp = Sdp()
        sdp.version = 0
        sdp.origin = "o=- 10000 2 IN IP4 127.0.0.1"
        sdp.name = "-"
        sdp.timing = "0 0"
        sdp.msidSemantic = " WMS"
        
        if let algorithm = remoteDTLSParameters["algorithm"], let fingerprintValue = remoteDTLSParameters["value"] {
            sdp.fingerprint = Fingerprint(algorithm: algorithm, hash: fingerprintValue)
        }
        
        for receiver in receivers {
            sdp.medias.append(receiver.media)
        }
        
        return RTCSessionDescription(type: .offer, sdp: sdp.toString())
    }
}
