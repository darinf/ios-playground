// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct AnimationCompletionModifier<Value>: Animatable, ViewModifier where Value: VectorArithmetic {
    let targetValue: Value
    let completion: () -> Void

    var animatableData: Value {
        didSet {
            if animatableData == targetValue {
                DispatchQueue.main.async(execute: completion)
            }
        }
    }

    init(_ value: Value, completion: @escaping () -> Void) {
        self.targetValue = value
        self.animatableData = self.targetValue
        self.completion = completion
    }

    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func onAnimationCompleted<Value: VectorArithmetic>(for value: Value, completion: @escaping () -> Void) -> some View {
        self.modifier(AnimationCompletionModifier<Value>(value, completion: completion))
    }
    func onAnimationCompleted(for value: Bool, completion: @escaping () -> Void) -> some View {
        self.modifier(AnimationCompletionModifier<Double>(value ? 1 : 0, completion: completion))
    }
}
