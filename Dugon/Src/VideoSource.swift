//
//  VideoSource.swift
//  Dugon
//
//  Created by cong chen on 2020/4/15.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC


public struct Format:Hashable{
    public let width:Int
    public let height:Int
    public let fps:Int
    
    init(width:Int,height:Int,fps:Int) {
        self.width = width
        self.height = height
        self.fps = fps
    }
    
    public static func == (lhs: Format, rhs: Format) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height && lhs.fps == rhs.fps
    }
}


public class VideoSource:MediaSource{
 
    
    private static let FramerateLimit = 30.0
    
    //https://developer.apple.com/documentation/avfoundation/avcapturedevice/position
    public enum CameraPosition:Int {
        case back = 1
        case front
    }

    private let capturer:RTCCameraVideoCapturer?
    
    public static func getSupportedFormats(position:CameraPosition) -> [Format]{
        let captureDevices = RTCCameraVideoCapturer.captureDevices();

        var mydevice:AVCaptureDevice!
        
        for device in captureDevices{
            if (device.position == AVCaptureDevice.Position(rawValue: position.rawValue)) {
              mydevice = device
              break;
          }
        }
        
        let capturerformats = RTCCameraVideoCapturer.supportedFormats(for: mydevice)
                
        var formatSet = Set<Format>()

        for cformat in capturerformats {
          let dimension = CMVideoFormatDescriptionGetDimensions(cformat.formatDescription);
            let ranges = cformat.videoSupportedFrameRateRanges
//            print("width \(dimension.width), height \(dimension.height)")
            var maxFps = 0.0
            for r in ranges {
                if r.maxFrameRate > maxFps {
                    maxFps = r.maxFrameRate
                }
            }
            
            maxFps = max(maxFps,FramerateLimit)
            let format = Format(width: Int(dimension.width), height: Int(dimension.height),fps: Int(maxFps))
            formatSet.insert(format)
        }
        
        var formats = Array(formatSet)
        formats.sort {$0.width > $1.width}
        
        return formats
    }
    
    
    init(source:RTCVideoSource,track:RTCVideoTrack){
        self.capturer =  RTCCameraVideoCapturer.init(delegate: source)
        super.init(track: track, source: source)
    }
    
    public func play(player:Player,position:CameraPosition,format:Format){

        let captureDevices = RTCCameraVideoCapturer.captureDevices();

        var mydevice:AVCaptureDevice!
        
        for device in captureDevices{
            if (device.position == AVCaptureDevice.Position(rawValue: position.rawValue)) {
              mydevice = device
              break;
          }
        }
         
        let selectedFormat = getAVFormat(device: mydevice, width: format.width, height: format.height)

        capturer!.startCapture(with: mydevice, format: selectedFormat, fps: format.fps)

        player.view.captureSession = capturer!.captureSession
    }
    
    func getAVFormat(device:AVCaptureDevice,width:Int,height:Int) -> AVCaptureDevice.Format{
        let capturerformats = RTCCameraVideoCapturer.supportedFormats(for: device)

        var selectedFormat:AVCaptureDevice.Format!
        var  currentDiff = INT_MAX
        for format in capturerformats {
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
            let pixelFormat = CMFormatDescriptionGetMediaSubType(format.formatDescription);
            let diff = abs(Int32(width) - dimension.width) + abs(Int32(height) - dimension.height)
             
            if diff < currentDiff {
              selectedFormat = format
              currentDiff = diff
            } else if diff == currentDiff && pixelFormat == capturer!.preferredOutputPixelFormat() {
              selectedFormat = format
            }
        }
        return selectedFormat;
    }
    
}


