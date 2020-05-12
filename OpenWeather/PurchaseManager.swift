//
//  PurchaseManager.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 07.04.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import Foundation
import StoreKit

enum Products: String, CaseIterable {
    case disable_ads = "com.openweather.disableads2"
}

protocol PurchaseListener: class {
    func productBought( product: Products )
}

class PurchaseManager: NSObject {
    private var availableProducts = [SKProduct]()
    
    static let shared: PurchaseManager = .init()
    
    struct WeakListener {
        weak var value: PurchaseListener?
    }
    
    private var listeners: [WeakListener] = .init()
    
    private override init() {
        super.init()
    }
    
    func addListener( listener: PurchaseListener ) {
        listeners.append( WeakListener(value: listener) )
    }
    
    func prepare() {
        SKPaymentQueue.default().add(self)
        fetchProducts(identifiers: Products.allCases.map{ $0.rawValue })
    }
    
    
    func fetchProducts( identifiers: [String] ) {
        let productIDs = Set(identifiers)
        let productRequest = SKProductsRequest(productIdentifiers: productIDs)
        productRequest.delegate = self
        productRequest.start()
    }
    
    func makePayment( product: Products ) {
        if let found = availableProducts.first(where: { $0.productIdentifier == product.rawValue }) {
            let payment = SKPayment(product: found)
            SKPaymentQueue.default().add(payment)
        }
    }
    
    func restore() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

extension PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .failed:
                print(transaction.error?.localizedDescription)
                break
                
            case .deferred:
                break
                
            case .purchased:
                if let product = Products(rawValue: transaction.payment.productIdentifier) {
                    listeners.forEach{ $0.value?.productBought(product: product) }
                }
                break
                
            case .purchasing:
                break
                
            case .restored:
                break
            }
        }
    }
}


extension PurchaseManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        availableProducts = response.products
    }
}
