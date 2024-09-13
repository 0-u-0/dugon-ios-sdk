//
//  File.swift
//
//
//  Created by cong chen on 2020/4/17.
//

import Foundation

struct ICECandidate: Codable {
    let component: Int
    let foundation: String
    let ip: String
    let port: Int
    let priority: Int
    let transport: String
    let type: String
    
    var description: String {
        return "a=candidate:\(foundation) \(component) \(transport) \(priority) \(ip) \(port) typ \(type)"
    }
}

public struct Rtp {
    public let payload: Int
    public var codec: String
    public var rate: Int
    public var channels: Int = 1
    public var rtcpFb = [RtcpFeedback]()
    public var fmtp = [String: String]()
    
    public var rtx: Int? // payload
    
    public func toString() -> String {
        var lines = [String]()
        if channels == 1 {
            lines.append("a=rtpmap:\(payload) \(codec)/\(rate)")
        } else {
            lines.append("a=rtpmap:\(payload) \(codec)/\(rate)/\(channels)")
        }
        if let rtx = rtx {
            lines.append("a=rtpmap:\(rtx) rtx/\(rate)")
        }
        
        if fmtp.count > 1{
            let config = fmtp.map { "\($0)=\($1)" }.joined(separator: ";")
            lines.append("a=fmtp:\(payload) \(config)")
        }

        
        for rf in rtcpFb {
            let r = "a=rtcp-fb:\(payload) \(rf.type) \(rf.parameter)".trimmingCharacters(in: .whitespacesAndNewlines)
            lines.append(r)
        }
        
        if let rtx = rtx {
            lines.append("a=fmtp:\(rtx) apt=\(payload)")
        }
        
        let rtpSdp = lines.joined(separator: "\n")
        return rtpSdp
    }
}

public struct Fingerprint {
    public let algorithm: String
    public let hash: String
}

public struct RtcpFeedback: Codable {
    public let type: String
    public let parameter: String
    
    init(type: String, parameter: String = "") {
        self.type = type
        self.parameter = parameter
    }
}

public struct Extension: Codable {
    public let id: Int
    public let uri: String
}

enum MediaRole {
    case send
    case recv
    case undf
}

public struct Media {
    public var type: String?
    public var port: Int?
    public var mid: String?
    var role:MediaRole
    // protocol
    public var proto: String?
    public var connection: String?
    public var direction: String?
    public var iceUfrag: String?
    public var icePwd: String?
    public var iceOptions: String?
    public var setup: String?
    public var rtcp: String?
    public var msid: String?
    public var msidAppdata: String?
    
    public var ssrc: Int?
    public var rtxSsrc: Int?
    
    public var cname: String?
    
    public var fingerprint: Fingerprint?
    
    public var extensions = [Extension]()
    public var rtps = [Rtp]()
    var candidates = [ICECandidate]()
    
//    public var ssrcGroups = [SsrcGroup]()
    
    public var rtxPayloads = [Int]()
    
    public var rtcpMux: Bool = false
    public var rtcpRsize: Bool = false
    
    public var available: Bool {
        if let direction = direction {
            return direction != "inactive"
        }
        return false
    }
    // for sub
    static func create(mid: String, codec: Codec, iceParameters: ICEParameters, iceCandidates: [ICECandidate], msidAppdata: String) -> Media {
        var media = Media(role: .send)
        media.type = codec.kind
        media.mid = mid
        media.port = 7
        // TODO: iceOptions
        media.iceOptions = "renomination"
        media.proto = "UDP/TLS/RTP/SAVPF"
        media.connection = "IN IP4 127.0.0.1"
        //
        media.setup = "actpass"
        media.direction = "inactive"
        media.iceUfrag = iceParameters.usernameFragment
        media.icePwd = iceParameters.password
        media.ssrc = codec.ssrc
        media.cname = codec.cname
        media.candidates = iceCandidates
        media.extensions = codec.extensions
        media.rtcpRsize = codec.reducedSize
        media.rtcpMux = codec.mux ?? true
        // https://tools.ietf.org/html/draft-ietf-mmusic-msid-17#page-5
        media.msidAppdata = msidAppdata
        
        var rtp = Rtp(payload: codec.payload, codec: codec.codecName, rate: codec.clockRate, channels: codec.channels)
        if codec.kind == "audio"{
            rtp.fmtp = codec.parameters
        }
//        rtp.fmtp["level-asymmetry-allowed"] = "1"
//        rtp.fmtp["profile-level-id"] = "42e01f"

        rtp.rtcpFb = codec.rtcpFeedback
        
        if let rtx = codec.rtx {
            rtp.rtx = rtx.payload
            media.rtxSsrc = rtx.ssrc
        }
        
        media.rtps.append(rtp)
        // this will become trackId
        return media
    }
    // for pub
    func merge(codecCap: Codec, iceParameters: ICEParameters, iceCandidates: [ICECandidate]) -> Media? {
        // extensions
        // rtcpFb
        var mergedMedia = Media(role: .recv)
        
        mergedMedia.type = type
        mergedMedia.proto = proto
        mergedMedia.port = port
        mergedMedia.cname = cname
        mergedMedia.connection = "IN IP4 127.0.0.1"
        mergedMedia.mid = mid
        //useless
//        mergedMedia.ssrc = ssrc
        mergedMedia.iceOptions = "renomination"
        
        if let direction = self.direction {
            if direction == "inactive" {
                mergedMedia.direction = "inactive"
            } else {
                mergedMedia.direction = "recvonly"
            }
        }
        
        mergedMedia.setup = "passive"
        //
        mergedMedia.rtcpMux = true
        mergedMedia.rtcpRsize = true
        mergedMedia.iceUfrag = iceParameters.usernameFragment
        mergedMedia.icePwd = iceParameters.password
        
        for rtp in rtps {
            if rtp.codec == codecCap.codecName {
                if rtp.codec == "H264" {
                    if rtp.fmtp["packetization-mode"] == codecCap.parameters["packetization-mode"], rtp.fmtp["level-asymmetry-allowed"] == codecCap.parameters["level-asymmetry-allowed"], rtp.fmtp["profile-level-id"]![0...3] == codecCap.parameters["profile-level-id"]![0...3] {
                        
                        var newRtp = Rtp(payload: rtp.payload, codec: rtp.codec, rate: rtp.rate)
                        //FIXME : use server fmtp will cause video freeze
                        newRtp.fmtp = rtp.fmtp
                        newRtp.rtcpFb = codecCap.rtcpFeedback
                        
                        if rtp.rtx != nil {
                            newRtp.rtx = rtp.rtx
                            mergedMedia.rtxSsrc = rtxSsrc
                        }
                        mergedMedia.rtps.append(newRtp)

                        
                        break
                    }
                } else {
                    mergedMedia.rtps.append(rtp)
                    
                    if rtp.rtx != nil {
                        mergedMedia.rtxSsrc = rtxSsrc
                    }
                    break
                }
            }
        }
        
//        guard let ssrc = self.ssrc else { return }
        
        for ext in extensions {
            for cext in codecCap.extensions {
                if ext.uri == cext.uri {
                    mergedMedia.extensions.append(ext)
                }
            }
        }
        
        for (index, rf) in mergedMedia.rtps[0].rtcpFb.enumerated() {
            if rf.type == "goog-remb" {
                mergedMedia.rtps[0].rtcpFb.remove(at: index)
            }
        }
        
        for candidate in iceCandidates {
            mergedMedia.candidates.append(candidate)
        }
        
        
//        print(mergedMedia.toString())
        
        return mergedMedia
    }
    
