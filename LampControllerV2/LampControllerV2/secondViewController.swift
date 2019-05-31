//
//  secondViewController.swift
//  LampControllerV2
//
//  Created by Chris Sainsbury on 17/1/19.
//  Copyright © 2019 Chris Sainsbury. All rights reserved.
//

import UIKit

class secondViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate{

    @IBOutlet weak var sleepNowButton: UIButton!
    @IBOutlet weak var sleepSet: UIButton!
    @IBOutlet weak var sleepText: UITextField!
    @IBOutlet weak var wakeSet: UIButton!
    @IBOutlet weak var wakeText: UITextField!
    @IBOutlet weak var transText: UITextField!
    let TCPConnection = try! Socket.create(family: .inet)
    let transOptions = ["Fast", "Standard", "Slow"]
    let defaults = UserDefaults.standard
    var pickerUserSelect = 1 //default value
    var sleepNowActive = false
    var connected = false
   
    @IBAction func sleepNowClick(_ sender: UIButton) {
        if(!sleepNowActive)
        {
            sender.setTitle("Undo Sleep Now", for: .normal)
            Util.TCPSend(message: "SN 180 100 100 10:00 1" ,TCPConnection: TCPConnection)
            print("sent TCP MSG: SN 180 100 100 10:00 1")
            sleepNowActive = true
            
        }
        else
        {
            sender.setTitle("Sleep Now!", for: .normal)
            Util.TCPSend(message: "SN 180 100 100 10:00 0" ,TCPConnection: TCPConnection)
            print("sent TCP MSG: SN 180 100 100 10:00 0")
            sleepNowActive = false
        }
    }
    
    
    @IBAction func sleepSetClick(_ sender: UIButton) {
        sleepSet.isHidden = true
        if let time = defaults.string(forKey: "savedSleep")
        {
            if(Util.TCPSend(message: "NT 180 100 100 "+time+" 1",TCPConnection: TCPConnection))
            {
                print("sent TCP MSG: NT 180 100 100 "+time+" 1")
            }
        }
        sleepText.resignFirstResponder()
    }
    
    @IBAction func wakeSetClick(_ sender: UIButton) {
        wakeSet.isHidden = true
        if let time = defaults.string(forKey: "savedWake")
        {
            if(Util.TCPSend(message: "MT 180 100 100 "+time+" 1",TCPConnection: TCPConnection))
            {
                print("sent TCP MSG: MT 180 100 100 "+time+" 1")
            }
        }
        wakeText.resignFirstResponder()
    }
    
