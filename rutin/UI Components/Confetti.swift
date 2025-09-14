/*
 * ConfettiSwiftUI
 *
 * Based on: https://github.com/simibac/ConfettiSwiftUI
 * Original author: Simon Bachmann (@simibac)
 *
 * Adapted for rutin - minimal modifications for iOS 18+ compatibility
 */

import SwiftUI

// MARK: - Confetti Types

public enum ConfettiType: CaseIterable, Hashable {
    
    public enum Shape {
        case circle
        case triangle
        case square
        case slimRectangle
        case roundedCross
    }

    case shape(Shape)
    case text(String)
    case sfSymbol(symbolName: String)
    case image(String)
    
    public var view: AnyView {
        switch self {
        case .shape(.square):
            return AnyView(Rectangle())
        case .shape(.triangle):
            return AnyView(Triangle())
        case .shape(.slimRectangle):
            return AnyView(SlimRectangle())
        case .shape(.roundedCross):
            return AnyView(RoundedCross())
        case let .text(text):
            return AnyView(Text(text))
        case .sfSymbol(let symbolName):
            return AnyView(Image(systemName: symbolName))
        case .image(let image):
            return AnyView(Image(image).resizable())
        default:
            return AnyView(Circle())
        }
    }
    
    public static var allCases: [ConfettiType] {
        return [.shape(.circle), .shape(.triangle), .shape(.square), .shape(.slimRectangle), .shape(.roundedCross)]
    }
}

// MARK: - Main Confetti Cannon

public struct ConfettiCannon<T: Equatable>: View {
    @Binding var trigger: T
    @StateObject private var confettiConfig: ConfettiConfig

    @State var animate: [Bool] = []
    @State var finishedAnimationCounter = 0
    @State var firstAppear = false
    
    /// Renders configurable confetti animation
    /// - Parameters:
    ///   - trigger: Animation triggers when this value changes
    ///   - num: Amount of confetti pieces
    ///   - confettis: Types of confetti to display
    ///   - colors: Colors applied to default shapes
    ///   - confettiSize: Size that confetti pieces are scaled to
    ///   - rainHeight: Vertical distance that confetti travels
    ///   - fadesOut: Reduce opacity towards end of animation
    ///   - opacity: Maximum opacity reached during animation
    ///   - openingAngle: Opening angle boundary in degrees
    ///   - closingAngle: Closing angle boundary in degrees
    ///   - radius: Explosion radius
    ///   - repetitions: Number of explosion repetitions
    ///   - repetitionInterval: Duration between repetitions
    ///   - hapticFeedback: Play haptic feedback on explosion
    public init(
        trigger: Binding<T>,
        num: Int = 20,
        confettis: [ConfettiType] = ConfettiType.allCases,
        colors: [Color] = [.blue, .red, .green, .yellow, .pink, .purple, .orange],
        confettiSize: CGFloat = 10.0,
        rainHeight: CGFloat = 600.0,
        fadesOut: Bool = true,
        opacity: Double = 1.0,
        openingAngle: Angle = .degrees(60),
        closingAngle: Angle = .degrees(120),
        radius: CGFloat = 300,
        repetitions: Int = 1,
        repetitionInterval: Double = 1.0,
        hapticFeedback: Bool = true
    ) {
        self._trigger = trigger
        var shapes = [AnyView]()
        
        for confetti in confettis {
            for color in colors {
                switch confetti {
                case .shape(_):
                    shapes.append(AnyView(confetti.view.foregroundColor(color).frame(width: confettiSize, height: confettiSize, alignment: .center)))
                case .image(_):
                    shapes.append(AnyView(confetti.view.frame(maxWidth: confettiSize, maxHeight: confettiSize)))
                default:
                    shapes.append(AnyView(confetti.view.foregroundColor(color).font(.system(size: confettiSize))))
                }
            }
        }
    
        _confettiConfig = StateObject(wrappedValue: ConfettiConfig(
            num: num,
            shapes: shapes,
            colors: colors,
            confettiSize: confettiSize,
            rainHeight: rainHeight,
            fadesOut: fadesOut,
            opacity: opacity,
            openingAngle: openingAngle,
            closingAngle: closingAngle,
            radius: radius,
            repetitions: repetitions,
            repetitionInterval: repetitionInterval,
            hapticFeedback: hapticFeedback
        ))
    }

