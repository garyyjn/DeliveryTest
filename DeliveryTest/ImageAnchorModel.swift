//
//  ImageDetectionModel.swift
//  TwoImageAnchorTest
//
//  Created by Gary Yao on 5/2/24.
//

import Foundation
import ARKit
import RealityKit
import RealityKitContent

class ImageDetectionModel:ObservableObject{
    let session = ARKitSession()
    let imageInfo = ImageTrackingProvider(
        referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "ImageAnchorsSource")
    )
    
    var referenceAnchorOne = Entity()
    var referenceAnchorTwo = Entity()
    var foundAnchorOne = false
    var foundAnchorTwo = false
    var marker = Entity()
    var imageAnchors: [UUID: ImageAnchor] = [:]
    var entityMap: [UUID: Entity] = [:]
    var rootEntity = Entity()
    var axis_one:Entity = Entity()
    init() {
        Task{
            if let axis = try? await Entity(named: "axisarrow", in: realityKitContentBundle){
                marker = axis
            }else{
                print("Failed")
            }
        }
        axis_one = marker.clone(recursive: true)
        rootEntity.addChild(axis_one)
       // print(axis_one)
        axis_one.setPosition(SIMD3(0.0,0.0,-2.0), relativeTo: nil)
    }

    func startrunning(){
        Task {
            print("running session")
            try await session.run([imageInfo])
            print("done running session")
            for await update in imageInfo.anchorUpdates {
                await updateImage(update.anchor)
            }
        }
    }
    @MainActor
    func updateImage(_ anchor: ImageAnchor) {
    //    print("updating Image")
        guard let name = anchor.referenceImage.name else{
            print("failed to get bane")
            return()
        }
        if name == "anchor1"{
            referenceAnchorOne.setTransformMatrix(anchor.originFromAnchorTransform, relativeTo: nil)
            //let entity = ModelEntity(mesh: .generateSphere(radius: 0.02))
            referenceAnchorOne.look(at: referenceAnchorTwo.position, from: referenceAnchorOne.position, relativeTo: nil)
            //referenceAnchorOne.addChild(entity)
           // rootEntity.addChild(referenceAnchorOne)
        }else{
            referenceAnchorTwo.setTransformMatrix(anchor.originFromAnchorTransform, relativeTo: nil)
            //let entity = ModelEntity(mesh: .generateSphere(radius: 0.02))
            //referenceAnchorTwo.addChild(entity)
            //rootEntity.addChild(referenceAnchorTwo)
        }
    }
}
