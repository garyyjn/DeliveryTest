//
//  PostureUtils.swift
//  ThrowingBall
//
//  Created by Gary Yao on 4/27/24.
//

import Foundation
import ARKit
import RealityKit

extension simd_float4x4 {
    init(translation vector: SIMD3<Float>) {
        self.init(SIMD4<Float>(1, 0, 0, 0),
                  SIMD4<Float>(0, 1, 0, 0),
                  SIMD4<Float>(0, 0, 1, 0),
                  SIMD4<Float>(vector.x, vector.y, vector.z, 1))
    }
    
    var translation: SIMD3<Float> {
        get {
            columns.3.xyz
        }
        set {
            self.columns.3 = [newValue.x, newValue.y, newValue.z, 1]
        }
    }
    
    var rotation: simd_quatf {
        simd_quatf(rotationMatrix)
    }
    
    var xAxis: SIMD3<Float> { columns.0.xyz }
    
    var yAxis: SIMD3<Float> { columns.1.xyz }
    
    var zAxis: SIMD3<Float> { columns.2.xyz }
    
    var rotationMatrix: simd_float3x3 {
        matrix_float3x3(xAxis,
                        yAxis,
                        zAxis)
    }
    
    /// Get a gravity-aligned copy of this 4x4 matrix.
    var gravityAligned: simd_float4x4 {
        // Project the z-axis onto the horizontal plane and normalize to length 1.
        let projectedZAxis: SIMD3<Float> = [zAxis.x, 0.0, zAxis.z]
        let normalizedZAxis = normalize(projectedZAxis)
        
        // Hardcode y-axis to point upward.
        let gravityAlignedYAxis: SIMD3<Float> = [0, 1, 0]
        
        let resultingXAxis = normalize(cross(gravityAlignedYAxis, normalizedZAxis))
        
        return simd_matrix(
            SIMD4(resultingXAxis.x, resultingXAxis.y, resultingXAxis.z, 0),
            SIMD4(gravityAlignedYAxis.x, gravityAlignedYAxis.y, gravityAlignedYAxis.z, 0),
            SIMD4(normalizedZAxis.x, normalizedZAxis.y, normalizedZAxis.z, 0),
            columns.3
        )
    }
}

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

extension SIMD2<Float> {
    /// Checks whether this point is inside a given triangle defined by three vertices.
    func isInsideOf(_ vertex1: SIMD2<Float>, _ vertex2: SIMD2<Float>, _ vertex3: SIMD2<Float>) -> Bool {
        // This point lies within the triangle given by v1, v2 & v3 if its barycentric coordinates are in range [0, 1].
        let coords = barycentricCoordinatesInTriangle(vertex1, vertex2, vertex3)
        return coords.x >= 0 && coords.x <= 1 && coords.y >= 0 && coords.y <= 1 && coords.z >= 0 && coords.z <= 1
    }
    
    /// Computes the barycentric coordinates of this point relative to a given triangle defined by three vertices.
    func barycentricCoordinatesInTriangle(_ vertex1: SIMD2<Float>, _ vertex2: SIMD2<Float>, _ vertex3: SIMD2<Float>) -> SIMD3<Float> {
        // Compute vectors between the vertices.
        let v2FromV1 = vertex2 - vertex1
        let v3FromV1 = vertex3 - vertex1
        let selfFromV1 = self - vertex1
        
        // Compute the area of:
        // 1. the passed in triangle,
        // 2. triangle "u" (v1, v3, self) &
        // 3. triangle "v" (v1, v2, self).
        // Note: The area of a triangle is the length of the cross product of the two vectors that span the triangle.
        let areaOverallTriangle = cross(v2FromV1, v3FromV1).z
        let areaU = cross(selfFromV1, v3FromV1).z
        let areaV = cross(v2FromV1, selfFromV1).z

        // The barycentric coordinates of point self are vertices v1, v2 & v3 weighted by (u, v, w).
        // Compute these weights by dividing the triangle’s areas by the overall area.
        let u = areaU / areaOverallTriangle
        let v = areaV / areaOverallTriangle
        let w = 1.0 - v - u
        return SIMD3<Float>(u, v, w)
    }
}

