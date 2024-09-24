//
//  Publisher.swift
//  Dugon
//
//  Created by cong chen on 2020/4/21.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC

class Publisher: Transport {
    var senders = [Sender]()
    
    let asyncQueue = DispatchQueue(label: "publisher.queue")
    
    var isDtls: Bool = false
    
    // follow sdp stupid mid's order
    var usedMids = [String]()
    
    public var onDtls: ((_ algorithm: String, _ hash: String, _ role: String) -> Void)?
    public var onSender: ((_ sender: Sender) -> Void)?
    public var onUnpublished: ((_ senderId: String) -> Void)?
    
    override init(factory: RTCPeerConnectionFactory, id: String, iceCandidates: [ICECandidate], iceParameters: ICEParameters, dtlsParameters: [String: String]) {
        super.init(factory: factory, id: id, iceCandidates: iceCandidates, iceParameters: iceParameters, dtlsParameters:
            dtlsParameters)
    }
    
    func publish(source: MediaSource, codec: Codec, metadata: [String: String]) {
        asyncQueue.async {
            self._publish(source: source, codec: codec, metadata: metadata)
        }
    }
    
    func getSender(id: String) -> Sender? {
        return senders.first(where: { $0.id == id })
    }
    
    func unpublish(senderId: String) {
        if let sender = getSender(id: senderId) {
            asyncQueue.async {
                self._unpublish(sender: sender)
            }
        }
    }
    
    private func _unpublish(sender: Sender) {
        guard let pc = pc else { return }
        
        pc.removeTrack(sender.transceiver.sender)
        
        let constraints2 = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        
        pc.offer(for: constraints2) { sdp, error in
            guard error == nil else {
                // TODO:
                return
            }
            
            guard let sdp = sdp else { return }
            pc.setLocalDescription(sdp) { error in
                guard error == nil else {
                    // TODO:
                    return
                }
                
                let session = Sdp.parse(sdpStr: sdp.sdp)
                
                self.usedMids = session.medias.map { $0.mid ?? "?" }
                
                sender.media?.direction = "inactive"
                
                let remoteSdp = self.generateRemoteSdp()
//                print(remoteSdp)
                pc.setRemoteDescription(remoteSdp, completionHandler: { (error: Error?) in
                    guard error == nil else { print(error); return }
                    guard let onUnpublished = self.onUnpublished else { return } // TODO: error
                    onUnpublished(sender.id!)
                })
            }
        }
    }
    
    func _publish(source: MediaSource, codec: Codec, metadata: [String: String]) {
        guard let pc = pc else { return }
        
        let initConfig = RTCRtpTransceiverInit()
        initConfig.direction = RTCRtpTransceiverDirection.sendOnly
        
        let transceiver = pc.addTransceiver(with: source.mediaTrack, init: initConfig)
        let sender = Sender(transceiver: transceiver!,metadata: metadata)
        senders.append(sender)
        
        let constraints2 = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        
        pc.offer(for: constraints2) { sdp, error in
            guard error == nil else {
                // TODO:
                return
            }
            
            guard let sdp = sdp else { return }
            pc.setLocalDescription(sdp) { error in
                guard error == nil else {
                    // TODO:
                    return
                }
//                print("local sdp")
//                print(sdp.sdp)
                let session = Sdp.parse(sdpStr: sdp.sdp)
                
                if !self.isDtls {
                    self.isDtls = true
                    let media = session.medias[0]
                    guard let fingerprint = media.fingerprint else { return }
                    
                    guard let onDtls = self.onDtls else { return } // TODO: error
                    onDtls(fingerprint.algorithm, fingerprint.hash, "active")
                }
                
                // RemoteSdp
                var mergedMedia: Media?
                var usedMids = [String]()
                for media in session.medias {
                    guard let mid = media.mid else { break }
                    usedMids.append(mid)
                    if sender.mid == mid {
                        mergedMedia = media.merge(codecCap: codec, iceParameters: self.remoteICEParameters, iceCandidates: self.remoteICECandidates)
                    }
                }
                self.usedMids = usedMids
//                print(usedMids)
                
                sender.media = mergedMedia
                
                let remoteSdp = self.generateRemoteSdp()
//                print(remoteSdp)
                self.pc?.setRemoteDescription(remoteSdp, completionHandler: { (error: Error?) in
                    guard error == nil else { print(error); return }
                    guard let onSender = self.onSender else { return } // TODO: error
                    onSender(sender)
                })
            }
        }
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
        
        for mid in usedMids {
            if let s = senders.first(where: { $0.mid == mid }) {
                sdp.medias.append(s.media!)
            }
        }
        
        return RTCSessionDescription(type: .answer, sdp: sdp.toString())
    }
}
