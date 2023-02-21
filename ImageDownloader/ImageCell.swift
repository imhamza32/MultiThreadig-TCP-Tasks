//
//  ImageCell.swift
//  ImageDownloader
//
//  Created by Munib Hamza on 19/02/2023.
//

import UIKit

class ImageCell: UITableViewCell {

    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var imgView: UIImageView!
  
    override func prepareForReuse() {
        super.prepareForReuse()
        imgView?.image = nil
    }
    
}
