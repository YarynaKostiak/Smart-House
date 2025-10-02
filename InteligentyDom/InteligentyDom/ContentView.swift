//
//  ContentView.swift
//  InteligentyDom
//
//  Created by Yaryna Kostiak on 16.09.2025.
//

import SwiftUI
import SceneKit
import Combine

let HA_TOKEN = ""
let HA_IP_ADDRESS = "http://localhost:8123"

struct Model: Identifiable{
    var id: Int
    var nameModel : String
}

var models = [
    Model (id: 0, nameModel: "")
    
]
enum RoomType {
    case bathroom
    case livingRoom
    case kitchen
    case office
    case security
    case corridor
}

struct Room: Identifiable {
    
    let id = UUID()
    let name: String
    let type: RoomType
    
    let lightEntityID: String?
    let colorModeEntityID: String?
    var isOn: Bool
    var color: Color
    var colorModeEnabled: Bool
    
    var temperature: Double?
    var humidity: Double?
    var temperatureID: String?
    var humidityID: String?

    var fireSensorID: String?
    var smokeSensorID: String?
    var fireSensorLevel: Double?
    var smokeSensorLevel: Double?
    
    var doorContactOpen: Bool?
    var doorSensorID: String?

    var motionDetected: Bool?
    var beeperOn: Bool?
    var beeperEntityID: String?
    var motionSensorID: String?
    
    var rainSensorID: String?
    var isRaining: Bool?

    var dayNightSensorID: String?
    var isDaytime: Bool?
    
    var presenceSensorID: String?
    var isSomeoneHome: Bool?
    
    var fanEntityID: String?
    var isFanOn: Bool?
    
    var idModel: Int?
    var nameModel : String?

}
struct ContentView: View {
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .system
    @State private var showSettings = false
    @State private var showModelViewer = false
    @State private var preloadedScenes: [String: SCNScene] = [:]
    
    @State private var rooms = [
        
        Room(name: "Вітальня",
             type: .livingRoom,
             
             lightEntityID: "",
             colorModeEntityID: "",
             isOn: false,
             color: .white,
             colorModeEnabled: false,
             
             temperature: nil,
             humidity: nil,
             temperatureID: "",
             humidityID: "",
             
             doorContactOpen: false,
             doorSensorID: "",
             
             fanEntityID: "fan.living_room",
             isFanOn: false,
             
             idModel: 0,
             nameModel : ""),
        
        Room(name: "Коридор",
             type: .corridor,
             
             lightEntityID: "",
             colorModeEntityID: "",
             isOn: false,
             color: .white,
             colorModeEnabled: false,
             
             doorContactOpen: false,
             doorSensorID: "",
             
             rainSensorID: "",
             isRaining: false,
             
             dayNightSensorID: "",
             isDaytime: false,
             
             idModel: 0,
             nameModel : ""),
        
        Room(name: "Офіс",
             type: .office,
             
             lightEntityID: "",
             colorModeEntityID: "",
             isOn: false,
             color: .white,
             colorModeEnabled: false,
             
             temperature: nil,
             humidity: nil,
             temperatureID: "",
             humidityID: "",
             
             idModel: 0,
             nameModel : ""),
        
        Room(name: "Кухня",
             type: .kitchen,
             
             lightEntityID: "",
             colorModeEntityID: "",
             isOn: false,
             color: .white,
             colorModeEnabled: false,
             
             fireSensorID: "",
             smokeSensorID: "",
             fireSensorLevel: nil,
             smokeSensorLevel: nil,
             
             idModel: 0,
             nameModel : ""),
        
        Room(name: "Ванна",
             type: .bathroom,
             
             lightEntityID: "light.home",
             colorModeEntityID: "",
             isOn: false,
             color: .white,
             colorModeEnabled: false,
             
             temperature: nil,
             humidity: nil,
             temperatureID: "",
             humidityID: "",
             
             motionDetected: false,
             motionSensorID: "",
             
             idModel: 0,
             nameModel : ""),
        
        Room(name: "Безпека",
            type: .security,
             
            lightEntityID: "",
            colorModeEntityID: nil,
            isOn: false,
            color: .white,
            colorModeEnabled: false,
             
            motionDetected: false,
             
            beeperOn: false,
            beeperEntityID: "",
             
            motionSensorID: "",
             
            presenceSensorID: "",
            isSomeoneHome: nil,
             
            idModel: 0,
            nameModel : "secuirity.usdz")
        
    ]
    
