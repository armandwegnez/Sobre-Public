//
//  DrinkSummary.swift
//  Sobre Watch App
//
//  Created by Armand S Wegnez on 1/26/25.
//
// https://x.com/_armandwegnez Suivez-moi sur X 

import SwiftUI
import HealthKit
import WatchKit

// MARK: - Core Weight Management Models
struct WeightRecord: Identifiable, Hashable {
    let id: UUID
    let weight: Double
    let date: Date
    let source: String
    
    // MARK: - Init
    init(
        id: UUID = UUID(),
        weight: Double,
        date: Date = Date(),
        source: String
    ) {
        self.id = id
        self.weight = weight
        self.date = date
        self.source = source
    }
    
    // MARK: - Conformité Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Conformité Equatable
    static func == (lhs: WeightRecord, rhs: WeightRecord) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Propriétés calculées
    var formattedWeight: String {
        String(format: "%.1f", weight)
    }
    
    var formattedDate: String {
        date.formatted(
            .dateTime
                .month(.abbreviated)
                .day()
                .hour()
                .minute()
        )
    }
}

// MARK: - Weight Management System
final class WeightManager: ObservableObject {
    // MARK: - Priv Properties
    private let healthStore = HKHealthStore()
    
    // MARK: - Public Properties
    @Published var currentWeight: Double = 70.0
    @Published var weightUnit: HKUnit = .gramUnit(with: .kilo)
    @Published var weightHistory: [WeightRecord] = []
    @Published var isLoading: Bool = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    // MARK: - Constant
    private enum Constants {
        static let defaultWeight: Double = 70.0
        static let minWeight: Double = 40.0
        static let maxWeight: Double = 140.0
        static let weightStep: Double = 0.5
    }
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let weightType = HKQuantityType(.bodyMass)
        
