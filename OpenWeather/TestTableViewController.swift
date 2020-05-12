//
//  TestTableViewController.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 21.04.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit
import Alamofire

class TestTableCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
}

class BlurOperation: Operation {
    var outputImage: UIImage?
    
    
    override func main() {
        guard let downloadOperation = dependencies.first as? DownloadOperation,
            let inputImage = downloadOperation.outputImage else { return }
        
        let inputCIImage = CIImage(image: inputImage)!
        
        let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputImageKey: inputCIImage])!
        let outputImage = blurFilter.outputImage!
        let context = CIContext()
        
        let cgiImage = context.createCGImage(outputImage, from: outputImage.extent)
        
        self.outputImage = UIImage(cgImage: cgiImage!)
        
    }
}


class AsyncOperation: Operation {
    enum State: String {
        case ready, executing, finished
        
        var keyPath: String {
            return "is" + rawValue.capitalized
        }
    }
    
    var state: State = .ready {
        willSet {
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
        }
        didSet {
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }
    
    
    override var isReady: Bool {
        return super.isReady && state == .ready
    }
    
    override var isExecuting: Bool {
        return state == .executing
    }
    
    override var isFinished: Bool {
        return state == .finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    
    override func start() {
        if isCancelled {
            state = .finished
        }
        else {
            main()
            state = .executing
        }
    }
    
    override func cancel() {
        super.cancel()
        state = .finished
    }
}


class DownloadOperation: AsyncOperation {
    let url: URL
    var outputImage: UIImage?
    var request: DataRequest
    
    
    init(url: URL ) {
        self.url = url
        request = Alamofire.request(url)
    }
    
    override func cancel() {
        request.cancel()
        super.cancel()
    }
    
    override func main() {
        request.responseData { (data) in
            if let dt = data.data {
                self.outputImage = UIImage(data: dt)
            }
            
            self.state = .finished
        }
    }
}



class TestTableViewController : UITableViewController {
    let operationQueue = OperationQueue()
    let url = URL(string: "https://i.imgur.com/F1MKVoG.jpg")!
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "testCell") as? TestTableCell else { fatalError() }
        
        let downloadOperation = DownloadOperation(url: url)
        operationQueue.addOperation(downloadOperation)
        downloadOperation.completionBlock = {
            print(downloadOperation.outputImage?.size)
        }
        
        let blurOperation = BlurOperation()
        blurOperation.addDependency(downloadOperation)
        
        blurOperation.completionBlock = {
            OperationQueue.main.addOperation { 
                cell.iconImageView.image = blurOperation.outputImage
            }
        }
        
        operationQueue.addOperation(blurOperation)
        
        return cell
    }
}