    @State private var ignoreUpdateForRoom: UUID? = nil
    // Нова змінна для запобігання конфліктам оновлення світла
      @State private var ignoreLightUpdateForRoom: UUID? = nil
      // Нова змінна для запобігання конфліктам оновлення біпера
      @State private var ignoreBeeperUpdateForRoom: UUID? = nil
      
    @State private var ignoreFanUpdateForRoom: UUID? = nil
    
    func fetchSensorData() {
        for index in rooms.indices {
            // 🚨 Додаємо синхронізацію для біпера
            if let beeperEntityID = rooms[index].beeperEntityID,
               let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(beeperEntityID)") {
                
                // Ігноруємо оновлення, якщо біпер було щойно перемкнено
                if rooms[index].id == ignoreBeeperUpdateForRoom {
                    continue
                }

                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: request) { data, _, error in
                    guard let data = data, error == nil else {
//                        print("❌ Стан біпера \(beeperEntityID): \(error?.localizedDescription ?? "невідомо")")
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let stateStr = json["state"] as? String {

                        let isBeeperOn = (stateStr == "on")
                        
                        DispatchQueue.main.async {
                            if self.rooms[index].beeperOn != isBeeperOn {
                                self.rooms[index].beeperOn = isBeeperOn
//                                            print("🚨 Стан біпера \(beeperEntityID) оновлено: \(isBeeperOn)")
                            }
                        }
                    } else {
//                                    print("⚠️ Не вдалося розпарсити JSON для біпера \(beeperEntityID)")
                    }
                }.resume()
            }
            // 💨 Вентилятор
            if let fanID = rooms[index].fanEntityID,
               let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(fanID)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, _, error in
                    guard let data = data, error == nil else {
                        print("❌ Вентилятор \(fanID): \(error?.localizedDescription ?? "невідомо")")
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let stateStr = json["state"] as? String {
                        DispatchQueue.main.async {
                            rooms[index].isFanOn = (stateStr == "on")
                        }
                    }
                }.resume()
            }
            // 💡 Синхронізація для світла
                        if let lightEntityID = rooms[index].lightEntityID,
                           let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(lightEntityID)") {

                            // Ігноруємо оновлення, якщо світло було щойно перемкнено
                            if rooms[index].id == ignoreLightUpdateForRoom {
                                continue
                            }

                            var request = URLRequest(url: url)
                            request.httpMethod = "GET"
                            request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")

