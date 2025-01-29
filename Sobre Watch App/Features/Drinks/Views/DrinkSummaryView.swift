//
//  DrinkSummary.swift
//  Sobre Watch App
//
//  Created by Armand S Wegnez on 1/26/25.
//
// https://x.com/_armandwegnez Suivez-moi sur X 

import Foundation
import SwiftUI

struct SoberCountdownCard: View {
    // MARK: - Properties
    let drinks: [DrinkType]
    let lastDrinkTime: Date
    let weight: Double
    let gender: AlcoholMetabolism.Gender
    let isFasted: Bool
    
    // MARK: - Metabolism Calculations
    private var metabolism: AlcoholMetabolism {
        AlcoholMetabolism(
            weight: weight,
            gender: gender,
            isFasted: isFasted,
            firstDrinkTime: lastDrinkTime
        )
    }
    
    private var timeToSobriety: TimeInterval {
        let currentBAC = metabolism.calculateBAC(drinks: drinks)
        
        // Si déjà sobre
        if currentBAC <= 0 { return 0 }
        
        // Calcul du temps nécessaire pour atteindre 0.00 BAC
        let hoursToSober: Double
        
        if currentBAC > 0.08 {
            // Phase 1: Élimination ralentie (>0.08)
            let fastPhaseHours = (currentBAC - 0.08) / (0.015 * 0.9)
            // Phase 2: Élimination normale (≤0.08)
            let slowPhaseHours = 0.08 / 0.015
            hoursToSober = fastPhaseHours + slowPhaseHours
        } else {
            // Élimination normale uniquement
            hoursToSober = currentBAC / 0.015
        }
        
        return hoursToSober * 3600
    }
    
    private var timeLeftString: String {
        let totalSeconds = Int(timeToSobriety)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        return "\(hours)h \(minutes)m"
    }
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vous ne serez plus bourré dans :")
                .font(.headline)
            
            Text(timeLeftString)
                .font(.largeTitle)
                .fontWeight(.bold)
                
            if metabolism.calculateBAC(drinks: drinks) > 0 {
                Text(String(format: "Taux actuel : %.3f%%",
                          metabolism.calculateBAC(drinks: drinks)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

// MARK: - Preview Provider
struct SoberCountdownCard_Previews: PreviewProvider {
    static var previews: some View {
        SoberCountdownCard(
            drinks: [
                DrinkType(count: 2, type: .beer),
                DrinkType(count: 1, type: .shot)
            ],
            lastDrinkTime: Date().addingTimeInterval(-1800),
            weight: 70.0,
            gender: .male,
            isFasted: false
        )
        .previewLayout(.sizeThatFits)
    }
}
