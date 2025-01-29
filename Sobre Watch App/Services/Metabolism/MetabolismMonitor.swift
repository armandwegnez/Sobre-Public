//
//  MetabolismMonitor.swift
//  Sobre Watch App
//
//  Created by Armand S Wegnez on 29/01/2025.
//
import Foundation

class MetabolismMonitor: ObservableObject {
    @Published private(set) var currentBAC: Double = 0
    @Published private(set) var metabolicStatus: MetabolicStatus = .normal
    
    private let updateInterval: TimeInterval = 300 // 5 minutes
    private var timer: Timer?
    private var metabolism: AlcoholMetabolism
    private var drinks: [TimestampedDrink] = []
    
    private let healthKit: HealthKitManager
    private let motionManager: MotionManager
    
    enum MetabolicStatus {
        case normal, impaired, critical
        
        static func determine(
            bac: Double,
            heartRate: Double,
            stability: Double
        ) -> MetabolicStatus {
            let isHeartRateElevated = heartRate > 100 // Le rythme cardiaque est-il élevé ?
            let isStabilityCompromised = stability < 0.8 // La stabilité est-elle compromise ?
            let isBAcCritical = bac > 0.08 // Le taux d'alcoolémie est-il critique ?
            
            switch (isBAcCritical, isHeartRateElevated, isStabilityCompromised) {
            case (true, true, _), (true, _, true):
                return .critical
            case (true, false, false), (false, true, true):
                return .impaired
            default:
                return .normal
            }
        }
    }
    
    init(metabolism: AlcoholMetabolism, healthKit: HealthKitManager, motionManager: MotionManager) {
        self.metabolism = metabolism
        self.healthKit = healthKit
        self.motionManager = motionManager
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateMetabolicStatus()
        }
    }
    
    // Nouvelle méthode pour mettre à jour le métabolisme
    func updateMetabolism(_ newMetabolism: AlcoholMetabolism) {
        self.metabolism = newMetabolism
        updateMetabolicStatus()
    }
    
    // Nouvelle méthode pour mettre à jour les boissons
    func updateDrinks(_ newDrinks: [TimestampedDrink]) {
        self.drinks = newDrinks
        updateMetabolicStatus()
    }
    
    private func updateMetabolicStatus() {
        currentBAC = metabolism.calculateBAC(timestampedDrinks: drinks) // Calculer le taux d'alcoolémie actuel
        
        metabolicStatus = MetabolicStatus.determine(
            bac: currentBAC,
            heartRate: healthKit.currentHeartRate,
            stability: motionManager.stabilityScore
        ) // Déterminer le statut métabolique
    }
}
