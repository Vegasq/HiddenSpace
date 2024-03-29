//
//  Client.swift
//  jimmy
//
//  Created by Jonathan Foucher on 16/02/2022.
//

import Foundation
import Network

class Client {
    let connection: ClientConnection
    let host: NWEndpoint.Host
    let port: NWEndpoint.Port
    
    var responseReceived = false
    let timeoutInterval: TimeInterval = 10 // Timeout after 10 seconds

    var dataReceivedCallback: ((NWError?, Data?, Int, String) -> Void)? = nil
    
    init(host: String, port: UInt16, validateCert: Bool) {
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port)!
        
        let tlsopts = NWProtocolTLS.Options()
        
        sec_protocol_options_set_peer_authentication_required(tlsopts.securityProtocolOptions, validateCert)
        
        let params = NWParameters(tls: tlsopts, tcp: NWProtocolTCP.Options())
    
        let nwConnection = NWConnection(host: self.host, port: self.port, using: params)
        self.connection = ClientConnection(nwConnection: nwConnection)
    }
    
    
    func start() {
        print("Client started \(host) \(port)")
        connection.didStopCallback = didStopCallback(error:message:statusCode:contentType:)
        connection.start()
    }

    func stop() {
        connection.stop()
    }

    func send(data: Data) {
        connection.send(data: data)
        startTimeoutCountdown()
    }

    func didStopCallback(error: NWError?, message: Data?, statusCode: Int, contentType: String) {
        responseReceived = true
        if let dataReceivedCallback = self.dataReceivedCallback {
            dataReceivedCallback(error, message, statusCode, contentType);
            self.dataReceivedCallback = nil;
        }
    }

    private func startTimeoutCountdown() {
        responseReceived = false
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval) {
            self.checkForTimeout()
        }
    }

    private func checkForTimeout() {
        if !responseReceived {
            self.stop() // stop the connection
            self.didStopCallback(error: NWError.posix(POSIXErrorCode.ETIMEDOUT), message: nil, statusCode: 408, contentType: "timeout")
        }
    }
}
