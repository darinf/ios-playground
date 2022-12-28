// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct AnimationActiveModifier<Value>: Animatable, ViewModifier where Value: VectorArithmetic {
    let targetValue: Value
    @Binding var binding: Bool

    var animatableData: Value {
        didSet {
            DispatchQueue.main.async { [self] in
                binding = animatableData != targetValue
            }
        }
    }

    init(_ value: Value, binding: Binding<Bool>) {
        self.targetValue = value
        self.animatableData = self.targetValue
        self._binding = binding
    }

    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func onAnimationActive<Value: VectorArithmetic>(for value: Value, binding: Binding<Bool>) -> some View {
        self.modifier(AnimationActiveModifier<Value>(value, binding: binding))
    }
    func onAnimationActive(for value: Bool, binding: Binding<Bool>) -> some View {
        self.modifier(AnimationActiveModifier<Double>(value ? 1 : 0, binding: binding))
    }
}