    public var body: some View {
        ZStack {
            ForEach(finishedAnimationCounter..<animate.count, id: \.self) { i in
                ConfettiContainer(
                    finishedAnimationCounter: $finishedAnimationCounter,
                    confettiConfig: confettiConfig
                )
            }
        }
        .onAppear {
            firstAppear = true
        }
        .onChange(of: trigger) { oldValue, newValue in
            if firstAppear {
                for i in 0..<confettiConfig.repetitions {
                    DispatchQueue.main.asyncAfter(deadline: .now() + confettiConfig.repetitionInterval * Double(i)) {
                        animate.append(false)
                        
                        // Haptic feedback (simplified for iOS)
                        if confettiConfig.hapticFeedback {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                            impactFeedback.impactOccurred()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ConfettiContainer: View {
    @Binding var finishedAnimationCounter: Int
    @StateObject var confettiConfig: ConfettiConfig
    @State var firstAppear = true

    var body: some View {
        ZStack {
            ForEach(0...confettiConfig.num-1, id: \.self) { _ in
                ConfettiView(confettiConfig: confettiConfig)
            }
        }
        .onAppear {
            if firstAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + confettiConfig.animationDuration) {
                    self.finishedAnimationCounter += 1
                }
                firstAppear = false
            }
        }
    }
}

struct ConfettiView: View {
    @State var location: CGPoint = CGPoint(x: 0, y: 0)
    @State var opacity: Double = 0.0
    @StateObject var confettiConfig: ConfettiConfig
    
    func getShape() -> AnyView {
        return confettiConfig.shapes.randomElement()!
    }
    
    func getColor() -> Color {
        return confettiConfig.colors.randomElement()!
    }
    
    func getSpinDirection() -> CGFloat {
        let spinDirections: [CGFloat] = [-1.0, 1.0]
        return spinDirections.randomElement()!
    }
    
    func getRandomExplosionTimeVariation() -> CGFloat {
         CGFloat((0...999).randomElement()!) / 2100
    }
    
    func getAnimationDuration() -> CGFloat {
        return 0.2 + confettiConfig.explosionAnimationDuration + getRandomExplosionTimeVariation()
    }
    
    func getAnimation() -> Animation {
        return Animation.timingCurve(0.1, 0.8, 0, 1, duration: getAnimationDuration())
    }
    
    func getDistance() -> CGFloat {
        return pow(CGFloat.random(in: 0.01...1), 2.0/7.0) * confettiConfig.radius
    }
    
    func getDelayBeforeRainAnimation() -> TimeInterval {
        confettiConfig.explosionAnimationDuration * 0.1
    }

    var body: some View {
        ConfettiAnimationView(shape: getShape(), color: getColor(), spinDirX: getSpinDirection(), spinDirZ: getSpinDirection())
            .offset(x: location.x, y: location.y)
            .opacity(opacity)
            .onAppear {
                withAnimation(getAnimation()) {
                    opacity = confettiConfig.opacity
                    
                    let randomAngle: CGFloat
                    if confettiConfig.openingAngle.degrees <= confettiConfig.closingAngle.degrees {
                        randomAngle = CGFloat.random(in: CGFloat(confettiConfig.openingAngle.degrees)...CGFloat(confettiConfig.closingAngle.degrees))
                    } else {
                        randomAngle = CGFloat.random(in: CGFloat(confettiConfig.openingAngle.degrees)...CGFloat(confettiConfig.closingAngle.degrees + 360)).truncatingRemainder(dividingBy: 360)
                    }
                    
                    let distance = getDistance()
                    
                    location.x = distance * cos(deg2rad(randomAngle))
                    location.y = -distance * sin(deg2rad(randomAngle))
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + getDelayBeforeRainAnimation()) {
                    withAnimation(Animation.timingCurve(0.12, 0, 0.39, 0, duration: confettiConfig.rainAnimationDuration)) {
                        location.y += confettiConfig.rainHeight
                        opacity = confettiConfig.fadesOut ? 0 : confettiConfig.opacity
                    }
                }
            }
    }
    
    func deg2rad(_ number: CGFloat) -> CGFloat {
        return number * CGFloat.pi / 180
    }
}

struct ConfettiAnimationView: View {
    @State var shape: AnyView
    @State var color: Color
    @State var spinDirX: CGFloat
    @State var spinDirZ: CGFloat
    @State var firstAppear = true
    
    @State var move = false
    @State var xSpeed: Double = Double.random(in: 0.501...2.201)
    @State var zSpeed = Double.random(in: 0.501...2.201)
    @State var anchor = CGFloat.random(in: 0...1).rounded()
    
    var body: some View {
        shape
            .foregroundColor(color)
            .rotation3DEffect(.degrees(move ? 360 : 0), axis: (x: spinDirX, y: 0, z: 0))
            .animation(Animation.linear(duration: xSpeed).repeatCount(10, autoreverses: false), value: move)
            .rotation3DEffect(.degrees(move ? 360 : 0), axis: (x: 0, y: 0, z: spinDirZ), anchor: UnitPoint(x: anchor, y: anchor))
            .animation(Animation.linear(duration: zSpeed).repeatForever(autoreverses: false), value: move)
            .onAppear {
                if firstAppear {
                    move = true
                    firstAppear = false
                }
            }
    }
}

// MARK: - Configuration Class

class ConfettiConfig: ObservableObject {
    let num: Int
    let shapes: [AnyView]
    let colors: [Color]
    let confettiSize: CGFloat
    let rainHeight: CGFloat
    let fadesOut: Bool
    let opacity: Double
    let openingAngle: Angle
    let closingAngle: Angle
    let radius: CGFloat
    let repetitions: Int
    let repetitionInterval: Double
    let hapticFeedback: Bool
    
    let explosionAnimationDuration: Double
    let rainAnimationDuration: Double
    
    init(num: Int, shapes: [AnyView], colors: [Color], confettiSize: CGFloat, rainHeight: CGFloat, fadesOut: Bool, opacity: Double, openingAngle: Angle, closingAngle: Angle, radius: CGFloat, repetitions: Int, repetitionInterval: Double, hapticFeedback: Bool) {
        self.num = num
        self.shapes = shapes
        self.colors = colors
        self.confettiSize = confettiSize
        self.rainHeight = rainHeight
        self.fadesOut = fadesOut
        self.opacity = opacity
        self.openingAngle = openingAngle
        self.closingAngle = closingAngle
        self.radius = radius
        self.repetitions = repetitions
        self.repetitionInterval = repetitionInterval
        self.explosionAnimationDuration = Double(radius / 1300)
        self.rainAnimationDuration = Double((rainHeight + radius) / 200)
        self.hapticFeedback = hapticFeedback
    }
    
    var animationDuration: Double {
        return explosionAnimationDuration + rainAnimationDuration
    }
}

// MARK: - View Extension

public extension View {
    /// Renders configurable confetti animation
    ///
    /// Based on ConfettiSwiftUI by Simon Bachmann
    /// Source: https://github.com/simibac/ConfettiSwiftUI
    ///
    /// - Parameters:
    ///   - trigger: Animation triggers when this value changes
    ///   - num: Amount of confetti pieces
    ///   - confettis: Types of confetti to display
    ///   - colors: Colors applied to default shapes
    ///   - confettiSize: Size that confetti pieces are scaled to
    ///   - rainHeight: Vertical distance that confetti travels
    ///   - fadesOut: Reduce opacity towards end of animation
    ///   - opacity: Maximum opacity reached during animation
    ///   - openingAngle: Opening angle boundary in degrees
    ///   - closingAngle: Closing angle boundary in degrees
    ///   - radius: Explosion radius
    ///   - repetitions: Number of explosion repetitions
    ///   - repetitionInterval: Duration between repetitions
    ///   - hapticFeedback: Play haptic feedback on explosion
    @ViewBuilder func confettiCannon<T>(
        trigger: Binding<T>,
        num: Int = 20,
        confettis: [ConfettiType] = ConfettiType.allCases,
        colors: [Color] = [.blue, .red, .green, .yellow, .pink, .purple, .orange],
        confettiSize: CGFloat = 10.0,
        rainHeight: CGFloat = 600.0,
        fadesOut: Bool = true,
        opacity: Double = 1.0,
        openingAngle: Angle = .degrees(60),
        closingAngle: Angle = .degrees(120),
        radius: CGFloat = 300,
        repetitions: Int = 1,
        repetitionInterval: Double = 1.0,
        hapticFeedback: Bool = true
    ) -> some View where T: Equatable {
        ZStack {
            self.layoutPriority(1)
            ConfettiCannon(
                trigger: trigger,
                num: num,
                confettis: confettis,
                colors: colors,
                confettiSize: confettiSize,
                rainHeight: rainHeight,
                fadesOut: fadesOut,
                opacity: opacity,
                openingAngle: openingAngle,
                closingAngle: closingAngle,
                radius: radius,
                repetitions: repetitions,
                repetitionInterval: repetitionInterval,
                hapticFeedback: hapticFeedback
            )
        }
    }
}

// MARK: - Custom Shapes

public struct SlimRectangle: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: 4*rect.maxY/5))
        path.addLine(to: CGPoint(x: rect.maxX, y: 4*rect.maxY/5))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        return path
    }
}

public struct Triangle: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))

        return path
    }
}

public struct RoundedCross: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY/3))
        path.addQuadCurve(to: CGPoint(x: rect.maxX/3, y: rect.minY), control: CGPoint(x: rect.maxX/3, y: rect.maxY/3))
        path.addLine(to: CGPoint(x: 2*rect.maxX/3, y: rect.minY))
        
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY/3), control: CGPoint(x: 2*rect.maxX/3, y: rect.maxY/3))
        path.addLine(to: CGPoint(x: rect.maxX, y: 2*rect.maxY/3))

        path.addQuadCurve(to: CGPoint(x: 2*rect.maxX/3, y: rect.maxY), control: CGPoint(x: 2*rect.maxX/3, y: 2*rect.maxY/3))
        path.addLine(to: CGPoint(x: rect.maxX/3, y: rect.maxY))

        path.addQuadCurve(to: CGPoint(x: 2*rect.minX/3, y: 2*rect.maxY/3), control: CGPoint(x: rect.maxX/3, y: 2*rect.maxY/3))

        return path
    }
}
