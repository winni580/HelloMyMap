//
//  ViewController.swift
//  HelloMyMap
//
//  Created by winni on 2018/6/6.
//  Copyright © 2018年 winni. All rights reserved.
//

import UIKit
import MapKit//地圖
import CoreLocation//定位

class ViewController: UIViewController{

    @IBAction func userTrackingModeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            mainMapView.userTrackingMode = .none
        case 1:
            mainMapView.userTrackingMode = .follow
        case 2:
            mainMapView.userTrackingMode = .followWithHeading
        default:
            mainMapView.userTrackingMode = .none
        }
        
    }
    @IBAction func mapTypeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            mainMapView.mapType = .standard
        case 1:
            mainMapView.mapType = .satellite
        case 2:
            mainMapView.mapType = .hybrid
        case 3:
            mainMapView.mapType = .satelliteFlyover
            
            let coordinate = CLLocationCoordinate2DMake(35.710063, 139.8107)
            let crmera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: 800, pitch: 65, heading: 0)
            mainMapView.camera = crmera
            
        default:
            mainMapView.mapType = .standard
        }
    }
    @IBOutlet weak var mainMapView: MKMapView!
    
   
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mainMapView.delegate = self//這行沒打 我們移動地圖 不會有反應所以在DidLoad裡打
        
        
        //Ask user's permission P26頁
        locationManager.requestAlwaysAuthorization()
        
        //Background location update support.
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        //下面是檢查user有們有授權
        guard CLLocationManager.locationServicesEnabled()
            else{
                //Show hint to user....
                return
        }
        
        guard CLLocationManager.authorizationStatus() == .authorizedAlways
            else{
                //Show hint to user...
                return
        }
        //Prepare locationManager
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .automotiveNavigation//告訴系統活動總類是什麼 讓ＧＰＳ開關時間調整 讓手機續航力提高
        // locationManager.distanceFilter = 20.0//移動20米就會回報,20米內不回報
        locationManager.startUpdatingLocation()//自動回報位置
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let location = locationManager.location else{
            print("Location is not ready.")
            return
        }
        //aa下面是要設定 店家很多 距離user 3公里才秀出來
        //Demo how to show annotation view only when it is not too far form user
        let stores = [CLLocation(latitude:24.987, longitude:121.510),
                      CLLocation(latitude:24.887, longitude:121.410),
                      CLLocation(latitude:24.900, longitude:121.610)]
        for storeLocation in stores{
            //Check if the distance of each store.
            guard location.distance(from: storeLocation) < 3000
                else {
                    continue
            }
        }
        //aa
        
        
        
        // Add a annotationView at a fake place. 虛擬一個位置
        var storeCoordinate = location.coordinate
        storeCoordinate.latitude += 0.005
        storeCoordinate.longitude += 0.005
        
        //let annotation = MKPointAnnotation()
        let annotation = StoreAnnotation()
        annotation.coordinate = storeCoordinate
        annotation.title = "啃德雞"
        annotation.subtitle = "真好吃"
        annotation.storeID = 123456
        annotation.storeType = StoreType.seven
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){//一秒鐘後再執行 裡面 大頭針插上去的動作
             self.mainMapView.addAnnotation(annotation)
        }
    
        
        // Move and zoom the map to the storecoordinate.
        let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        let region = MKCoordinateRegion(center: storeCoordinate, span: span)
        mainMapView.setRegion(region, animated: false)
        
        //a)0.001看到範圍變小
        //a)0,01 看到範圍更大

        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController: CLLocationManagerDelegate{
    //MARK: - CLLocationManagerDelegate methods.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {//CLLocation不只用來提供經緯度
        //coordinat 是用來拿經緯度的
        guard let coordinate = locations.last?.coordinate//locations是allary
            else{
                assertionFailure("Invalid coordinate.")//assertionFailure 方便於做Debug如果有跑進來代表有問題 他會卡住
                return
        }
        print("Coordinate:\(coordinate.latitude).\(coordinate.longitude)")
        
    }
    
}
extension ViewController:MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let region = mapView.region
        print("Center:\(region.center.latitude),\(region.center.longitude)")
        print("Region:\(region.span.latitudeDelta),\(region.span.longitudeDelta)")
        
    }
    
    //下面是把地圖上標誌 換回大頭針形狀的
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
       
        if annotation is MKUserLocation{// is 用來判斷型別 這裡是說其實系統圖除了我們設定的大頭針 還有一個藍點點 是userlocation
            return nil
        }
        guard let annotation = annotation as?
            StoreAnnotation else{
                assertionFailure("Fail to cast the annotation.")
                return nil
        }
        print("\(annotation.storeID),\(annotation.storeType)")
       
        
        let identifier = "Store" // 幫AnnotationView 取名字 叫Store
        var result = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        //這邊做一個轉型dequeueReusableAnnotationView 轉MKPinAnnotationView
        if result == nil {
            //Creat one if no exist one.
            result = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        else{result?.annotation = annotation
            
        }
        result?.canShowCallout = true//地圖點下去出現的泡泡 是canShowCallout
   //  result?.pinTintColor = .blue//大頭針變藍色
//    result?.animatesDrop = true//強調某一個點 吸引 user 目光
        
//下面是將地圖大頭針換成自己的圖 1.把127行 的（as? MKPinAnnotationView）刪掉
        //2.把131行 MKPinAnnotationView 里的  Pin刪掉
        //3.助解掉 137 138 行 敲 143 144 行換成自己的圖案即可
      let image = UIImage(named: "pointRed.png")
      result?.image = image
        
        
        // Prepare left-callout accessory view.
        result?.leftCalloutAccessoryView = UIImageView(image: image)
        
        //Prepare right-callout accessory view
        let button = UIButton(type: .detailDisclosure)
        button.addTarget(self, action: #selector(callOutBtnTapped(sender:)),
                         for: .touchUpInside)
        result?.rightCalloutAccessoryView = button
        
      return result
}
    @objc
    func callOutBtnTapped(sender: Any){
        print("callOutBtnTapped!")
    }
    
}
enum StoreType {
    case none
    case hilife
    case family
    case seven
    
}

class StoreAnnotation: MKPointAnnotation {
    var storeID = -1
    var storeType = StoreType.none
}






