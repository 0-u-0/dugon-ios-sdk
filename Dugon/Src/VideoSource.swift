//
//  VideoSource.swift
//  Dugon
//
//  Created by cong chen on 2020/4/15.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC




public class VideoSouce{
    //https://developer.apple.com/documentation/avfoundation/avcapturedevice/position
    public enum CameraPosition:Int {
        case back = 1
        case front
    }


    
    private let source:RTCVideoSource
    private let track:RTCVideoTrack
    
    private var capturer:RTCCameraVideoCapturer?

    init(source:RTCVideoSource,track:RTCVideoTrack){
        self.source = source
        self.track = track
    }
    
    func play(position:CameraPosition,width:Int,height:Int){
        capturer =  RTCCameraVideoCapturer.init(delegate: source)

        let captureDevices = RTCCameraVideoCapturer.captureDevices();

        var mydevice:AVCaptureDevice!
        
        for device in captureDevices{
            if (device.position == AVCaptureDevice.Position(rawValue: position.rawValue)) {
              mydevice = device
              break;
          }
        }
        let formats = RTCCameraVideoCapturer.supportedFormats(for: mydevice)

         let targetWidth = 640
         let targetHeight = 480
         
         var selectedFormat:AVCaptureDevice.Format!
         var  currentDiff = INT_MAX;

         for format in formats {
           let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
           let pixelFormat = CMFormatDescriptionGetMediaSubType(format.formatDescription);
             let diff = abs(Int32(targetWidth) - dimension.width) + abs(Int32(targetHeight) - dimension.height)
           if diff < currentDiff {
             selectedFormat = format
             currentDiff = diff
           } else if diff == currentDiff && pixelFormat == capturer!.preferredOutputPixelFormat() {
             selectedFormat = format
           }
         }
         
         let fps = 15

        capturer!.startCapture(with: mydevice, format: selectedFormat, fps: fps)

    }
    
    
}


