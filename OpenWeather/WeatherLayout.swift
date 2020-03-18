//
//  WeatherLayout.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 13.03.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit

class WeatherLayout: UICollectionViewLayout {
    var cacheAttributes = [IndexPath: UICollectionViewLayoutAttributes]()
    var columnsCount = 2
    var cellHeight: CGFloat = 128
    var totalCellHeight: CGFloat = 0
    
    override func prepare() {
        super.prepare()
        cacheAttributes = [:]
        
        guard let collection = self.collectionView,
            let itemsCount = collectionView?.numberOfItems(inSection: 0) else { return }
        
        guard itemsCount > 0 else { return }
        
        let bigCellWidth = collection.frame.width
        let smallCellWidth = collection.frame.width / CGFloat(columnsCount)
        var lastY: CGFloat = 0
        var lastX: CGFloat = 0
        
        
        for index in 0..<itemsCount {
            let indexPath = IndexPath(item: index, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            
            let isBigCell = (index + 1) % (columnsCount + 1) == 0
            
            if isBigCell {
                attributes.frame = CGRect(x: 0, 
                                          y: lastY, 
                                          width: bigCellWidth, 
                                          height: cellHeight)
                
                lastY += cellHeight
            }
            else {
                attributes.frame = CGRect(x: lastX, 
                                          y: lastY, 
                                          width: smallCellWidth, 
                                          height: cellHeight)
                
                let isLastColumnt = (index + 2) % (columnsCount + 1) == 0 || index == itemsCount - 1
                
                if isLastColumnt {
                    lastX = 0
                    lastY += cellHeight
                }
                else {
                    lastX += smallCellWidth
                }
            }
            
            cacheAttributes[indexPath] = attributes
            totalCellHeight = lastY
        }
    }
    
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: collectionView?.frame.width ?? 0, 
                      height: self.totalCellHeight)
    }
    
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cacheAttributes.values.filter{ attributes in
            return rect.intersects(attributes.frame)
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cacheAttributes[indexPath]
    }
}
