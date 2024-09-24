//
//  File.swift
//  
//
//  Created by cong chen on 2020/4/17.
//

import Foundation



//https://tools.ietf.org/html/rfc4566
public class Sdp{
    public var version:Int?
    public var origin:String?
    public var name:String?
    public var timing:String?
    public var group:String?
    public var msidSemantic:String?
    
    public var fingerprint:Fingerprint?
    public var medias = [Media]()
    public var iceLite = true
    
    public static func parse(sdpStr:String) -> Sdp {
            //TODO: make separator as parameters
            let lines  = sdpStr.split(separator: "\r\n")
            //find indexs of medias
            var mediaIndexs = [Int]()
            for (index,line) in lines.enumerated() {
                if line.starts(with: "m=") {
                    mediaIndexs.append(index)
                }
            }
            //TODO: no session
            var session:Sdp
            if 0 == mediaIndexs.count {
                //no media
                session = handleSession(lines: lines)
            }else{
                let sessionLines  = Array(lines[..<mediaIndexs[0]])
                session = handleSession(lines: sessionLines)
                
                for i in 0..<mediaIndexs.count {
                    var mediaLines:[String];
                    if i == (mediaIndexs.count - 1){
                        mediaLines  = Array(lines[mediaIndexs[i]..<(lines.count)])
                    }else{
                        mediaLines  = Array(lines[mediaIndexs[i]..<mediaIndexs[i+1]])
                    }
                    let media = handleMedia(lines: mediaLines)
                    session.medias.append(media)
                }
            }
            return session
        }
 
        static func handleSession(lines:[String]) -> Sdp {
            let session = Sdp()
            for line in lines{
                let type = line[line.startIndex]
                let value = line[2...]

                switch type {
                case "v":
                    //%x76 "=" 1*DIGIT CRLF
                    session.version = Int(line[2])
                case "o":
                    session.origin = value
                case "s":
                    session.name = value
                case "t":
                    session.timing = value
                case "a":
                    let attrPair  = value.components(separatedBy: ":")
                    if attrPair.count == 2 {
                        let attrKey = attrPair[0]
                        let attrValue = attrPair[1]
                        switch attrKey {
                            case "group":
                                //TODO:
                                session.group = attrValue
                            case "msid-semantic":
                                session.msidSemantic = attrValue
                            default:
                                print("unknown attr \(attrKey)")
                        }
                    }
                default:
                    print("unknown  type \(type)")
                }
            }
            
            return session
        }
        
