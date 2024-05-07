//
//  DeliveryTestApp.swift
//  DeliveryTest
//
//  Created by Gary Yao on 5/6/24.
//

import SwiftUI

@main
struct DeliveryTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
