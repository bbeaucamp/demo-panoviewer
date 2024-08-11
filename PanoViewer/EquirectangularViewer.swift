import SwiftUI
import MetalKit

struct EquirectangularViewer: NSViewRepresentable {
    @ObservedObject var viewModel: ImageViewModel
    @Binding var yaw: Float
    @Binding var pitch: Float
    @Binding var roll: Float
    @Binding var fov: Float

    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0)
        
        let panGesture = NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        mtkView.addGestureRecognizer(panGesture)
        
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.texture = viewModel.texture
        context.coordinator.yaw = yaw
        context.coordinator.pitch = pitch
        context.coordinator.roll = roll
        context.coordinator.fov = fov
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var parent: EquirectangularViewer
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var texture: MTLTexture?
        
        var yaw: Float = 0
        var pitch: Float = 0
        var roll: Float = 0
        var fov: Float = 90

        init(_ parent: EquirectangularViewer) {
            self.parent = parent
            super.init()
            
            if let device = MTLCreateSystemDefaultDevice() {
                self.device = device
                self.commandQueue = device.makeCommandQueue()
                setupMetal()
            } else {
                fatalError("Metal is not supported on this device")
            }
        }

        func setupMetal() {
            guard let library = device.makeDefaultLibrary() else { fatalError("Unable to create default Metal library") }
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
            
            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                fatalError("Unable to create pipeline state: \(error)")
            }
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }

            renderEncoder.setRenderPipelineState(pipelineState)
            
            var uniforms = Uniforms(yaw: yaw, pitch: pitch, roll: roll, fov: fov)
            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
            renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)

            if let texture = texture {
                renderEncoder.setFragmentTexture(texture, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            } else {
                print("Texture is nil")
            }

            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        @objc func handlePan(_ gestureRecognizer: NSPanGestureRecognizer) {
            let translation = gestureRecognizer.translation(in: gestureRecognizer.view)
            parent.yaw -= Float(translation.x) * 0.01
            parent.pitch += Float(translation.y) * 0.01
            
            parent.pitch = max(-Float.pi/2, min(Float.pi/2, parent.pitch))
            
            gestureRecognizer.setTranslation(.zero, in: gestureRecognizer.view)
        }
    }
}

struct Uniforms {
    var yaw: Float
    var pitch: Float
    var roll: Float
    var fov: Float
}
