//
//  ThemeAwareView.swift
//  InteligentyDom
//
//  Created by Yaryna Kostiak on 02.10.2025.
//

import Foundation
import SwiftUI

struct ThemeAwareView<Content: View>: View {
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .system
    let content: () -> Content

    var body: some View {
        content()
            .preferredColorScheme(selectedTheme.colorScheme)
    }
}
