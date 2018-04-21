//
//  ViewController.swift
//  FolledoPokemonGo
//
//  Created by Samuel Folledo on 4/19/18.
//  Copyright © 2018 Samuel Folledo. All rights reserved.
//

import UIKit
import SceneKit
import AVFoundation //p.5
import CoreLocation //p.9

protocol ARControllerDelegate { //p.14
    func viewController(controller: ViewController, tappedTarget: ARItem)
}

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var leftIndicator: UILabel!
    @IBOutlet weak var rightIndicator: UILabel!
    
    var cameraSession: AVCaptureSession? //to connect a video input, like a camera
    var cameraLayer: AVCaptureVideoPreviewLayer? //preview layer
    
    var target: ARItem!
    
    var locationManager = CLLocationManager() //p.9 to receive the heading the device is looking
    var heading: Double = 0 //p.9 heading is measured in degrees from either true north or the magnetic north pole
    var userLocation = CLLocation() //p.9
    
    let scene = SCNScene() //p.9
    let cameraNode = SCNNode() //p.9
    let targetNode = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)) //p.9
    
    var delegate: ARControllerDelegate? //p.14
    
//viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCamera() //p.7
        self.cameraSession?.startRunning() //p.7 start grabbing frames from the camera, which are displayed automatically on the preview layer
        
        self.locationManager.delegate = self //p.9 #1 sets ViewController a the delegate for the CLLocationManager
        self.locationManager.startUpdatingHeading() //p.9 #2 after this call, you will have the heading information. By default, the delegate is informed when the heading changes more than 1 degree
        
        sceneView.scene = scene //p.9 #3 creates an empty scene and adds a camera
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x:0, y:0, z:10)
        scene.rootNode.addChildNode(cameraNode)
        
        setUpTarget()//p.11
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//createCaptureSession
    func createCaptureSession() -> (session: AVCaptureSession?, error: NSError?) { //p.5 to have the input in the camera
        //#1 vars for return value
        var error: NSError?
        var captureSession: AVCaptureSession?
        let backVideoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) //#2 p.6 get the rear camera of the device
        
        if backVideoDevice != nil { //#3 if camera exists, get its input
            var videoInput: AVCaptureDeviceInput!
            do {
                videoInput = try AVCaptureDeviceInput(device: backVideoDevice!)
            } catch let error1 as NSError {
                error = error1
                videoInput = nil
                print("No rear camera found")
            }
            
            //#4 p.6 create an instance of AVCaptureSession
            if error == nil {
                captureSession = AVCaptureSession()
                
                //#5 p.6 add the video device as an input
                if captureSession!.canAddInput(videoInput) {
                    captureSession!.addInput(videoInput)
                } else {
                    error = NSError(domain: "", code: 1, userInfo: ["description":"Error adding video input."])
                }
            } else {
                error = NSError(domain: "", code: 1, userInfo: ["description": "Error creating capture device input."])
            }
        } else { //if backVideo is nil
            error = NSError(domain: "", code: 2, userInfo: ["description": "Back video device not found."])
        }
        
        return (session: captureSession, error: error) //#6 p.6 return a tuple that contains either the captureSession or an error
    } //end of createCaptureSession
    
//loadCamera p.6
    func loadCamera() {
        let captureSessionResult = createCaptureSession() //p.7 #1 call captureSession
        guard captureSessionResult.error == nil, let session = captureSessionResult.session else { //p.7 #2 if error or captureSession is nil, return
            print("Error creating capture session")
            return
        }
        
        self.cameraSession = session //p.7 #3 if everything is fine, store capture session in cameraSession
        
        //if let cameraLayer = AVCaptureVideoPreviewLayer(session: self.cameraSession!) {
        let cameraLayer = AVCaptureVideoPreviewLayer(session: self.cameraSession!) //p.7 #4 creates a video preview layer; if successful, it sets videoGravity and sets the frame of the layer to the views bounds (fullscreen view)..... AVCaptureVideoPreviewLayer is a core animation layer that can display a video as it is being captured
        cameraLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraLayer.frame = self.view.bounds
        
        self.view.layer.insertSublayer(cameraLayer, at: 0) //p.7 #5 add the layer as a sublayer and store it in cameraLayer
        self.cameraLayer = cameraLayer
        
    }
    
//repositionTarget p.9
    func repositionTarget() {
        let heading = getHeadingForDirectionFromCoordinate(from: userLocation, to: target.location) //p. 10 #1 calculates the heading from the current location to the target
        let delta = heading - self.heading //p. 10 #2 then calculate a delta value of the device's current heading and teh location's heading
        
        if delta < -15.0 { //if delta is less than -15, display the left indicator label
            leftIndicator.isHidden = false
            rightIndicator.isHidden = true
        } else if delta > 15 {
            leftIndicator.isHidden = true
            rightIndicator.isHidden = false
        } else {
            leftIndicator.isHidden = true
            rightIndicator.isHidden = true
        }
        
        let distance = userLocation.distance(from: target.location) //p. 10 #3 get the distance from the device's position to the enemy
        
        if let node = target.itemNode { //p. 10 #4 if item has a node assigned...
            if node.parent == nil { //p. 10 #5 and the node has no parent, you set the position using the distance and add the node to the scene
                node.position = SCNVector3(x: Float(delta), y: 0, z:Float(-distance))
                scene.rootNode.addChildNode(node)
            } else { //p. 10 #6 otherwise, remove all actions adn create a new action
                node.removeAllActions()
                node.runAction(SCNAction.move(to: SCNVector3(x: Float(delta), y:0, z:Float(-distance)), duration: 0.2)) //p.10 SCNAction.move(to:,duration:) creates ana ction that moves a node to the given position in the given duration.
            }
        }
    }
    
