//
//  ViewControllerThree.swift
//  LampControllerV2
//
//  Created by Chris Sainsbury on 21/2/19.
//  Copyright © 2019 Chris Sainsbury. All rights reserved.
//

import UIKit

class thirdViewController: UIViewController {
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var hueSlider: UISlider!
    @IBOutlet weak var satSlider: UISlider!
    @IBOutlet weak var briSlider: UISlider!
    
    @IBOutlet weak var hLabel: UILabel!
    @IBOutlet weak var sLabel: UILabel!
    @IBOutlet weak var bLabel: UILabel!
    
    
    
    let TCPConnection = try! Socket.create(family: .inet)
    let defaults = UserDefaults.standard
    var bri = ""
    var sat = ""
    var hue = ""
    var connected = false

    @IBAction func hSliderChanged(_ sender: UISlider, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            var updatedValue = String(Int(sender.value))
            hLabel.text = updatedValue
            while(updatedValue.count < 3)
            {
                updatedValue = "0" + updatedValue
            }
            
            switch touchEvent.phase {
            case .began:
                break
            case .moved:
                switch segmentControl.selectedSegmentIndex
                {
                case 0:
                    defaults.set(updatedValue, forKey: "nHue")
                case 1:
                    defaults.set(updatedValue, forKey: "mHue")
                default:
                    defaults.set(updatedValue, forKey: "dHue")
                }
            
            // handle drag moved
            case .ended:
                hue = updatedValue
                switch segmentControl.selectedSegmentIndex
                {
                case 0:
                    bri = defaults.string(forKey: "nBri") ?? "000"
                    sat = defaults.string(forKey: "nSat") ?? "000"
                    if(Util.TCPSend(message: "NC " + hue + " " + sat + " " +  bri + " 10:00 1",TCPConnection: TCPConnection))
                    {
                        print("sent TCP MSG: NC " + hue + " " + sat + " " +  bri + " 10:00 1")
                    }
                case 1:
                    bri = defaults.string(forKey: "mBri") ?? "000"
                    sat = defaults.string(forKey: "mSat") ?? "000"

                    if(Util.TCPSend(message: "MC " + hue + " " + sat + " " +  bri + " 10:00 1",TCPConnection: TCPConnection))
                    {
                        print("sent TCP MSG: MC " + hue + " " + sat + " " +  bri + " 10:00 1")
                    }
                default:
                    bri = defaults.string(forKey: "dBri") ?? "000"
                    sat = defaults.string(forKey: "dSat") ?? "000"
                    if(Util.TCPSend(message: "DC " + hue + " " + sat + " " +  bri + " 10:00 1",TCPConnection: TCPConnection))
                    {
                        print("sent TCP MSG: DC " + hue + " " + sat + " " +  bri + " 10:00 1")
                    }
            }

            default:
                break
            }
        }
    }
    
    @IBAction func sSliderChanged(_ sender: UISlider, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            var updatedValue = String(Int(sender.value))
            sLabel.text = updatedValue
            while(updatedValue.count < 3)
            {
                updatedValue = "0" + updatedValue
            }
            switch touchEvent.phase {
            case .began:
                break
            case .moved:
                switch segmentControl.selectedSegmentIndex
                {
                case 0:
                    defaults.set(updatedValue, forKey: "nSat")
                case 1:
                    defaults.set(updatedValue, forKey: "mSat")
                default:
                    defaults.set(updatedValue, forKey: "dSat")
                }
                
            // handle drag moved
            case .ended:
                sat = updatedValue
                switch segmentControl.selectedSegmentIndex
                {
                case 0:
                    bri = defaults.string(forKey: "nBri") ?? "000"
                    hue = defaults.string(forKey: "nHue") ?? "000"
                    if(Util.TCPSend(message: "NC " + hue + " " + sat + " " +  bri + " 10:00 1",TCPConnection: TCPConnection))
                    {
                        print("sent TCP MSG: NC " + hue + " " + sat + " " +  bri + " 10:00 1")
                    }
                case 1:
                    bri = defaults.string(forKey: "mBri") ?? "000"
                    hue = defaults.string(forKey: "mHue") ?? "000"
                    if(Util.TCPSend(message: "MC " + hue + " " + sat + " " +  bri + " 10:00 1",TCPConnection: TCPConnection))
                    {
                        print("sent TCP MSG: MC " + hue + " " + sat + " " +  bri + " 10:00 1")
                    }
                default:
                    bri = defaults.string(forKey: "dBri") ?? "000"
                    hue = defaults.string(forKey: "dHue") ?? "000"
                    if(Util.TCPSend(message: "DC " + hue + " " + sat + " " +  bri + " 10:00 1",TCPConnection: TCPConnection))
                    {
                        print("sent TCP MSG: DC " + hue + " " + sat + " " +  bri + " 10:00 1")
                    }
                }

            default:
                break
            }
        }
    }
    
    @IBAction func bSliderChanged(_ sender: UISlider, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            var updatedValue = String(Int(sender.value))
            bLabel.text = updatedValue
            while(updatedValue.count < 3)
            {
                updatedValue = "0" + updatedValue
            }
            
            switch touchEvent.phase {
            case .began:
                break
            case .moved:
                switch segmentControl.selectedSegmentIndex
                {
                case 0:
                    defaults.set(updatedValue, forKey: "nBri")
                case 1:
                    defaults.set(updatedValue, forKey: "mBri")
                default:
                    defaults.set(updatedValue, forKey: "dBri")
                }
                
            // handle drag moved
            case .ended:
                bri = updatedValue
                switch segmentControl.selectedSegmentIndex
                {
                case 0:
                    sat = defaults.string(forKey: "nSat") ?? "000"
                    hue = defaults.string(forKey: "nHue") ?? "000"
                    if(Util.TCPSend(message: "NC " + hue + " " + sat + " " +  bri + " 10:00 1",TCPConnection: TCPConnection))
                    {
                        print("sent TCP MSG: NC " + hue + " " + sat + " " +  bri + " 10:00 1")
                    }
                case 1:
                    sat = defaults.string(forKey: "mSat") ?? "000"
                    hue = defaults.string(forKey: "mHue") ?? "000"
                    if(Util.TCPSend(message: "MC " + hue + " " + sat + " " +  bri + " 10:00 1",TCPConnection: TCPConnection))
                    {
                        print("sent TCP MSG: MC " + hue + " " + sat + " " +  bri + " 10:00 1")
                    }
                default:
                    sat = defaults.string(forKey: "dSat") ?? "000"
                    hue = defaults.string(forKey: "dHue") ?? "000"
                    if(Util.TCPSend(message: "DC " + hue + " " + sat + " " +  bri + " 10:00 1",TCPConnection: TCPConnection))
                    {
                        print("sent TCP MSG: DC " + hue + " " + sat + " " +  bri + " 10:00 1")
                    }
                }
                
            default:
                break
            }
        }
    }

    
    override func viewDidLoad() {
        let serverPort = defaults.integer(forKey: "serverPort")
        connected = defaults.bool(forKey: "connection")
        if let serverIP = defaults.string(forKey: "serverIP")
        {
            if(connected)
            {
                if (!Util.TCPConnect(serverIP:serverIP, serverPort:Int32(serverPort),TCPConnection:TCPConnection))
                {
                    print("TCP connection error") // toast this to user
                    super.viewDidLoad()
                    return
                }
                print("TCP connection accepted")
            }
            else
            {
                showToast(message: "Not Connected")
            }
        }
        super.viewDidLoad()
        self.navigationItem.title = "Colour Settings"

        // Do any additional setup after loading the view.
    }
    override func viewWillDisappear(_ animated: Bool) {
        if(Util.TCPSend(message: "XXXXXXXXXXXXXXXXXXXXXX", TCPConnection: TCPConnection))
        {
            TCPConnection.close()
            print("TCP connection closed")
        }
        super.viewWillDisappear(animated)

    }
    @IBAction func IndexChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex
        {
        case 0:
            if let nHue = defaults.string(forKey: "nHue"){
                hLabel.text = nHue
                
                hueSlider.setValue(Float(nHue) ?? 180.00, animated: true)
            }
            if let nBri = defaults.string(forKey: "nBri"){
                bLabel.text = nBri
                briSlider.setValue(Float(nBri) ?? 50.00, animated: true)
            }
            if let nSat = defaults.string(forKey: "nSat"){
                sLabel.text = nSat
                satSlider.setValue(Float(nSat) ?? 50.00, animated: true)
            }
        case 1:
            if let mHue = defaults.string(forKey: "mHue"){
                hLabel.text = mHue
                hueSlider.setValue(Float(mHue) ?? 180.00, animated: true)
            }
            if let mBri = defaults.string(forKey: "mBri"){
                bLabel.text = mBri
                
                briSlider.setValue(Float(mBri) ?? 50.00, animated: true)
            }
            if let mSat = defaults.string(forKey: "mSat"){
                sLabel.text = mSat
                satSlider.setValue(Float(mSat) ?? 50.00, animated: true)
            }
        default:
            if let dHue = defaults.string(forKey: "dHue"){
                hLabel.text = dHue
                hueSlider.setValue(Float(dHue) ?? 180.00, animated: true)
            }
            if let dBri = defaults.string(forKey: "dBri"){
                bLabel.text = dBri
                briSlider.setValue(Float(dBri) ?? 50.00, animated: true)
            }
            if let dSat = defaults.string(forKey: "dSat"){
                sLabel.text = dSat
                satSlider.setValue(Float(dSat) ?? 50.00, animated: true)
            }
            
        }
        
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
