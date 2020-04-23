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

struct Codec:Codable {
    var kind:String
    var payload:Int
    var clockRate:Int
    var channels:Int
    var codecName:String
    var codecFullName:String
    var dtx:Bool
    var senderPaused:Bool
    var reducedSize:Bool = true
    
    var ssrc:Int?
    var cname:String?
    var mid:Int?

    var rtx:RTX?
    
    var extensions:[Extension]
    var parameters:[String:String]
    var rtcpFeedback:[RtcpFeedback]

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
    
    static func create(dic:[String:Any]) -> Codec?{
        print(dic)
        let codecJson = dic.json.data(using: .utf8)!
        
        var codecCap: Codec?
        do {
            codecCap = try JSONDecoder().decode(Codec.self, from: codecJson)
            return codecCap
        } catch {
            print(dic)
            print("Error took place: \(error.localizedDescription).")
            return nil
        }
        
    }
}
