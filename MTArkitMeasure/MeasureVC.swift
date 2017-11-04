//
//  ViewController.swift
//  ARMeasureApp
//
//  Created by SA on 10/30/17.
//  Copyright © 2017 Sris. All rights reserved.


import UIKit
import SceneKit
import ARKit

enum measureState: String {
    case start = "start"
    case stop = "stop"
}

class MeasureVC: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var centerPlusButton: UIButton!
    @IBOutlet weak var scaleLabel: UILabel!
    @IBOutlet weak var stateButton: UIButton!
    
    var viewCenter: CGPoint!
    var startLocation: SCNVector3?
    var scene: SCNScene!
    var lineNode: SCNNode?
    var state = measureState.stop
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewCenter = self.view.center
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        scene = SCNScene()
        // Set the scene to the view
        sceneView.scene = scene
        stateButton.setTitle("Tap Here to start", for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
        // Pause the view's session
        sceneView.session.pause()
    }
   
    @IBAction func stateButtonTapped(_ sender: Any) {
        setButtonState()
        state = (state == measureState.stop) ?  measureState.start : measureState.stop
        if state == measureState.start {
            self.startLocation = nil
            self.lineNode?.removeFromParentNode()
            self.lineNode = nil
        } else {
            DispatchQueue.main.async {
               self.scaleLabel.text = ""
            }
            self.startLocation = nil
            self.lineNode?.removeFromParentNode()
            self.lineNode = nil
        }
    }
    
    func setButtonState() {
        stateButton.setTitle(state.rawValue, for: .normal)
    }
    
    // MARK: - ARSCNViewDelegate  
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if state == measureState.stop {
            return
        }
        
        if startLocation == nil {
            let hitResults = self.sceneView.hitTest(self.viewCenter, types: ARHitTestResult.ResultType.featurePoint)
            if hitResults.count > 0 {
                let result: ARHitTestResult = hitResults.first!
                self.startLocation = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
            }
            return
        }
        
        let hitResults = self.sceneView.hitTest(self.viewCenter, types: ARHitTestResult.ResultType.featurePoint)
        
        if hitResults.count > 0 {
            let result: ARHitTestResult = hitResults.first!
            let newLocation = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
            if let distance = self.startLocation?.distance(vector: newLocation) {
                DispatchQueue.main.async {
                    self.scaleLabel.text = String.init(format: "%.2f inches", self.meterToInches(val: CGFloat(distance)))
                }
                    self.drawLine(from: self.startLocation!, to: newLocation)
                }
                
            }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        glLineWidth(20)
    }
    
    func drawLine(from: SCNVector3, to: SCNVector3) {
        self.lineNode?.removeFromParentNode()
        self.lineNode = nil
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [from, to])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let geometry =  SCNGeometry(sources: [source], elements: [element])
        geometry.materials.first?.diffuse.contents = UIColor.blue
        self.lineNode = SCNNode(geometry: geometry)
        self.scene.rootNode.addChildNode(self.lineNode!)
    }
    
    func meterToInches(val: CGFloat) -> CGFloat {
        return 39.37 * val
    }
   
}

