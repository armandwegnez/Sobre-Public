//
//  MetabolismConfigView.swift
//  Sobre Watch App
//
//  Created by Armand S Wegnez on 29/01/2025.
//
// https://x.com/_armandwegnez Suivez-moi sur X 

import SwiftUI

struct MetabolismConfigView: View {
    @Binding var gender: AlcoholMetabolism.Gender
    @Binding var isFasted: Bool
    @State private var showTooltip = false
    @Environment(\.dismiss) private var dismiss
    private let hapticEngine = WKInterfaceDevice.current()
    
    // Options de config
    private struct Constants {
        static let spacing: CGFloat = 16
        static let buttonHeight: CGFloat = 48
        static let cornerRadius: CGFloat = 12
        static let opacity: Double = 0.15
        static let headerSpacing: CGFloat = 8
        
        static let widmarkFactors: [AlcoholMetabolism.Gender: Double] = [
            .male: 0.68,
            .female: 0.55
        ]
        
        static let absorptionRates: [Bool: (title: String, description: String)] = [
            true: ("À jeun", "Absorption plus rapide"),
            false: ("Après repas", "Absorption ralentie")
        ]
        
        static let genderOptions: [(id: Int, gender: AlcoholMetabolism.Gender)] = [
            (0, .male),
            (1, .female)
        ]
    }
    
    private let feedbackGenerator = WKHapticType.click
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Constants.spacing) {
                    // Genres
                    VStack(alignment: .leading, spacing: Constants.headerSpacing) {
                        SectionHeader(title: "Genre")
                        
                        HStack(spacing: 12) {
                            ForEach(Constants.genderOptions, id: \.id) { option in
                                GenderSelectionButton(
                                    isSelected: gender == option.gender,
                                    gender: option.gender,
                                    height: Constants.buttonHeight
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        gender = option.gender
                                        hapticEngine.play(feedbackGenerator)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    
                    // Section de statut de jeûne
                    VStack(alignment: .leading, spacing: Constants.headerSpacing) {
                        SectionHeader(title: "État digestif")
                        FastingStatusCard(isFasted: $isFasted)
                            .padding(.horizontal, 4)
                    }
                    
                    // Section d'information métabolique
                    MetabolicInfoCard(
                        gender: gender,
                        isFasted: isFasted
                    )
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Métabolisme")
    }
}

// MARK: - Support Views
private struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(.caption, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal)
    }
}

// MARK: - Gender Selection Button
struct GenderSelectionButton: View {
    let isSelected: Bool
    let gender: AlcoholMetabolism.Gender
    let height: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(gender == .male ? "Homme" : "Femme")
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.blue.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}
// MARK: - Fasting Status Card
struct FastingStatusCard: View {
    @Binding var isFasted: Bool
    
    private let statusInfo: [Bool: (title: String, description: String)] = [
        true: ("À jeun", "Absorption plus rapide"),
        false: ("Après repas", "Absorption ralentie")
    ]
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isFasted.toggle()
                WKInterfaceDevice.current().play(.click)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusInfo[isFasted]?.title ?? "")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                    
                    Text(statusInfo[isFasted]?.description ?? "")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isFasted ? "stomach" : "fork.knife")
                    .font(.title3)
                    .foregroundStyle(isFasted ? .orange : .green)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}
// MARK: - Metabolic Info Card
struct MetabolicInfoCard: View {
    let gender: AlcoholMetabolism.Gender
    let isFasted: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Impact sur le métabolisme")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                MetabolicFactorRow(
                    icon: "gauge.with.dots.needle.bottom",
                    title: "Facteur Widmark",
                    value: String(format: "%.2f", gender.widmarkFactor)
                )
                
                Divider()
                
                MetabolicFactorRow(
                    icon: "clock.arrow.circlepath",
                    title: "Absorption",
                    value: isFasted ? "Rapide" : "Modérée"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.15))
            )
            .padding(.horizontal)
        }
    }
}
// MARK: - Metabolic Factor Row
struct MetabolicFactorRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.blue)
            
            Text(title)
                .font(.system(.caption2, design: .rounded))
            
            Spacer()
            
            Text(value)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview Provider
#Preview {
    NavigationStack {
        MetabolismConfigView(
            gender: .constant(.male),
            isFasted: .constant(false)
        )
    }
}
