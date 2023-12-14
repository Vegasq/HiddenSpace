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
    
    let nwConnection: NWConnection;
    let queue = DispatchQueue(label: "Client connection Q");
    var read: String;
    var data: Data;
    
    init(nwConnection: NWConnection) {
        self.nwConnection = nwConnection
        self.read = ""
        self.data = Data()
    }
    
    var didStopCallback: ((NWError?, Data?, Int, String) -> Void)? = nil
    
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
        stop(error: nil, message: nil, statusCode: 0, contentType: "")
    }
    
    private func connectionDidFail(error: NWError) {
        self.stop(error: error, message: nil, statusCode: 0, contentType: "")
    }
    
    private func connectionDidEnd() {
        let (statusCode, contentType, message) = processStatusCode(data: self.data)
        self.stop(error: nil, message: message, statusCode: statusCode ?? 0, contentType: contentType)
    }
    
    private func stop(error: NWError?, message: Data?, statusCode: Int, contentType: String) {
        self.nwConnection.stateUpdateHandler = nil
        self.nwConnection.cancel()
        if let didStopCallback = self.didStopCallback {
            didStopCallback(error, message, statusCode, contentType)
            self.didStopCallback = nil
        }
    }
    
    func extractFirstLineAndRemainingData(from data: Data) -> (firstLine: String, remainingData: Data)? {
        let crlfData = "\r\n".data(using: .utf8)!

        if let range = data.range(of: crlfData) {
            let firstLineData = data.subdata(in: data.startIndex..<range.lowerBound)
            if let firstLine = String(data: firstLineData, encoding: .utf8) {
                let remainingData = data.subdata(in: range.upperBound..<data.endIndex)
                return (firstLine, remainingData)
            }
        }
        return nil
    }

    func processStatusCode(data: Data) -> (statusCode: Int?, conentType: String, message: Data?) {
        var contentType = "";
        var statusCode = 0;
        var message = Data();

        if let result = extractFirstLineAndRemainingData(from: data) {
            let headerSplit = result.firstLine.split(separator: " ", maxSplits: 1);

            contentType = String(headerSplit[1]);
            statusCode = Int(headerSplit[0]) ?? 0;
            message = result.remainingData;
        } else {
            print("CRLF not found in the data, or unable to convert to string.");
        }

        return (statusCode, contentType, message)
    }

}
