//
//  DeliveryTestApp.swift
//  DeliveryTest
//
//  Created by Gary Yao on 5/6/24.
//

import SwiftUI

@main
struct DeliveryTestApp: App {
    @State var sevm = SampleEntityViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView(sevm: $sevm)
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView(sevm: $sevm)
        }
    }
}
