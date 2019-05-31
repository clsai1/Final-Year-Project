//
//  ViewController.swift
//  LampControllerV2
//
//  Created by Chris Sainsbury on 15/1/19.
//  Copyright © 2019 Chris Sainsbury. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var CircleOverhead: UIView!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var button4: UIButton!
    
    @IBAction func actionPanels(_ sender: UIButton) {
            switch sender.tag
            {
            case 1:
                break
            case 2:
                break
            case 3:
                break
            case 4:
                break
            default:
                break
            }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button1.layer.cornerRadius = 25.0
        button1.layer.masksToBounds = false
        button1.layer.shadowColor = UIColor.black.cgColor
        button1.layer.shadowOffset = CGSize(width: 0, height: 2)
        button1.layer.shadowRadius = 3
        button1.layer.shadowOpacity = 0.7
        
        button2.layer.cornerRadius = 25.0
        button2.layer.masksToBounds = false
        button2.layer.shadowColor = UIColor.black.cgColor
        button2.layer.shadowOffset = CGSize(width: 0, height: 2)
        button2.layer.shadowRadius = 3
        button2.layer.shadowOpacity = 0.7
        
        button3.layer.cornerRadius = 25.0
        button3.layer.masksToBounds = false
        button3.layer.shadowColor = UIColor.black.cgColor
        button3.layer.shadowOffset = CGSize(width: 0, height: 2)
        button3.layer.shadowRadius = 3
        button3.layer.shadowOpacity = 0.7
        
        button4.layer.cornerRadius = 25.0
        button4.layer.masksToBounds = false
        button4.layer.shadowColor = UIColor.black.cgColor
        button4.layer.shadowOffset = CGSize(width: 0, height: 2)
        button4.layer.shadowRadius = 3
        button4.layer.shadowOpacity = 0.7
    
        
        //add circle overhead
        
        CircleOverhead.setNeedsLayout()
        CircleOverhead.layoutIfNeeded()
        let circleWidth = CircleOverhead.bounds.size.height*1.5
        let circleHeight = CircleOverhead.bounds.size.height
        let circleXPosition = CircleOverhead.bounds.size.width/2 - circleWidth/2
        let circleYPosition = -circleHeight*0.65
        let circlePath = UIBezierPath(ovalIn: CGRect(x: circleXPosition,
                                                     y: circleYPosition,
                                                     width: circleWidth,
                                                     height: circleHeight))
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        
        //change the fill color
        shapeLayer.fillColor = UIColor.orange.cgColor
        //you can change the stroke color
        shapeLayer.strokeColor = UIColor.orange.cgColor
        //you can change the line width
        shapeLayer.lineWidth = 3.0
        
        CircleOverhead.layer.insertSublayer(shapeLayer,at: 0)
        
        
        //button titles
        button1.contentEdgeInsets = UIEdgeInsets(top: 12,left: 12,bottom: 12,right: 12)
        button2.contentEdgeInsets = UIEdgeInsets(top: 12,left: 12,bottom: 12,right: 12)
        button3.contentEdgeInsets = UIEdgeInsets(top: 12,left: 12,bottom: 12,right: 12)
        button4.contentEdgeInsets = UIEdgeInsets(top: 12,left: 12,bottom: 12,right: 12)
        
        
       
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    


}
extension UIViewController {
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-300, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.red
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 30.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    } }

