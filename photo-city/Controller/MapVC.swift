//
//  MapVC.swift

//  photo-city
//
//  Created by AndyWu on 2017/10/30.
//  Copyright © 2017年 AndyWu. All rights reserved.
//

import UIKit
import MapKit
class MapVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func centerMapBtnWasPressed(_ sender: Any) {
    }
    
}

extension MapVC: MKMapViewDelegate {
    
}
