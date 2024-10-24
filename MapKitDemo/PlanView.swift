import SwiftUI
import MapKit
import SceneKit
import ARKit

// Vue principale qui gère l'AR et la carte
struct ARMapView: View {
    let monuments = [
        Monument(name: "Monument 1", description: "Ce monument est un symbole historique important de la ville de Pompei.", coordinate: CLLocationCoordinate2D(latitude: 40.7505, longitude: 14.4866)),
        Monument(name: "Monument 2", description: "Un autre monument avec une riche histoire de l'époque romaine.", coordinate: CLLocationCoordinate2D(latitude: 40.751, longitude: 14.487)),
        Monument(name: "Monument 3", description: "Ce monument est connu pour son architecture unique et ses fresques anciennes.", coordinate: CLLocationCoordinate2D(latitude: 40.7515, longitude: 14.4875))
    ]
    
    let ago = CLLocationCoordinate2D(latitude: 40.7505, longitude: 14.4866)
    
    @State private var selectedMonumentIndex = 0
    @State private var showMap = false
    @State private var mapPosition: CGPoint? = nil
    @State private var mapSize: CGSize? = nil
    @State private var recenterOnAGO = false
    @State private var showMonumentDetail = false
    @Environment(\.presentationMode) var presentationMode
    var selectedMonument: Monument {
        monuments[selectedMonumentIndex]
    }

    var body: some View {
        ZStack {
            if let _ = try? ARImageDetectionView(userLocation: ago, showMap: $showMap, mapPosition: $mapPosition, mapSize: $mapSize) {
                ARImageDetectionView(userLocation: ago, showMap: $showMap, mapPosition: $mapPosition, mapSize: $mapSize)
                    .edgesIgnoringSafeArea(.all)
            }
            
            if showMap, let mapPosition = mapPosition, let mapSize = mapSize {
                MapView(monuments: monuments, userLocation: ago, selectedMonument: $selectedMonumentIndex, recenterOnAGO: $recenterOnAGO, showMonumentDetail: $showMonumentDetail)
                    .frame(width: mapSize.width, height: mapSize.height)
                    .cornerRadius(10)
                    .background(Color.white.opacity(0))
                    .position(mapPosition)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: showMap)
            }
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.backward.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.black)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Spacer()

                    // Bouton pour recentrer sur AGO à droite
                    Button(action: recenterOnAGOLocation) {
                        Image(systemName: "location.circle.fill")  // Utilisation d'une icône SF Symbols pour le bouton de localisation
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.black)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: {
                        showPreviousMonument()
                        showMonumentDetail = true
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.black)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 5)
                    
                    Button(action: {
                        showNextMonument()
                        showMonumentDetail = true
                    }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.black)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 5)
                    Spacer()
                }
                .padding(.bottom, 20)
            }
            
            if showMonumentDetail {
                VStack {
                    
                    HStack {
                        Spacer()
                        VStack {
                            Button(action: {
                                showMonumentDetail = false
                            }) {
                                Image(systemName: "xmark")
                                               .foregroundColor(.white)
                                               .padding()
                                               .background(Color.black)
                                               .clipShape(Circle())
                            }
                            SceneView(
                                scene: SCNScene(named: "WorkshopScene.usdz"),
                                options: [.allowsCameraControl]
                            )
                            .frame(width: 100, height: 100) // Augmentation de la taille du SceneView
                            .cornerRadius(10)
                            .padding(.top, 0)
                            .padding(.bottom, 0)
                            
                            Text(selectedMonument.name)
                                .font(.headline)
                                .padding(.bottom, 0)
                            
                            Text(selectedMonument.description)
                                .font(.body)
                                .padding(.horizontal)
                                .padding(.bottom, 0)
                            
                            .padding()
                        }
                        .frame(width: UIScreen.main.bounds.width * 0.5, height: UIScreen.main.bounds.height * 0.8) // Centrer la frame et ajuster la largeur
                        .background(Color.white)
                        .cornerRadius(15)
                        Spacer()
                    }

                }
            }
        }
        .navigationBarBackButtonHidden(true) // Masque le bouton "Back" en haut à gauche
        .navigationBarHidden(true) // Cache complètement la barre de navigation
        
    }
    
    private func showPreviousMonument() {
        selectedMonumentIndex = (selectedMonumentIndex - 1 + monuments.count) % monuments.count
    }

    private func showNextMonument() {
        selectedMonumentIndex = (selectedMonumentIndex + 1) % monuments.count
    }
    
    // Fonction pour recentrer la carte sur AGO
    private func recenterOnAGOLocation() {
        recenterOnAGO = true
    }
}

#Preview {
    ARMapView()
}

struct Monument: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    
    static func ==(lhs: Monument, rhs: Monument) -> Bool {
        return lhs.id == rhs.id
    }
}

// ... (ARImageDetectionView et MapView restent inchangés)
// ... (ARImageDetectionView et MapView restent inchangés)

// ... (ARImageDetectionView et MapView restent inchangés)

// ... (ARImageDetectionView et MapView restent inchangés)

