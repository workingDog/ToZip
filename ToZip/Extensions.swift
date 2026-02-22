//
//  Extensions.swift
//  ToZip
//
//  Created by Ringo Wathelet on 2026/02/22.
//
import Foundation
import SwiftUI


#if os(macOS)
import AppKit
#endif

extension View {
    @ViewBuilder
    func noAutoCapitalization() -> some View {
#if os(iOS)
        self.textInputAutocapitalization(.never)
#else
        self
#endif
    }
}

extension String {
    
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}

extension Date {
    
    func fileTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: self)
    }
    
}

