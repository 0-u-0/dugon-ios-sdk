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

public protocol SessionDelegate:class {
    func onConnected();
    func onSender(sender:Sender);
}

public class Session{
    var pub:Bool = false
    var sub:Bool = false

    let socket:Socket
    var supportedCodec:[String:Any]?

    let factory:RTCPeerConnectionFactory
    
    var publisher:Publisher?
    
    public weak var delegate:SessionDelegate?

    init(factory:RTCPeerConnectionFactory,sessionId:String,tokenId:String, metadata:[String:Any]) {
        self.factory = factory
        let params = ["sessionId":sessionId,"tokenId":tokenId,"metadata":metadata] as [String : Any]
        socket = Socket(url: "ws://192.168.31.254:8080", params: params)
        socket.onConnected = self.onConnected
        socket.onNotification = self.onNotification
    }
    
    public func connect(pub:Bool=true,sub:Bool=true) {
        self.pub = pub
        self.sub = sub
        socket.connect()
    }
    

    public func publish(source:MediaSource, codec:String){
        guard let publisher = publisher else { return }
        guard let supportedCodec = supportedCodec else { return }
        guard let codecDic:[String:Any] = supportedCodec[codec] as? [String:Any] else { return }

        let codecCap = Codec.create(dic: codecDic)
        guard codecCap != nil else { return }
        
        publisher.publish(source: source,codec: codecCap!)
    }
    
    public func publish(source:MediaSource){
        var codec:String
        if source.type == "audio" {
            codec = DEFAULT_AUDIO_CODEC
        } else {
            codec = DEFAULT_VIDEO_CODEC
        }
        self.publish(source: source, codec: codec)
    }
    
    public func unpublish(senderId:String){
        guard let publisher = publisher else { return }
        publisher.unpublish(senderId: senderId)
    }
    
    private func initTransport(role:String,parameters:[String:Any]){
        guard let transportId = parameters["id"] as? String else {return}
        guard let iceParameters = parameters["iceParameters"] as? [String:Any] else {return}
        guard let iceCandidates = parameters["iceCandidates"] as? [[String:Any]] else {return}
        guard let dtlsParameters = parameters["dtlsParameters"] as? [String:Any] else {return}

        if role == "pub" {
            publisher = Publisher(factory: factory, id: transportId, iceCandidate: iceCandidates, iceParameters: iceParameters, dtlsParameters: dtlsParameters)
            publisher!.onDtls = {(algorithm,hash,role)->Void in
                self.socket.request(params: ["event":"dtls","data":[
                    "transportId":self.publisher!.id,
                    "role":"pub",
                    "dtlsParameters":[
                        "setup":role,
                        "fingerprint": [
                          "algorithm": algorithm,
                          "value": hash
                        ]
                    ]
                    ]], callback:{(data:[String:Any])->() in
                        print("dtls ok")
                })
            }
            
            
            publisher!.onSender = {(sender)->Void in
                if let mergedMedia = sender.media {
                    if let pubCodec = mergedMedia.toCodec() {
                        let codecJson = pubCodec.toJson()
                        self.socket.request(event:"publish",data:[
                            "transportId":self.publisher!.id,
                            "codec":codecJson,
                            "metadata":[]
                            ], callback:{(data:[String:Any])->() in
                                guard let senderId = data["senderId"] as? String else { return }
                                sender.id = senderId
                                
                                guard let delegate = self.delegate else { return }
                                delegate.onSender(sender: sender)
                        })
                    }
                }
            }
            
            publisher!.onSenderClosed = {(senderId)-> Void in
                self.socket.request(event:"unpublish",data:[
                    "transportId":self.publisher!.id,
                    "senderId":senderId,
                    "metadata":[]
                    ], callback:{(data:[String:Any])->() in
                        print("unpublish ok")
                })
            }
            
            publisher!.initi()
        }else if role == "sub" {
            //TODO:
        }
    }
    
    
    // MARK: - SocketDelegate
    func onConnected() {
        socket.request(params: ["event":"join","data":[
            "pub":self.pub,
            "sub":self.sub
            ]], callback:{(data:[String:Any])->() in
                guard let codecs = data["codecs"] as? [String:Any] else {return}
                if self.pub {
                    guard let pubParameters = data["pub"] as? [String:Any] else {return}
                    self.initTransport(role: "pub", parameters: pubParameters)
                }
                if self.sub {
                    guard let subParameters = data["sub"] as? [String:Any] else {return}
                    self.initTransport(role: "sub", parameters: subParameters)
                }
                
                self.supportedCodec = codecs
                
                guard let delegate = self.delegate else { return }
                delegate.onConnected()
        })
    }
    
    func onNotification(event:String,data:[String:Any])  {
        print("notification: \(event) ")
          switch event {
            case "join":
                break
            case "leave":
                break
            case "publish":
                break
            case "unpublish":
                break
            case "pause":
                break
            case "resume":
                break
            default:
                break
          }
    }
}
