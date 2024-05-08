//
//  SampleEntityViewModel.swift
//  ReceiverTest
//
//  Created by Gary Yao on 5/6/24.
//

import Foundation
import RealityKit
struct SampleEntityViewModel{
    var rootEntity = Entity()
    var sampleSaveBall = ModelEntity(mesh: .generateSphere(radius: 0.15), materials: [SimpleMaterial(color: .red, isMetallic: false)])
    var debug_test = ""
    init() {
        sampleSaveBall.components[InputTargetComponent] = InputTargetComponent()
        sampleSaveBall.components[CollisionComponent] = CollisionComponent(shapes: [ShapeResource.generateSphere(radius: 0.15)])
        self.rootEntity.addChild(sampleSaveBall)
        sampleSaveBall.setPosition(SIMD3(x: 0.0, y: 0.0, z: -2.0), relativeTo: rootEntity)
    }
}