/* //not needed anymore since Swift4
    func radiansToDegree(_ radians: Double) -> Double {
        return (radians) * (180.0 / Double.pi)
    }
    func degressToRadians(_ degrees: Double) -> Double {
        return (degrees) * (Double.pi / 180.0)
    }
*/
    
    func getHeadingForDirectionFromCoordinate(from: CLLocation, to: CLLocation) -> Double {
        //p.11 #1 first, convert all values for lat and long to radians
        let fLat = GLKMathDegreesToRadians(Float(from.coordinate.latitude))
        let fLng = GLKMathDegreesToRadians(Float(from.coordinate.longitude))
        let tLat = GLKMathDegreesToRadians(Float(to.coordinate.latitude))
        let tLng = GLKMathDegreesToRadians(Float(to.coordinate.longitude))
        
        let degree = GLKMathRadiansToDegrees (atan2 (sin(tLng - fLng) * cos(tLat), cos(fLat) * sin(tLat) - sin(fLat) * cos(tLat) * cos(tLng - fLng))) //p.11 #2 with these values, you calculate the heading and convert it back to degrees
        
        //p.11 #3 if value is negative, normalize it by adding 360 degrees. Since -90 degrees is the same as 270 degree
        if degree >= 0 {
            return Double(degree)
        } else {
            return Double(degree + 360)
        }
    }
    
    func setUpTarget() { //p.11 give targetNode a name and assign it to the target. called in viewDidLoad
        //targetNode.name = "enemy" //p.11
        //self.target.itemNode = targetNode //p.11
        
        let scene = SCNScene(named: "art.scnassets/\(target.itemDescription).dae") //p.12 #1 load the model into a scene
        let enemy = scene?.rootNode.childNode(withName: target.itemDescription, recursively: true) //p.12 #2 traverse the scene to find a node with the name of itemDescriptionn. There's only one node with this name which also happens to be the root node of the model
        
        if target.itemDescription == "dragon" { //p.12 #3 adjust the position so that both models appear at the same palce. If you get your models from the same designed, you might nod need this step
            enemy?.position = SCNVector3(x:0, y:-15, z:0)
        } else {
            enemy?.position = SCNVector3(x:0, y:0, z:0)
        }
        
        let node = SCNNode() //p.13 #4 add the model to an empy node assign it to the itemNode property of the current target. Small trick to make touch handling in the next section a little easier
        node.addChildNode(enemy!)
        node.name = "enemy"
        self.target.itemNode = node
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first! //p.13 #1 conver touch to a coordinate inside the scene
        let location = touch.location(in: sceneView)
        
        let hitResult = sceneView.hitTest(location, options: nil) //p.13 #2 hitTest(_, options:) sends a ray trace to the given position and returns an array of SCNHitTestResult for every node that is on the line of the ray trace
        let fireBall = SCNParticleSystem(named: "Fireball.scnp", inDirectory: nil) //p.13 #3 this loads the particle system for the fireball
        
        let emitterNode = SCNNode() //p.13 #4 then load the particle system to an empty node and place it at the bottom, outside the screen. This makes it look like the fireball is coming from the player's position
        emitterNode.position = SCNVector3(x:0, y:-5, z:10)
        emitterNode.addParticleSystem(fireBall!)
        scene.rootNode.addChildNode(emitterNode)
        
        if hitResult.first != nil { //p.13 #5 if you detect a hit...
            //p.13 #6wait for a short period then remove the itemNode containing the enemy. You also move the emitter node to the enemy's position at the same time
            target.itemNode?.runAction(SCNAction.sequence([SCNAction.wait(duration: 0.5), SCNAction.removeFromParentNode(), SCNAction.hide()])) //p.13
            
            let sequence = SCNAction.sequence([SCNAction.move(to: target.itemNode!.position, duration: 0.5), //p.14 #1 change the action of the emtiter node to a sequence, the move actions stays the same
                                               SCNAction.wait(duration: 3), //p.14 #2 after emitter moves, pause for 3 seconds
                                               SCNAction.run({_ in self.delegate?.viewController(controller: self, tappedTarget: self.target) //p.14 #3 then inform the delegate that a target was hit
                                               })]) //p.14
            
            //let moveAction = SCNAction.move(to: target.itemNode!.position, duration: 0.5)//p.13
            emitterNode.runAction(sequence)//p.13
        } else {//p.13
             //p.13 #7 if you dont hit,the fireball simply moves to a fixed position
            emitterNode.runAction(SCNAction.move(to: SCNVector3(x:0,y:0,z:-30), duration: 0.5))//p.13
        }
    }
    
}

extension ViewController: CLLocationManagerDelegate { //p.9 CLLocationManager calls this delegate method each time a new heading information is available. fmod is the module function for double values, and assures that heading is in the range of 0-359
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = fmod(newHeading.trueHeading, 360.0) //The heading (measured in degrees) relative to true north. The value in this property represents the heading relative to the geographic North Pole. The value 0 means the device is pointed toward true north, 90 means it is pointed due east, 180 means it is pointed due south, and so on. A negative value indicates that the heading could not be determined.
        repositionTarget()
    }
}

