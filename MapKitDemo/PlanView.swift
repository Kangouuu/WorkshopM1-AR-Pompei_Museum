import SwiftUI
import MapKit
import SceneKit
import ARKit

// Vue principale qui gère l'AR et la carte
struct ARMapView: View {
    let monuments = [
        Monument(name: "Monument 2", description: "Un autre monument avec une riche histoire de l'époque romaine.", coordinate: CLLocationCoordinate2D(latitude: 40.7512, longitude: 14.4875), modelFileName: "Monument2Scene.usdz"),
        Monument(name: "Monument 3", description: "Ce monument est connu pour son architecture unique et ses fresques anciennes.", coordinate: CLLocationCoordinate2D(latitude: 40.7515, longitude: 14.4878), modelFileName: "Monument3Scene.usdz"),
        Monument(name: "Monument 4", description: "Ce monument est un témoignage de l'ingénierie romaine et est situé au coeur de la ville.", coordinate: CLLocationCoordinate2D(latitude: 40.7518, longitude: 14.4872), modelFileName: "Monument4Scene.usdz"),
        Monument(name: "Monument 5", description: "Un monument qui représente l'époque médiévale avec des influences architecturales notables.", coordinate: CLLocationCoordinate2D(latitude: 40.7520, longitude: 14.4870), modelFileName: "Monument5Scene.usdz")
    ]
    
    let ago = CLLocationCoordinate2D(latitude: 40.7505, longitude: 14.4866)
    
    @State private var selectedMonumentIndex = 0
    @State private var showMap = false
    @State private var mapPosition: CGPoint? = nil
    @State private var mapSize: CGSize? = nil
    @State private var recenterOnAGO = false
    @State private var showDetailView = false
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showARView = false // État pour gérer la présentation de la vue AR

    var selectedMonument: Monument {
        monuments[selectedMonumentIndex]
    }

    var body: some View {
        NavigationView {
            ZStack {
                ARImageDetectionView(userLocation: ago, showMap: $showMap, mapPosition: $mapPosition, mapSize: $mapSize, selectedMonumentIndex: $selectedMonumentIndex)
                    .edgesIgnoringSafeArea(.all)
                    
                if showMap, let mapPosition = mapPosition, let mapSize = mapSize {
                    MapView(monuments: monuments, userLocation: ago, selectedMonument: $selectedMonumentIndex, recenterOnAGO: $recenterOnAGO, showDetailView: $showDetailView)
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

                        Button(action: recenterOnAGOLocation) {
                            Image(systemName: "location.circle.fill")
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
                        NavigationLink(
                            destination: ARMonumentViewWrapper(modelFileName: selectedMonument.modelFileName),
                            isActive: $showARView,
                            label: {
                                EmptyView()
                            }
                        )
                        
                        Button(action: {
                            showPreviousMonument()
                            showARView = true
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
                            showARView = true
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
            }
        }
        .sheet(isPresented: $showDetailView) {
            MonumentDetailView(monument: selectedMonument)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    private func showPreviousMonument() {
        selectedMonumentIndex = (selectedMonumentIndex - 1 + monuments.count) % monuments.count
    }

    private func showNextMonument() {
        selectedMonumentIndex = (selectedMonumentIndex + 1) % monuments.count
    }
    
    private func recenterOnAGOLocation() {
        recenterOnAGO = true
    }
}

struct Monument: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let modelFileName: String
    
    static func ==(lhs: Monument, rhs: Monument) -> Bool {
        return lhs.id == rhs.id
    }
}

// Optimisation de la vue MapView
struct MapView: UIViewRepresentable {
    let monuments: [Monument]
    let userLocation: CLLocationCoordinate2D
    @Binding var selectedMonument: Int
    @Binding var recenterOnAGO: Bool
    @Binding var showDetailView: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        
        let camera = MKMapCamera(lookingAtCenter: userLocation, fromDistance: 500, pitch: 60, heading: 0)
        mapView.camera = camera
        mapView.mapType = .mutedStandard
        
        mapView.showsPointsOfInterest = false
        mapView.showsUserLocation = true
        
        mapView.delegate = context.coordinator
        
        // Ajout des annotations de manière plus efficace
        let annotations = monuments.map { monument in
            Custom3DAnnotation(coordinate: monument.coordinate, title: monument.name)
        }
        mapView.addAnnotations(annotations)
        
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        if recenterOnAGO {
            let camera = MKMapCamera(lookingAtCenter: userLocation, fromDistance: 500, pitch: 60, heading: 0)
            mapView.setCamera(camera, animated: true)
            DispatchQueue.main.async {
                recenterOnAGO = false
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

                // Utilisation d'une vue simplifiée pour alléger la carte
                annotationView?.image = UIImage(systemName: "mappin.circle.fill")
            } else {
                annotationView?.annotation = annotation
            }

            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? Custom3DAnnotation, let index = parent.monuments.firstIndex(where: { $0.name == annotation.title }) {
                parent.selectedMonument = index
                parent.showDetailView = true
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

// Vue 3D pour les détails du monument
struct Scene3DView: UIViewRepresentable {
    let modelFileName: String

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView(frame: .zero)
        if let scene = SCNScene(named: modelFileName) {
            sceneView.scene = scene
            sceneView.allowsCameraControl = true
            sceneView.autoenablesDefaultLighting = true
        }
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Mises à jour si nécessaire
    }
}

// Vue détaillée du monument
struct MonumentDetailView: View {
    let monument: Monument

    var body: some View {
        VStack {
            Text(monument.name)
                .font(.largeTitle)
                .padding()
            Text(monument.description)
                .padding()

            // Vue 3D pour afficher le modèle du monument
            Scene3DView(modelFileName: monument.modelFileName)
                .frame(width: 300, height: 300)
                .padding()

            Spacer()
        }
        .navigationTitle("Monument Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Wrapper pour ARMonumentView pour éviter l'erreur de portée
struct ARMonumentViewWrapper: View {
    let modelFileName: String

    var body: some View {
        Scene3DView(modelFileName: modelFileName)
            .navigationTitle("AR Monument View")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// Vue pour la détection d'image en AR
struct ARImageDetectionView: UIViewRepresentable {
    let userLocation: CLLocationCoordinate2D
    @Binding var showMap: Bool
    @Binding var mapPosition: CGPoint?
    @Binding var mapSize: CGSize?
    @Binding var selectedMonumentIndex: Int

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
