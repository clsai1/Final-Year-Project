//
//  network_util.swift
//  LampControllerV2
//
//  Created by Chris Sainsbury on 12/4/19.
//  Copyright © 2019 Chris Sainsbury. All rights reserved.
//

import Foundation
class Util
{
    class func UDPBroadCast() -> (serverIP: String, serverPort: Int32)
    {
        let UDPAddr = Socket.createAddress(for: "255.255.255.255", on: 56701)
        let UDPconnection = try! Socket.create(family: .inet, type: .datagram, proto: .udp)
        try! UDPconnection.udpBroadcast(enable: true)
        do
        {
            try UDPconnection.write(from: "CS.UDP.discovery", to: UDPAddr!)
        }
        catch
        {
            print("UDP Send error")
            return ("",0)
        }
        try! UDPconnection.setReadTimeout(value: UInt(5000))
        try? UDPconnection.listen(on: Int(56701))
        var data = Data()
        let (bytesRead, address) = try! UDPconnection.readDatagram(into: &data) //read data from UDP connection
        var response = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        if(response == "CS.UDP.discoveryACK")
        {
            
            var (HostIP, HostPort) = Socket.hostnameAndPort(from: address!)!
            print("server discovered with IP: " + HostIP )
            UDPconnection.close()
            return (HostIP, HostPort)
        }
        else
        {
            print("UDP receive ack failure")
            return ("", 0)
        }
    }

    
    class func TCPHubInitialise(serverIP:String, serverPort:Int32,TCPConnection:Socket) -> (hubConnected: Bool, LIFXConnected: Bool)
    {
        var hubConnected = false
        var LIFXConnected = false
        //let signature = try! Socket.Signature(protocolFamily: .inet, socketType: .stream, proto: .tcp, hostname: serverIP, port: 56702)!
        do
        {
            try TCPConnection.connect(to: serverIP, port: 56702, timeout: 10)
            print("passcode sent to server...")
        }
        catch
        {
        print("TCP connect error")
        return (hubConnected, LIFXConnected)
        }
        hubConnected = true //if error not caught, hub is connected
        let msg = "CS.TCP.123456"
        try? TCPConnection.write(from: msg)
        var data = Data()
        try? TCPConnection.read(into: &data)
        var response = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        if(response == "CS.TCP.CONNECTED")
        {
            LIFXConnected = true
            print("LIFX and server connected")
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2)
        {
            TCPConnection.close()
            print("closing TCP discovery connection")
            
        }
        return (hubConnected, LIFXConnected)
    }
    class func TCPConnect(serverIP:String, serverPort:Int32,TCPConnection:Socket) -> Bool
    {
        let signature = try! Socket.Signature(protocolFamily: .inet, socketType: .stream, proto: .tcp, hostname: serverIP, port: 56702)!
        do
        {
            try TCPConnection.connect(to: serverIP, port: 56702, timeout: 10)
        }
        catch
        {
            print("TCP connect error")
            return false
        }
        return true
    }
    
    class func TCPSend(message: String,TCPConnection:Socket) -> Bool
    {
        do
        {
            try TCPConnection.write(from: message)
        }
        catch
        {
            print("TCP send error")
            return false
        }
        return true
    }
    class func TCPRecieve(TCPConnection: Socket) -> String
    {   var data = Data()
        try? TCPConnection.read(into: &data)
        var response = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        return String(response ?? "0")
    }
    
}

