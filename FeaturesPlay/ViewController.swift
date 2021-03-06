import UIKit
import MapKit
import Projection

class ViewController: UIViewController, MKMapViewDelegate {

    var mapView: MKMapView!
    var displayLink: CADisplayLink!
    var overlay: OverlayView!

    let maxAnnotationCount = 100

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        view.addSubview(mapView)

        displayLink = CADisplayLink(target: self, selector: "updateOverlayWithDisplayLink:")
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)

        overlay = OverlayView(frame: view.bounds, mapView: mapView)
        view.insertSubview(overlay, aboveSubview: mapView)

        mapView.addGestureRecognizer(UITapGestureRecognizer(target: overlay, action: "overlayTapWithGesture:"))

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            [unowned self] in
            let jsonData = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("fire-hydrants", ofType: "geojson")!)
            let jsonObject = NSJSONSerialization.JSONObjectWithData(jsonData!, options: nil, error: nil) as NSDictionary
            let hydrants = jsonObject["features"] as NSArray
            var annotations = NSMutableArray()
            for hydrant in hydrants {
                let properties = hydrant["properties"] as NSDictionary
                let annotation = MKPointAnnotation()
                annotation.title = properties["NAME"] as NSString
                annotation.subtitle = {
                    let description = properties["DESCRIPTIO"] as NSString
                    let parts = description.componentsSeparatedByString("<p")
                    return parts[0] as NSString
                }()
                annotation.coordinate = {
                    let geometry = hydrant["geometry"] as NSDictionary
                    let coordinates = geometry["coordinates"] as NSArray
                    return CLLocationCoordinate2DMake(coordinates[1] as Double, coordinates[0] as Double)
                }()
                if (annotations.count < self.maxAnnotationCount) {
                    annotations.addObject(annotation)
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                [unowned self] in
                if let mapView = self.mapView {
                    mapView.addAnnotations(annotations)
                    mapView.showAnnotations(mapView.annotations, animated: false)
                }
            }
        }
    }

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        view.image = UIImage() //imageWithColor(UIColor.redColor())

        return view
    }

    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        overlay.setNeedsDisplay()
    }

    func updateOverlayWithDisplayLink(displayLink: CADisplayLink!) {
        overlay.setNeedsDisplay()
    }

}

class OverlayView: UIView {

    var mapView: MKMapView!
    var debugLabel: UILabel!
    var lastTap: CGPoint!

    init(frame: CGRect, mapView: MKMapView) {
        super.init(frame: frame)

        userInteractionEnabled = false

        backgroundColor = UIColor.clearColor()

        self.mapView = mapView

        debugLabel = UILabel(frame: CGRect(x: 10, y: 30, width: 200, height: 50))
        debugLabel.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.9)
        debugLabel.textAlignment = .Center
        debugLabel.numberOfLines = 0
        self.addSubview(debugLabel)

        lastTap = CGPointZero
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func overlayTapWithGesture(gesture: UITapGestureRecognizer) {
        lastTap = gesture.locationInView(gesture.view)

        let tapCoordinate = mapView.convertPoint(lastTap, toCoordinateFromView: mapView)

        NSLog("MapKit lat/lon: %f, %f", tapCoordinate.latitude, tapCoordinate.longitude)
        NSLog("MKMapPoint: %f, %f", MKMapPointForCoordinate(tapCoordinate).y, MKMapPointForCoordinate(tapCoordinate).x)

        NSLog("===")

        NSLog("Projection point: %e, %e", Projection.Utilities.projectedMetersFromCoordinate(tapCoordinate).y, Projection.Utilities.projectedMetersFromCoordinate(tapCoordinate).x)

//        let foo = Projection.Sampler()




        NSLog("===")

        for (lat: Double, lon: Double) in [(85, -180), (45, -120), (0, 0), (-45, 120), (-85, 180)] {
            let p = Projection.Utilities.projectedMetersFromCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            NSLog("Projection of %f, %f: %e, %e", lat, lon, p.y, p.x)
        }




        NSLog("===")

//        NSLog("mapping scale: %f", <#args: CVarArgType#>...)




//        NSLog("1: 38.896725, -76.988960")
//        NSLog("m: %f, %f", MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: 38.896725, longitude: -76.988960)).x, MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: 38.896725, longitude: -76.988960)).y)
//        NSLog("1: 38, -76")
//        NSLog("m: %f, %f", MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: 38, longitude: -76)).x, MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: 38, longitude: -76)).y)





//        NSLog("MKMapPoints/m at 0N: %f at 45N: %f at 85N: %f", MKMapPointsPerMeterAtLatitude(0), MKMapPointsPerMeterAtLatitude(45), MKMapPointsPerMeterAtLatitude(85))


        let scale = mapView.visibleMapRect.size.width / MKMapSizeWorld.width


        NSLog("MapKit zoom scale: %f", Projection.Utilities.zoomForScale(scale))

//        NSLog("pixels at circumference: %f", pow(2, Projection.zoomForScale(scale)) * 256)

        NSLog("===")



        NSLog("MKMapSizeWorld: %f, %f", MKMapSizeWorld.width, MKMapSizeWorld.height)

        NSLog("===")

        let nw = MKMapPointForCoordinate(CLLocationCoordinate2DMake(85, -180))
        let se = MKMapPointForCoordinate(CLLocationCoordinate2DMake(-85, 180))

        NSLog("NW MKMapPoint: %f, %f", nw.y, nw.x)
        NSLog("SE MKMapPoint: %f, %f", se.y, se.x)

        NSLog("===")
        NSLog("===")

    }