                            URLSession.shared.dataTask(with: request) { data, _, error in
                                guard let data = data, error == nil else {
                                    print("❌ Стан світла \(lightEntityID): \(error?.localizedDescription ?? "невідомо")")
                                    return
                                }
                                
                                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                   let stateStr = json["state"] as? String {

                                    let isLightOn = (stateStr == "on")
                                    
                                    DispatchQueue.main.async {
                                        if self.rooms[index].isOn != isLightOn {
                                            self.rooms[index].isOn = isLightOn
//                                            print("💡 Стан світла \(lightEntityID) оновлено: \(isLightOn)")
                                        }
                                    }
                                } else {
//                                    print("⚠️ Не вдалося розпарсити JSON для світла \(lightEntityID)")
                                }
                            }.resume()
                        }
                        
                      
            // 🌧 Дощ (тільки для тераси)
            if let rainID = rooms[index].rainSensorID,
               let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(rainID)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, _, error in
                    guard let data = data, error == nil else {
                        print("❌ Дощ \(rainID): \(error?.localizedDescription ?? "невідомо")")
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let stateStr = json["state"] as? String {
                        DispatchQueue.main.async {
                            rooms[index].isRaining = (stateStr == "on")
                        }
                    }
                }.resume()
            }
            // 👤 Мітка присутності
            
            if let presenceID = rooms[index].presenceSensorID,
               let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(presenceID)") {

                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: request) { data, _, error in
                    guard let data = data, error == nil else {
//                        print("❌ Мітка \(presenceID): \(error?.localizedDescription ?? "невідомо")")
                        return
                    }

                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let stateStr = json["state"] as? String {
                        var updatedRoom = rooms[index]
                        updatedRoom.isSomeoneHome = (stateStr == "on")
//                        print("✅ isSomeoneHome = \(updatedRoom.isSomeoneHome!)")
                        DispatchQueue.main.async {
                            rooms[index] = updatedRoom
                        }
                    }
                }.resume()
            }

            // ☀️ День/ніч (тільки для тераси)
            if let dayID = rooms[index].dayNightSensorID,
               let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(dayID)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("❌ День/ніч \(dayID): \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = data else {
                        print("❌ Дані порожні для \(dayID)")
                        return
                    }
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let stateStr = json["state"] as? String {
                            var updatedRoom = rooms[index]
                            updatedRoom.isDaytime = (stateStr == "on")
                            DispatchQueue.main.async {
                                rooms[index] = updatedRoom
                            }
                        } else {
//                            print("⚠️ Не вдалося парсити JSON")
                        }
                    } catch {
//                        print("❌ JSON error: \(error.localizedDescription)")
                    }
                }.resume()
            }
            // Вогонь
            if let fireID = rooms[index].fireSensorID,
               let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(fireID)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, _, error in
                    guard let data = data, error == nil else {
                        print("❌ Вогонь \(fireID): \(error?.localizedDescription ?? "невідомо")")
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let stateStr = json["state"] as? String,
                       let value = Double(stateStr) {
                        DispatchQueue.main.async {
                            rooms[index].fireSensorLevel = value
                        }
                    }
                }.resume()
            }

            // Дим
            if let smokeID = rooms[index].smokeSensorID,
               let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(smokeID)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, _, error in
                    guard let data = data, error == nil else {
                        print("❌ Дим \(smokeID): \(error?.localizedDescription ?? "невідомо")")
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let stateStr = json["state"] as? String,
                       let value = Double(stateStr) {
                        DispatchQueue.main.async {
                            rooms[index].smokeSensorLevel = value
                        }
                    }
                }.resume()
            }


            // Температура
            if let tempID = rooms[index].temperatureID,
               let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(tempID)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, _, error in
                    guard let data = data, error == nil else {
                        print("❌ Температура \(tempID): \(error?.localizedDescription ?? "невідомо")")
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let stateStr = json["state"] as? String,
                       let value = Double(stateStr) {
                        DispatchQueue.main.async {
                            rooms[index].temperature = value
                        }
                    }
                }.resume()
            }
            // Вологість
            if let humidityID = rooms[index].humidityID,
               let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(humidityID)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, _, error in
                    guard let data = data, error == nil else {
                        print("❌ Вологість \(humidityID): \(error?.localizedDescription ?? "невідомо")")
                        return
                    }
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let stateStr = json["state"] as? String,
                       let value = Double(stateStr) {
                        DispatchQueue.main.async {
                            rooms[index].humidity = value
                        }
                    }
                }.resume()
            }
            
            // Геркони дверей door
            if let doorID = rooms[index].doorSensorID,
               let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(doorID)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, _, error in
                    guard let data = data, error == nil else {
                        print("❌ Двері \(doorID): \(error?.localizedDescription ?? "невідомо")")
                        return
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let stateStr = json["state"] as? String {
                        DispatchQueue.main.async {
                            rooms[index].doorContactOpen = (stateStr == "on")
                        }
                    }
                }.resume()
            }
            // Рух motion
            if let motionID = rooms[index].motionSensorID,
               let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(motionID)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("❌ Помилка запиту руху: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = data else {
                        print("❌ Немає даних від Home Assistant для сенсора руху")
                        return
                    }
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let state = json["state"] as? String {
                            
                            DispatchQueue.main.async {
                                rooms[index].motionDetected = (state == "on")
//                                print("📡 Рух виявлено (сенсор \(motionID)): \(state)")
                            }
                        } else {
                         
                        }
                    } catch {
                      
                    }
                }.resume()
            }

            
        }
        
    }

    var body: some View {
            NavigationView {
                List {
                    Section {
                        ModelViewer(modelName: "")
                            .frame(height: 300)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .shadow(radius: 5)
                            .listRowInsets(EdgeInsets())
                    }
                    
                    ForEach($rooms) { $room in
                        NavigationLink(destination: RoomDetailView(room: $room,
                                                                   toggleLightAction: toggleLight,
                                                                   toggleColorModeAction: toggleColorMode,
                                                                   setColorAction: setLightColor,
                                                                   toggleBeeperAction: toggleBeeper,
                                                                   toggleFanAction: toggleFan,
                                                                   preloadedScenes: preloadedScenes)) {
                            Text(room.name)
                        }
                    }
                }
                .navigationTitle("Розумний дім")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    ThemeAwareView {
                        SettingsView()
                    }
                }
                .onAppear {
                    preloadModels()
                }
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        fetchSensorData()
                    }
                }
            }
            .preferredColorScheme(selectedTheme.colorScheme)
        }
    func preloadModels() {
         DispatchQueue.global(qos: .userInitiated).async {
             for room in rooms {
                 if let modelName = room.nameModel, !modelName.isEmpty {
                     if let url = Bundle.main.url(forResource: modelName, withExtension: nil) {
                         do {
                             let scene = try SCNScene(url: url)
                             // Центрування Center
                             let rootNode = scene.rootNode
                             let (min, max) = rootNode.boundingBox
                             rootNode.position = SCNVector3(-(min.x + max.x)/2, -(min.y + max.y)/2, -(min.z + max.z)/2)
                             
                             DispatchQueue.main.async {
                                 preloadedScenes[modelName] = scene
                             }
                         } catch {
                             print("Помилка завантаження: \(modelName)")
                         }
                     }
                 }
             }
         }
     }
    
    func toggleLight(room: Room, isOn: Bool) {
           guard let lightEntityID = room.lightEntityID else {
               print("❌ Помилка: EntityID для світла відсутній.")
               return
           }
           
           ignoreLightUpdateForRoom = room.id
           
           let domain = lightEntityID.hasPrefix("light.") ? "light" : "switch"
           let service = isOn ? "turn_on" : "turn_off"
           
           guard let url = URL(string: "\(HA_IP_ADDRESS)/api/services/\(domain)/\(service)") else { return }

           var request = URLRequest(url: url)
           request.httpMethod = "POST"
           request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")

           let body: [String: Any] = ["entity_id": lightEntityID]
           request.httpBody = try? JSONSerialization.data(withJSONObject: body)

           URLSession.shared.dataTask(with: request) { data, response, error in
               DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                   if self.ignoreLightUpdateForRoom == room.id {
                       self.ignoreLightUpdateForRoom = nil
                   }
               }
               if let error = error {
//                   print("❌ Помилка: \(error.localizedDescription)")
               } else {
//                   print("✅ Запит на \(domain).\(service) для \(lightEntityID) успішно надіслано.")
               }
           }.resume()
       }
    
    func toggleFan(room: Room, isOn: Bool) {
            guard let fanEntityID = room.fanEntityID,
                  let url = URL(string: "\(HA_IP_ADDRESS)/api/services/fan/\(isOn ? "turn_on" : "turn_off")") else {
                print("❌ Невірний URL або відсутній fanEntityID")
                return
            }
            
            ignoreFanUpdateForRoom = room.id

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = ["entity_id": fanEntityID]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { _, _, error in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.ignoreFanUpdateForRoom == room.id {
                        self.ignoreFanUpdateForRoom = nil
                    }
                }
                if let error = error {
//                    print("❌ Помилка керування вентилятором: \(error.localizedDescription)")
                } else {
//                    print("✅ Запит на fan.\(isOn ? "turn_on" : "turn_off") для \(fanEntityID) успішно надіслано.")
                }
            }.resume()
        }
    // Оновлена функція toggleBeeper
        func toggleBeeper(room: Room, isOn: Bool) {
            guard let entityID = room.beeperEntityID,
                  let url = URL(string: "\(HA_IP_ADDRESS)/api/services/switch/\(isOn ? "turn_on" : "turn_off")") else { return }
            
            // Встановлюємо мітку для ігнорування оновлень біпера
            ignoreBeeperUpdateForRoom = room.id

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = ["entity_id": entityID]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { _, _, error in
                // Через 2 секунди знімаємо мітку
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.ignoreBeeperUpdateForRoom == room.id {
                        self.ignoreBeeperUpdateForRoom = nil
                    }
                }
                if let error = error {
//                    print("❌ Помилка керування сигналізацією: \(error.localizedDescription)")
                } else {
//                    print("✅ Запит на switch.\(isOn ? "turn_on" : "turn_off") для \(entityID) успішно надіслано.")
                }
            }.resume()
        }
    
        func toggleColorMode(room: Room, isOn: Bool) {
            guard let url = URL(string: "\(HA_IP_ADDRESS)/api/services/switch/\(isOn ? "turn_on" : "turn_off")") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = ["entity_id": room.colorModeEntityID]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { _, _, error in
                if let error = error {
                    print("❌ Помилка режиму кольору: \(error.localizedDescription)")
                }
            }.resume()
        }

    
    func startBeeperStatusSync(for roomID: UUID, beeperEntityID: String) {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            guard let url = URL(string: "\(HA_IP_ADDRESS)/api/states/\(beeperEntityID)") else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
//                    print("❌ Статус біпера: \(error?.localizedDescription ?? "невідомо")")
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let state = json["state"] as? String {

                    DispatchQueue.main.async {
                        if let index = rooms.firstIndex(where: { $0.id == roomID }) {
                            rooms[index].beeperOn = (state == "on")
//                            print("🔁 Біпер оновлено: \(state)")
                        }
                    }
                }
            }.resume()
        }
    }



        func setLightColor(room: Room) {
            let rgb = UIColor(room.color).cgColor.components ?? [1, 1, 1]
            let red = Int((rgb[0]) * 255)
            let green = Int((rgb[1]) * 255)
            let blue = Int((rgb[2]) * 255)
            
            guard let url = URL(string: "\(HA_IP_ADDRESS)/api/services/light/turn_on") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(HA_TOKEN)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "entity_id": room.lightEntityID,
                "rgb_color": [red, green, blue]
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { _, _, error in
                if let error = error {
                    print("❌ Помилка кольору: \(error.localizedDescription)")
                }
            }.resume()
        }
    }
