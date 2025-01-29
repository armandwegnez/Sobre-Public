//
//  AnalysisView.swift
//  Sobre Watch App
//
//  Created by Armand S Wegnez on 1/26/25.
// https://x.com/_armandwegnez Suivez-moi sur X

import SwiftUI
import WatchKit

// MARK: - Heart Rate
enum HeartRateZone: Equatable {
    case low, normal, elevated, high
    
    init(bpm: Double) {
        switch bpm {
        case ..<60: self = .low
        case 60..<100: self = .normal
        case 100..<120: self = .elevated
        default: self = .high
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .normal: return .green
        case .elevated: return .orange
        case .high: return .red
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Repos"
        case .normal: return "Normal"
        case .elevated: return "Élevé"
        case .high: return "Critique"
        }
    }
}

// MARK: - Constants
private enum Constants {
    static let soberBAC = 0.08
    static let highStability = 0.8
    static let maxStability = 0.9
    static let mediumStability = 0.6
    
    enum BAC {
        static let minimal = 0.03
        static let light = 0.05
        static let moderate = 0.08
        static let high = 0.15
    }
}

struct AnalysisView: View {
    let drinks: [DrinkType]
    let weight: Double
    let bac: Double
    let heartRate: Double
    let stability: Double
    let motionConfidence: Double
    let lastDrinkTime: Date
    let gender: AlcoholMetabolism.Gender
    let isFasted: Bool
    
    @State private var showingDetails = false
    
    private var sobrietyStatus: Bool {
        let heartRateZone = HeartRateZone(bpm: heartRate)
        let isHeartRateNormal = heartRateZone != .high
        let isStable = stability > Constants.highStability
        let isBACSafe = bac < Constants.soberBAC
        
        return isBACSafe && isHeartRateNormal && isStable
    }
    
    var body: some View {
        VStack(spacing: 12) {
            headerView
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    MetricCard(
                        title: "Est. C.A.S.",
                        value: String(format: "%.3f%%", bac),
                        icon: "waveform.path.ecg",
                        color: bac >= Constants.soberBAC ? .red : .green,
                        subtitle: bacDescription(bac)
                    )
                    
                    MetricCard(
                        title: "Rythme Cardiaque",
                        value: "\(Int(heartRate)) BPM",
                        icon: "heart.fill",
                        color: HeartRateZone(bpm: heartRate).color,
                        subtitle: HeartRateZone(bpm: heartRate).description
                    )
                    
                    MetricCard(
                        title: "Stabilité",
                        value: "\(Int(stability * 100))%",
                        icon: "gyroscope",
                        color: stability < Constants.highStability ? .red : .blue,
                        confidence: motionConfidence,
                        subtitle: stabilityDescription(stability)
                    )
                    
                    SoberCountdownCard(
                        drinks: drinks,
                        lastDrinkTime: lastDrinkTime,
                        weight: weight,
                        gender: gender,
                        isFasted: isFasted
                    )
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Analyse")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
            
            Spacer()
            
            StatusBadge(isSober: sobrietyStatus)
        }
        .padding(.horizontal, 16)
    }
    
    private func bacDescription(_ bac: Double) -> String {
        switch bac {
        case 0..<Constants.BAC.minimal: return "Minimal"
        case Constants.BAC.minimal..<Constants.BAC.light: return "Léger"
        case Constants.BAC.light..<Constants.BAC.moderate: return "Modéré"
        case Constants.BAC.moderate..<Constants.BAC.high: return "Élevé"
        default: return "Critique"
        }
    }
    
    private func stabilityDescription(_ stability: Double) -> String {
        switch stability {
        case Constants.maxStability...: return "Excellent"
        case Constants.highStability..<Constants.maxStability: return "Bon"
        case Constants.mediumStability..<Constants.highStability: return "Moyen"
        default: return "Instable"
        }
    }
}

// MARK: - Status Sobre (belek a pas trop se dechirer hein)
struct StatusBadge: View {
    let isSober: Bool
    
    private var statusColor: Color {
        isSober ? .green : .red
    }
    
    private var gradientColors: [Color] {
        let baseColor = statusColor
        return [baseColor, baseColor.opacity(0.8)]
    }
    
    var body: some View {
        Text(isSober ? "Sobre" : "Bourré")
            .font(.system(.caption, design: .rounded))
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: statusColor.opacity(0.3),
                        radius: 2,
                        x: 0,
                        y: 1
                    )
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSober)
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var confidence: Double = 1.0
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                
                if confidence < 1.0 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(color)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}


struct StabilityWarning: View {
    let stability: Double
    
    var body: some View {
        Text("Stabilisation du mouvement")
            .font(.system(.caption2, design: .rounded))
            .foregroundColor(.red)
            .opacity(2 - 2 * stability)
            .animation(.easeInOut(duration: 0.3), value: stability)
    }
}

struct MotionCalibrationHint: View {
    var body: some View {
        Label("Reste droit avec la montre", systemImage: "gyroscope")
            .font(.system(.caption2, design: .rounded))
            .foregroundColor(.orange)
    }
}

#Preview {
    AnalysisView(
        drinks: [],
        weight: 70.0,
        bac: 0.05,
        heartRate: 75.0,
        stability: 0.9,
        motionConfidence: 1.0,
        lastDrinkTime: Date(),
        gender: .male,
        isFasted: false
    )
}