    override func drawRect(rect: CGRect) {
        var annotations = mapView.annotations as [MKPointAnnotation]

        if (lastTap != CGPointZero) {
            let touchRect = CGRect(x: lastTap.x - 22, y: lastTap.y - 22, width: 44, height: 44)
            MKPointAnnotation.imageWithColor(UIColor.blackColor().colorWithAlphaComponent(0.5), diameter: 44).drawInRect(touchRect)

            let tapCoordinate = mapView.convertPoint(lastTap, toCoordinateFromView: mapView)
            let tapLocation = CLLocation(latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude)
            annotations = sortedAnnotations(annotations, location: tapLocation)

            let closestAnnotation = annotations.first!
            let p = closestAnnotation.convertedPointInMapView(mapView)
            let c = UIGraphicsGetCurrentContext()
            CGContextSetStrokeColorWithColor(c, UIColor.blackColor().CGColor)
            CGContextSetLineWidth(c, 3)
            CGContextSetLineCap(c, kCGLineCapRound)
            CGContextMoveToPoint(c, p.x, p.y)
            CGContextAddLineToPoint(c, lastTap.x, lastTap.y)
            CGContextStrokePath(c)
        }

        var visibleAnnotations = [(MKPointAnnotation, CGPoint, Int)]()
        var index = 0
        for annotation in annotations {
            let p = annotation.convertedPointInMapView(mapView)
            if (CGRectContainsPoint(rect, p)) {
                visibleAnnotations.append((annotation, p, index))
                index++
            }
        }

        let diameter: CGFloat = 40
        var drawDiameter: CGFloat
        var image: UIImage
        var blueImage = MKPointAnnotation.imageWithColor(UIColor.blueColor(), diameter: diameter)
        for (annotation, p, index) in visibleAnnotations {
            if (lastTap != CGPointZero) {
                if (index == 0) {
                    drawDiameter = diameter * 0.75
                    image = MKPointAnnotation.imageWithColor(UIColor.redColor(), diameter: diameter)
                } else {
                    drawDiameter = diameter * 0.75 - ((diameter / 2) * (CGFloat(index) / CGFloat(visibleAnnotations.count)))
                    image = blueImage
                }
            } else {
                drawDiameter = diameter * 0.75
                image = blueImage
            }
            let r = CGRect(x: p.x - drawDiameter / 2, y: p.y - drawDiameter / 2, width: drawDiameter, height: drawDiameter)
            image.drawInRect(r)
        }

        debugLabel.text = "Total: \(annotations.count)\nRendered: \(visibleAnnotations.count)"
    }

    func sortedAnnotations(annotations: [MKPointAnnotation], location: CLLocation) -> [MKPointAnnotation] {

        func defaultSorter(annotations: [MKPointAnnotation], location: CLLocation) -> [MKPointAnnotation] {
            return sorted(annotations) {
                let d1 = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude).distanceFromLocation(location)
                let d2 = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude).distanceFromLocation(location)
                return d1 < d2
            }
        }

        return defaultSorter(annotations, location)
    }

}

extension MKPointAnnotation {

    class func imageWithColor(color: UIColor, diameter: CGFloat = 20) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, UIScreen.mainScreen().scale)
        let c = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(c, color.colorWithAlphaComponent(0.5).CGColor)
        CGContextSetStrokeColorWithColor(c, color.CGColor)
        CGContextSetLineWidth(c, 1)
        CGContextAddEllipseInRect(c, CGRect(x: 0, y: 0, width: diameter, height: diameter))
        CGContextFillPath(c)
        CGContextStrokePath(c)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    func convertedPointInMapView(mapView: MKMapView) -> CGPoint {
        return mapView.convertCoordinate(self.coordinate, toPointToView: mapView)
    }

}