    func toCodec() -> Codec? {
        let rtp = rtps[0]
        var rtx: RTX?
        if let rtxSsrc = rtxSsrc {
            if let rtpPayload = rtp.rtx {
                rtx = RTX(payload: rtpPayload, ssrc: rtxSsrc)
            }
        } else {
            rtx = nil
        }
        
        if let type = self.type {
            return Codec(kind: type, payload: rtp.payload, clockRate: rtp.rate, channels: rtp.channels, codecName: rtp.codec, codecFullName: rtp.codec, dtx: false, senderPaused: false, ssrc: ssrc, cname: cname, mid: mid, rtx: rtx, extensions: extensions, parameters: rtp.fmtp, rtcpFeedback: rtp.rtcpFb)
        }
        return nil
    }
    
    func getRtpIndex(payload: Int) -> Int? {
        return rtps.firstIndex(where: { $0.payload == payload })
    }
    
    public func toString() -> String {
        /*
         
         */
        var lines = [String]()
        var payloads = rtps.map { String($0.payload) }
        
        if let type = type, let port1 = port, let proto = proto {
            var port: Int
            if available || mid! == "0" {
                port = port1
            } else {
                port = 0
            }
            
            if rtxSsrc != nil {
                payloads.append(String(rtps[0].rtx!))
            }
            lines.append("m=\(type) \(port) \(proto) \(payloads.joined(separator: " "))")
        }
        
        if let connection = connection {
            lines.append("c=\(connection)")
        }
        
        if let rtcp = rtcp {
            lines.append("a=rtcp:\(rtcp)")
        }
        
        if role == .send, let msidAppdata = msidAppdata, let cname = cname {
            lines.append("a=msid:\(cname) \(msidAppdata)")
        }
        
        if let iceUfrag = iceUfrag {
            lines.append("a=ice-ufrag:\(iceUfrag)")
        }
        
        if let icePwd = icePwd {
            lines.append("a=ice-pwd:\(icePwd)")
        }

        if fingerprint != nil {
            lines.append("a=fingerprint:\(fingerprint!.algorithm) \(fingerprint!.hash)")
        }
        
        if setup != nil {
            lines.append("a=setup:\(setup!)")
        }
        
        if mid != nil {
            lines.append("a=mid:\(mid!)")
        }
        
        if msid != nil {
            lines.append("a=msid:\(msid!)")
        }
        
        if direction != nil {
            lines.append("a=\(direction!)")
        }
        
        if available {
            for ext in extensions {
                lines.append("a=extmap:\(ext.id) \(ext.uri)")
            }
        }
        
        for rtp in rtps {
            lines.append(rtp.toString())
        }
        
        if role == .send {
            if let rtxSsrc = self.rtxSsrc {
                if let ssrc = self.ssrc {
                    lines.append("a=ssrc-group:FID \(ssrc) \(rtxSsrc)")
                }
            }
            
            if let ssrc = self.ssrc, let cname = self.cname {
                lines.append("a=ssrc:\(ssrc) cname:\(cname)")
                if let rtxSsrc = self.rtxSsrc {
                    lines.append("a=ssrc:\(rtxSsrc) cname:\(cname)")
                }
            }
        }
//
//        for ssrc in ssrcs {
//            lines.append("a=ssrc:\(ssrc.id) \(ssrc.attribute):\(ssrc.value)")
//        }
        if candidates.count > 0 {
            for candidate in candidates {
                lines.append(candidate.description)
            }
            lines.append("a=end-of-candidates")
        }
        
        if rtcpMux {
            lines.append("a=rtcp-mux")
        }
        
        if rtcpRsize {
            lines.append("a=rtcp-rsize")
        }
        
        
        if iceOptions != nil {
            lines.append("a=ice-options:\(iceOptions!)")
        }
        
        
        let mediaSdp = lines.joined(separator: "\n")
        return mediaSdp
    }
}