        static func handleMedia(lines:[String]) -> Media {
            var media = Media(role: .undf)
            for line in lines{
                let type = line[line.startIndex]
                let value = line[2...]

                switch type {
                case "m":
                    let pattern = #"(video|audio|application) ([0-9]+) ([A-Z/]+) ([[0-9]|\s]+)"#
                    let result = value.matchingStrings(regex: pattern)
                    if result.count == 5 {
                        media.type = result[1]
                        //TODO: Int
                        media.port = Int(result[2])
                        media.proto = result[3]
                        //FIXME: use array
//                        let payloads = result[4].components(separatedBy: " ")
//                        for payload in payloads {
//                            let rtp = Rtp(payload: Int(payload)!)
//                            media.rtps.append(rtp)
//                        }
                    }
                case "c":
                    media.connection = value
                case "a":
                    let attrPair  = value.splitOnce(separator: ":")
                    if attrPair.count == 1{
                        switch value {
                        case "rtcp-mux":
                            media.rtcpMux = true
                        case "rtcp-rsize":
                            media.rtcpRsize = true
                        case "sendrecv","sendonly","recvonly","inactive":
                            media.direction = value
                        default:
                            print("unknown attr c1 \(value)")
                         }
                    }else if attrPair.count == 2{
                        let attrKey = attrPair[0]
                        let attrValue = attrPair[1]
                        switch attrKey {
                        case "ice-ufrag":
                            media.iceUfrag = attrValue
                        case "ice-pwd":
                            media.icePwd = attrValue
                        case "ice-options":
                            media.iceOptions = attrValue
                        case "setup":
                            media.setup = attrValue
                        case "mid":
                            //TODO: to Int
                            media.mid = attrValue
                        case "rtcp":
                            //TODO: destruct
                            media.rtcp = attrValue
                        case "msid":
                            media.msid = attrValue
                        case "fingerprint":
                            let fingerprintPair = attrValue.splitOnce(separator: " ")
                            //TODO: check pair count
                            media.fingerprint = Fingerprint(algorithm: fingerprintPair[0], hash: fingerprintPair[1])
                        case "extmap":
                             let pattern = #"([0-9]+) (\S+)"#
                             let result = value.matchingStrings(regex: pattern)
                             if result.count == 3 {
                                let ext = Extension(id: Int(result[1])!, uri: result[2])
                                media.extensions.append(ext)
                             }
                            
                        case "rtpmap":
                            let pattern = #"([0-9]+) ([\w-]+)/([0-9]+)(?:/([0-9]+))?"#
                            let result = value.matchingStrings(regex: pattern)
                            if result.count >= 4 {
                                guard let payload = Int(result[1]) else { break }
                                if result[2] == "rtx" {
                                    media.rtxPayloads.append(payload)
                                }else{
                                    var rtp = Rtp(payload: payload,codec: result[2],rate:Int(result[3])! )
                                    if result.count == 5 {
                                        rtp.channels = Int(result[4])!
                                    }
                                    media.rtps.append(rtp)
                                    
                                }
                            }
                        case "rtcp-fb":
                              let pattern = #"([0-9]+) ([\w\p{Z}-]+)"#
                              let result = value.matchingStrings(regex: pattern)
                              //TODO: check count
                              if let index = media.getRtpIndex(payload: Int(result[1])!)  {
                                let rf = result[2].splitOnce(separator: " ")
                                if rf.count == 1 {
                                    media.rtps[index].rtcpFb.append(RtcpFeedback(type:rf[0]))
                                }else if rf.count == 2{
                                    media.rtps[index].rtcpFb.append(RtcpFeedback(type:rf[0],parameter:rf[1]))
                                }
                              }
                        case "fmtp":
                            let pattern = #"([0-9]+) ([\w-;=]+)"#
                            let result = value.matchingStrings(regex: pattern)
                            //TODO: check count
                    
                            guard let payload = Int(result[1]) else { break }
                            
                            if media.rtxPayloads.contains(payload) {
                                let config = result[2].splitOnce(separator: "=")
                                let mainPayload = Int(config[1])!
                                if let index = media.getRtpIndex(payload: mainPayload)  {
                                    media.rtps[index].rtx = payload
                                }
                            }else{
                                if let index = media.getRtpIndex(payload: payload)  {
                                    let fmtps = result[2].split(separator: ";")
                                    for f in fmtps {
                                        let value = f.split(separator: "=")
                                        media.rtps[index].fmtp[value[0]] = value[1]
                                    }
                                }
                            }
                            
                        case "ssrc":
                            //https://tools.ietf.org/html/rfc5576#page-5
                            let pattern = #"([0-9]+) ([\w]+):([\w\W\b]+)$"#
                            let result = value.matchingStrings(regex: pattern)
                            
                            
                            if media.ssrc == nil {
                                media.ssrc = Int(result[1])!
                            }
                            if  result[2] == "cname" {
                                if media.cname == nil{
                                    media.cname = result[3]
                                }
                            }
                            
                            //TODO: check count
//                            let ssrc = Ssrc(id: Int(result[1])!, attribute: result[2], value: result[3])
//                            media.ssrcs.append(ssrc)
                        case "ssrc-group":
                            let pattern = #"([\w]+) ([0-9\p{Z}]+)"#
                            let result = value.matchingStrings(regex: pattern)
                            if result.count == 3 {
                                if result[1] == "FID" {
                                    let ssrcs = result[2].splitOnce(separator: " ")
                                    
                                    //TODO: check count
                                    if media.ssrc == nil {
                                        media.ssrc = Int(ssrcs[0])!
                                    }
                                    
                                    if media.rtxSsrc == nil {
                                        media.rtxSsrc = Int(ssrcs[1])!
                                    }
                                }
//                                let sg = SsrcGroup(semantics: result[1], ssrcs: ssrcs)
//                                media.ssrcGroups.append(sg)
                            }
                        case "candidate":
                            //TODO: address it later
                            break
                        default:
                           print("unknown attr c2 \(attrKey)")
                        }
                    }
                   
                default:
                    print("unknown  type \(type)")
                }
            }
            return media
        }
    
    public func toString(insertMedia:Media? = nil) -> String {
        var lines = [String]()
        if version != nil {
            lines.append("v=\(version!)")
        }
        
        if origin != nil {
            lines.append("o=- 10000 2 IN IP4 127.0.0.1")
        }
        
        if name != nil {
            lines.append("s=\(name!)")
        }
        
        if timing != nil {
            lines.append("t=\(timing!)")
        }
        
        if iceLite {
            lines.append("a=ice-lite")
        }
        
        if group != nil {
            lines.append("a=group:\(group!)")
        }
        if let msidSemantic = msidSemantic {
            lines.append("a=msid-semantic:\(msidSemantic)")
        }
        
        let mids = medias.filter{$0.available || $0.mid! == "0"}.map{$0.mid!}.joined(separator: " ")
        lines.append("a=group:BUNDLE \(mids)")

        if let fingerprint = fingerprint {
            lines.append("a=fingerprint:\(fingerprint.algorithm) \(fingerprint.hash)")
        }
        
        for media in medias {
            lines.append(media.toString())
        }
        
        if let insertMedia = insertMedia {
            lines.append(insertMedia.toString())
        }
        var sdp = lines.joined(separator: "\n")
        
        sdp = sdp + "\n"
        return sdp
    }

}
