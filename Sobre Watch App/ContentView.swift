//
//  AnalysisView.swift
//  Sobre Watch App
//
//  Created by Armand S Wegnez on 1/26/25.
// https://x.com/_armandwegnez Suivez-moi sur X 

import SwiftUI
import HealthKit
import CoreMotion
import WatchKit

// MARK: - Core Views
struct ContentView: View {
    // Core managers
    @StateObject private var healthKit = HealthKitManager()
    @StateObject private var motionManager = MotionManager()
    @StateObject private var weightManager = WeightManager()
    
    // State management
    @State private var drinks: [DrinkType] = DrinkCategory.allCases.map {
        DrinkType(count: 0, type: $0)
    }
    @State private var showingSobrietyCheck = false
    @State private var showingWeightSheet = false
    @State private var currentPage = 0
    @State private var lastDrinkTime = Date()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var userGender: AlcoholMetabolism.Gender = .male
    @State private var userIsFasted: Bool = false
    
    // Computed metrics
    private var totalStandardDrinks: Double {
        drinks.reduce(0.0) { $0 + $1.standardDrinks }
    }
    
    // MARK: - BAC Calculation
    private var estimatedBAC: Double {
        // Créer une instance de notre calculateur de métabolisme
        let metabolism = AlcoholMetabolism(
            weight: weightManager.currentWeight,  // Poids actuel en kg
            gender: userGender,                   // Genre de l'utilisateur (impact le facteur Widmark)
            isFasted: userIsFasted,              // État digestif (impact l'absorption)
            firstDrinkTime: lastDrinkTime        // Heure du premier verre (pour le calcul d'élimination)
        )
        
        // Calculer le taux d'alcoolémie en utilisant notre nouveau modèle
        return metabolism.calculateBAC(drinks: drinks)
    }

    /* Explication détaillée de l'algorithme de calcul du taux d'alcoolémie :

    1. Données d'entrée importantes :
       - Poids (kg) : Impact la dilution de l'alcool dans le corps
       - Genre : Détermine le facteur Widmark (distribution de l'eau dans le corps)
         * Homme = 0.68
         * Femme = 0.55
       - État digestif : Impact la vitesse d'absorption
         * À jeun = absorption plus rapide (100%)
         * Après repas = absorption ralentie (85%)
       - Temps écoulé : Pour calculer l'élimination progressive

    2. Calcul de base (Formule de Widmark améliorée) :
       BAC = (Grammes d'alcool / (Poids en grammes × Facteur Widmark)) × 100
       
       Où :
       - Grammes d'alcool = Nombre d'unités standard × 14g
       - Poids en grammes = Poids en kg × 1000
       - Facteur Widmark = 0.68 (H) ou 0.55 (F)

    3. Ajustements pour plus de précision :
       a. État digestif
          - Si pas à jeun : BAC × 0.85 (absorption ralentie)
       
       b. Élimination non linéaire
          - Taux standard = 0.015 par heure
          - Si BAC > 0.08 : Taux réduit à 90% (0.015 × 0.9)
          - Elimination = Taux × Heures écoulées

    4. Résultat final :
       BAC final = max(0, BAC initial - Élimination)

    Cette approche est plus précise que la version précédente car elle prend en compte :
    - Les différences physiologiques liées au genre
    - L'impact de l'état digestif sur l'absorption
    - L'élimination progressive et non linéaire de l'alcool
    */
    
    var body: some View {
        TabView(selection: $currentPage) {
            // First Tab: Input Interface
            VStack(spacing: 16) {
                DrinkSelectionView(
                    drinks: $drinks,
                    onDrinkAdded: {
                        lastDrinkTime = Date()
                        checkSobriety()
                    }
                )
                
                // Weight Management Card
                Button(action: showWeightSheet) {
                    WeightDisplayCard(weight: weightManager.currentWeight)
                }
                .buttonStyle(.plain)
            }
            .tag(0)

            AnalysisView(
                drinks: drinks,
                weight: weightManager.currentWeight,
                bac: estimatedBAC,
                heartRate: healthKit.currentHeartRate,
                stability: motionManager.stabilityScore,
                motionConfidence: motionManager.motionConfidence,
                lastDrinkTime: lastDrinkTime,
                gender: userGender,
                isFasted: userIsFasted
            )
            .tag(1)
        }
        .tabViewStyle(.page)
        .sheet(isPresented: $showingWeightSheet) {
            WeightConfigurationView(
                weightManager: weightManager,
                gender: $userGender,
                isFasted: $userIsFasted
            )
        }
        .onAppear {
            setupHealthKit()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Private Methods
    private func setupHealthKit() {
        Task {
            do {
                healthKit.requestAuthorization()
                weightManager.requestAuthorization()
                WKInterfaceDevice.current().play(.start)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func showWeightSheet() {
        WKInterfaceDevice.current().play(.click)
        showingWeightSheet = true
    }
    
    private func checkSobriety() {
        if estimatedBAC > 0.04 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingSobrietyCheck = true
            }
        }
    }

}

// MARK: - Weight Display Card
struct WeightDisplayCard: View {
    let weight: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Poids")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("\(weight, specifier: "%.1f") kg")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            Image(systemName: "pencil.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)
                .background(
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 30, height: 30)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

// MARK: - Preview Provider
#Preview {
    ContentView()
}
