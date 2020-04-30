//
//  Session.swift
//  Dugon
//
//  Created by cong chen on 2020/4/20.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC

let DEFAULT_VIDEO_CODEC = "VP8"
let DEFAULT_AUDIO_CODEC = "opus"

// TODO: move
struct ICEParameters: Codable {
    let password: String
    let usernameFragment: String
}

public protocol SessionDelegate: class {
    func onConnected()
    func onSender(sender: Sender)
    func onIn(tokenId: String, metadata: [String: String])
    func onOut(tokenId: String)
    func onReceiver(receiver: Receiver)
    func onMedia(source: MediaSource, receiver: Receiver)
    func onUnsubscribed(receiver: Receiver)
}

public class Session {
    var pub: Bool = false
    var sub: Bool = false
    
    let socket: Socket
    var supportedCodec: [String: Any]?
    
    let factory: RTCPeerConnectionFactory
    
    var publisher: Publisher?
    var subscriber: Subscriber?
    
    public weak var delegate: SessionDelegate?
    
    init(factory: RTCPeerConnectionFactory, sessionId: String, tokenId: String, metadata: [String: Any]) {
        self.factory = factory
        let params = ["sessionId": sessionId, "tokenId": tokenId, "metadata": metadata] as [String: Any]
        socket = Socket(url: "ws://192.168.31.254:8080", params: params)
        socket.onConnected = onConnected
        socket.onNotification = onNotification
    }
    
    public func connect(pub: Bool = true, sub: Bool = true) {
        self.pub = pub
        self.sub = sub
        socket.connect()
    }
    
    public func publish(source: MediaSource, codec: String) {
        guard let publisher = publisher else { return }
        guard let supportedCodec = supportedCodec else { return }
        guard let codecDic: [String: Any] = supportedCodec[codec] as? [String: Any] else { return }
        
        let codecCap = createByDic(type: Codec.self, dic: codecDic)
        guard codecCap != nil else { return }
        
        publisher.publish(source: source, codec: codecCap!)
    }
    
    public func publish(source: MediaSource) {
        var codec: String
        if source.type == .audio {
            codec = DEFAULT_AUDIO_CODEC
        } else {
            codec = DEFAULT_VIDEO_CODEC
        }
        publish(source: source, codec: codec)
    }
    
    public func unpublish(senderId: String) {
        guard let publisher = publisher else { return }
        publisher.unpublish(senderId: senderId)
    }
    
    public func subscribe(receiverId: String) {
        guard let subscriber = subscriber else { return }
        subscriber.subscribe(receiverId: receiverId)
    }
    
    public func unsubscribe(receiverId: String) {
        guard let subscriber = subscriber else { return }
        subscriber.unsubscriber(receiverId: receiverId)
    }
    
