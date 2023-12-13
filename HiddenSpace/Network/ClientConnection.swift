//
//  ClientConnection.swift
//  jimmy
//
//  Created by Jonathan Foucher on 16/02/2022.
//  Updated by Nick Yakovliev on 13/12/2023
//


import Foundation
import Network



class ClientConnection {
    
    let nwConnection: NWConnection
    let queue = DispatchQueue(label: "Client connection Q")
    
    var read: String
    
    var data: Data
    
    init(nwConnection: NWConnection) {
        self.nwConnection = nwConnection
        self.read = ""
        self.data = Data()
    }
    
    var didStopCallback: ((NWError?, String, Int, String) -> Void)? = nil
    
    func start() {
        nwConnection.stateUpdateHandler = stateDidChange(to:)
        setupReceive()
        nwConnection.start(queue: queue)
    }
    
    private func stateDidChange(to state: NWConnection.State) {
        switch state {
            case .waiting(let error):
                connectionDidFail(error: error)
            case .ready:
                print("Client connection ready")
            case .failed(let error):
                connectionDidFail(error: error)
            default:
                break
        }
    }
    
    private func setupReceive() {
        nwConnection.receive(minimumIncompleteLength: 0, maximumLength: 65536) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                self.data += data
            }
            
            if isComplete {
                self.connectionDidEnd()
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive()
            }
        }
    }
    
    func send(data: Data) {
        nwConnection.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
        }))
    }
    
    func stop() {
        stop(error: nil, message: "", statusCode: 0, contentType: "")
    }
    
    private func connectionDidFail(error: NWError) {
        self.stop(error: error, message: "", statusCode: 0, contentType: "")
    }
    
    private func connectionDidEnd() {
        let (statusCode, contentType, message) = processStatusCode(data: self.data)
        handleStatusCode(statusCode, message: message)
        self.stop(error: nil, message: message, statusCode: statusCode!, contentType: contentType)
    }

    private func handleStatusCode(_ statusCode: Int?, message: String?) {
        guard let statusCode = statusCode else {
            print("Error: Unable to process status code.")
            return
        }

        switch statusCode {
        case 10...19:
            print("Input expected. Message: \(message ?? "")")
            // Handle input
        case 20...29:
            print("Success. Content type: \(message ?? "")")
            // Handle successful response
        case 30...39:
            print("Redirection. New URI: \(message ?? "")")
            // Handle redirection
        case 40...49:
            print("Temporary failure. Message: \(message ?? "")")
            // Handle temporary failure
        case 50...59:
            print("Permanent failure. Message: \(message ?? "")")
            // Handle permanent failure
        case 60...69:
            print("Client certificate required. Message: \(message ?? "")")
            // Handle client certificate request
        default:
            print("Unknown status code: \(statusCode)")
        }
    }

    
    private func stop(error: NWError?, message: String, statusCode: Int, contentType: String) {
        self.nwConnection.stateUpdateHandler = nil
        self.nwConnection.cancel()
        if let didStopCallback = self.didStopCallback {
            didStopCallback(error, message, statusCode, contentType)
            self.didStopCallback = nil
        }
    }
    
    func processStatusCode(data: Data) -> (statusCode: Int?, conentType: String, message: String) {
        guard let response = String(data: data, encoding: .utf8) else {
            return (nil, "", "Invalid response encoding")
        }
        
        let firstLine = response.split(separator: "\r\n", maxSplits: 1, omittingEmptySubsequences: true)[0];
        let components = firstLine.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true);

        guard let statusCodeString = components.first, let statusCode = Int(statusCodeString) else {
            return (nil, "", "Invalid status code")
        }
        
        let splitFirstLine = response.split(separator: "\r\n", maxSplits: 2, omittingEmptySubsequences: true);

        var contentType = "";
        var message = "";

        if splitFirstLine.count == 2 {
            contentType = String(splitFirstLine[0].split(separator: " ")[1]);
            message = String(splitFirstLine[1]);
        }
                
        return (statusCode, contentType, message)
    }

}
