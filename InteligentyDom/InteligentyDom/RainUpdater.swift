//
//  RainUpdater.swift
//  InteligentyDom
//
//  Created by Yaryna Kostiak on 02.10.2025.
//

import Foundation
import Combine

class RainUpdater: ObservableObject {
    @Published var isRaining: Bool = false
    private var timer: Timer?
    
    func start(sensorID: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.fetchRainState(sensorID: sensorID)
        }
    }
    
    func stop() {
        timer?.invalidate()
    }
    
    private func fetchRainState(sensorID: String) {
        guard let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(sensorID)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("🌧️ Запит дощу не вдалось: \(error?.localizedDescription ?? "невідомо")")
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let state = json["state"] as? String {
                DispatchQueue.main.async {
                    self.isRaining = (state == "on")
                }
            }
        }.resume()
    }
}