    private func initTransport(role: String, parameters: [String: Any]) {
        guard let transportId = parameters["id"] as? String else { return }
        guard let iceParam = parameters["iceParameters"] as? [String: Any] else { return }
        guard let iceCandidates = parameters["iceCandidates"] as? [[String: Any]] else { return }
        guard let dtlsParameters = parameters["dtlsParameters"] as? [String: Any] else { return }
        
        let candidates = iceCandidates.map { createByDic(type: ICECandidate.self, dic: $0)! }
        let iceParameters = createByDic(type: ICEParameters.self, dic: iceParam)!
        if role == "pub" {
            publisher = Publisher(factory: factory, id: transportId, iceCandidates: candidates, iceParameters: iceParameters, dtlsParameters: dtlsParameters)
            publisher!.onDtls = { (algorithm, hash, role) -> () in
                self.socket.request(params: ["event": "dtls", "data": [
                    "transportId": self.publisher!.id,
                    "role": "pub",
                    "dtlsParameters": [
                        "setup": role,
                        "fingerprint": [
                            "algorithm": algorithm,
                            "value": hash
                        ]
                    ]
                ]], callback: { (_: [String: Any]) -> () in
                    print("dtls ok")
                })
            }
            
            publisher!.onSender = { (sender) -> () in
                if let mergedMedia = sender.media {
                    if let pubCodec = mergedMedia.toCodec() {
                        let codecJson = pubCodec.toJson()
                        self.socket.request(event: "publish", data: [
                            "transportId": self.publisher!.id,
                            "codec": codecJson,
                            "metadata": []
                        ], callback: { (data: [String: Any]) -> () in
                            guard let senderId = data["senderId"] as? String else { return }
                            sender.id = senderId
                            
                            guard let delegate = self.delegate else { return }
                            delegate.onSender(sender: sender)
                        })
                    }
                }
            }
            
            publisher!.onUnpublished = { (senderId) -> () in
                self.socket.request(event: "unpublish", data: [
                    "transportId": self.publisher!.id,
                    "senderId": senderId,
                    "metadata": []
                ], callback: { (_: [String: Any]) -> () in
                    print("unpublish ok")
                })
            }
            
            publisher!.initi()
        } else if role == "sub" {
            // TODO:
            subscriber = Subscriber(factory: factory, id: transportId, iceCandidates: candidates, iceParameters: iceParameters, dtlsParameters: dtlsParameters)
            subscriber!.onMedia = { (source, receiver) -> () in
                guard let delegate = self.delegate else { return }
                delegate.onMedia(source: source, receiver: receiver)
            }
            
            subscriber!.onDtls = { (algorithm, hash, role) -> () in
                self.socket.request(params: ["event": "dtls", "data": [
                    "transportId": self.subscriber!.id,
                    "role": "sub",
                    "dtlsParameters": [
                        "setup": role,
                        "fingerprint": [
                            "algorithm": algorithm,
                            "value": hash
                        ]
                    ]
                ]], callback: { (_: [String: Any]) -> () in
                    print("dtls ok")
                })
            }
            
            subscriber!.onUnsubscribed = { (receiver) -> () in
                guard let delegate = self.delegate else { return }
                delegate.onUnsubscribed(receiver: receiver)
                self.socket.request(event: "unsubscribe", data: [
                    "transportId": self.subscriber!.id, "senderId": receiver.senderId
                ], callback: { (_: [String: Any]) -> () in
                    print("unsubscribed ok")
                })
            }
            
            subscriber!.initi()
        }
    }
    
    // MARK: - SocketDelegate
    
    func onConnected() {
        socket.request(params: ["event": "join", "data": [
            "pub": pub,
            "sub": sub
        ]], callback: { (data: [String: Any]) -> () in
            guard let codecs = data["codecs"] as? [String: Any] else { return }
            if self.pub {
                guard let pubParameters = data["pub"] as? [String: Any] else { return }
                self.initTransport(role: "pub", parameters: pubParameters)
            }
            if self.sub {
                guard let subParameters = data["sub"] as? [String: Any] else { return }
                self.initTransport(role: "sub", parameters: subParameters)
            }
            
            self.supportedCodec = codecs
            
            guard let delegate = self.delegate else { return }
            delegate.onConnected()
        })
    }
    
    func onNotification(event: String, data: [String: Any]) {
        print("notification: \(event) ")
        switch event {
            case "join":
                guard let tokenId = data["tokenId"] as? String, let metadata = data["metadata"] as? [String: String] else { return }
                guard let delegate = delegate else { return }
                delegate.onIn(tokenId: tokenId, metadata: metadata)
            case "leave":
                guard let tokenId = data["tokenId"] as? String else { return }
                
                guard let subscriber = self.subscriber else { return }
                subscriber.unsubscribers(tokenId: tokenId)
                
                guard let delegate = delegate else { return }
                delegate.onOut(tokenId: tokenId)
                                
            case "publish":
                guard let senderId = data["senderId"] as? String, let tokenId = data["tokenId"] as? String, let receiverId = data["receiverId"] as? String, let metadata = data["metadata"] as? [String: String], let codecDic = data["codec"] as? [String: Any] else { return }
                // TODO: check codec
                let codec = createByDic(type: Codec.self, dic: codecDic)!
                
                guard let subscriber = self.subscriber else { return }
                let receiver = subscriber.addReceiver(senderId: senderId, tokenId: tokenId, receiverId: receiverId, codec: codec, metadata: metadata)
                guard let delegate = delegate else { return }
                delegate.onReceiver(receiver: receiver)
                
            case "unpublish":
                guard let senderId = data["senderId"] as? String, let tokenId = data["tokenId"] as? String else { return }
                guard let subscriber = self.subscriber else { return }
                subscriber.unsubscriber(senderId: senderId)
            
            case "pause":
                break
            case "resume":
                break
            default:
                break
        }
    }
}
