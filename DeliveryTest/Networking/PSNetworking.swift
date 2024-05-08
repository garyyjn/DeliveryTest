//
//  PSNetworking.swift
//  MuPeerTest
//
//  Created by Paige Sun on 3/30/24.
//

import Combine
import RealityKit
import Foundation

protocol PSSendable: Codable {
    var sender: String { get }
    var timeSince1970: Double {get }
}

class PSNetworking<Sendable: PSSendable>: ObservableObject {

    public lazy var myName: PeerName = {
        return peersController.myName
    }()
    
    private let peersController = PeersController.shared
    
    private var cancellables = Set<AnyCancellable>()

    @Published var entity: Sendable {
        didSet {
            send(entity)
        }
    }
    @Published var ballEntity:SendableBall
    
    init(defaultSendable: Sendable) {
        self.entity = defaultSendable
        ballEntity = SendableBall(state: "dafault", playerTransform: simd_float4x4())
        
        myName = peersController.myName
        peersController.peersDelegates.append(self)
        
    }

    func send(_ sendable: Sendable) {
//        if sendable.sender == myName {
            peersController.sendMessage(sendable, viaStream: false)
//        }
    }
    
    func listen(_ callback: @escaping (Sendable) -> Void) {
        print("listening")
        $entity.sink { [weak self] recievedSendable in
            callback(recievedSendable)
        }.store(in: &cancellables)
    }
}

extension PSNetworking: PeersControllerDelegate {
    public func received(data: Data, viaStream: Bool) -> Bool {
        if let receivedEntity = try? JSONDecoder().decode(SendableBall.self, from: data) {
            if receivedEntity.sender != myName {
                Task {
                    await MainActor.run {
                        self.ballEntity = receivedEntity
                        print("assigned to ball entity: \(self.ballEntity)")
                    }
                }
            }else{
                print("shorted my name")
            }
            return true
        }else  if let receivedEntity = try? JSONDecoder().decode(Sendable.self, from: data) {
            print("found sendable instead")
        }
        print("extension PSNETWORK didn't work")
        return false
    }

}
