import SwiftUI
import SceneKit

class ImageViewModel: ObservableObject {
    @Published var scene: SCNScene
    @Published var cameraNode: SCNNode
    @Published var roll: Float = 0 {
        didSet { updateCamera() }
    }
    @Published var pitch: Float = 0 {
        didSet { updateCamera() }
    }
    @Published var yaw: Float = 0 {
        didSet { updateCamera() }
    }
    @Published var fov: CGFloat = 60 {
        didSet { updateCamera() }
    }
    
    init() {
        scene = SCNScene()
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(cameraNode)
        
        // Set up sphere with equirectangular texture
        let sphere = SCNSphere(radius: 10)
        sphere.firstMaterial?.diffuse.contents = NSImage(named: "equirectangular_image")
        sphere.firstMaterial?.isDoubleSided = true
        let sphereNode = SCNNode(geometry: sphere)
        scene.rootNode.addChildNode(sphereNode)
    }
    
    func handlePan(_ value: DragGesture.Value) {
        let sensitivity: Float = 0.0001
        print(Float(value.translation.width) * sensitivity)
        yaw -= Float(value.translation.width) * sensitivity
        pitch += Float(value.translation.height) * sensitivity
        
        // Clamp pitch to avoid flipping
        pitch = max(-Float.pi/2, min(Float.pi/2, pitch))
        updateCamera()
    }

    func handlePinch(_ value: MagnificationGesture.Value) {
        fov = max(30, min(120, fov / CGFloat(value.magnitude)))
        updateCamera()
    }
    
    func updateCamera() {
        var transform = matrix_identity_float4x4
        transform = matrix_multiply(transform, matrix_float4x4(SCNMatrix4MakeRotation(CGFloat(yaw), 0, 1, 0)))
        transform = matrix_multiply(transform, matrix_float4x4(SCNMatrix4MakeRotation(CGFloat(pitch), 1, 0, 0)))
        transform = matrix_multiply(transform, matrix_float4x4(SCNMatrix4MakeRotation(CGFloat(roll), 0, 0, 1)))
        
        // Apply rotation
        cameraNode.simdTransform = transform
        // Update FOV
        cameraNode.camera?.fieldOfView = fov
    }
    
}
