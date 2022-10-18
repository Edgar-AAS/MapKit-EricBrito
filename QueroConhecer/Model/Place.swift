//
//  Place.swift
//  QueroConhecer
//
//  Created by Edgar Arlindo on 13/10/22.
//

import Foundation
import MapKit //mapkit ja tem o Core location dentro

struct Place: Codable {
    let name: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let adress: String
    
    var coordinate: CLLocationCoordinate2D {
        return .init(latitude: latitude, longitude: longitude)
    }
    
    static func getFormattedAdress(with placemark: CLPlacemark) -> String {
        var adress = ""

        if let street = placemark.thoroughfare {
            adress += street
        }

        if let number = placemark.subThoroughfare {
            adress += " \(number)"
        }

        if let subLocality = placemark.subLocality {
            adress += " \(subLocality)" //Bairro
        }

        if let city = placemark.locality {
            adress += "\n\(city)" //cidade
        }

        if let state = placemark.administrativeArea {
            adress += " -\(state)" //Estado
        }

        if let postalCode = placemark.postalCode {
            adress += "\nCEP: \(postalCode)" //CEP
        }

        if let country = placemark.country {
            adress += "\n\(country)" //Pais
        }
        
        return adress
    }
}

//definir qual a regra para comparacao de Places
extension Place: Equatable {
    static func ==(lhs: Place, rhs: Place) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
