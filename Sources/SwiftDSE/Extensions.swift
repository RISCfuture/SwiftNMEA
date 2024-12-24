import Foundation

extension Measurement where UnitType: Dimension {
    var absoluteValue: Self { Self(value: abs(value), unit: unit) }

    var signum: Double {
        switch value.sign {
            case .plus: return 1
            case .minus: return -1
        }
    }

    func refine(_ refinement: Self) -> Self {
        (absoluteValue + refinement.converted(to: unit)) * signum
    }
}
