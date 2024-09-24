//
//  Codec.swift
//  Dugon
//
//  Created by cong chen on 2020/4/21.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation

struct RTX:Codable{
    var payload:Int
    var ssrc:Int
}

class Codec:Codable {
    var kind:String
    var payload:Int
    var clockRate:Int
    var channels:Int
    var codecName:String
    var codecFullName:String
    var dtx:Bool
    var senderPaused:Bool
    var reducedSize = true
    
    var mux:Bool?

    var ssrc:Int?
    var cname:String?
    var mid:String?

    var rtx:RTX?
    
    var extensions:[Extension]
    var parameters:[String:String]
    var rtcpFeedback:[RtcpFeedback]
    
    init(kind: String, payload: Int, clockRate: Int, channels: Int, codecName: String, codecFullName: String, dtx: Bool, senderPaused: Bool, ssrc: Int?, cname: String?, mid: String?, rtx: RTX?, extensions: [Extension], parameters: [String:String], rtcpFeedback: [RtcpFeedback]) {
        self.kind = kind
        self.payload = payload
        self.clockRate = clockRate
        self.channels = channels
        self.codecName = codecName
        self.codecFullName = codecFullName
        self.dtx = dtx
        self.senderPaused = senderPaused
        self.ssrc = ssrc
        self.cname = cname
        self.mid = mid
        self.rtx = rtx
        self.extensions = extensions
        self.parameters = parameters
        self.rtcpFeedback = rtcpFeedback
    }

//    func parameterArray() -> [String]{
//        var arr = [String]()
//        for (key,value) in parameters{
//            arr.append("\(key)=\(value)")
//        }
//        return arr
//    }
    func toJson() -> [String:Any]? {

        do {
            let encoder = JSONEncoder()
            if #available(iOS 13.0, *) {
                encoder.outputFormatting = .withoutEscapingSlashes
            } else {
                //TODO:
            }
            let jsonData = try encoder.encode(self)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            if let json = json {
                return json.jsonStr2Dict()
            }
            
        } catch {
            return nil
        }
        
        return nil
       
    }
    
}
