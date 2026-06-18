//
//  UIImage+Resizing.swift
//  FamilyJOurney
//
//  Created by Antigravity on 17/06/26.
//

#if canImport(UIKit)
import UIKit

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage? {
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
#endif
