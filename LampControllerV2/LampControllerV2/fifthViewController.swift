//
//  fifthViewController.swift
//  LampControllerV2
//
//  Created by Chris Sainsbury on 9/4/19.
//  Copyright © 2019 Chris Sainsbury. All rights reserved.
//

import UIKit

class fifthViewController: UIViewController
{
    var TCPConnection = try! Socket.create(family: .inet)
    let defaults = UserDefaults.standard
    var hubConnected = false
    var LIFXConnected = false
    @IBOutlet weak var hubLabel: UILabel!
    @IBOutlet weak var LIFXLabel: UILabel!
    @IBOutlet weak var hubImage: UIImageView!
    @IBOutlet weak var LIFXImage: UIImageView!
    @IBAction func connectToHub(_ sender: UIButton)
    {
        TCPConnection = try! Socket.create(family: .inet)
        try! TCPConnection.setReadTimeout(value: UInt(5))
        let (serverIP, serverPort) = Util.UDPBroadCast()
        if(serverPort != 0)
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
            {
                (self.hubConnected,self.LIFXConnected) = Util.TCPHubInitialise(serverIP:serverIP, serverPort:serverPort, TCPConnection: self.TCPConnection)
                self.defaults.set(serverIP, forKey: "serverIP")
                self.defaults.set(serverPort, forKey: "serverPort")
                if(self.hubConnected)
                {
                    self.hubImage.image = UIImage(named: "tick1")
                }
                else
                {
                  self.hubImage.image = UIImage(named: "cross1")
                }
                if(self.LIFXConnected)
                {
                    self.LIFXImage.image = UIImage(named: "tick1")
                    self.defaults.set(true, forKey: "connection")
                }
                else
                {
                   self.LIFXImage.image = UIImage(named: "cross1")
                   self.defaults.set(false, forKey: "connection")
                }
            }
        }
        else
        {
          hubImage.image = UIImage(named: "cross1")
          LIFXImage.image = UIImage(named: "cross1")
          self.defaults.set(false, forKey: "connection")
        }
    }
    override func viewDidLoad()
    {
        self.navigationItem.title = "Connect Devices"
        
        super.viewDidLoad()
    }
}
