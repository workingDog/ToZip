//
//  PasswordChecker.swift
//  ToZip
//
//  Created by Ringo Wathelet on 2026/02/22.
//
import Foundation

enum PasswordStrength: String {
    case weak = "Weak"
    case okay = "Basic"
    case strong = "Strong"
}

struct PasswordStrengthResult {
    let entropyBits: Double
    let strength: PasswordStrength
}

struct PasswordStrengthEvaluator {

    static func evaluate(_ password: String) -> PasswordStrengthResult {
        let length = password.count
        guard length > 0 else {
            return PasswordStrengthResult(entropyBits: 0, strength: .weak)
        }

        var poolSize = 0

        if password.range(of: "[a-z]", options: .regularExpression) != nil {
            poolSize += 26
        }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil {
            poolSize += 26
        }
        if password.range(of: "[0-9]", options: .regularExpression) != nil {
            poolSize += 10
        }
        if password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil {
            poolSize += 32
        }

        let entropy = log2(pow(Double(poolSize), Double(length)))

        let strength: PasswordStrength
        switch entropy {
            case ..<40: strength = .weak
            case 40..<60: strength = .okay
            default: strength = .strong
        }

        return .init(entropyBits: entropy, strength: strength)
    }
}



