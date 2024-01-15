//
//  Favicon.swift
//  HiddenSpace
//
//  Created by Nick Yakovliev on 12/16/23.
//

import Foundation


class FaviconCache {
    private var faviconCache: [String: String] {
        didSet {
            saveCache()
        }
    }

    init() {
        faviconCache = UserDefaults.standard.object(forKey: "FaviconCache") as? [String: String] ?? [:]
    }

    private func saveCache() {
        UserDefaults.standard.set(faviconCache, forKey: "FaviconCache")
    }
    
    func getCachedFavicon(for url: String) -> String {
        let parsedURL = Foundation.URL(string: url)

        guard let host = parsedURL?.host, !host.isEmpty else {
            return "";
        }

        // Check cache first
        if let cachedFavicon = faviconCache[host] {
            return String(cachedFavicon);
        }

        return "";
    }

    func getFavicon(for url: String) -> String {
        let parsedURL = Foundation.URL(string: url)

        guard let host = parsedURL?.host, !host.isEmpty else {
            return "";
        }

        // Check cache first
        if let cachedFavicon = faviconCache[host] {
            return String(cachedFavicon);
        }

        // Fetch and update cache
        self.fetch(url: url);
        return "";
    }
    
    func fetch(url: String) {
        let parsedURL = Foundation.URL(string: url);
        if parsedURL == nil {
            return
        }
        var host = "";
        if parsedURL?.host() == nil || parsedURL?.host() == "" {
            return
        } else {
            host = (parsedURL?.host())!;
        }

        let port = UInt16(parsedURL?.port ?? 1965);
        
        
        let favURL = "gemini://\(host):\(port)/favicon.txt";

        let cl = Client(host: parsedURL?.host() ?? "", port: UInt16(parsedURL?.port ?? 1965), validateCert: false);
//        cl.setupSecConnection();
        cl.start();
        cl.dataReceivedCallback = self.processResponse(favURL);
        cl.send(data: (favURL + "\r\n").data(using: .utf8)!);
    }

    func processResponse(_ host: String) -> (Error?, Data?, Int, String) -> Void {
        return  { error, data, statusCode, contentType in
             var responseContentType = "";
            
            // Ignoring ; lang=en
            if contentType.split(separator: ";", maxSplits: 1).count == 2 {
                responseContentType = String(contentType.split(separator: ";")[0]);
            } else {
                responseContentType = contentType;
            }

            switch statusCode {
                case 20...29:
                    if responseContentType == "text/plain" {
                        print(host);
                        let content = String(data: data ?? Data(), encoding: .utf8) ?? "";
                        let parsedURL = Foundation.URL(string: host);
                        let hostname = parsedURL?.host() ?? "";
                        if hostname.count > 0 {
                            self.faviconCache[hostname] = String(content.first ?? " ");
                        }
                    }
                default:
                    print("Unknown status code \(statusCode).")
            }
        }
    }
}
