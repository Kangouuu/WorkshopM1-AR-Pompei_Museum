//MVP final partie fonctionelle
import SwiftUI
import MapKit
import ARKit
import SceneKit

// Représentation de la carte MapKit en SwiftUI
struct MapView: UIViewRepresentable {
    let monuments: [Monument]
    let userLocation: CLLocationCoordinate2D
    @Binding var selectedMonument: Monument

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        
        // Configuration initiale de la caméra pour une vue 3D
        let camera = MKMapCamera(lookingAtCenter: userLocation,
                                 fromDistance: 500,
                                 pitch: 60,  // Inclinaison pour vue 3D
                                 heading: 0) // Orientation
        mapView.camera = camera
        mapView.mapType = .standard
        
        // Ajout des annotations pour les monuments
        for monument in monuments {
            let annotation = MKPointAnnotation()
            annotation.coordinate = monument.coordinate
            annotation.title = monument.name
            mapView.addAnnotation(annotation)
        }
        
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let camera = MKMapCamera(lookingAtCenter: selectedMonument.coordinate,
                                 fromDistance: 500,
                                 pitch: 60,
                                 heading: 0)
        mapView.setCamera(camera, animated: true)
    }
}

// Structure Monument conforme à Identifiable et Equatable
struct Monument: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    static func ==(lhs: Monument, rhs: Monument) -> Bool {
        return lhs.id == rhs.id
    }
}

// Vue AR avec tracking et détection d'image personnalisée
struct ARImageDetectionView: UIViewRepresentable {
    let userLocation: CLLocationCoordinate2D
    @Binding var showMap: Bool
    @Binding var mapPosition: CGPoint?
    @Binding var mapSize: CGSize?  // Ajouter une variable pour la taille de la carte

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        
        // Charger les images à détecter à partir du groupe "AR Resources"
        if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) {
            configuration.detectionImages = referenceImages
            configuration.maximumNumberOfTrackedImages = 1
        }
        
        sceneView.session.run(configuration)
        sceneView.delegate = context.coordinator
        sceneView.scene = SCNScene()
        
        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARImageDetectionView
        
        init(_ parent: ARImageDetectionView) {
            self.parent = parent
        }
        
        // Méthode appelée lorsque l'image est détectée
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            if let imageAnchor = anchor as? ARImageAnchor {
                let referenceImage = imageAnchor.referenceImage
                
                DispatchQueue.main.async {
                    self.parent.showMap = true
                }
                
                // Créer un plan correspondant à la taille de l'image détectée
                let plane = SCNPlane(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height)
                
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.clear
                plane.materials = [material]
                
                let planeNode = SCNNode(geometry: plane)
                planeNode.eulerAngles.x = -.pi / 2
                node.addChildNode(planeNode)
                
                // Mettre à jour la position et la taille de la carte
                updateMapPosition(renderer: renderer, node: planeNode)
                updateMapSize(referenceImage: referenceImage)  // Mettre à jour la taille
            }
        }
        
        // Méthode appelée lorsque l'image est suivie en continu (tracking)
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            if let imageAnchor = anchor as? ARImageAnchor {
                DispatchQueue.main.async {
                    self.parent.showMap = imageAnchor.isTracked
                }
                
                // Mettre à jour la position de la carte
                updateMapPosition(renderer: renderer, node: node)
            }
        }

        // Méthode appelée lorsque l'image sort du cadre
        func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            if anchor is ARImageAnchor {
                DispatchQueue.main.async {
                    self.parent.showMap = false
                }
            }
        }
        
        // Met à jour la position de la carte en projetant les coordonnées 3D en 2D
        func updateMapPosition(renderer: SCNSceneRenderer, node: SCNNode) {
            guard let sceneView = renderer as? ARSCNView else { return }
            
            // Projeter la position 3D de l'image sur l'écran
            let projectedPoint = sceneView.projectPoint(node.position)
            let screenPoint = CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(projectedPoint.y))
            
            DispatchQueue.main.async {
                self.parent.mapPosition = screenPoint
            }
        }
        
        // Met à jour la taille de la carte en fonction des dimensions physiques de l'image détectée
        func updateMapSize(referenceImage: ARReferenceImage) {
            let physicalWidth = referenceImage.physicalSize.width
            let physicalHeight = referenceImage.physicalSize.height
            let screenScale = UIScreen.main.scale  // Facteur d'échelle de l'écran (pour les écrans Retina, etc.)
            
            // Convertir la taille physique en points d'écran (en tenant compte de l'échelle)
            let size = CGSize(width: physicalWidth * screenScale * 1000,  // Ajuster le facteur d'échelle pour correspondre à la taille de la vue
                              height: physicalHeight * screenScale * 1000)
            
            DispatchQueue.main.async {
                self.parent.mapSize = size
            }
        }
    }
}

// Vue principale qui gère l'AR et la carte
struct ContentView: View {
    let monuments = [
        Monument(name: "Monument 1", coordinate: CLLocationCoordinate2D(latitude: 43.654823, longitude: -79.391623)),
        Monument(name: "Monument 2", coordinate: CLLocationCoordinate2D(latitude: 43.654957, longitude: -79.393223))
    ]
    
    let ago = CLLocationCoordinate2D(latitude: 43.653823848647725, longitude: -79.3925230435043)
    
    @State private var selectedMonument = Monument(name: "Monument 1", coordinate: CLLocationCoordinate2D(latitude: 43.654823, longitude: -79.391623))
    @State private var showMap = false
    @State private var mapPosition: CGPoint? = nil
    @State private var mapSize: CGSize? = nil  // Ajouter une variable d'état pour la taille

    var body: some View {
        ZStack {
            // Afficher la vue AR avec tracking
            ARImageDetectionView(userLocation: ago, showMap: $showMap, mapPosition: $mapPosition, mapSize: $mapSize)
                .edgesIgnoringSafeArea(.all)
            
            // Afficher la carte quand l'image est détectée
            if showMap, let mapPosition = mapPosition, let mapSize = mapSize {
                MapView(monuments: monuments, userLocation: ago, selectedMonument: $selectedMonument)
                    .frame(width: mapSize.width, height: mapSize.height)  // Ajuster la taille de la carte en fonction de l'image détectée
                    .cornerRadius(10)
                    .background(Color.white.opacity(0.9))
                    .position(mapPosition)  // Positionner la carte sur l'image détectée
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: showMap)
            }
        }
    }
}

#Preview {
    ContentView()
}
