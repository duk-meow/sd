//
//  Config.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation

struct Config {
    // ⚠️ PASTE YOUR URLS HERE FROM YOUR .env FILE:
    // Replace these localhost values with your actual backend URLs
    
    static let apiURL = "https://chatsignaldesk.vercel.app"
    // Use https (Socket.IO uses this for polling + upgrade; must be https for ATS).
    static let socketURL = "https://signaldesk-6xgf.onrender.com"
    static let aiServiceURL = "https://signaldesk-4qla.onrender.com"
    
    // Example from TypeScript .env:
    // static let apiURL = "https://your-api-url.com"
    // static let socketURL = "wss://your-socket-url.com"
    // static let aiServiceURL = "https://your-ai-service-url.com"
}
