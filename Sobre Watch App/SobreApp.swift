//
//  SobreApp.swift
//  Sobre Watch App
//
//  Created by Armand S Wegnez on 1/26/25.
// https://x.com/_armandwegnez Suivez-moi sur X

import SwiftUI

struct DisclaimerView: View {
    @State private var hasAcceptedDisclaimer = UserDefaults.standard.bool(forKey: "hasAcceptedDisclaimer")
    
    var body: some View {
        if hasAcceptedDisclaimer {
            ContentView()
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.orange)
                        .padding(.top, 8)
                    
                    Text("⚠️ Avertissement Important")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Cette application est expérimentale et ne doit PAS être utilisée pour :")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        WarningBullet("Déterminer votre capacité à conduire")
                        WarningBullet("Remplacer un éthylotest homologué")
                        WarningBullet("Prendre des décisions de sécurité")
                    }
                    .padding(.horizontal, 8)
                    
                    Text("Les calculs sont approximatifs et ne peuvent pas remplacer un test professionnel.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                    
                    Button("J'accepte les risques") {
                        UserDefaults.standard.set(true, forKey: "hasAcceptedDisclaimer")
                        hasAcceptedDisclaimer = true
                        WKInterfaceDevice.current().play(.success)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .padding(.top, 8)
                }
            }
        }
    }
}

struct WarningBullet: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text("•")
                .foregroundColor(.orange)
            Text(text)
                .font(.caption2)
        }
    }
}

@main
struct Sobre_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            DisclaimerView()
        }
    }
}

#Preview {
    DisclaimerView()
}
