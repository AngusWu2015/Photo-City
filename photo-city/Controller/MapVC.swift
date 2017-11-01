//
//  MapVC.swift

//  photo-city
//
//  Created by AndyWu on 2017/10/30.
//  Copyright © 2017年 AndyWu. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage
import PinterestLayout

class MapVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var pullUpView: UIView!
    
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var progressLbl: UILabel!
    
    var flowLayout = PinterestLayout()
    var collectionView: UICollectionView?
    
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    var imageDataArray = [Dictionary<String, AnyObject>]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        addSwipe()
        
        
        
        flowLayout.delegate = self
        flowLayout.cellPadding = 5
        flowLayout.numberOfColumns = 2
        
        collectionView = UICollectionView (frame: pullUpView.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        collectionView?.contentInset = UIEdgeInsets(
            top: 15,
            left: 5,
            bottom: 5,
            right: 5
        )
        pullUpView.insertSubview(collectionView!, at: 0)
        
        collectionView?.translatesAutoresizingMaskIntoConstraints = false
        collectionView?.leadingAnchor.constraint(equalTo: pullUpView.leadingAnchor).isActive = true
        collectionView?.trailingAnchor.constraint(equalTo: pullUpView.trailingAnchor).isActive = true
        collectionView?.topAnchor.constraint(equalTo: pullUpView.topAnchor).isActive = true
        collectionView?.bottomAnchor.constraint(equalTo: pullUpView.bottomAnchor).isActive = true
        
        
        spinner.startAnimating()
        self.mapViewBottomConstraint.constant = 0
        self.view.layoutIfNeeded()
        
        
        registerForPreviewing(with: self, sourceView: collectionView!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func animateViewUp() {
        UIView.animate(withDuration: 0.3) {
            self.mapViewBottomConstraint.constant = 300
            self.view.layoutIfNeeded()
        }
        
    }
    
    func spinnerSwitch(start: Bool, text: String?) {
        if start {
            spinner.isHidden = false
            progressLbl.isHidden = false
            progressLbl.text = text
        } else {
            spinner.isHidden = true
            progressLbl.isHidden = true
        }
    }
    
   @objc func animateViewDown() {
        cancelAllSessions()
        UIView.animate(withDuration: 0.3) {
            self.mapViewBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer (target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer (target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        
        pullUpView.addGestureRecognizer(swipe)
    }
    
    
    @IBAction func centerMapBtnWasPressed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
            
        }
    }
    
}

extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        let pinAnnotation = MKPinAnnotationView (annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        
        return pinAnnotation
    }
    
    func centerMapOnUserLocation() {
        //檢查有沒有定位
        guard let coordinate = locationManager.location?.coordinate else{ return }
        //建立顯示範圍
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        //清空標點
        removePin()
        cancelAllSessions()
        
        imageUrlArray = []
        imageArray = []
        collectionView?.reloadData()
        
        spinnerSwitch(start: true, text: "")
        //取得點擊位置
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = DroppablePin (coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        

        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius * 2.0, regionRadius * 2.0)
        
        mapView.setRegion(coordinateRegion, animated: true)
        
        animateViewUp()
        retrieveUrls(forAnnotation: annotation) { (finished) in
            //取的圖片列表
            if finished {
                self.retrieveImages(handler: { (finished) in
                    if finished {
                        self.spinnerSwitch(start: false, text: "") //隱藏spinner、Label
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
    }
    
    func removePin() {
        for MKAnnotation in mapView.annotations {
            mapView.removeAnnotation(MKAnnotation)
        }
    }
    
    func retrieveUrls(forAnnotation annotation: DroppablePin, handler: @escaping(_ status: Bool) -> ()) {
        
        let url = flockrUrl(forApiKey: apiKey, withAnntation: annotation, andNumverOfPhotos: 10)
        Alamofire.request(url).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
            let photossDict = json["photos"] as! Dictionary<String, AnyObject>
            self.imageDataArray = photossDict["photo"] as! [Dictionary<String, AnyObject>]
            print(self.imageDataArray)
            for photo in self.imageDataArray {
                let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_n_d.jpg"
                self.imageUrlArray.append(postUrl)
            }
            handler(true)
        }
    }
    
    func retrieveImages(handler: @escaping (_ status: Bool) -> ()) {
        imageArray = []
        
        for url in imageUrlArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                guard let image = response.result.value else { return }
                self.imageArray.append(image)
                self.progressLbl.text = "\(self.imageArray.count)/40 IMAGES DOWNLOADED"
                if self.imageArray.count == self.imageUrlArray.count {
                    print("image download over")
                    handler(true)
                }
            })
        }
    }
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({ $0.cancel() })
            downloadData.forEach({ $0.cancel() })
            uploadData.forEach({ $0.cancel() })
        }
    }
}

extension MapVC: CLLocationManagerDelegate {
    func configureLocationServices() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource ,PinterestLayoutDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imageArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        
        if let imageview = cell.viewWithTag(100) {
            imageview.removeFromSuperview()
        }
        
        cell.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView (image: imageFromIndex)
        imageView.frame.size = cell.frame.size
        imageView.tag = 100
        cell.addSubview(imageView)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return }
        
        popVC.initData(forImage: imageArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }

    func collectionView(collectionView: UICollectionView,
                        heightForImageAtIndexPath indexPath: IndexPath,
                               withWidth: CGFloat) -> CGFloat {
        let image = imageArray[indexPath.row]
        
        return image.height(forWidth: withWidth)
    }
    
    public func collectionView(collectionView: UICollectionView,
                               heightForAnnotationAtIndexPath indexPath: IndexPath,
                               withWidth: CGFloat) -> CGFloat {
        
        
        return 0.0
    }
    
}
//3D touch
extension MapVC: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else { return nil }
        
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return nil }
        popVC.initData(forImage: imageArray[indexPath.row])
        
        previewingContext.sourceRect = view.frame
        
        return popVC
    }
    
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}