struct ModelContainerView: View {
    var modelName: String
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZoomableContainer(scale: $scale, lastScale: $lastScale) {
                ModelViewer(modelName: modelName)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .gesture(MagnificationGesture()
                .onChanged { value in
                    let delta = value / lastScale
                    lastScale = value
                    scale *= delta
                    scale = max(0.5, min(scale, 3.0))
                }
                .onEnded { _ in
                    lastScale = 1.0
                }
            )
        }
    }
}

struct ZoomableContainer<Content: View>: View {
    @Binding var scale: CGFloat
    @Binding var lastScale: CGFloat
    var content: Content
    
    init(scale: Binding<CGFloat>, lastScale: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self._scale = scale
        self._lastScale = lastScale
        self.content = content()
    }
    
    var body: some View {
        content
            .scaleEffect(scale)
            .animation(.easeInOut, value: scale)
    }
}

struct ModelViewer: UIViewRepresentable {
    var modelName: String
    var preloadedScene: SCNScene?
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = preloadedScene ?? loadScene()
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true
        scnView.backgroundColor = .clear
        scnView.defaultCameraController.interactionMode = .orbitTurntable
        scnView.defaultCameraController.inertiaEnabled = true
        return scnView
    }
    
    private func loadScene() -> SCNScene? {
        guard preloadedScene == nil else { return preloadedScene }
        guard let url = Bundle.main.url(forResource: modelName, withExtension: nil) else {
            print("Файл не знайдено: \(modelName)")
            return nil
        }
        
        do {
            let scene = try SCNScene(url: url)
            let rootNode = scene.rootNode
            let (min, max) = rootNode.boundingBox
            rootNode.position = SCNVector3(-(min.x + max.x)/2, -(min.y + max.y)/2, -(min.z + max.z)/2)
            return scene
        } catch {
            print("Помилка завантаження: \(error.localizedDescription)")
            return nil
        }
    }
    
    func updateUIView(_ scnView: SCNView, context: Context) {}
    
}

