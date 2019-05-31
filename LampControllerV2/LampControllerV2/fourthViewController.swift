//
//  fourthViewController.swift
//  LampControllerV2
//
//  Created by Chris Sainsbury on 8/5/19.
//  Copyright © 2019 Chris Sainsbury. All rights reserved.
//

import UIKit

class fourthViewController: UIViewController {
    
    @IBAction func manualControlToggle(_ sender: UISwitch) {
        if(toggle == 1)
        {
            manualControlToggle.setOn(false, animated: true)
            toggle = 0
            defaults.set(toggle, forKey: "manualEnabled")

                let message = "MA " + manHue + " " + manSat + " " +  manBri + " 10:00 " + String(toggle)
                if(Util.TCPSend(message: message,TCPConnection: TCPConnection))
                {
                    print("sent TCP MSG: MA " + manHue + " " + manSat + " " +  manBri + " 10:00 " + String(toggle))
                }
        }
        else
        {
            manualControlToggle.setOn(true, animated: true)
            toggle = 1
            defaults.set(toggle, forKey: "manualEnabled")
            manHue = defaults.string(forKey: "manHue") ?? "180"
            manSat = defaults.string(forKey: "manSat") ?? "050"
            manBri = defaults.string(forKey: "manBri") ?? "050"

                let message = "MA " + manHue + " " + manSat + " " +  manBri + " 10:00 " + String(toggle)
                if(Util.TCPSend(message: message,TCPConnection: TCPConnection))
                {
                    print("sent TCP MSG: MA " + manHue + " " + manSat + " " +  manBri + " 10:00 " + String(toggle))
                }

        }
    }
    
    @IBOutlet weak var manualControlToggle: UISwitch!
    @IBOutlet weak var hSlider: UISlider!
    @IBOutlet weak var sSlider: UISlider!
    @IBOutlet weak var bSlider: UISlider!
    @IBOutlet weak var hLabel: UILabel!
    @IBOutlet weak var sLabel: UILabel!
    @IBOutlet weak var bLabel: UILabel!
    var manHue = "000"
    var manSat = "000"
    var manBri = "000"
    var toggle = 0
    let TCPConnection = try! Socket.create(family: .inet)
    let defaults = UserDefaults.standard
    var connected = false
    
    @IBAction func hSliderChanged(_ sender: UISlider, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                break
            case .moved:
                var updatedValue = String(Int(sender.value))
                hLabel.text = updatedValue
                while(updatedValue.count < 3)
                {
                    updatedValue = "0" + updatedValue
                }
                    defaults.set(updatedValue, forKey: "manHue")

                
            // handle drag moved
            case .ended:
                manHue = defaults.string(forKey: "manHue") ?? "180"
                manSat = defaults.string(forKey: "manSat") ?? "050"
                manBri = defaults.string(forKey: "manBri") ?? "050"
                if(toggle == 1)
                {
                    let message = "MA " + manHue + " " + manSat + " " +  manBri + " 10:00 " + String(toggle)
                    if(Util.TCPSend(message: message,TCPConnection: TCPConnection))
                    {
                        print("sent TCP MSG: MA " + manHue + " " + manSat + " " +  manBri + " 10:00 " + String(toggle))
                    }
                }

            default:
                break
                }
            }
        }
    
    @IBAction func sSliderChanged(_ sender: UISlider, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                break
            case .moved:
                var updatedValue = String(Int(sender.value))
                sLabel.text = updatedValue
                while(updatedValue.count < 3)
                {
                    updatedValue = "0" + updatedValue
                }
                defaults.set(updatedValue, forKey: "manSat")
                
                
            // handle drag moved
            case .ended:
                manHue = defaults.string(forKey: "manHue") ?? "180"
                manSat = defaults.string(forKey: "manSat") ?? "050"
                manBri = defaults.string(forKey: "manBri") ?? "050"
                if(toggle == 1)
                {
                    let message = "MA " + manHue + " " + manSat + " " +  manBri + " 10:00 " + String(toggle)
                    if(Util.TCPSend(message: message,TCPConnection: TCPConnection))
                    {
                        print("sent TCP MSG: MA " + manHue + " " + manSat + " " +  manBri + " 10:00 " + String(toggle))
                    }
                }

            default:
                break
            }
        }
    }
    @IBAction func bSliderChanged(_ sender: UISlider, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                break
            case .moved:
                var updatedValue = String(Int(sender.value))
                bLabel.text = updatedValue
                while(updatedValue.count < 3)
                {
                    updatedValue = "0" + updatedValue
                }
                defaults.set(updatedValue, forKey: "manBri")
                
                
            // handle drag moved
            case .ended:
                manHue = defaults.string(forKey: "manHue") ?? "180"
                manSat = defaults.string(forKey: "manSat") ?? "050"
                manBri = defaults.string(forKey: "manBri") ?? "050"
                if(toggle == 1)
                {
                    let message = "MA " + manHue + " " + manSat + " " +  manBri + " 10:00 " + String(toggle)
                    if(Util.TCPSend(message: message,TCPConnection: TCPConnection))
                    {
                        print("sent TCP MSG: MA " + manHue + " " + manSat + " " +  manBri + " 10:00 " + String(toggle))
                    }
                }

            default:
                break
            }
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Manual Control"
        let serverPort = defaults.integer(forKey: "serverPort")
        connected = defaults.bool(forKey: "connection")
        manHue = defaults.string(forKey: "manHue") ?? "180"
        manSat = defaults.string(forKey: "manSat") ?? "050"
        manBri = defaults.string(forKey: "manBri") ?? "050"
        toggle = defaults.integer(forKey: "manualEnabled")
        hSlider.setValue(Float(manHue) ?? 0.00, animated: true)
        sSlider.setValue(Float(manSat) ?? 0.00, animated: true)
        bSlider.setValue(Float(manBri) ?? 0.00, animated: true)
        
        if(toggle == 1)
        {
            manualControlToggle.setOn(true, animated: true)
        }
        else
        {
           manualControlToggle.setOn(false, animated: true)
        }

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
                print("sent TCP MSG: MQ 180 050 050 10:00 0")
                print("Manual query recieved 0")
                Util.TCPSend(message: "MQ 180 100 100 10:00 0" ,TCPConnection: TCPConnection)
                /*DispatchQueue.main.asyncAfter(deadline: .now() + 0.25)
                {
                    var message = Util.TCPRecieve(TCPConnection: self.TCPConnection)
                    //self.showToast(message: "doing stuff in 025 secs")
                    if(message == "1")
                    {
                        self.toggle = 1
                        self.manualControlToggle.setOn(true, animated: true)
                        print("manual query recieved 1")
                    }
                    else
                    {
                        self.toggle = 0
                        self.manualControlToggle.setOn(false, animated: true)
                    }
                }*/
            }
            else
            {
                showToast(message: "Not Connected")
            }
        }

        

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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
