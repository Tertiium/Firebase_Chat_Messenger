//
//  Extensions.swift
//  GameOfChats
//
//  Created by user on 23/03/17.
//  Copyright © 2017 yangguozhang. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(urlString: String){
        
        self.image = nil
        
        // check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage{
            self.image = cachedImage
            return
        }
        
        
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            // Download hit an error so lets return outs
            if error != nil{
                print(error!)
                return
            }
            
            DispatchQueue.main.async {
                
                if let downloadImage = UIImage(data: data!){
                    imageCache.setObject(downloadImage , forKey: urlString as AnyObject)
                    
                    self.image = downloadImage
                }
            
                
            }
            
        }).resume()
    }
    
}
