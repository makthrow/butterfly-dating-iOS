//
//  MeetMedia.swift
//  butterfly2
//
//  Created by Alan Jaw on 10/15/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import Foundation

// firebase: meet_media_for_userID/userIDxxx/...MeetMedia entry
struct MeetMedia {
    let fromUserID: String
    let mediaID: String
    let mediaType: String
    let timestamp: Double
    let title: String
    let toUserID: String
    let unread: Bool
    let unsent_notification: Bool
}
