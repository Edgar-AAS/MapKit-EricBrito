//
//  PlacesTableViewController.swift
//  QueroConhecer
//
//  Created by Edgar Arlindo on 06/10/22.
//

import UIKit

class PlacesTableViewController: UITableViewController {
    private var lbNoPlaces: UILabel!
    private var viewModel = PlacesTableViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.loadPlaces()
        tableView.reloadData()
        setLabelNoPlaces()
    }
    
    func setLabelNoPlaces() {
        lbNoPlaces = UILabel()
        lbNoPlaces.text = viewModel.noPlaceText
        lbNoPlaces.textAlignment = .center
        lbNoPlaces.numberOfLines = 0
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! != "mapSegue" {
            guard let placeFinderVC = segue.destination as? PlaceFinderViewController else { return }
            placeFinderVC.delegate = self
        } else {
            guard let mapVC = segue.destination as? MapViewController else { return }
            switch sender {
                case let place as Place:
                    mapVC.places = [place]
                default:
                    mapVC.places = viewModel.getAllPlaces
            }
        }
    }
    
    @objc func showAll() {
        performSegue(withIdentifier: "mapSegue", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.getPlacesCount > 0 {
            let buttonShowAll = UIBarButtonItem(title: "Mostrar todos no mapa", style: .plain, target: self, action: #selector(showAll))
            navigationItem.leftBarButtonItem = buttonShowAll
            tableView.backgroundView = nil
        } else {
            navigationItem.leftBarButtonItem = nil
            tableView.backgroundView = lbNoPlaces
        }
        
        return viewModel.getPlacesCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = viewModel.getPlaceName(with: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = viewModel.getPlace(with: indexPath)
        performSegue(withIdentifier: "mapSegue", sender: place)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.removePlace(with: indexPath)
            tableView.deleteRows(at: [indexPath], with: .fade)
            viewModel.savePlaces()
        }
    }
}

extension PlacesTableViewController: PlaceFinderDelegate {
    func addPlace(_ place: Place) {
        viewModel.validatePlaces(place: place)
        tableView.reloadData()
    }
}