func preSnap(lefthand:HandAnchor) -> Bool{
    guard
        let indextip = lefthand.handSkeleton?.joint(.indexFingerTip),
        let indexknuckle = lefthand.handSkeleton?.joint(.indexFingerKnuckle),
        let middletip = lefthand.handSkeleton?.joint(.middleFingerTip),
        let middleknuckle = lefthand.handSkeleton?.joint(.middleFingerKnuckle),
        let thumbtip = lefthand.handSkeleton?.joint(.thumbTip),
        let thumbknuckle = lefthand.handSkeleton?.joint(.thumbKnuckle),
        let forearm = lefthand.handSkeleton?.joint(.forearmArm),
        let wrist = lefthand.handSkeleton?.joint(.wrist)
    else{
        return false
    }
    let lefthandanchor = lefthand.originFromAnchorTransform
    let indextiploc = getlocation(jointloc: lefthandanchor, parentloc: indextip.anchorFromJointTransform)
    let indexknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: indexknuckle.anchorFromJointTransform)
    
    let middletiploc = getlocation(jointloc: lefthandanchor, parentloc: middletip.anchorFromJointTransform)
    let middleknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: middleknuckle.anchorFromJointTransform)
    let thumbtiploc = getlocation(jointloc: lefthandanchor, parentloc: thumbtip.anchorFromJointTransform)
    let thumbknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: thumbknuckle.anchorFromJointTransform)
    let forearmloc = getlocation(jointloc: lefthandanchor, parentloc: forearm.anchorFromJointTransform)
    let wristloc = getlocation(jointloc: lefthandanchor, parentloc: wrist.anchorFromJointTransform)
    
    let distance_middle_index = distance(middletiploc, thumbtiploc)
    return distance_middle_index < 0.02
}

func afterSnap(lefthand:HandAnchor) -> Bool{
    guard
        let indextip = lefthand.handSkeleton?.joint(.indexFingerTip),
        let indexknuckle = lefthand.handSkeleton?.joint(.indexFingerKnuckle),
        let middletip = lefthand.handSkeleton?.joint(.middleFingerTip),
        let middleknuckle = lefthand.handSkeleton?.joint(.middleFingerKnuckle),
        let thumbtip = lefthand.handSkeleton?.joint(.thumbTip),
        let thumbknuckle = lefthand.handSkeleton?.joint(.thumbKnuckle),
        let forearm = lefthand.handSkeleton?.joint(.forearmArm),
        let wrist = lefthand.handSkeleton?.joint(.wrist)
    else{
        return false
    }
    let lefthandanchor = lefthand.originFromAnchorTransform
    let indextiploc = getlocation(jointloc: lefthandanchor, parentloc: indextip.anchorFromJointTransform)
    let indexknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: indexknuckle.anchorFromJointTransform)
    
    let middletiploc = getlocation(jointloc: lefthandanchor, parentloc: middletip.anchorFromJointTransform)
    let middleknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: middleknuckle.anchorFromJointTransform)
    let thumbtiploc = getlocation(jointloc: lefthandanchor, parentloc: thumbtip.anchorFromJointTransform)
    let thumbknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: thumbknuckle.anchorFromJointTransform)
    let forearmloc = getlocation(jointloc: lefthandanchor, parentloc: forearm.anchorFromJointTransform)
    let wristloc = getlocation(jointloc: lefthandanchor, parentloc: wrist.anchorFromJointTransform)
    
    let distance_middle_index = distance(middletiploc, thumbknuckleloc)
    return distance_middle_index < 0.08
}

func getlocation(jointloc:simd_float4x4, parentloc:simd_float4x4) -> simd_float4{
    return(matrix_multiply(jointloc, parentloc).columns.3)
}
