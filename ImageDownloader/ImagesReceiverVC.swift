//
//  ImagesReceiverVC.swift
//  ImageDownloader
//
//  Created by Munib Hamza on 21/02/2023.
//

import UIKit
import Network

class ImagesReceiverVC: UIViewController {

    @IBOutlet weak var portLbl: UILabel!
    @IBOutlet weak var ipAddressLbl: UILabel!
    @IBOutlet weak var tblVu: UITableView!
    
    var othersIP = ""
    var othersPort = ""
    var images : [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblVu.delegate = self
        tblVu.dataSource = self
    }
   
    override func viewWillAppear(_ animated: Bool) {
        self.ipAddressLbl.text = "Sender IP Address: " + othersIP
        self.portLbl.text = "Sender Port: " + othersPort
    }
    override func viewDidAppear(_ animated: Bool) {
        receiveImages()
    }
    
    func receiveImages() {
        let tcp = TCPConnection()
        tcp.start(host: NWEndpoint.Host(othersIP), port: othersPort)
        tcp.setupReceive { images in
            self.images = images
            DispatchQueue.main.async {
                self.tblVu.reloadData()
            }
        }
    }

}


extension ImagesReceiverVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return images.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImageCell", for: indexPath) as! ImageCell
        cell.imgView.image = images[indexPath.row]
        return cell
    }
    
}

