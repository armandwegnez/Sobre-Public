//
//  HeartRateManager.swift
//  Sobre Watch App
//
//  Created by Armand S Wegnez on 1/26/25.

// https://x.com/_armandwegnez Suivez-moi sur X 
import Foundation
import HealthKit

class HeartRateManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    // Publier la dernière lecture de la fréquence cardiaque
    @Published var currentHeartRate: Double = 0.0
    
    // Appelez ceci une fois pour demander l'autorisation et démarrer la requête
    func requestAuthorizationAndStartUpdates() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Les données de santé ne sont pas disponibles sur cet appareil.")
            return
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let typesToShare: Set<HKSampleType> = []
        let typesToRead: Set<HKObjectType> = [heartRateType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                // Commencer à surveiller la fréquence cardiaque
                self.startHeartRateQuery()
            } else if let error = error {
                print("L'autorisation a échoué: \(error.localizedDescription)")
            }
        }
    }
    
    private func startHeartRateQuery() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        
        // Créer une requête qui se déclenche chaque fois qu'un nouvel échantillon de FC est ajouté
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("Erreur ObserverQuery: \(error.localizedDescription)")
                return
            }
            // Si de nouvelles données sont disponibles, récupérer le dernier échantillon
            self?.fetchLatestHeartRateSample()
        }
        
        healthStore.execute(query)
        // Activer la livraison en arrière-plan pour les changements de fréquence cardiaque
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if let error = error {
                print("Erreur enableBackgroundDelivery: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchLatestHeartRateSample() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType,
                                  predicate: nil,
                                  limit: 1,
                                  sortDescriptors: [sortByDate]) { [weak self] _, samples, error in
            guard let self = self, error == nil else {
                return
            }
            
            if let sample = samples?.first as? HKQuantitySample {
                // La FC est stockée en comptage/min -> récupérer la valeur
                let hrUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let hrValue = sample.quantity.doubleValue(for: hrUnit)
                
                DispatchQueue.main.async {
                    self.currentHeartRate = hrValue
                }
            }
        }
        healthStore.execute(query)
    }
}
