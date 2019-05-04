//
//  GameViewController.swift
//  ScreenCapture
//
//  Created by Toshihiro Goto on 2019/04/27.
//  Copyright © 2019 Toshihiro Goto. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {

    @IBOutlet weak var captureView: SCNView!
    @IBOutlet weak var mainView: SCNView!
    
    // Box geometry node
    private var capturedNode:SCNNode!
    
    // Metal
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var renderer: SCNRenderer!
    
    // Texture Settings
    var offscreenTexture: MTLTexture!
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = Int(4)
    let bitsPerComponent = Int(8)
    let bitsPerPixel:Int = 32
    
    var textureSizeX:CGFloat!
    var textureSizeY:CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Metal Settings
        device = captureView.device
        commandQueue = device.makeCommandQueue()
        renderer = SCNRenderer(device: device, options: nil)
        
        // Texture Settings
        textureSizeX = captureView.bounds.width
        textureSizeY = captureView.bounds.height
        
        setupTexture()
        
        // captureView
        let captureScene = SCNScene(named: "art.scnassets/caputre.scn")!
        
        captureView.scene = captureScene
        captureView.allowsCameraControl = true
        captureView.showsStatistics = true
        
        // mainView
        let mainScene = SCNScene(named: "art.scnassets/main.scn")!
        
        // Put textures on Box geometry
        capturedNode = mainScene.rootNode.childNode(withName: "box", recursively: false)!
        capturedNode.geometry?.firstMaterial?.diffuse.contents = offscreenTexture

        capturedNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 4)))
        
        mainView.scene = mainScene
        mainView.allowsCameraControl = true
        mainView.showsStatistics = true
        
        mainView.delegate = self
    }
    
    // MARK: - SceneKit Delegate
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        sceneRender()
    }

    // MARK: - Metal
    func sceneRender() {
        let viewport = CGRect(x: 0, y: 0, width: CGFloat(textureSizeX), height: CGFloat(textureSizeY))

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = offscreenTexture
        //renderPassDescriptor.colorAttachments[0].loadAction = .clear
        //renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0.0); // clear
        //renderPassDescriptor.colorAttachments[0].storeAction = .store

        let commandBuffer = commandQueue.makeCommandBuffer()

        // reuse scene1 and the current point of view
        renderer.scene = captureView.scene
        renderer.pointOfView = captureView.pointOfView
        renderer.render(atTime: 0, viewport: viewport, commandBuffer: commandBuffer!, passDescriptor: renderPassDescriptor)

        commandBuffer?.commit()
    }

    func setupTexture() {

        var rawData0 = [UInt8](repeating: 0, count: Int(textureSizeX) * Int(textureSizeY) * 4)

        let bytesPerRow = 4 * Int(textureSizeX)
        
        //let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

        //let context = CGContext(data: &rawData0, width: Int(textureSizeX), height: Int(textureSizeY), bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: bitmapInfo)!
        //context.setFillColor(UIColor.green.cgColor)
        //context.fill(CGRect(x: 0, y: 0, width: CGFloat(textureSizeX), height: CGFloat(textureSizeY)))

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba8Unorm, width: Int(textureSizeX), height: Int(textureSizeY), mipmapped: false)

        textureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)

        let texture = device.makeTexture(descriptor: textureDescriptor)

        let region = MTLRegionMake2D(0, 0, Int(textureSizeX), Int(textureSizeY))
        texture?.replace(region: region, mipmapLevel: 0, withBytes: &rawData0, bytesPerRow: Int(bytesPerRow))

        offscreenTexture = texture
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
}
