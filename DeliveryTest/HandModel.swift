//
//  ThrowingHandModel.swift
//  ThrowingBall
//
//  Created by Gary Yao on 4/27/24.
//

import Foundation
import RealityKit
import UIKit
import SwiftUI
import QuartzCore
import ARKit
import simd

enum BallState:String{
    case in_hand
    case in_air
}
class ThrowingHandModel{
    let handDetection = HandTrackingProvider()
    
    var stm = ServerTrackingModel()
    
    private let worldTracking = WorldTrackingProvider()
    var arkitSession = ARKitSession()
    
    var common_root = Entity()
    var ball = Entity()
    var facing_helper = Entity()
    var facing_entity = Entity()
    var running = true
    var frequency:UInt64 = 30
    var time_tick = 0
    var last_presnap = -100
    var ballState:BallState = .in_hand
    var last_distance_to_facing:Float = 1000.0
    var last_y:Float = 1000.0
    var last_thrown = -100
    init() {
        ball = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [SimpleMaterial(color: .red, isMetallic: false)])
        common_root.addChild(ball)
        facing_entity = ModelEntity(mesh: .generateSphere(radius: 0.1), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
        common_root.addChild(facing_helper)
        common_root.addChild(facing_entity)
    }
    @MainActor
    func runARKitSession() async {
        do {
            try await arkitSession.run([handDetection, worldTracking])
        } catch {
            fatalError("arkit start failed")
        }
    }
    
    @MainActor
    private func updateUserFacin(){
        if let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()){
            // print(deviceAnchor.originFromAnchorTransform.translation)
            let trans = Transform(translation: SIMD3(x: 0.0, y: 0.0, z: -3.0))
            facing_helper.transform.matrix = deviceAnchor.originFromAnchorTransform
            facing_entity.setPosition(SIMD3(x: 0.0, y: 0.0, z: -3.0), relativeTo: facing_helper)
        }
    }
    
    @MainActor
    func queryAndProcessLatestHandAnchor(){
        time_tick += 1
        guard let rh = handDetection.latestAnchors.rightHand else{
            print("right hand failed")
            return
        }
        guard let wrist = rh.handSkeleton?.joint(.wrist) else{
            print("write not found")
            return
        }
        guard let middlefinger = rh.handSkeleton?.joint(.middleFingerTip) else{
            print("middle not found")
            return
        }
        updateUserFacin()
       
        let wristloc = getlocation(jointloc: rh.originFromAnchorTransform, parentloc: wrist.anchorFromJointTransform)
        let middleloc = getlocation(jointloc: rh.originFromAnchorTransform, parentloc: middlefinger.anchorFromJointTransform)
        
        let fep = facing_entity.position
        let plane_write = SIMD2(x: wristloc.x, y: wristloc.z)
        let fepp = SIMD2(x:fep.x,y:fep.z)
        let distance = simd_distance(plane_write, fepp)
        if distance - last_distance_to_facing < -0.05 && ballState == .in_hand{
            ballState = .in_air
            setphysics(ball: ball)
            setfly(ball: ball, diff: distance - last_distance_to_facing )
            last_thrown = time_tick
        }else{let presnap_result = preSnap(lefthand: rh)
            let postsnap_result = afterSnap(lefthand: rh)
            if presnap_result{
                last_presnap = time_tick
            }
            if postsnap_result && time_tick - last_presnap < 10{
                stm.strong_request = 2
                stm.my_last_strong_control = Date().timeIntervalSince1970
                ballState = .in_hand
                last_presnap = -100
            }
        }
        last_distance_to_facing = distance
        
        if wristloc.y - last_y > 0.05 && ballState == .in_hand{
            ballState = .in_air
            setphysics(ball: ball)
            settoss(ball: ball)
            last_thrown = time_tick
        }
        last_y = wristloc.y
        
        var ball_hand_dist = pow((ball.position.x - middleloc.x),2) + pow((ball.position.y - middleloc.y),2) + pow((ball.position.z - middleloc.z),2)
        ball_hand_dist = pow(ball_hand_dist, 0.5)
        print(ball_hand_dist)
        if ball_hand_dist < 0.25 && time_tick - last_thrown > 6 && stm.my_last_strong_control > stm.your_last_strong_control{
            print("newly grabbed ")
            if ballState != .in_hand{
                stm.strong_request = 1
                stm.my_last_strong_control = Date().timeIntervalSince1970
                ballState = .in_hand
                last_thrown = time_tick
            }
            
        }
        
        if ballState == .in_hand{
                summontohand(ball: ball, rh: rh)
                removephysics(ball: ball)
        }
        
        // print(ballState)
        //print(ball.transform)
    }
    func processHandAnchorUpdates() async{
        await run(function: self.queryAndProcessLatestHandAnchor)
    }
    
    func summontohand(ball:Entity, rh:HandAnchor){
        guard let palm = rh.handSkeleton?.joint(.middleFingerTip) else{
            print("can't find palm")
            return
        }
        let righthandanchor = rh.originFromAnchorTransform
        let location = getlocation(jointloc: righthandanchor, parentloc: palm.anchorFromJointTransform)
        ball.transform.translation = SIMD3(x: location.x, y: location.y + 0.02, z: location.z)
        ball.look(at: facing_entity.position, from: ball.position, relativeTo: nil)
    }
    
    func setphysics(ball:Entity){
        let dummyshape = ShapeResource.generateBox(size: [0.1, 0.1, 0.1])
        let physicsComponent = PhysicsBodyComponent(shapes: [dummyshape], mass: 1.0, material: nil, mode: .dynamic)
        ball.components.set(physicsComponent)
        ball.components.set(CollisionComponent(shapes: [dummyshape]))
        ball.components[InputTargetComponent.self] = InputTargetComponent()
    }
    
    func removephysics(ball:Entity){
        //stm.strong_request = 3
        ball.components[PhysicsBodyComponent] = nil
        ball.components[CollisionComponent] = nil
    }
    func setfly(ball:Entity, diff:Float = -0.03){
        stm.strong_request = 3
        stm.my_last_strong_control = Date().timeIntervalSince1970
        (ball as? HasPhysics)!.addForce(SIMD3(x:0.0, y:200.0, z: -200.0 + 10000*diff), relativeTo:facing_helper)
    }
    func settoss(ball:Entity){
        self.stm.strong_request = 3
        print("in hand model sevm string requests \(self.stm.strong_request)")
        print(self.stm.source)
        self.stm.my_last_strong_control = Date().timeIntervalSince1970
        (ball as? HasPhysics)!.addForce(SIMD3(x:0.0, y:500.0, z: 0.0), relativeTo:nil)
    }
    
    
    @MainActor
    func run(function: () async -> Void) async {
        while true {
            if !running{
                return
            }
            if Task.isCancelled {
                return
            }
            
            // Sleep for 1 s / hz before calling the function.
            let nanoSecondsToSleep: UInt64 = NSEC_PER_SEC / frequency
            do {
                try await Task.sleep(nanoseconds: nanoSecondsToSleep)
            } catch {
                // Sleep fails when the Task is cancelled. Exit the loop.
                return
            }
            await function()
        }
    }
    
    
}
