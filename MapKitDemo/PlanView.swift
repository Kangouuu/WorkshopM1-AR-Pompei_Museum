import SwiftUI
import MapKit
import SceneKit
import ARKit

// Vue principale qui gère l'AR et la carte
struct ARMapView: View {
    let monuments = [
        Monument(name: "Monument 1", coordinate: CLLocationCoordinate2D(latitude: 43.654823, longitude: -79.391623)),
        Monument(name: "Monument 2", coordinate: CLLocationCoordinate2D(latitude: 43.654957, longitude: -79.393223)),
        Monument(name: "Monument 3", coordinate: CLLocationCoordinate2D(latitude: 43.655, longitude: -79.394))
    ]
    
    let ago = CLLocationCoordinate2D(latitude: 43.653823848647725, longitude: -79.3925230435043)
    
    @State private var selectedMonument = Monument(name: "Monument 1", coordinate: CLLocationCoordinate2D(latitude: 43.654823, longitude: -79.391623))
    @State private var showMap = false
    @State private var mapPosition: CGPoint? = nil
    @State private var mapSize: CGSize? = nil

    var body: some View {
        ZStack {
            ARImageDetectionView(userLocation: ago, showMap: $showMap, mapPosition: $mapPosition, mapSize: $mapSize)
                .edgesIgnoringSafeArea(.all)
            
            if showMap, let mapPosition = mapPosition, let mapSize = mapSize {
                MapView(monuments: monuments, userLocation: ago, selectedMonument: $selectedMonument)
                    .frame(width: mapSize.width, height: mapSize.height)
                    .cornerRadius(10)
                    .background(Color.white.opacity(0.9))
                    .position(mapPosition)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: showMap)
            }
            
            VStack {
                Spacer()
                
                HStack {
                    Button(action: showPreviousMonument) {
                        Text("Monument Précédent")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: showNextMonument) {
                        Text("Monument Suivant")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private func showPreviousMonument() {
        if let currentIndex = monuments.firstIndex(of: selectedMonument) {
            let previousIndex = (currentIndex - 1 + monuments.count) % monuments.count
            selectedMonument = monuments[previousIndex]
        }
    }

    private func showNextMonument() {
        if let currentIndex = monuments.firstIndex(of: selectedMonument) {
            let nextIndex = (currentIndex + 1) % monuments.count
            selectedMonument = monuments[nextIndex]
        }
    }
}

#Preview {
    ARMapView()
}

struct Monument: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    static func ==(lhs: Monument, rhs: Monument) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ARImageDetectionView: UIViewRepresentable {
    let userLocation: CLLocationCoordinate2D
    @Binding var showMap: Bool
    @Binding var mapPosition: CGPoint?
    @Binding var mapSize: CGSize?

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        
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
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            if let imageAnchor = anchor as? ARImageAnchor {
                let referenceImage = imageAnchor.referenceImage
                
                DispatchQueue.main.async {
                    self.parent.showMap = true
                }
                
                let plane = SCNPlane(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height)
                
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.clear
                plane.materials = [material]
                
                let planeNode = SCNNode(geometry: plane)
                planeNode.eulerAngles.x = -.pi / 2
                node.addChildNode(planeNode)
                
                updateMapPosition(renderer: renderer, node: planeNode)
                updateMapSize(referenceImage: referenceImage)
            }
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            if let imageAnchor = anchor as? ARImageAnchor {
                DispatchQueue.main.async {
                    self.parent.showMap = imageAnchor.isTracked
                }
                
                updateMapPosition(renderer: renderer, node: node)
            }
        }

        func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            if anchor is ARImageAnchor {
                DispatchQueue.main.async {
                    self.parent.showMap = false
                }
            }
        }
        
        func updateMapPosition(renderer: SCNSceneRenderer, node: SCNNode) {
            guard let sceneView = renderer as? ARSCNView else { return }
            
            let projectedPoint = sceneView.projectPoint(node.position)
            let screenPoint = CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(projectedPoint.y))
            
            DispatchQueue.main.async {
                self.parent.mapPosition = screenPoint
            }
        }
        
