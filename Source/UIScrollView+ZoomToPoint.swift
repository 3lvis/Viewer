//
//  UIScrollView+ZoomToPoint.swift
//  Demo
//
//  Created by Christian Askeland on 29/11/2016.
//
//

import UIKit

extension UIScrollView {

    func zoomToPoint(zoomPoint: CGPoint, withScale scale: CGFloat, animated: Bool) {
        
        //Normalize current content size back to content scale of 1.0f
        let contentSize = CGSize(width: self.contentSize.width / self.zoomScale,
                                 height: self.contentSize.height / self.zoomScale)
        
        //translate the zoom point to relative to the content rect
        let relativeZoomPoint = CGPoint(x: (zoomPoint.x / self.bounds.size.width) * contentSize.width,
                                        y: (zoomPoint.y / self.bounds.size.height) * contentSize.height)
        
        //derive the size of the region to zoom to
        let zoomSize = CGSize(width: self.bounds.size.width / scale,
                              height: self.bounds.size.height / scale)
        
        //offset the zoom rect so the actual zoom point is in the middle of the rectangle
        let zoomRect = CGRect(x: relativeZoomPoint.x - zoomSize.width / 2.0,
                              y: relativeZoomPoint.y - zoomSize.height / 2.0,
                              width: zoomSize.width,
                              height: zoomSize.height)
        
        //apply the resize
        self.zoom(to: zoomRect, animated: animated)
    }
}
