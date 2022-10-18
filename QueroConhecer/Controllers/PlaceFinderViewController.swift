//
//  PlaceFinderViewController.swift
//  QueroConhecer
//
//  Created by Edgar Arlindo on 06/10/22.
//

import UIKit
import MapKit

protocol PlaceFinderDelegate: AnyObject {
    func addPlace(_ place: Place)
}

class PlaceFinderViewController: UIViewController {
    enum PlaceFinderMessageType {
        case error(String)
        case confirmation(String)
    } 
    
    @IBOutlet var tfCity: UITextField!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var viLoading: UIView!
    @IBOutlet var aiLoading: UIActivityIndicatorView!
    
    var place: Place!
    weak var delegate: PlaceFinderDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //MARK: - Adicionando Gesture Recognizer
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(getLocation(_:)))
        gesture.minimumPressDuration = 2.0
        mapView.addGestureRecognizer(gesture)
    }
    
    @objc func getLocation(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            load(show: true)
            //pegando location do gesture do mapview
            let point = gesture.location(in: mapView)
            //convertendo esse ponto em coordenadas
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            //criando location com as coordenadas
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                self.load(show: true)
                self.locationHandler(placemark: placemarks?.first, error: error)
            }
        }
    }
    
    func locationHandler(placemark: CLPlacemark?, error: Error?) {
        if error != nil  {
            return self.showMessage(type: .error("Erro desconhecido"))
        } else {
            if !self.savePlace(with: placemark) {
                self.showMessage(type: .error("Nao foi encontrado nenhum local com esse nome"))
            }
        }
    }
    
    @IBAction func findCity(_ sender: UIButton) {
        tfCity.resignFirstResponder()
        guard let adress = tfCity.text else { return }
        load(show: true)
        
        let geoCoder = CLGeocoder()
        //bate no servidor da apple e verificar se existe o endereço
        geoCoder.geocodeAddressString(adress) { (placemarks, error) in
            self.load(show: false)
            self.locationHandler(placemark: placemarks?.first, error: error)
        }
    }
    
    func savePlace(with placemark: CLPlacemark?) -> Bool {
        guard let placemark = placemark, let coordinate = placemark.location?.coordinate else { return false }
        let name = placemark.name ?? placemark.country ?? "Desconhecido"
        let adress = Place.getFormattedAdress(with: placemark)
        place = Place(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude, adress: adress)
        
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 3500, longitudinalMeters: 3500)
        mapView.setRegion(region, animated: true)
        self.showMessage(type: .confirmation(place.name))
        return true
    }
    
    func showMessage(type: PlaceFinderMessageType) {
        let title: String, message: String
        var hasConfimation: Bool = false
        
        switch type {
        case .confirmation(let name):
            title = "Local encontrado"
            message = "Deseja adicionar \(name)?"
            hasConfimation = true
        case .error(let errorMessage):
            title = "Erro"
            message = errorMessage
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        if hasConfimation {
            let confirmACtion = UIAlertAction(title: "OK", style: .default) { (action) in
                self.delegate?.addPlace(self.place)
                self.dismiss(animated: true, completion: nil)
            }

            self.load(show: false)
            alert.addAction(confirmACtion)
        }
        
        present(alert, animated: true)
    }
    
    func load(show: Bool) {
        viLoading.isHidden = !show
        if show {
            aiLoading.startAnimating()
        } else {
            aiLoading.stopAnimating()
        }
    }
    
    @IBAction func close(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
