//
//  ViewController.swift
//  ImageDownloader
//
//  Created by Munib Hamza on 19/02/2023.
//

import UIKit
import Network


class ViewController: UIViewController, URLSessionTaskDelegate {
    
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var ipAddressTF: UITextField!
    @IBOutlet weak var portTF: UITextField!
    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var senderIP: UITextField!
    @IBOutlet weak var senderPort: UITextField!
    
    var imagesArray = [
        ImageData(url: "https://picsum.photos/4000/5000"),
        ImageData(url: "https://picsum.photos/3000/3000"),
        ImageData(url: "https://picsum.photos/3000/4000")
    ]
    
    // Create a session configuration with a delegate queue
    let sessionConfig = URLSessionConfiguration.default
    let sessionDelegateQueue = OperationQueue()
    var session : URLSession!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Image Downloader - Munib"
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
        tblView.dataSource = self
        tblView.delegate = self
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        sessionConfig.urlCache = nil
        sessionDelegateQueue.maxConcurrentOperationCount = 3
        session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: sessionDelegateQueue)
        downloadImages()
        
    }
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
    @IBAction func sendImagesPressed(_ sender: Any) {
        sendImages()
    }
    
    @IBAction func receiveImagesPressed(_ sender: Any) {
        guard let ip = senderIP.text, !ip.isEmpty else {
            showAlert(title: "Error", message: "Enter sender IP")
            return
        }
        guard let port = senderPort.text, !port.isEmpty else {
            showAlert(title: "Error", message: "Enter sender Port")
            return
        }
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ImagesReceiverVC") as! ImagesReceiverVC
        vc.othersIP = ip
        vc.othersPort = port
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func sendImages() {
        let tcp = TCPConnection()
        guard let ip = ipAddressTF.text, !ip.isEmpty else {
            print()
            showAlert(title: "Error", message: "Enter IP Address")
            return
        }
        guard let portStr = portTF.text, !portStr.isEmpty else {
            print()
            showAlert(title: "Error", message: "Enter Port Number")
            return
        }
        tcp.start(host: NWEndpoint.Host(ip), port: portStr)
        tcp.sendData(data: archiveImages(self.imagesArray.compactMap({$0.image})))
        
    }
    
    func downloadImages() {
        // Download each image on a separate thread and track its progress
        for (index, img) in imagesArray.enumerated() {
            guard let url = URL(string: img.url) else {return}
            // Create a new progress object for this download
            let progress = Progress(totalUnitCount: 100)
            imagesArray[index].progress = progress
            
            DispatchQueue.global(qos: .background).async {
                // Create a download task with the progress object
                let downloadTask = self.session.downloadTask(with: url)
                downloadTask.taskDescription = "\(index)"
                downloadTask.progress.addChild(progress, withPendingUnitCount: 1)
                downloadTask.resume()
            }
        }
    }
    
    func archiveImages(_ images: [UIImage]) -> Data? {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: images, requiringSecureCoding: false)
            return data
        } catch {
            print("Error archiving images: \(error)")
            return nil
        }
    }
    func unarchiveImages(_ data: Data) -> [UIImage]? {
        do {
            if let images = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [UIImage] {
                return images
            } else {
                return nil
            }
        } catch {
            print("Error unarchiving images: \(error)")
            return nil
        }
    }
    
}

// Implement the URLSessionDownloadDelegate method to track the download progress
extension ViewController: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handle downloaded image data here
        guard let taskDescription = downloadTask.taskDescription, let index = Int(taskDescription), index < imagesArray.count else {
            return
        }
        
        if let data = try? Data(contentsOf: location), let image = UIImage(data: data) {
            imagesArray[index].image = image
            DispatchQueue.main.async {
                self.tblView.reloadData()
            }
        }
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // Get the progress object for this download
        guard let taskDescription = downloadTask.taskDescription, let index = Int(taskDescription), index < imagesArray.count else {
            return
        }
        let progress = imagesArray[index].progress
        
        // Update the progress object on the main thread
        DispatchQueue.main.async {
            progress?.completedUnitCount = totalBytesWritten
            progress?.totalUnitCount = totalBytesExpectedToWrite
            self.imagesArray[index].fractionCompleted = Float(progress?.fractionCompleted ?? 0)
            print("progress",progress?.fractionCompleted ?? 0)
            if let cell = self.tblView.cellForRow(at: IndexPath(row: index, section: 0)) as? ImageCell {
                cell.progressBar.progress = Float(progress!.fractionCompleted)
            }
            //            self.tblView.reloadRows(at: [], with: .automatic)
        }
    }
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // ...
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true)
    }
}



extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imagesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImageCell", for: indexPath) as! ImageCell
        
        let imageObject = imagesArray[indexPath.row]
        if imageObject.fractionCompleted == 1.0 {
            cell.progressBar.isHidden = true
        } else {
            
            cell.progressBar.progress = Float(imageObject.fractionCompleted)
        }
        cell.imgView.image = imageObject.image ?? UIImage()
        return cell
    }
    
}

func archiveImages(_ images: [UIImage]) -> Data? {
    do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: images, requiringSecureCoding: false)
        return data
    } catch {
        print("Error archiving images: \(error)")
        return nil
    }
}
func unarchiveImages(_ data: Data) -> [UIImage]? {
    do {
        if let images = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [UIImage] {
            return images
        } else {
            return nil
        }
    } catch {
        print("Error unarchiving images: \(error)")
        return nil
    }
}

extension UIDevice {
    
    private struct InterfaceNames {
        static let wifi = ["en0"]
        static let wired = ["en2", "en3", "en4"]
        static let cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]
        static let supported = wifi + wired + cellular
    }
    
    func ipAddress() -> String? {
        var ipAddress: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var pointer = ifaddr
            
            while pointer != nil {
                defer { pointer = pointer?.pointee.ifa_next }
                
                guard
                    let interface = pointer?.pointee,
                    interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) || interface.ifa_addr.pointee.sa_family == UInt8(AF_INET6),
                    let interfaceName = interface.ifa_name,
                    let interfaceNameFormatted = String(cString: interfaceName, encoding: .utf8),
                    InterfaceNames.supported.contains(interfaceNameFormatted)
                else { continue }
                
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                
                getnameinfo(interface.ifa_addr,
                            socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname,
                            socklen_t(hostname.count),
                            nil,
                            socklen_t(0),
                            NI_NUMERICHOST)
                
                guard
                    let formattedIpAddress = String(cString: hostname, encoding: .utf8),
                    !formattedIpAddress.isEmpty
                else { continue }
                
                ipAddress = formattedIpAddress
                break
            }
            
            freeifaddrs(ifaddr)
        }
        
        return ipAddress
    }
    
}
