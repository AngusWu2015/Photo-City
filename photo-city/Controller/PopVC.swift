//
//  PopVC.swift
//  photo-city
//
//  Created by AndyWu on 2017/11/1.
//  Copyright © 2017年 AndyWu. All rights reserved.
//

import UIKit

class PopVC: UIViewController, UIGestureRecognizerDelegate{

    @IBOutlet weak var popImageView: UIImageView!
    
    var passedImage: UIImage!
    
    func initData(forImage image: UIImage) {
        self.passedImage = image
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        popImageView.image = passedImage
        addDoubleTap()
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer (target: self, action: #selector(screenWasDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
        let swipe = UISwipeGestureRecognizer (target: self, action: #selector(screenWasDoubleTapped))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
        
    }
    
    @objc func screenWasDoubleTapped() {
        dismiss(animated: true, completion: nil)
    }

    
}