struct RoomDetailView: View {
    @Binding var room: Room
    var toggleLightAction: (Room, Bool) -> Void
    var toggleColorModeAction: (Room, Bool) -> Void
    var setColorAction: (Room) -> Void
    var toggleBeeperAction: ((Room, Bool) -> Void)? = nil
    var toggleGarageDoorAction: ((Room, Bool) -> Void)? = nil
    var toggleFanAction: ((Room, Bool) -> Void)? = nil
    var preloadedScenes: [String: SCNScene]
    var toggleServoAction: ((String, Bool) -> Void)?
    
    // Стани для утримання кнопок
    @State private var openTimer: Timer?
    @State private var closeTimer: Timer?
    @State private var isLongPressingOpen = false
    @State private var isLongPressingClose = false
    
    var body: some View {
        Form {
            if let modelName = room.nameModel, !modelName.isEmpty {
                Section {
                    VStack {
                        ModelViewer(modelName: modelName, preloadedScene: preloadedScenes[modelName])
                            .frame(height: 250)
                    }
                    .listRowInsets(EdgeInsets())
                }
            }
            // 🔌 Основне управління світлом
            if [ .kitchen, .livingRoom, .bathroom ,.security, .office, .corridor].contains(room.type) {
                Section(header: Text("Основні налаштування")) {
                    Toggle("Увімкнути світло", isOn: $room.isOn)
                        .onChange(of: room.isOn) { value in
                            toggleLightAction(room, value)
                        }
                    
                    if [.kitchen, .livingRoom, .bathroom, .office, .corridor].contains(room.type) {
                        Toggle("Режим автоматичної зміни кольорів", isOn: $room.colorModeEnabled)
                            .onChange(of: room.colorModeEnabled) { value in
                                toggleColorModeAction(room, value)
                            }
                    }
                }
                
                // 🎨 Колір світла (якщо режим кольору вимкнено)
                if [.kitchen, .livingRoom, .bathroom, .office, .corridor].contains(room.type), !room.colorModeEnabled {
                    Section(header: Text("Колір світла")) {
                        ColorPicker("Обрати колір", selection: $room.color)
                            .onChange(of: room.color) { _ in
                                if room.isOn {
                                    setColorAction(room)
                                }
                            }
                    }
                }
                
                // 🌀 Інфо про авто-зміну кольорів
                if [ .kitchen, .livingRoom, .bathroom, .office, .corridor].contains(room.type), room.colorModeEnabled {
                    Section {
                        Text("У режимі автоматичної зміни кольорів світло буде змінювати колір кожні 3 секунди")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
            }
            // 🛁 Стан середовища
            if [.bathroom, .livingRoom, .office].contains(room.type) {
                Section(header: Text("Стан середовища")) {
                    HStack {
                        Label("Температура", systemImage: "thermometer")
                        Spacer()
                        Text("\(room.temperature ?? 0.0, specifier: "%.1f") ℃")
                    }
                    
                    HStack {
                        Label("Вологість", systemImage: "drop.fill")
                        Spacer()
                        Text("\(room.humidity ?? 0.0, specifier: "%.0f") %")
                    }
                }
            }
            
            // 🍳 Кухонні датчики
            if room.type == .kitchen {
                
                Section(header: Text("Датчики кухні")) {
                    HStack {
                        Label("Рівень вогню", systemImage: "flame.fill")
                        Spacer()
                        if let fire = room.fireSensorLevel {
                            Text(String(format: "%.1f", fire))
                                .foregroundColor(fire > 4.0 ? .red : .green)
                        } else {
                            Text("Н/Д").foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Label("Рівень диму", systemImage: "smoke.fill")
                        Spacer()
                        if let smoke = room.smokeSensorLevel {
                            Text(String(format: "%.1f", smoke))
                                .foregroundColor(smoke > 5.0 ? .red : .green)
                        } else {
                            Text("Н/Д").foregroundColor(.gray)
                        }
                    }
                }
            }
            // 🛡️ Безпека
            if room.type == .security {
                Section(header: Text("Сигналізація")) {
                    Toggle("Активувати сигналізацію", isOn: Binding(
                        get: { room.beeperOn ?? false },
                        set: { newValue in
                            room.beeperOn = newValue
                            toggleBeeperAction?(room, newValue)
                        }
                    ))
                    HStack {
                        Label("Рух виявлено", systemImage: "figure.walk")
                        Spacer()
                        Text((room.motionDetected ?? false) ? "Так" : "Ні")
                            .foregroundColor((room.motionDetected ?? false) ? .red : .green)
                    }
                }
            }
            
            if room.type == .security {
                Section(header: Text("Присутність")) {
                    HStack {
                        Label("Мітка присутності", systemImage: "person.fill.checkmark")
                        Spacer()
                        Text((room.isSomeoneHome ?? false) ? "Вдома" : "Відсутній")
                            .foregroundColor((room.isSomeoneHome ?? false) ? .green : .red)
                    }
                }
            }
            
            // 🌀 Вентилятор (тільки для вітальні)
            if room.type == .livingRoom, let fanEntityID = room.fanEntityID, !fanEntityID.isEmpty {
                Section(header: Text("Вентилятор")) {
                    Toggle("Увімкнути вентилятор", isOn: Binding(
                        get: { room.isFanOn ?? false },
                        set: { newValue in
                            room.isFanOn = newValue
                            toggleFanAction?(room, newValue)
                        }
                    ))
                }
            }
            
            if room.type == .livingRoom, let _ = room.doorSensorID {
                if let doorOpen = room.doorContactOpen {
                    Section(header: Text("Стан дверей")) {
                        HStack {
                            Label("Двері", systemImage: "door.left.hand.open")
                            Spacer()
                            Text(doorOpen ? "Відчинено" : "Зачинено")
                                .foregroundColor(doorOpen ? .orange : .green)
                        }
                    }
                }
            }
            
            
            
            
            // Секція для головних дверей
            if room.type == .corridor, let _ = room.doorSensorID {
                Section(header: Text("Зовнішні умови")) {
                    // 🌧 Датчик дощу
                    if let isRaining = room.isRaining {
                        HStack {
                            Label("Дощ", systemImage: "cloud.rain")
                            Spacer()
                            Text(isRaining ? "Йде дощ" : "Сухо")
                                .foregroundColor(isRaining ? .blue : .gray)
                        }
                    }
                    
                    // 🌞 Датчик дня/ночі
                    if let isDaytime = room.isDaytime {
                        HStack {
                            Label("Час доби", systemImage: isDaytime ? "sun.max" : "moon.stars")
                            Spacer()
                            Text(isDaytime ? "День" : "Ніч")
                                .foregroundColor(isDaytime ? .yellow : .indigo)
                        }
                    }
                }
                Section(header: Text("Головні двері")) {
                    if let doorOpen = room.doorContactOpen {
                        HStack {
                            Label("Стан дверей", systemImage: "door.left.hand.open")
                            Spacer()
                            Text(doorOpen ? "Відчинено" : "Зачинено")
                                .foregroundColor(doorOpen ? .orange : .green)
                        }
                    }
                    
                    
                    
                }
                .navigationTitle(room.name)
                
            }
        }
    }
    
}
