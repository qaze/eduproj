//
//  PhotoCache.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 12.05.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit
import Alamofire

fileprivate protocol Reloadable {
    func reloadRow( index: IndexPath )
}


class PhotoCache {
    private let cacheLifeTime: TimeInterval = 60 * 5
    private var images = [String: UIImage]()
    
    private static let pathName: String = {
        let pathName = "images"
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return pathName }
        
        let url = cacheDirectory.appendingPathComponent(pathName)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print(error.localizedDescription)
            }
        }
        
        return pathName
    }()
    
    private let container: Reloadable
    
    init( table: UITableView ) {
        container = Table(table: table)
    }
    
    init( collection: UICollectionView ) {
        container = Collection(collection: collection)
    }
    
    private let syncQueue = DispatchQueue(label: "photo.cache.queue")
    
    private func loadImage( for indexPath: IndexPath, at url: String ) {
        Alamofire.request(url).responseData(queue: syncQueue) { [weak self] response in
            guard let data = response.data,
                let image = UIImage(data: data) else { return }
            
            self?.images[url] = image
            self?.saveImageToCache(url: url, image: image)
            DispatchQueue.main.async { [weak self] in
                self?.container.reloadRow(index: indexPath)
            }
        }
    }
    
    private func getFilePath( for url: String ) -> String? {
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let fileName = url.split(separator: "/").last ?? "default"
        return cachesDirectory.appendingPathComponent(PhotoCache.pathName + fileName).path
    }
    
    private func saveImageToCache( url: String, image: UIImage ) {
        if let filePath = getFilePath(for: url),
            let data = image.pngData() {
            FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
        }
    }
    
    
    private func readImageFromCache(url: String) -> UIImage? {
        guard let filePath = getFilePath(for: url),
            let info = try? FileManager.default.attributesOfItem(atPath: filePath),
            let modificationDate = info[FileAttributeKey.modificationDate] as? Date else { return nil }
        
        let timePassed = Date().timeIntervalSince(modificationDate)
        
        if timePassed < cacheLifeTime, 
            let image = UIImage(contentsOfFile: filePath) {
            images[url] = image
            return image
        }
        else {
            return nil
        }
    }
    
    func image(indexPath: IndexPath, at url: String) -> UIImage? {
        var image: UIImage?
        
        if let cached = images[url] {
            print("from RAM")
            image = cached
        }
        else if let cached = readImageFromCache(url: url) {
            print("from CACHE")
            image = cached
        }
        else {
            print("Loading image...")
            loadImage(for: indexPath, at: url)
        }
        
        return image
    }
}

extension PhotoCache {
    private class Table: Reloadable {
        let table: UITableView
        
        init( table: UITableView ) {
            self.table = table
        }
        
        func reloadRow(index: IndexPath) {
            table.reloadRows(at: [index], with: .automatic)
        }
    }
    
    
    private class Collection: Reloadable {
        let collection: UICollectionView
        
        init( collection: UICollectionView ) {
            self.collection = collection
        }
        
        func reloadRow(index: IndexPath) {
            collection.reloadItems(at: [index])
        }
    }
    
}
