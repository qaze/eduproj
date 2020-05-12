//
//  CitiesViewController.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 13.03.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit
import RealmSwift
import FirebaseDatabase

class CitiesViewController: UITableViewController {
    var cities: Results<City>?
    var token: NotificationToken?
    var requestHandler: UInt = 0
    
    func observeChanges(results: Results<City>) {
        token = results.observe { (changes) in
            switch changes {
            case .initial:
                self.tableView.reloadData()
                
            case .update(_, let deletions, let insertions, let modifications):
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: deletions.map{ IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.insertRows(at: insertions.map{ IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.reloadRows(at: modifications.map{ IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.endUpdates()
                
            case .error(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let realm = try Realm()
            let request = realm.objects(City.self).sorted(byKeyPath: "name")
            cities = request
            observeChanges(results: request)
        }   
        catch {
            print(error.localizedDescription)
        }
        
        let db = Database.database().reference()
        requestHandler = db.child("cities").observe(.value) { (snapshot) in
            guard let cities = snapshot.value as? [String] else { return }
            cities.enumerated().forEach{ self.addCity(with: $0.element, withID: $0.offset) }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities?.count ?? 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let city = cities?[indexPath.row], 
            let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath) as? CityCell 
            else { fatalError() }
        
        cell.nameLabel.text = city.name
        cell.city = city
        return cell
    }
    
    
    func addCity( with name: String, withID : Int? = nil ) -> Int {
        do {
            let realm = try Realm()
            let newCity = City()
            newCity.name = name
            newCity.id = (realm.objects(City.self).max(ofProperty: "id") as Int? ?? 0) + 1
            
            if let ownId = withID {
                newCity.id = ownId
            }
            realm.beginWrite()
            
            realm.add(newCity, update: .modified)
            
            try realm.commitWrite()
            
            return newCity.id
        }
        catch {
            print(error.localizedDescription)
            return -1
        }
    }
    
    @IBAction func addCityTapped(_ sender: UITabBarItem) {
        let alertController = UIAlertController(title: "Введите город", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: nil)
        
        let confirmAction = UIAlertAction(title: "Добавить", style: .default) { (action) in
            guard let name = alertController.textFields?[0].text else { return }
            let cleared = name.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !cleared.isEmpty {
                let newId = self.addCity(with: name)
                
                Database.database().reference().child("cities").updateChildValues(["\(newId)": name])
            }
        }
        
        alertController.addAction(confirmAction)
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detaillCellSeque" {
            guard let collectionViewController = segue.destination as? WeatherViewController,
                let cell = sender as? CityCell
                else { return }
            
            collectionViewController.name = cell.nameLabel.text
            collectionViewController.city = cell.city
        }
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let city = cities?[indexPath.row] else { return }
        
        if editingStyle == .delete {
            do {
                let realm = try Realm()
                realm.beginWrite()
                realm.delete(city.weathers)
                realm.delete(city)
                try realm.commitWrite()
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
}
