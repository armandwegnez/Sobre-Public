//
//  Drink.swift
//  Sobre Watch App
//
//  Created by Armand S Wegnez on 1/26/25.
// https://x.com/_armandwegnez Suivez-moi sur X 

import SwiftUI
import HealthKit
import CoreMotion
import WatchKit

// MARK: - Core Data Models
struct DrinkType: Identifiable {
    let id = UUID()
    var count: Int
    let type: DrinkCategory
    
    /// Total des boissons standard pour cette catégorie particulière
    var standardDrinks: Double {
        type.standardDrinks * Double(count)
    }
}

enum DrinkCategory: String, CaseIterable {
    case beer = "Bière"
    case wine = "Vin"
    case shot = "Shot"
    
    var icon: String {
        switch self {
            case .beer: return "🍺"
            case .wine: return "🍷"
            case .shot: return "🥃"
        }
    }
    
    /// Unités de boisson standard basées sur la teneur en alcool et la taille de portion typique
    var standardDrinks: Double {
        switch self {
            case .beer: return 1.0    // 5% ABV, 330ml (12oz)
            case .wine: return 1.2    // 12% ABV, 150ml (5oz)
            case .shot: return 1.5    // 40% ABV, 44ml (1.5oz)
        }
    }
}

// MARK: - Enhanced HealthKit Manager
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var currentHeartRate: Double = 0
    @Published var currentWeight: Double = 70.0 // Poids par défaut en kg
    
    private let requiredTypes: Set<HKQuantityType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.bodyMass)
    ]
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        healthStore.requestAuthorization(
            toShare: [HKQuantityType(.bodyMass)],
            read: requiredTypes
        ) { [weak self] success, error in
            guard success else { return }
            
            self?.startHeartRateMonitoring()
            self?.fetchLatestWeight()
        }
    }
    
    private func startHeartRateMonitoring() {
        let heartRateType = HKQuantityType(.heartRate)
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            guard let sample = samples?.last as? HKQuantitySample else { return }
            
            DispatchQueue.main.async {
                self?.currentHeartRate = sample.quantity.doubleValue(
                    for: HKUnit.count().unitDivided(by: .minute())
                )
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestWeight() {
        let weightType = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )
        
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            DispatchQueue.main.async {
                self?.currentWeight = sample.quantity.doubleValue(
                    for: .gramUnit(with: .kilo)
                )
            }
        }
        
        healthStore.execute(query)
    }
    
    func saveWeight(_ weight: Double) {
        let weightType = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(
            unit: .gramUnit(with: .kilo),
            doubleValue: weight
        )
        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: Date(),
            end: Date()
        )
        
        healthStore.save(sample) { [weak self] success, error in
            if success {
                DispatchQueue.main.async {
                    self?.currentWeight = weight
                }
            }
        }
    }
}

// MARK: - Enhanced Motion Manager
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var stabilityScore: Double = 1.0
    @Published var motionConfidence: Double = 1.0
    
    init() {
        setupMotionTracking()
    }
    
    private func setupMotionTracking() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion else { return }
            
            let rotationMagnitude = sqrt(
                pow(motion.rotationRate.x, 2) +
                pow(motion.rotationRate.y, 2) +
                pow(motion.rotationRate.z, 2)
            )
            
            let accelerationMagnitude = sqrt(
                pow(motion.userAcceleration.x, 2) +
                pow(motion.userAcceleration.y, 2) +
                pow(motion.userAcceleration.z, 2)
            )
            
            // Calcul de stabilité amélioré avec métrique de confiance
            self?.stabilityScore = 1.0 - min(1.0, (rotationMagnitude + accelerationMagnitude) / 10.0)
            self?.motionConfidence = motion.attitude.roll.magnitude < 0.3 ? 1.0 : 0.7
        }
    }
    
    func calibrateMotion() {
        // Réinitialiser la base et recalibrer le suivi du mouvement
        motionManager.stopDeviceMotionUpdates()
        setupMotionTracking()
    }
}

