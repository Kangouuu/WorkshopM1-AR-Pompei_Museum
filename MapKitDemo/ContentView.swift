import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Image de fond utilisée comme background
                Color(red: 35/255, green: 35/255, blue: 35/255)
                    .edgesIgnoringSafeArea(.all)
                Color.clear.overlay(
                    Image("statueImage") // Remplace par ton image
                        .resizable()
                        .scaledToFill()  // Faire en sorte que l'image remplisse tout l'espace
                )
                .edgesIgnoringSafeArea(.all)  // Couvrir tout l'écran

                // Superposition du logo et du bouton
                VStack {
                    // Supprimer le Spacer() supérieur pour placer les éléments en haut
                    HStack {
                        VStack(alignment: .leading, spacing: 20) {
                            // Logo
                            Image("Logo") // Remplace par ton image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200) // Taille du logo
                                .padding(.leading)

                            // Bouton de navigation
                            NavigationLink(destination: ARMapView()) {
                                HStack {
                                    Text("View Plan")
                                        .font(.custom("montserrat", size: 20)) // Utilisation de la police Montserrat
                                        .fontWeight(.bold)
                                        .foregroundColor(.black) // Couleur noire pour le texte

                                    Image(systemName: "arrow.right")
                                        .font(.title2)
                                        .foregroundColor(.black) // Couleur noire pour l'icône
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.leading) // Aligner à gauche
                        
                        Spacer() // Pousser tout à gauche
                    }
                    
                    Spacer() // Garde ce Spacer pour repousser les éléments du bas de l'écran
                }
                .padding(.top, 50) // Ajoute un padding en haut pour contrôler la hauteur
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
