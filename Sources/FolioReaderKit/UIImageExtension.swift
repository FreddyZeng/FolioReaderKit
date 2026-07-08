//
//  UIImageExtension.swift
//  FolioReaderKit
//
//  Created by Antigravity on 2026/07/06.
//

import UIKit

internal extension UIImage {
    
    convenience init?(readerImageNamed: String) {
        self.init(named: readerImageNamed, in: Bundle.frameworkBundle(), compatibleWith: nil)
    }
    
    /// Forces the image to be colored with Reader Config tintColor
    ///
    /// - Parameter readerConfig: Current folio reader configuration.
    /// - Returns: Returns a colored image
    func ignoreSystemTint(withConfiguration readerConfig: FolioReaderConfig) -> UIImage? {
        return self.imageTintColor(readerConfig.tintColor)?.withRenderingMode(.alwaysOriginal)
    }
    
    /**
     Colorize the image with a color
     
     - parameter tintColor: The input color
     - returns: Returns a colored image
     */
    func imageTintColor(_ tintColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)
        
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height) as CGRect
        if let cgImage = self.cgImage {
            context?.clip(to: rect, mask:  cgImage)
        }
        
        tintColor.setFill()
        context?.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /**
     Generate a image with a color
     
     - parameter color: The input color
     - returns: Returns a colored image
     */
    class func imageWithColor(_ color: UIColor?) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        if let color = color {
            color.setFill()
        } else {
            UIColor.white.setFill()
        }
        
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    /**
     Generates a image with a `CALayer`
     
     - parameter layer: The input `CALayer`
     - returns: Return a rendered image
     */
    class func imageWithLayer(_ layer: CALayer) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(layer.bounds.size, layer.isOpaque, 0.0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
    /**
     Generates a image from a `UIView`
     
     - parameter view: The input `UIView`
     - returns: Return a rendered image
     */
    class func imageWithView(_ view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
