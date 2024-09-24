//
//  MediaSource.swift
//  Dugon
//
//  Created by cong chen on 2020/4/21.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation
import WebRTC

public enum MediaType {
    case video
    case audio

    init(type: String) {
        switch type {
        case "video":
            self = .video
        case "audio":
            self = .audio
        default:
            self = .video
        }
    }
}

// interface
public protocol MediaSource {
    var mediaTrack: RTCMediaStreamTrack { get }
}

extension MediaSource {
    public var type: MediaType {
        return MediaType(type: mediaTrack.kind)
    }
}

public class AudioSource: MediaSource {
    public var mediaTrack: RTCMediaStreamTrack {
        return track
    }

    let track: RTCAudioTrack
    let source: RTCAudioSource
    init(track: RTCAudioTrack) {
        self.track = track
        self.source = track.source
    }
}

public class VideoSource: MediaSource {
    public var mediaTrack: RTCMediaStreamTrack {
        return track
    }

    let track: RTCVideoTrack
    let source: RTCVideoSource
    init(track: RTCVideoTrack) {
        self.track = track
        self.source = track.source
    }
}
