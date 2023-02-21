//
//  Models.swift
//  ImageDownloader
//
//  Created by Munib Hamza on 19/02/2023.
//

import Foundation
import UIKit

struct ImageData {
    let url: String
    var image: UIImage?
    var progress: Progress?
    var fractionCompleted: Float = 0.0
    
}
