//
//  SettingsView.swift
//  InteligentyDom
//
//  Created by Yaryna Kostiak on 02.10.2025.
//
import Foundation
import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .system

    var body: some View {
        Form {
            Section(header: Text("Тема оформлення")) {
                Picker("Оберіть тему", selection: $selectedTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("Налаштування")
    }
}
