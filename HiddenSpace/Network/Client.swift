//
//  Client.swift
//  jimmy
//
//  Created by Jonathan Foucher on 16/02/2022.
//

import Foundation
import Network
import Security
import X509
import SelfSignedCert


func saveIdentity(identity: SecIdentity){
    let query: [String: Any] = [
        kSecClass as String: kSecClassIdentity,
        kSecAttrLabel as String: "dev.mkla.geminispace.identity",

        kSecValueRef as String: identity as CFTypeRef
    ]
    let status = SecItemAdd(query as CFDictionary, nil)
    if status == errSecSuccess {
        print("Identity stored successfully!")
    } else {
        print("Error storing identity:  \(String(describing: SecCopyErrorMessageString(status, nil)))")
    }
}

func getIdentity() -> SecIdentity? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassIdentity,
        kSecAttrLabel as String: "dev.mkla.geminispace.identity",

        kSecReturnRef as String: kCFBooleanTrue!,
    ]
    
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    
    if status == errSecSuccess {
        print("Identity retrieved")
        return (item as! SecIdentity?);
    } else {
        print("Error retrieving identity: \(String(describing: SecCopyErrorMessageString(status, nil)))")
        return nil
    }
}



class Client {
    var connection: ClientConnection
    let host: NWEndpoint.Host
    let port: NWEndpoint.Port
    let validateCert: Bool
    
    var dataReceivedCallback: ((NWError?, Data?, Int, String) -> Void)? = nil
    
    init(host: String, port: UInt16, validateCert: Bool) {
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port)!
        self.validateCert = validateCert

        // Will not regenerate if already present
        let tlsOptions = NWProtocolTLS.Options();

        var identity = getIdentity();
        if identity == nil {
            identity = SecIdentity.create(subjectCommonName: "vegasq", subjectEmailAddress: "vegasq@gmail.com")
            if identity != nil {
                saveIdentity(identity: identity!);
            }
        } else {
            print("Identity found")
        }

        if identity != nil {
            let secIdentityType = sec_identity_create(identity!);
            sec_protocol_options_set_local_identity(tlsOptions.securityProtocolOptions, secIdentityType!);
        }

        let params = NWParameters(tls: tlsOptions, tcp: NWProtocolTCP.Options())
        let nwConnection = NWConnection(host: self.host, port: self.port, using: params)
        self.connection = ClientConnection(nwConnection: nwConnection)
    }

    
//    func setupSecConnection(){
//        let tlsOptions = NWProtocolTLS.Options()
//        
//        // Load TLS identity
//        let identity = self.loadTLSIdentity()
//        if let identity = identity {
//            sec_protocol_options_set_local_identity(tlsOptions.securityProtocolOptions, sec_identity_create(identity)!)
//        }
//        sec_protocol_options_set_peer_authentication_required(tlsOptions.securityProtocolOptions, self.validateCert)
//        
//        // Now that host and port are initialized, create the connection
//        let params = NWParameters(tls: tlsOptions, tcp: NWProtocolTCP.Options())
//        let nwConnection = NWConnection(host: self.host, port: self.port, using: params)
//        self.connection = ClientConnection(nwConnection: nwConnection)
//    }
    
//    private func loadTLSIdentity() -> SecIdentity? {
//        // Assuming the identity is stored in the keychain, adjust as necessary
//        let query: [String: Any] = [
//            kSecClass as String: kSecClassIdentity,
//            kSecReturnRef as String: true,
//            kSecAttrLabel as String: "dev.mkla.hiddenspace"
//        ]
//        
//        var item: CFTypeRef?
//        let status = SecItemCopyMatching(query as CFDictionary, &item)
//        if status == errSecSuccess {
//            return (item as! SecIdentity)
//        } else {
//            print("Error loading TLS identity from keychain: \(status)")
//            return nil
//        }
//    }
//    
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
    }
    
    func didStopCallback(error: NWError?, message: Data?, statusCode: Int, contentType: String) {
        if let dataReceivedCallback = self.dataReceivedCallback {
            dataReceivedCallback(error, message, statusCode, contentType);
            self.dataReceivedCallback = nil;
        }
    }

}
