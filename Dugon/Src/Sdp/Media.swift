//
//  File.swift
//  
//
//  Created by cong chen on 2020/4/17.
//

import Foundation

struct Candidate:Codable{
    let component:Int
    let foundation:String
    let ip:String
    let port:Int
    let priority:Int
    let transport:String
    let type:String
    
    var description: String {
        return "a=candidate:\(foundation) \(component) \(transport) \(priority) \(ip) \(port) typ \(type)"
    }
    
    static func create(dic:[String:Any]) -> Candidate?{
        
        let codecJson = dic.json.data(using: .utf8)!
        
        var candidate: Candidate?
        do {
            candidate = try JSONDecoder().decode(Candidate.self, from: codecJson)
            return candidate
        } catch {
            print(dic)
            print("Error took place: \(error.localizedDescription).")
            return nil
        }
    }

}

public struct Rtp{
    public let payload:Int
    public var codec:String?
    public var rate:Int?
    public var rtx:Int?

    public var channels:Int = 1
    public var rtcpFb = [RtcpFeedback]()
    public var fmtp = [String:String]()
        
    public func toString() -> String{
        var lines = [String]()
        if channels == 1 {
            lines.append("a=rtpmap:\(payload) \(codec!)/\(rate!)")
        }else{
            lines.append("a=rtpmap:\(payload) \(codec!)/\(rate!)/\(channels)")
        }
        
        for rf in rtcpFb {
            let r = "a=rtcp-fb:\(payload) \(rf.type) \(rf.parameter)".trimmingCharacters(in: .whitespacesAndNewlines)
            lines.append(r)
        }
        

        var fmtpArr = [String]()
        for (key,value) in fmtp{
           fmtpArr.append("\(key)=\(value)")
        }
        lines.append("a=fmtp:\(payload) \(fmtpArr.joined(separator: ";"))")


        let rtpSdp = lines.joined(separator: "\n")
        return rtpSdp
    }
}

public struct Fingerprint{
    public let algorithm:String
    public let hash:String
}

public struct RtcpFeedback:Codable{
    public let type:String
    public let parameter:String
    
    init(type:String,parameter:String = "") {
        self.type = type
        self.parameter = parameter
    }
}

public struct Extension:Codable {
    public let id:Int
    public let uri:String
}

public class Media{
    public var type:String?
    public var port:Int?
    public var mid:Int?
    //protocol
    public var proto:String?
    public var connection:String?
    public var direction:String?
    public var iceUfrag:String?
    public var icePwd:String?
    public var iceOptions:String?
    public var setup:String?
    public var rtcp:String?
    public var msid:String?
    
    public var ssrc:Int?
    public var rtxSsrc:Int?
    
    public var cname:String?
    
    public var fingerprint:Fingerprint?
    
    public var extensions = [Extension]()
    public var rtps = [Rtp]()
    var candidates = [Candidate]()

//    public var ssrcGroups = [SsrcGroup]()

    public var rtxPayloads = [Int]()
    
    public var rtcpMux:Bool = false
    public var rtcpRsize:Bool = false

