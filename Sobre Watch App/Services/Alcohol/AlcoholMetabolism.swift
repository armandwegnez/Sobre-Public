//
//  AlcoholMetabolism.swift
//  Sobre Watch App
//
//  Created by Armand S Wegnez on 29/01/2025.
// https://x.com/_armandwegnez Suivez-moi sur X 

import Foundation

// MARK: - Core Metabolism Models
struct TimestampedDrink: Identifiable {
    let id = UUID()
    let type: DrinkType
    let timestamp: Date
    
    var minutesSinceConsumption: Double {
        -timestamp.timeIntervalSinceNow / 60
    }
    
    var absorptionPhase: AbsorptionPhase {
        switch minutesSinceConsumption {
        case ..<30: return .initial
        case 30..<90: return .peak
        default: return .elimination
        }
    }
}

enum AbsorptionPhase {
    case initial
    case peak
    case elimination
    
    var absorptionRate: Double {
        switch self {
        case .initial: return 0.75
        case .peak: return 1.0
        case .elimination: return 0.98
        }
    }
}

struct AlcoholMetabolism {
    // MARK: - Properties
    let weight: Double
    let gender: Gender
    let isFasted: Bool
    let firstDrinkTime: Date
    
    // MARK: - Constants
    private enum Constants {
        static let alcoholGramsPerUnit = 14.0
        static let fastingModifier = 0.85
        static let criticalBACThreshold = 0.08
        static let baseEliminationRate = 0.015
        static let highBACEliminationModifier = 0.9
    }
    
    enum Gender: String {
        case male = "Homme"
        case female = "Femme"
        
        var widmarkFactor: Double {
            switch self {
            case .male: return 0.68
            case .female: return 0.55
            }
        }
    }
    
    // MARK: - BAC Calculations
    func calculateBAC(timestampedDrinks: [TimestampedDrink]) -> Double {
        let totalContribution = timestampedDrinks.reduce(0.0) { acc, drink in
            let baseContribution = drink.type.standardDrinks * Constants.alcoholGramsPerUnit
            return acc + (baseContribution * drink.absorptionPhase.absorptionRate)
        }
        
        let weightInGrams = weight * 1000.0
        var bac = (totalContribution / (weightInGrams * gender.widmarkFactor)) * 100.0
        
        // Ajustement selon l'état digestif
        if !isFasted {
            bac *= Constants.fastingModifier
        }
        
        // Calcul de l'élimination
        let oldestDrinkTime = timestampedDrinks.map(\.timestamp).min() ?? firstDrinkTime
        let hoursElapsed = Date().timeIntervalSince(oldestDrinkTime) / 3600
        
        // Élimination non linéaire basée sur le taux d'alcoolémie
        let eliminationRate = bac > Constants.criticalBACThreshold ?
            Constants.baseEliminationRate * Constants.highBACEliminationModifier :
            Constants.baseEliminationRate
            
        let eliminated = eliminationRate * hoursElapsed
        
        return max(0.0, bac - eliminated)
    }
    
    // Support de l'ancienne méthode pour la rétrocompatibilité (ne touchez pas sauf si vous savez ce que vous faites)
    func calculateBAC(drinks: [DrinkType]) -> Double {
        let timestampedDrinks = drinks.map { drink in
            TimestampedDrink(type: drink, timestamp: firstDrinkTime)
        }
        return calculateBAC(timestampedDrinks: timestampedDrinks)
    }
}