        healthStore.requestAuthorization(
            toShare: [weightType],
            read: [weightType]
        ) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.fetchLatestWeight()
                    self?.observeWeightChanges()
                    self?.authorizationStatus = .sharingAuthorized
                } else {
                    self?.authorizationStatus = .sharingDenied
                    if let error = error {
                        print("Authorization failed: \(error.localizedDescription)")
                    }
                }
            }
        }
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
            guard let self = self,
                  let sample = samples?.first as? HKQuantitySample else {
                if let error = error {
                    print("Failed to fetch weight: \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.currentWeight = sample.quantity.doubleValue(for: self.weightUnit)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func observeWeightChanges() {
        let weightType = HKQuantityType(.bodyMass)
        
        let query = HKAnchoredObjectQuery(
            type: weightType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, deletedObjects, anchor, error in
            guard let self = self,
                  let samples = samples as? [HKQuantitySample] else {
                if let error = error {
                    print("Failed to observe weight changes: \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.processNewWeightSamples(samples)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func processNewWeightSamples(_ samples: [HKQuantitySample]) {
        let newRecords = samples.map { sample in
            WeightRecord(
                weight: sample.quantity.doubleValue(for: weightUnit),
                date: sample.startDate,
                source: sample.sourceRevision.source.name
            )
        }
        
        weightHistory.append(contentsOf: newRecords)
        if let latestWeight = newRecords.last?.weight {
            currentWeight = latestWeight
        }
    }
    
    func saveWeight(_ weight: Double) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let weightType = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: weightUnit, doubleValue: weight)
        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: Date(),
            end: Date()
        )
        
        try await healthStore.save(sample)
        
        await MainActor.run {
            self.currentWeight = weight
            let newRecord = WeightRecord(
                weight: weight,
                source: "Sobre Watch App"
            )
            self.weightHistory.append(newRecord)
        }
    }
}

struct WeightConfigurationView: View {
    @State private var showError = false
    @State private var errorMessage = ""
    @StateObject private var weightManager: WeightManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    
    @Binding var gender: AlcoholMetabolism.Gender
    @Binding var isFasted: Bool
    
    private let genderOptions: [(id: Int, gender: AlcoholMetabolism.Gender)] = [
        (0, .male),
        (1, .female)
    ]
    
    private let weightRange: ClosedRange<Double> = 40...140
    private let weightStep: Double = 0.5
    private let hapticEngine = WKInterfaceDevice.current()
    
    init(weightManager: WeightManager? = nil, gender: Binding<AlcoholMetabolism.Gender>, isFasted: Binding<Bool>) {
        _weightManager = StateObject(wrappedValue: weightManager ?? WeightManager())
        _gender = gender
        _isFasted = isFasted
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 12) {
                    WeightControlSection(
                        currentWeight: $weightManager.currentWeight,
                        range: weightRange,
                        step: weightStep
                    )
                    .frame(height: geometry.size.height * 0.3)
                    
                    QuickAdjustmentSection(
                        currentWeight: $weightManager.currentWeight,
                        step: weightStep
                    )
                    
                    // Section Genre améliorée
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Genre")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            ForEach(genderOptions, id: \.id) { option in
                                GenderSelectionButton(
                                    isSelected: gender == option.gender,
                                    gender: option.gender,
                                    height: 48
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        gender = option.gender
                                        hapticEngine.play(.click)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    
                    // Section État digestif améliorée
                    FastingStatusCard(isFasted: $isFasted)
                        .padding(.horizontal, 4)
                    
                    
                    // Info métabolique
                    MetabolicInfoCard(gender: gender, isFasted: isFasted)
                    
                    ConfirmationButton(
                        action: saveAndDismiss,
                        isLoading: weightManager.isLoading
                    )
                }
                .padding(.horizontal, 8)
            }
        }
        .navigationTitle("Configuration")
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                hapticEngine.play(.start)
            }
        }
        .alert("Erreur", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveAndDismiss() {
        hapticEngine.play(.success)
        
        Task { @MainActor in
            do {
                try await weightManager.saveWeight(weightManager.currentWeight)
                UserDefaults.standard.set(gender.rawValue, forKey: "userGender")
                UserDefaults.standard.set(isFasted, forKey: "userIsFasted")
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Weight Control Section
struct WeightControlSection: View {
    @Binding var currentWeight: Double
    let range: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        VStack(spacing: 8) {
            DigitalCrownWeightSelector(
                value: $currentWeight,
                range: range,
                step: step
            ) {
                WeightDisplay(weight: currentWeight)
            }
            
        }
        .containerBackground(.blue.opacity(0.1), for: .navigation)
    }
}

// MARK: - Digital Crown Integration
struct DigitalCrownWeightSelector<Label: View>: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    @ViewBuilder let label: () -> Label
    
    var body: some View {
        VStack {
            Spacer()
            label()
                .focusable(true)
                .digitalCrownRotation(
                    $value,
                    from: range.lowerBound,
                    through: range.upperBound,
                    by: step,
                    sensitivity: .medium,
                    isContinuous: true,
                    isHapticFeedbackEnabled: true
                )
            Spacer()
        }
    }
}

// MARK: - Weight Display
struct WeightDisplay: View {
    let weight: Double
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(String(format: "%.1f", weight))
                .font(.system(.title, design: .rounded))
                .fontWeight(.semibold)
                .monospacedDigit()
            
            Text("kg")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue.opacity(0.15))
        )
    }
}

// MARK: - Quick Adjustment Section
struct QuickAdjustmentSection: View {
    @Binding var currentWeight: Double
    let step: Double
    
    var body: some View {
        HStack(spacing: 12) {
            AdjustmentButton(
                icon: "minus.circle.fill",
                action: { currentWeight = max(40, currentWeight - step) }
            )
            
            AdjustmentButton(
                icon: "plus.circle.fill",
                action: { currentWeight = min(140, currentWeight + step) }
            )
        }
    }
}

// MARK: - Adjustment Button
struct AdjustmentButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            WKInterfaceDevice.current().play(.click)
            action()
        }) {
            Image(systemName: icon)
                .font(.system(.title3, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.blue.opacity(0.15))
                )
        }
    }
}

// MARK: - Confirmation Button
struct ConfirmationButton: View {
    let action: () -> Void
    let isLoading: Bool
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sauvegarder")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .disabled(isLoading)
    }
}

// Pour le Preview
#Preview {
    NavigationStack {
        WeightConfigurationView(
            gender: .constant(.male),
            isFasted: .constant(false)
        )
    }
}