    func merge(codecCap:Codec,iceParameters:[String:Any],iceCandidates:[[String:Any]]) -> Media? {
        guard let remoteIcePwd = iceParameters["password"] as? String else { return nil}
        guard let remoteIceUfrag = iceParameters["usernameFragment"] as? String else { return nil }
        //extensions
        //rtcpFb
        let mergedMedia = Media()
        
        mergedMedia.type = type
        mergedMedia.proto = proto
        mergedMedia.port = port
        mergedMedia.cname = cname
        mergedMedia.connection = connection
        mergedMedia.mid = mid
        mergedMedia.ssrc = ssrc
        mergedMedia.iceOptions = "renomination"
        //TODO:
        mergedMedia.direction = "recvonly"
        mergedMedia.setup = "passive"
        //
        mergedMedia.rtcpMux = true
        mergedMedia.rtcpRsize = true
        mergedMedia.iceUfrag = remoteIceUfrag
        mergedMedia.icePwd = remoteIcePwd
        
        for rtp in rtps {
            guard let codec = rtp.codec else { continue }
            if codec == codecCap.codecName {
                if codec == "H264"{
                    if rtp.fmtp["packetization-mode"] == codecCap.parameters["packetization-mode"] && rtp.fmtp["level-asymmetry-allowed"] == codecCap.parameters["level-asymmetry-allowed"] && rtp.fmtp["profile-level-id"]![0...3] == codecCap.parameters["profile-level-id"]![0...3] {
                        mergedMedia.rtps.append(rtp)
                        
                        if rtp.rtx != nil{
                            mergedMedia.rtxSsrc = rtxSsrc
                        }
                        
                        break
                    }
                }else{
                    mergedMedia.rtps.append(rtp)
                    
                    if rtp.rtx != nil{
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
        
        
        
        for (index,rf) in mergedMedia.rtps[0].rtcpFb.enumerated() {
            if rf.type == "goog-remb" {
                mergedMedia.rtps[0].rtcpFb.remove(at: index)
            }
        }
        
        
        
        for candidate in iceCandidates {
            if let c = Candidate.create(dic: candidate) {
                mergedMedia.candidates.append(c)
            }
        }
        
        mergedMedia.rtps[0].rtcpFb = codecCap.rtcpFeedback
        
//        print(mergedMedia.toString())

        return mergedMedia
        
    }
    
    func toCodec() -> Codec?{
        let rtp = rtps[0]
        var rtx:RTX?
        if let rtxSsrc = rtxSsrc {
            if let rtpPayload = rtp.rtx {
                rtx = RTX(payload: rtpPayload, ssrc: rtxSsrc)
            }
        }else{
            rtx = nil
        }

        if let type = self.type , let clockRate = rtp.rate, let codecName = rtp.codec {
            
        return Codec(kind: type, payload: rtp.payload, clockRate: clockRate, channels: rtp.channels, codecName: codecName, codecFullName: codecName, dtx: false, senderPaused: false, ssrc: ssrc, cname: cname, mid: mid, rtx: rtx, extensions: extensions, parameters: rtp.fmtp, rtcpFeedback: rtp.rtcpFb)
        }
        return nil
    }
    
    func getRtpIndex(payload:Int) -> Int?{
        return rtps.firstIndex(where: {$0.payload == payload})
    }
    
    public func toString() -> String {
        /*

         */
        var lines = [String]()
        let payloads = rtps.map{String($0.payload)}
        
        if let type = self.type,let port = self.port,let proto = self.proto {
            lines.append("m=\(type) \(port) \(proto) \(payloads.joined(separator: " "))")
        }
        
        if let connection = self.connection {
            lines.append("c=\(connection)")
        }
    
        if rtcp != nil {
            lines.append("a=rtcp:\(rtcp!)")
        }
        
        if iceUfrag != nil {
            lines.append("a=ice-ufrag:\(iceUfrag!)")
        }
        
        if icePwd != nil {
            lines.append("a=ice-pwd:\(icePwd!)")
        }
        
        if iceOptions != nil {
            lines.append("a=ice-options:\(iceOptions!)")
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
        
        if rtcpMux {
            lines.append("a=rtcp-mux")
        }
        
        if rtcpRsize {
            lines.append("a=rtcp-rsize")
        }
        
        
        
        for ext in extensions {
            lines.append("a=extmap:\(ext.id) \(ext.uri)")
        }
        
        for rtp in rtps {
            lines.append(rtp.toString())
        }
        
        if let rtxSsrc = self.rtxSsrc {
            if let ssrc = self.ssrc {
                lines.append("a=a=ssrc-group:FID 3676306963:\(ssrc) \(rtxSsrc)")
            }
        }
        
        if let ssrc = self.ssrc,let cname = self.cname{
            lines.append("a=ssrc:\(ssrc) cname:\(cname)")
        }
//        
//        for ssrc in ssrcs {
//            lines.append("a=ssrc:\(ssrc.id) \(ssrc.attribute):\(ssrc.value)")
//        }
        if candidates.count > 0 {
            for candidate in candidates {
                lines.append(candidate.description)
            }
            lines.append("a=end-of-candidates");
        }
        

        let mediaSdp = lines.joined(separator: "\n")
        return mediaSdp
    }
}
