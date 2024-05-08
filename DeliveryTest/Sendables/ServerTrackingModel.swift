//
//  ServerTrackingModel.swift
//  DeliveryTest
//
//  Created by Gary Yao on 5/6/24.
//

import Foundation

class ServerTrackingModel{
    var source = "default"
    var my_last_strong_control:Double = Date().timeIntervalSince1970
    var your_last_strong_control:Double = Date().timeIntervalSince1970
    var strong_request = 0
}
