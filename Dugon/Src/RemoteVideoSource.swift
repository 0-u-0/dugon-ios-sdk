//
//  RemoteVideoSource.swift
//  Dugon
//
//  Created by cong chen on 2020/4/26.
//  Copyright © 2020 dugon. All rights reserved.
//

import Foundation

public class RemoteVideoSource: VideoSource {
    public func play(player: Player) {
        if player.type == .remote, let view = player.view as? RemoteVieoView {
            print("player")
            track.add(view)
        }
    }
}
