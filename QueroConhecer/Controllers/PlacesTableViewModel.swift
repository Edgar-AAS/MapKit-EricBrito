//
//  PlacesTableViewModel.swift
//  QueroConhecer
//
//  Created by Edgar Arlindo on 18/10/22.
//

import Foundation

struct PlacesTableViewModel {
    private var places = [Place]()
    let userDefaults = UserDefaults.standard
    
    var getAllPlaces: [Place] {
        return places
    }
    
    mutating func validatePlaces(place: Place) {
        if !places.contains(place) {
            places.append(place)
            savePlaces()
        }
    }
    
    var noPlaceText: String {
        return "Cadastre os locais que deseja conhecer\nclickando no botão acima"
    }
    
    func getPlaceName(with indexPath: IndexPath) -> String {
        return places[indexPath.row].name
    }
    
    
    func getPlace(with indexPath: IndexPath) -> Place {
        return places[indexPath.row]
    }
    
    mutating func removePlace(with indexPath: IndexPath) {
        places.remove(at: indexPath.row)
    }
    
    var getPlacesCount: Int {
        return places.count
    }
    
    mutating func loadPlaces() {
        if let placesData = userDefaults.data(forKey: "places") {
            do {
                places = try JSONDecoder().decode([Place].self, from: placesData)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func savePlaces() {
        let json = try? JSONEncoder().encode(places)
        userDefaults.setValue(json, forKey: "places")
    }
    
}
