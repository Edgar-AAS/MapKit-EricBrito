//
//  MapViewController.swift
//  QueroConhecer
//
//  Created by Edgar Arlindo on 06/10/22.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    enum MapMessageType {
        case routeError
        case authorizationWarning
    }
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var viInfo: UIView!
    @IBOutlet var lbName: UILabel!
    @IBOutlet var lbAdress: UILabel!
    @IBOutlet var aiLoading: UIActivityIndicatorView!
    
    var places: [Place]!
    var poi: [MKAnnotation] = []
    
    //so vai ser instanciando no momento que for utilizado
    lazy var locationManager = CLLocationManager()
    var btUserLocation: MKUserTrackingButton!
    var selectedAnnotation: PlaceAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.isHidden = true
        viInfo.isHidden = true
        mapView.mapType = .mutedStandard
        mapView.delegate = self
        locationManager.delegate = self
        
        if places.count == 1 {
            title = places[0].name
        } else {
            title = "Meus lugares"
        }
        
        places.forEach({ (place) in
            addToMap(place)
        })
        
        configureLocationButton()
        showPlaces()
        requestUserLocationAuthorization()
    }
    
    func configureLocationButton() {
        btUserLocation = MKUserTrackingButton(mapView: mapView)
        btUserLocation.backgroundColor = .white
        btUserLocation.frame.origin.x = 10
        btUserLocation.frame.origin.y = 10
        btUserLocation.layer.borderWidth = 1
        btUserLocation.layer.cornerRadius = 5
        btUserLocation.layer.borderColor = UIColor(named: "main")?.cgColor
    }
    
    //verificando o status
    func requestUserLocationAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            switch locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                mapView.addSubview(btUserLocation)
            case .denied:
                showMessage(type: .authorizationWarning)
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                break
            default:
                return
            }
        }
    }
    
    func showMessage(type: MapMessageType) {
        let title = type == .authorizationWarning ? "Aviso" : "Erro"
        let message = type == .authorizationWarning ? "Para usar os recursos de localização do App, você precisa permitir o uso na tela de ajustes" : "Não foi possivel encontrar esta rota"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        alert.addAction(cancelAction)
        
        if type == .authorizationWarning {
            let confirmACtion = UIAlertAction(title: "Ir para Ajustes", style: .default) { (action) in
                
                //Abrir tela de ajustes
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
            }
            
            alert.addAction(confirmACtion)
        }
        
        present(alert, animated: true)
    }
    
    //MARK: -Adicionando Annotation
    func addToMap(_ place: Place) {
        let annotation = PlaceAnnotation(coordinate: place.coordinate, type: .place)
        annotation.title = place.name
        annotation.adress = place.adress
        mapView.addAnnotation(annotation)
    }
    
    //MARK: - Mostrando anottations do mapa
    func showPlaces() {
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    func showInfo() {
        lbName.text = selectedAnnotation?.title
        lbAdress.text = selectedAnnotation?.adress
        viInfo.isHidden = false
    }
    
    @IBAction func showRoute(_ sender: UIButton) {
        if CLLocationManager().authorizationStatus != .authorizedWhenInUse {
            showMessage(type: .authorizationWarning)
            return
        }
        
        //Criando Rota
        let request = MKDirections.Request()
        //destino
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: selectedAnnotation!.coordinate))
        //origem
        if let location = locationManager.location {
            let origin = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
            request.source = origin
        }
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            if error == nil {
                if let response = response {
                    self.mapView.removeOverlays(self.mapView.overlays)
                    //é possivel filtrar as rotas
                    let route = response.routes.first!
                    print("Nome:", route.name)
                    print("Distância: ", route.distance)
                    print("Duração: ", route.expectedTravelTime)
                    print("==========================")
                    
                    for step in route.steps {
                        print("Em \(step.distance) metro(s), \(step.instructions)")
                    }
                    
                    self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                    var annotations = self.mapView.annotations.filter({ !($0 is PlaceAnnotation) })
                    annotations.append(self.selectedAnnotation!)
                    self.mapView.showAnnotations(annotations, animated: true)
                }
            } else {
                self.showMessage(type: .routeError)
            }
        }
    }
    
    @IBAction func showSearchBar(_ sender: UIBarButtonItem) {
        searchBar.resignFirstResponder()
        searchBar.isHidden = !searchBar.isHidden
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is PlaceAnnotation) {
            return nil
        }
        
        let type = (annotation as! PlaceAnnotation).type
        let identifier = "\(type)"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        //realimentando a celula com annotation
        annotationView?.annotation = annotation
        //balao de informacao na annotation
        annotationView?.canShowCallout = true
        annotationView?.markerTintColor = type == .place ? UIColor(named: "main") : UIColor(named: "poi")
        annotationView?.glyphImage = type == .place ? UIImage(named: "placeGlyph") : UIImage(named: "poiGlyph")
        //prioridade de visualização
        annotationView?.displayPriority = type == .place ? .required : .defaultHigh
        return annotationView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let camera = MKMapCamera()
        camera.centerCoordinate = view.annotation!.coordinate
        //angulo da camera
        camera.pitch = 80
        camera.altitude = 100
        //deifinindo camera no mapa
        mapView.setCamera(camera, animated: true)
        selectedAnnotation = view.annotation as? PlaceAnnotation
        showInfo()
    }
    
    //renderizando overlay
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(named: "main")?.withAlphaComponent(0.8)
            renderer.lineWidth = 5.0
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
}

extension MapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.isHidden = true
        searchBar.resignFirstResponder()
        aiLoading.startAnimating()
        
        //como eu quero que seja feita a requisicao
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBar.text
        request.region = mapView.region
        
        //executa essa requisicao
        let search = MKLocalSearch(request: request)
        
        search.start { (response, error) in
            if error == nil {
                if let response = response {
                    self.aiLoading.stopAnimating()
                    self.mapView.removeAnnotations(self.poi)
                    self.poi.removeAll()
                    
                    //varendo pontos de interesses
                    for item in response.mapItems {
                        let annotation = PlaceAnnotation(coordinate: item.placemark.coordinate, type: .poi)
                        annotation.title = item.name
                        annotation.subtitle = item.phoneNumber
                        annotation.adress = Place.getFormattedAdress(with: item.placemark)
                        self.poi.append(annotation)
                    }
                    
                    self.mapView.addAnnotations(self.poi)
                    self.mapView.showAnnotations(self.poi, animated: true)
                }
                self.aiLoading.stopAnimating()
            }
        }
    }
}

//responder a mudança do status
extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            mapView.addSubview(btUserLocation)
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    //Dispara quando a localizacao do usuario é alterada
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
}
