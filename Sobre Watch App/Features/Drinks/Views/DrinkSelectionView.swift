//
//  DrinkSelectionView.swift
//  Sobre Watch App
//
//  Created by Armand S Wegnez on 27/01/2025.
//
// https://x.com/_armandwegnez Suivez-moi sur X 

import SwiftUI
import WatchKit

// MARK: - Core Selection Interface
struct DrinkSelectionView: View {
    @Binding var drinks: [DrinkType]
    var onDrinkAdded: () -> Void
    @State private var selectedDrink: DrinkType?
    
    // Constantes de mise en page dynamiques !
    private let itemSpacing: CGFloat = 8
    private let iconSize: CGFloat = 44
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                HStack(spacing: itemSpacing) {
                    ForEach($drinks) { $drink in
                        DrinkIconButton(
                            drink: drink,
                            size: iconSize
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDrink = drink
                            }
                        }
                    }
                }
                .frame(height: iconSize)
                
                // Résumé des boissons
                DrinksSummaryView(drinks: drinks)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
        }
        .sheet(item: $selectedDrink) { drink in
            DrinkCounterSheet(
                drink: binding(for: drink),
                onDrinkAdded: onDrinkAdded
            )
        }
    }
    
    private func binding(for selectedDrink: DrinkType) -> Binding<DrinkType> {
        guard let index = drinks.firstIndex(where: { $0.id == selectedDrink.id }) else {
            fatalError("Drink not found")
        }
        return $drinks[index]
    }
}

// MARK: - Drink Icon
struct DrinkIconButton: View {
    let drink: DrinkType
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(drink.type.icon)
                    .font(.system(size: size * 0.5))
                
                if drink.count > 0 {
                    Text("\(drink.count)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(.blue.opacity(0.15))
                    .shadow(color: .blue.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
        .pressEffect()
    }
}

// MARK: - Drinks Summary View
struct DrinksSummaryView: View {
    let drinks: [DrinkType]
    
    private var activeDrinks: [(DrinkType, Double)] {
        drinks.filter { $0.count > 0 }
            .map { ($0, $0.standardDrinks) }
    }
    
    var body: some View {
        if !activeDrinks.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(activeDrinks, id: \.0.id) { drink, standardDrinks in
                    HStack {
                        Text(drink.type.icon)
                            .font(.system(size: 14))
                        Text("\(standardDrinks, specifier: "%.1f") std")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Digital Crown Counter Sheet
struct DrinkCounterSheet: View {
    @Binding var drink: DrinkType
    var onDrinkAdded: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var tempCount: Double
    
    // Constantes d'interaction raffinées
    private let maxDrinks = 20
    private let hapticEngine = WKInterfaceDevice.current()
    
    init(drink: Binding<DrinkType>, onDrinkAdded: @escaping () -> Void) {
        self._drink = drink
        self.onDrinkAdded = onDrinkAdded
        self._tempCount = State(initialValue: Double(drink.wrappedValue.count))
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                // HEADER du type de boisson
                HStack {
                    Text(drink.type.icon)
                        .font(.system(size: 32))
                    Text(drink.type.rawValue)
                        .font(.system(.headline, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                
                // Compteur 
                Text("\(Int(tempCount))")
                    .font(.system(size: 76, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .focusable(true)
                    .digitalCrownRotation(
                        $tempCount,
                        from: 0,
                        through: Double(maxDrinks),
                        by: 1,
                        sensitivity: .medium,
                        isContinuous: false,
                        isHapticFeedbackEnabled: true
                    )
                    .onChange(of: tempCount) { _ in
                        hapticEngine.play(.click)
                        drink.count = Int(tempCount)
                    }
                    .frame(height: geometry.size.height * 0.4)
                
                // Indicateur de boissons standard
                if drink.count > 0 {
                    Text("\(drink.standardDrinks, specifier: "%.1f") std")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                // Confirmation
                Button("Confirmer") {
                    if drink.count > 0 {
                        onDrinkAdded()
                    }
                    hapticEngine.play(.success)
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
            .padding()
        }
    }
}

// MARK: - Effet de boutton
struct PressEffectViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: 1.0)
    }
}

extension View {
    func pressEffect() -> some View {
        modifier(PressEffectViewModifier())
    }
}

// MARK: - Preview Provider
#Preview {
    DrinkSelectionView(
        drinks: .constant(DrinkCategory.allCases.map { DrinkType(count: 0, type: $0) }),
        onDrinkAdded: {}
    )
}
