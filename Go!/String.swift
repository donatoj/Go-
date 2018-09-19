//
//  String.swift
//  Go!
//
//  Created by Jordan Donato on 8/26/18.
//  Copyright © 2018 Go!. All rights reserved.
//

import Foundation
import UIKit

extension String {
	func emojiToImage() -> UIImage? {
		let size = CGSize(width: 30, height: 35)
		UIGraphicsBeginImageContextWithOptions(size, false, 0)
		UIColor.clear.set()
		let rect = CGRect(origin: CGPoint(), size: size)
		UIRectFill(CGRect(origin: CGPoint(), size: size))
		(self as NSString).draw(in: rect, withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 30)])
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image
	}
}
