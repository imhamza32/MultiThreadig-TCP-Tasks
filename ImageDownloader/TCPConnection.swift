//
//  TcpIP.swift
//  ImageDownloader
//
//  Created by Munib Hamza on 21/02/2023.
//

import Foundation
import Network

protocol TCPConnectionDelegate {
    func deviceStatusUpdated(isUpdated:Bool)
    func deviceSwitchToNetwork(deviceId:String)
    func TcpConnectionState(state:String,ip:String)
}

class TCPConnection {
    
    var delegate:TCPConnectionDelegate?
    var connection: NWConnection?
    
    final func start(host: NWEndpoint.Host, port : String) {
        connection = NWConnection(host: host, port: NWEndpoint.Port(port)!, using: .tcp)
        connection!.stateUpdateHandler = self.stateDidChange(to:)
        //        self.setupReceive()
        connection!.start(queue: .main)
    }
    
    func stateDidChange(to state: NWConnection.State) {
        let ipAddressWithPort = connection!.endpoint.debugDescription
        let ip = ipAddressWithPort.components(separatedBy: ":")
        switch state {
        case .setup:
            break
        case .waiting(let error):
            print("Errrooor",error)
            self.delegate?.TcpConnectionState(state: error.localizedDescription, ip: ip[0])
            //self.connectionDidFail(error: error)
        case .preparing:
            break
        case .ready:
            print("Readddy",connection?.endpoint.debugDescription as Any)
            
            print("IPAADERESS",ip[0])
            self.delegate?.TcpConnectionState(state: "Connected",ip: ip[0])
        case .failed(let error):
            print("FAiled",error)
            self.delegate?.TcpConnectionState(state: error.localizedDescription, ip: ip[0])
        case .cancelled:
            break
        }
        
    }
    
    func setupReceive(completionHandler: @escaping ([UIImage]) -> Void) {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, contentContext, isComplete, error) in
            if let data = data, !data.isEmpty {
                
                print("Received:", String(data: data, encoding: .utf8) as Any )
                
                if let images = unarchiveImages(data) {
                    completionHandler(images)
                }
                
                //                let stringData = String(data: data, encoding: .utf8)
                //                let data = stringData!.data(using: .utf8)
                //                do {
                //                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String:Any]
                //
                //
                //
                //
                //                    print("REsponseeeeData",json)
                //                }catch{
                //
                //                }
                
            }
            if isComplete {
                self.connectionDidEnd()
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive(completionHandler: completionHandler)
            }
        }
    }
    var didStopCallback: ((Error?) -> Void)? = nil
    private func connectionDidFail(error: Error) {
        print("connection did fail, error: \(error)")
        stop(error: error)
    }
    
    private func connectionDidEnd() {
        print("connection  did end")
        stop(error: nil)
    }
    private func stop(error: Error?) {
        connection!.stateUpdateHandler = nil
        connection!.cancel()
        if let didStopCallback = didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error)
        }
    }
    
    func sendStreamOriented(connection: NWConnection, data: Data) {
        connection.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("Errrorrrr",error)
                //  self.connectionDidFail(error: error)
            }
        }))
    }
    
    func sendEndOfStream(connection: NWConnection) {
        connection.send(content: nil, contentContext: .defaultStream, isComplete: true, completion: .contentProcessed({ error in
            if let error = error {
                print("Errrorrrr11111",error)
                // self.connectionDidFail(error: error)
            }
        }))
    }
    
    func sendData(data: Data?) {
        connection!.send(content: data, completion: .contentProcessed { (sendError) in
            if let sendError = sendError {
                print("\(sendError)")
            }
        })
        //        self.setupReceive(on: connection!)
    }
    
    func cancel() {
        connection!.cancel()
    }
    
    
}
