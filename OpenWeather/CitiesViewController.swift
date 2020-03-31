//
//  CitiesViewController.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 13.03.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit
import RealmSwift



class CitiesViewController: UITableViewController {
    var cities: [City] = []
    
    lazy var sections: [[City]] = {
        // Отсортированные города
        let sortedCities = cities
        
        // Разбиваем по группам
        let grouppedArray = sortedCities.reduce([[City]]()) { (result, element) -> [[City]] in
            // result - это массив который мы заполняем нашими секциями - по сути массив массивов City. Изначально пустой
            // element - текущий обрабатываемый city
            // Если последнего элемента нет - то вовзращаем последовательность которая содержит массив с текущим city 
            guard var last = result.last else { return [[element]] }
            
            var collection = result
            // Берем первую букву имени города
            let firstCityLetter = element.name.first
            
            // Берем последний массив из нашего массива массивов
            let lastAddedSection = result.last
            
            // Берем первый city из последней секции (массива)
            let firstCityInLastSection = lastAddedSection?.first
            
            // Берем первую букву из названия этого города
            let firstLetterOfLastAddedSection = firstCityInLastSection?.name.first
            
            // Сравниваем совпадают ли первые буквы текущего названия города и названия города из предыдущей секции
            // Если да то добавляем наш город в последнюю секцию
            if firstCityLetter == firstLetterOfLastAddedSection {
                last.append(element)
                collection[collection.count - 1] = last
            }
            else {
                // Если нет то добавляем новую секцию(массив) которая уже содержит наш текущий элемент 
                collection.append([element])
            }
            
            
            // Возвращаем отредактированный массив массивов
            return collection
        }
        
        return grouppedArray
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do{
            let realm = try Realm()
            cities = Array(realm.objects(City.self).sorted(byKeyPath: "id"))
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].first?.name.first?.uppercased()
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        // Делаем массив плоским
        // Например [[Москва, Мурманск], [Самара, Суздаль]] -> [Москва, Мурманск, Самара, Суздаль]
        let sectionsJoined = sections.joined()
        
        // Трансформируем наш "плоский" массив городов в массив первых букв названий городов
        let letterArray = sectionsJoined.compactMap{ $0.name.first?.uppercased() }
        
        // Делаем Set из массива чтобы все неуникальные буквы пропали
        let set = Set(letterArray)
        
        
        // Возвращаем массив уникальных букв предварительно его отсортировав
        return Array(set).sorted()
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath) as? CityCell 
            else { fatalError() }
        
        let city = sections[indexPath.section][indexPath.row]
        cell.nameLabel.text = city.name
        cell.city = city
//        cell.avatarImageView.image = city.image
        
        return cell
    }
    
    @IBAction func deleteTapped(_ sender: Any) {
        guard var first = sections.first, first.count > 0 else { return }
        var arrayToDelete = [IndexPath]()
        if first.count > 0 {
            first.remove(at: 0)
            arrayToDelete.append(.init(row: 0, section: 0))
        }
        
        if first.count > 0 {
            first.remove(at: 0)
            arrayToDelete.append(.init(row: 1, section: 0))
        }
        if first.count == 0 {
            sections.remove(at: 0)
            tableView.deleteSections(.init(integer: 0), with: .fade)
            tableView.reloadSectionIndexTitles()
        }
        else {
            sections[0] = first
            tableView.deleteRows(at: arrayToDelete, with: .fade)
        }
        
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
    
}