    @IBAction func sleepTime(_ sender: UITextField) {
        let timePicker:UIDatePicker = UIDatePicker()
        timePicker.tag = 1
        timePicker.datePickerMode = UIDatePicker.Mode.time
        sender.inputView = timePicker
        timePicker.addTarget(self, action: #selector(secondViewController.handleDatePicker), for: UIControl.Event.valueChanged)
        sleepSet.isHidden = false
        wakeSet.isHidden = true
    }
    
    @IBAction func wakeTime(_ sender: UITextField) {
        let timePicker:UIDatePicker = UIDatePicker()
        timePicker.tag = 2
        timePicker.datePickerMode = UIDatePicker.Mode.time
        sender.inputView = timePicker
        timePicker.addTarget(self, action: #selector(secondViewController.handleDatePicker), for: UIControl.Event.valueChanged)
        wakeSet.isHidden = false
        sleepSet.isHidden = true
    }
    
    @IBAction func transTime(_ sender: UITextField) {
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        sender.inputView = pickerView
        pickerView.selectRow(pickerUserSelect, inComponent: 0, animated: true)
        wakeSet.isHidden = true
        sleepSet.isHidden = true
        
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
    return transOptions.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return transOptions[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        transText.text = transOptions[row]
        pickerUserSelect = row
        defaults.set(transitionToString(int: row), forKey: "transitionSpeed")
        if(Util.TCPSend(message: "TC 180 100 100 10:00 " + String(row) ,TCPConnection: TCPConnection))
        {
            print("sent TCP MSG: TC 180 100 100 10:00 " + String(row))
        }
        transText.resignFirstResponder()
        //send data
    }
    
    override func viewDidLoad() {
        sleepSet.isHidden = true
        wakeSet.isHidden = true
        self.navigationItem.title = "Sleep & Wake Time"
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        connected = defaults.bool(forKey: "connection")
        
        if let savedSleep = defaults.string(forKey: "savedSleep"){ //string to date, converted date, then string
            formatter.dateFormat = "HH:mm"
            let date = formatter.date(from: savedSleep)
            formatter.dateFormat = "hh:mm a"
            let dateString = formatter.string(from: date ?? formatter.date(from: "00:00 am")! )
            sleepText.text = dateString
        }
        if let savedWake = defaults.string(forKey: "savedWake"){
            formatter.dateFormat = "HH:mm"
            let date = formatter.date(from: savedWake)
            formatter.dateFormat = "hh:mm a"
            let dateString = formatter.string(from: date ?? formatter.date(from: "00:00 am")! )
            wakeText.text = dateString
        }
        if let savedTrans = defaults.string(forKey: "savedTrans"){
            transText.text = savedTrans
            pickerUserSelect = transitionToInt(string: savedTrans)
        }
        else {
            pickerUserSelect = 1
        }
        
        let serverPort = defaults.integer(forKey: "serverPort")
        if let serverIP = defaults.string(forKey: "serverIP")
        {
            if(connected)
            {
             if (!Util.TCPConnect(serverIP:serverIP, serverPort:Int32(serverPort),TCPConnection:TCPConnection))
                {
                    print("TCP connection error") // toast this to user
                    sleepNowActive = false
                    super.viewDidLoad()
                    return
                }
            print("TCP connection accepted")
            Util.TCPSend(message: "SQ 180 100 100 10:00 0" ,TCPConnection: TCPConnection)
            print("sent TCP MSG: SQ 180 100 100 10:00 0")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25)
                {
                    var message = Util.TCPRecieve(TCPConnection: self.TCPConnection)
                    if(message == "1")
                    {
                        self.sleepNowActive = true
                        self.sleepNowButton.setTitle("Undo Sleep Now", for: .normal)
                        print("sleep now query recieved 1")
                    }
                    else
                    {
                        self.sleepNowActive = false
                        print("sleep now query recieved 0")
                    }
                }
                
            }
            else
            {
                showToast(message: "Not Connected")
            }
            
        }
        
        

        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        if(Util.TCPSend(message: "XXXXXXXXXXXXXXXXXXXXXX", TCPConnection: TCPConnection))
        {
            TCPConnection.close()
            print("TCP connection closed")
        }
    }
    
    
    @objc func handleDatePicker(sender: UIDatePicker) {
        let formatter = DateFormatter()
        
        if sender.tag == 1 {
        formatter.dateFormat = "hh:mm a"
        sleepText.text = formatter.string(from: sender.date)
        formatter.dateFormat = "HH:mm" // save as 24 hour time
        defaults.set(formatter.string(from: sender.date), forKey: "savedSleep")
        
     
        }
        else if sender.tag == 2 {
        formatter.dateFormat = "hh:mm a"
        wakeText.text = formatter.string(from: sender.date)
        formatter.dateFormat = "HH:mm"
        defaults.set(formatter.string(from: sender.date), forKey: "savedWake")
        }
        
        
    }
    
    func transitionToInt(string: String) -> Int {
        if string == "fast" {
            return 2
        }
        else if string == "standard" {
            return 1
        }
        else if string == "slow" {
            return 0
        }
        else {
            return -1
        }
    }
    func transitionToString(int: Int) -> String {
        if int == 0 {
            return "slow"
        }
        else if int == 1 {
            return "standard"
        }
        else if int == 2 {
            return "fast"
        }
        else {
            return "error"
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
