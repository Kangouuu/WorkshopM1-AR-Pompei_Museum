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
    @State private var showARView = false

    var selectedMonument: Monument {
        monuments[selectedMonumentIndex]
    }

    var body: some View {
        ZStack {
            if let _ = try? ARImageDetectionView(userLocation: ago, showMap: $showMap, mapPosition: $mapPosition, mapSize: $mapSize, selectedMonumentIndex: $selectedMonumentIndex) {
                ARImageDetectionView(userLocation: ago, showMap: $showMap, mapPosition: $mapPosition, mapSize: $mapSize, selectedMonumentIndex: $selectedMonumentIndex)
                    .edgesIgnoringSafeArea(.all)
            }
            
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
                
                // Bouton pour afficher la scène AR du monument sélectionné
                Button(action: {
                    showARView = true
                }) {
                    Text("Voir en AR")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showDetailView) {
            MonumentDetailView(monument: selectedMonument)
        }
        .sheet(isPresented: $showARView) {
            ARSceneView(monuments: monuments, selectedMonumentIndex: $selectedMonumentIndex)
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

// Nouveau ARSceneView pour afficher la scène AR et naviguer entre les monuments
struct ARSceneView: UIViewControllerRepresentable {
    let monuments: [Monument]
    @Binding var selectedMonumentIndex: Int

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let sceneView = ARSCNView(frame: viewController.view.bounds)
        viewController.view.addSubview(sceneView)

        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)

        // Charger le premier monument
        loadMonumentModel(sceneView: sceneView, modelFileName: monuments[selectedMonumentIndex].modelFileName)

        // Ajouter boutons de navigation pour se déplacer entre les monuments
        let previousButton = UIButton(type: .system)
        previousButton.setTitle("Précédent", for: .normal)
        previousButton.frame = CGRect(x: 20, y: viewController.view.bounds.height - 60, width: 100, height: 40)
        previousButton.addTarget(context.coordinator, action: #selector(context.coordinator.showPreviousMonument), for: .touchUpInside)

        let nextButton = UIButton(type: .system)
        nextButton.setTitle("Suivant", for: .normal)
        nextButton.frame = CGRect(x: viewController.view.bounds.width - 120, y: viewController.view.bounds.height - 60, width: 100, height: 40)
        nextButton.addTarget(context.coordinator, action: #selector(context.coordinator.showNextMonument), for: .touchUpInside)

        viewController.view.addSubview(previousButton)
        viewController.view.addSubview(nextButton)

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    // Fonction pour charger un modèle 3D
    private func loadMonumentModel(sceneView: ARSCNView, modelFileName: String) {
        if let scene = SCNScene(named: modelFileName) {
            sceneView.scene = scene

            if let modelNode = scene.rootNode.childNodes.first {
                let monumentSizeFactor: Float = 0.08
                modelNode.scale = SCNVector3(monumentSizeFactor, monumentSizeFactor, monumentSizeFactor)
            }

            // Ajouter lumière
            let lightNode = SCNNode()
            let light = SCNLight()
            light.type = .directional
            light.intensity = 1000
            lightNode.light = light
            lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
            scene.rootNode.addChildNode(lightNode)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: ARSceneView
        var sceneView: ARSCNView?

        init(_ parent: ARSceneView) {
            self.parent = parent
        }

        // Naviguer vers le monument précédent
        @objc func showPreviousMonument() {
            parent.selectedMonumentIndex = (parent.selectedMonumentIndex - 1 + parent.monuments.count) % parent.monuments.count
            if let sceneView = sceneView {
                parent.loadMonumentModel(sceneView: sceneView, modelFileName: parent.monuments[parent.selectedMonumentIndex].modelFileName)
            }
        }

        // Naviguer vers le monument suivant
        @objc func showNextMonument() {
            parent.selectedMonumentIndex = (parent.selectedMonumentIndex + 1) % parent.monuments.count
            if let sceneView = sceneView {
                parent.loadMonumentModel(sceneView: sceneView, modelFileName: parent.monuments[parent.selectedMonumentIndex].modelFileName)
            }
        }
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
        
        for monument in monuments {
            let annotation = Custom3DAnnotation(coordinate: monument.coordinate, title: monument.name)
            mapView.addAnnotation(annotation)
        }
        
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

                if let monument = parent.monuments.first(where: { $0.name == customAnnotation.title }) {
                    if let scene = SCNScene(named: monument.modelFileName) {
                        let sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
                        sceneView.scene = scene
                        sceneView.allowsCameraControl = true
                        sceneView.backgroundColor = .clear

                        if let modelNode = scene.rootNode.childNodes.first {
                            let monumentSizeFactor: Float = 0.08
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
                }
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

struct MonumentDetailView: View {
    let monument: Monument

    var body: some View {
        VStack {
            Text(monument.name)
                .font(.largeTitle)
                .padding()
            Text(monument.description)
                .padding()
            Spacer()
        }
        .navigationTitle("Monument Details")
        .navigationBarTitleDisplayMode(.inline)
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
