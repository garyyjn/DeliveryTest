//
//  ImmersiveView.swift
//  ReceiverTest
//
//  Created by Gary Yao on 5/6/24.
//
import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    
    @State var timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    @StateObject private var networkedCircle = PSNetworking<SendableBall>(defaultSendable: SendableBall(state: "dafault", playerTransform: Transform().matrix))
    
    @Binding var sevm:SampleEntityViewModel
    @State var stm = ServerTrackingModel()
    let thm = ThrowingHandModel()
    let itm = ImageDetectionModel()
    
    @State var pivot1 = Entity()
    @State var pivot2 = Entity()
    
    var body: some View {
        RealityView { content in
            content.add(sevm.rootEntity)
            pivot1 = itm.referenceAnchorOne
            pivot2 = itm.referenceAnchorTwo
            content.add(pivot1)
            content.add(pivot2)
            //pivot1.setPosition(SIMD3(0.5,1.0,-1.0), relativeTo: nil)
            //pivot2.setPosition(SIMD3(0.5,1.0,-1.2), relativeTo: nil)
            //pivot1.look(at: pivot2.position, from: pivot1.position, relativeTo: nil)
            let visu1 = ModelEntity(mesh: .generateSphere(radius: 0.20), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
            let visu2 = ModelEntity(mesh: .generateSphere(radius: 0.20), materials: [SimpleMaterial(color: .green, isMetallic: false)])
            pivot1.addChild(visu1)
            pivot2.addChild(visu2)
            visu1.setPosition(SIMD3(x: 0.0, y: 0.0, z: 0.0), relativeTo: pivot1)
            visu2.setPosition(SIMD3(x: 0.0, y: 0.0, z: 0.0), relativeTo: pivot2)
            thm.ball = sevm.sampleSaveBall
            stm.source = "Specicial, in immersive"
            thm.stm = self.stm
            stm.strong_request = 1
            Task {
            itm.startrunning()
               await thm.runARKitSession()
            }
        }.gesture(
            DragGesture().targetedToAnyEntity()
                .onChanged {value in
                    guard let parent = value.entity.parent else{
                        return
                    }
                    var currently_dragged_entity = value.entity
                    sevm.sampleSaveBall.position = value.convert(value.translation3D, from: .local, to: parent)
                    sevm.debug_test = "\(sevm.sampleSaveBall.transform.translation)"
                    stm.strong_request = 2
                    stm.my_last_strong_control = Date().timeIntervalSince1970
                   // print(sevm.sampleSaveBall.transform.translation)
                }
        ).onReceive(timer, perform: { value in
            
            print("answering received")
            let received = networkedCircle.ballEntity
            let message_status = networkedCircle.ballEntity.state
            let time_status = networkedCircle.ballEntity.timeSince1970
            if message_status == "strong"{
                stm.your_last_strong_control = time_status
            }
            
            
            if stm.your_last_strong_control > stm.my_last_strong_control{
                thm.removephysics(ball: thm.ball)
                thm.ballState = .in_air
                let received_matrix = received.transform
                let synced_transform = Transform(matrix: received_matrix)
                sevm.sampleSaveBall.setTransformMatrix(synced_transform.matrix, relativeTo: pivot1)
                sevm.debug_test = ""
            }
            
            
            
            
            var send_state = "default"
            if self.stm.strong_request > 0{
                self.stm.strong_request -= 1
                send_state = "strong"
            }
            networkedCircle.send(SendableBall(state: send_state, playerTransform: sevm.sampleSaveBall.transform.matrix))
            
            let transform_synced = Transform(translation: sevm.sampleSaveBall.position(relativeTo: pivot1)).matrix
            networkedCircle.send(SendableBall(state: send_state, playerTransform: transform_synced))
            
            
            }
        ).task {
            await thm.processHandAnchorUpdates()
        }
    }
}