// ... (ARImageDetectionView et MapView restent inchangés)


// ... (ARImageDetectionView et MapView restent inchangés)


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
                
                DispatchQueue.main.async { [weak self] in
                    self?.parent.showMap = true
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
                DispatchQueue.main.async { [weak self] in
                    self?.parent.showMap = imageAnchor.isTracked
                }
                
                updateMapPosition(renderer: renderer, node: node)
            }
        }

        func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            if anchor is ARImageAnchor {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.showMap = false
                }
            }
        }
        
        func updateMapPosition(renderer: SCNSceneRenderer, node: SCNNode) {
            guard let sceneView = renderer as? ARSCNView else { return }
            
            let projectedPoint = sceneView.projectPoint(node.position)
            let screenPoint = CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(projectedPoint.y))
            
            DispatchQueue.main.async { [weak self] in
                self?.parent.mapPosition = screenPoint
            }
        }
        
        func updateMapSize(referenceImage: ARReferenceImage) {
            let physicalWidth = referenceImage.physicalSize.width
            let physicalHeight = referenceImage.physicalSize.height
            let screenScale = UIScreen.main.scale
            
            let size = CGSize(width: physicalWidth * screenScale * 1000, height: physicalHeight * screenScale * 1000)
            
            DispatchQueue.main.async { [weak self] in
                self?.parent.mapSize = size
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    let monuments: [Monument]
    let userLocation: CLLocationCoordinate2D
    @Binding var selectedMonument: Int
    @Binding var recenterOnAGO: Bool
    @Binding var showMonumentDetail: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        
        let camera = MKMapCamera(lookingAtCenter: userLocation, fromDistance: 500, pitch: 60, heading: 0)
        mapView.camera = camera
        mapView.mapType = .mutedStandard
        
        mapView.showsPointsOfInterest = false
        mapView.showsUserLocation = true
        
        mapView.delegate = context.coordinator
        
        // Limiter la zone visible à une région définie autour des monuments
        let minLatitude = monuments.map { $0.coordinate.latitude }.min() ?? userLocation.latitude
        let maxLatitude = monuments.map { $0.coordinate.latitude }.max() ?? userLocation.latitude
        let minLongitude = monuments.map { $0.coordinate.longitude }.min() ?? userLocation.longitude
        let maxLongitude = monuments.map { $0.coordinate.longitude }.max() ?? userLocation.longitude
        
        let centerCoordinate = CLLocationCoordinate2D(latitude: (minLatitude + maxLatitude) / 2, longitude: (minLongitude + maxLongitude) / 2)
        let region = MKCoordinateRegion(center: centerCoordinate, span: MKCoordinateSpan(latitudeDelta: (maxLatitude - minLatitude) * 1.5, longitudeDelta: (maxLongitude - minLongitude) * 1.5))

        let boundary = MKMapView.CameraBoundary(coordinateRegion: region)
        mapView.setCameraBoundary(boundary, animated: true)

        // Optionnel : Limiter également le niveau de zoom
        let zoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 100, maxCenterCoordinateDistance: 1000)
        mapView.setCameraZoomRange(zoomRange, animated: true)

        for monument in monuments {
            let annotation = Custom3DAnnotation(coordinate: monument.coordinate, title: monument.name)
            mapView.addAnnotation(annotation)
        }
        
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        if recenterOnAGO {
            // Recentrer la caméra sur AGO quand recenterOnAGO est true
            let camera = MKMapCamera(lookingAtCenter: userLocation, fromDistance: 500, pitch: 60, heading: 0)
            mapView.setCamera(camera, animated: true)
            DispatchQueue.main.async {
                recenterOnAGO = false // Reset de l'état après l'animation
            }
        } else {
            let selectedMonument = monuments[selectedMonument]
            let camera = MKMapCamera(lookingAtCenter: selectedMonument.coordinate, fromDistance: 200, pitch: 75, heading: 0)
            mapView.setCamera(camera, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let customAnnotation = annotation as? Custom3DAnnotation else { return nil }

            let identifier = "3DMonument"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                
                if let scene = SCNScene(named: "WorkshopScene.usdz") {
                    let sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                    sceneView.scene = scene
                    sceneView.allowsCameraControl = true
                    sceneView.backgroundColor = .clear
                    
                    if let modelNode = scene.rootNode.childNodes.first {
                        let monumentSizeFactor: Float = 0.1  // Ajuster l'échelle selon les besoins
                        modelNode.scale = SCNVector3(monumentSizeFactor, monumentSizeFactor, monumentSizeFactor)
                    }
                    
                    let lightNode = SCNNode()
                    let light = SCNLight()
                    light.type = .directional
                    light.intensity = 1000
                    lightNode.light = light
                    lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
                    scene.rootNode.addChildNode(lightNode)

                    annotationView?.addSubview(sceneView)
                }
            } else {
                annotationView?.annotation = annotation
            }

            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.showMonumentDetail = true
                if let index = self?.parent.monuments.firstIndex(where: { $0.name == view.annotation?.title ?? "" }) {
                    self?.parent.selectedMonument = index
                }
            }
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
