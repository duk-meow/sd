import SwiftUI

// Version: 1.1 - Fixed platform dependencies
// This file provides cross-platform (iOS/macOS) styling utilities.

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let tr = corners.contains(.topRight) ? radius : 0
        let tl = corners.contains(.topLeft) ? radius : 0
        let br = corners.contains(.bottomRight) ? radius : 0
        let bl = corners.contains(.bottomLeft) ? radius : 0
        
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.closeSubpath()
        
        return path
    }
}

struct BlurView: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct GlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var opacity: Double = 0.8
    
    func body(content: Content) -> some View {
        content
            .background(SignalDeskTheme.baseSurface.opacity(0.95))
            .background(.ultraThinMaterial.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(SignalDeskTheme.baseBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16, opacity: Double = 0.5) -> some View {
        self.modifier(GlassModifier(cornerRadius: cornerRadius, opacity: opacity))
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Premium Background Components

struct PremiumBackground: View {
    var body: some View {
        ZStack {
            SignalDeskTheme.baseBg
                .ignoresSafeArea()
            
            GridView()
                .opacity(0.8)
            
            AuraEffect()
        }
    }
}

struct GridView: View {
    var spacing: CGFloat = 60
    
    var body: some View {
        Canvas { context, size in
            let horizontalLines = Int(size.height / spacing)
            let verticalLines = Int(size.width / spacing)
            
            for i in 0...horizontalLines {
                let y = CGFloat(i) * spacing
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    },
                    with: .color(SignalDeskTheme.whiteOver10),
                    lineWidth: 1.0
                )
            }
            
            for i in 0...verticalLines {
                let x = CGFloat(i) * spacing
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    },
                    with: .color(SignalDeskTheme.whiteOver10),
                    lineWidth: 1.0
                )
            }
        }
        .allowsHitTesting(false)
    }
}

struct AuraEffect: View {
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background to catch mouse movements without blocking
                Color.clear
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            position = location
                            withAnimation(.easeOut(duration: 0.3)) {
                                opacity = 1
                            }
                        case .ended:
                            withAnimation(.easeIn(duration: 0.8)) {
                                opacity = 0
                            }
                        }
                    }
                
                // The Purple Aura
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "7C3AED").opacity(0.4), // More pronounced Purple
                        .clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 400
                )
                .frame(width: 800, height: 800)
                .position(position)
                .opacity(opacity)
                .blur(radius: 60)
                .blendMode(.screen)
            }
        }
        .allowsHitTesting(true)
    }
}