        func updateMapSize(referenceImage: ARReferenceImage) {
            let physicalWidth = referenceImage.physicalSize.width
            let physicalHeight = referenceImage.physicalSize.height
            let screenScale = UIScreen.main.scale
            
            let size = CGSize(width: physicalWidth * screenScale * 1000, height: physicalHeight * screenScale * 1000)
            
            DispatchQueue.main.async {
                self.parent.mapSize = size
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    let monuments: [Monument]
    let userLocation: CLLocationCoordinate2D
    @Binding var selectedMonument: Monument

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        
        // Activer l'affichage des bâtiments 3D
        mapView.showsBuildings = true
        
        // Configuration de la caméra pour une vue 3D
        let camera = MKMapCamera(lookingAtCenter: userLocation, fromDistance: 200, pitch: 80, heading: 0)
        mapView.camera = camera
        mapView.mapType = .mutedStandard
        mapView.showsPointsOfInterest = false
        mapView.showsUserLocation = false
        mapView.delegate = context.coordinator

        for monument in monuments {
            let annotation = Custom3DAnnotation(coordinate: monument.coordinate, title: monument.name)
            mapView.addAnnotation(annotation)
        }
        
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Mise à jour de la caméra pour une vue 3D plus prononcée
        let camera = MKMapCamera(lookingAtCenter: selectedMonument.coordinate,
                                 fromDistance: 150,  // Distance ajustée pour être plus proche du monument
                                 pitch: 85,          // Inclinaison élevée pour une vue en perspective
                                 heading: 45)        // Angle horizontal ajusté pour un effet oblique
        mapView.setCamera(camera, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self, monuments: monuments)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var monuments: [Monument]

        // Définir les limites autorisées
        var boundingRegion: MKCoordinateRegion
        
        init(_ parent: MapView, monuments: [Monument]) {
            self.parent = parent
            self.monuments = monuments
            
            let coordinates = monuments.map { $0.coordinate }
            let latitudes = coordinates.map { $0.latitude }
            let longitudes = coordinates.map { $0.longitude }
            let center = CLLocationCoordinate2D(latitude: (latitudes.max()! + latitudes.min()!) / 2,
                                                longitude: (longitudes.max()! + longitudes.min()!) / 2)
            let span = MKCoordinateSpan(latitudeDelta: (latitudes.max()! - latitudes.min()!) * 1.5,
                                        longitudeDelta: (longitudes.max()! - longitudes.min()!) * 1.5)
            boundingRegion = MKCoordinateRegion(center: center, span: span)
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Empêcher l'utilisateur de naviguer en dehors de la région définie
            let currentRegion = mapView.region
            let maxLat = boundingRegion.center.latitude + boundingRegion.span.latitudeDelta / 2
            let minLat = boundingRegion.center.latitude - boundingRegion.span.latitudeDelta / 2
            let maxLon = boundingRegion.center.longitude + boundingRegion.span.longitudeDelta / 2
            let minLon = boundingRegion.center.longitude - boundingRegion.span.longitudeDelta / 2
            
            let currentMaxLat = currentRegion.center.latitude + currentRegion.span.latitudeDelta / 2
            let currentMinLat = currentRegion.center.latitude - currentRegion.span.latitudeDelta / 2
            let currentMaxLon = currentRegion.center.longitude + currentRegion.span.longitudeDelta / 2
            let currentMinLon = currentRegion.center.longitude - currentRegion.span.longitudeDelta / 2
            
            // Si la région actuelle dépasse les limites, on la réinitialise
            if currentMaxLat > maxLat || currentMinLat < minLat || currentMaxLon > maxLon || currentMinLon < minLon {
                mapView.setRegion(boundingRegion, animated: true)
            }
        }

        // Fonction pour rendre les annotations en 3D
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let customAnnotation = annotation as? Custom3DAnnotation else { return nil }

            let identifier = "3DMonument"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
                
                // Création d'une scène SCNNode directement dans la carte
                let scene = SCNScene(named: "WorkshopScene.usdz")
                
                if let modelNode = scene?.rootNode.childNodes.first {
                    let monumentSizeFactor: Float = 0.1
                    modelNode.scale = SCNVector3(monumentSizeFactor, monumentSizeFactor, monumentSizeFactor)
                    modelNode.position = SCNVector3(0, 1, 0)
                    modelNode.eulerAngles = SCNVector3(0, Float.pi / 4, 0)

                    // Lumière directionnelle pour éclairer l'objet 3D
                    let lightNode = SCNNode()
                    let light = SCNLight()
                    light.type = .directional
                    light.intensity = 1000
                    lightNode.light = light
                    lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
                    modelNode.addChildNode(lightNode)
                    
                    // Ajouter la vue 3D en tant que sous-vue de l'annotation
                    let scnView = SCNView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                    scnView.scene = scene
                    scnView.allowsCameraControl = true
                    scnView.backgroundColor = UIColor.clear
                    
                    annotationView?.addSubview(scnView)
                }
            } else {
                annotationView?.annotation = annotation
            }

            return annotationView
        }
    }
}

class Custom3DAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?

    init(coordinate: CLLocationCoordinate2D, title: String?) {
        self.coordinate = coordinate
        self.title = title
    }
}
