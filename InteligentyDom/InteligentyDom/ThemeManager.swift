//
//  ThemeManager.swift
//  InteligentyDom
//
//  Created by Yaryna Kostiak on 02.10.2025.
//

import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "Автоматично"
        case .light: return "Світла"
        case .dark: return "Темна"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
