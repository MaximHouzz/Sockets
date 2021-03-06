//
//  SocketManager.swift
//  SocketIO
//
//  Created by Maxim on 07/12/2017.
//  Copyright © 2017 Maxim. All rights reserved.
//

import Foundation
import SocketIO

@objc public enum SocketServiceReason: Int, RawRepresentable {
    case request
    case disconnect
    
    public typealias RawValue = String

    public var rawValue: RawValue {
        switch self {
        case .request:
            return "Request"
        case .disconnect:
            return "Disconnect"
            
        }
    }
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "Request":
            self = .request
        case "Disconnect":
            self = .disconnect
        default:
            return nil
        }
    }
}

public final class SocketService: NSObject {

    /**
     Singelton.
     */
    static public let shared = SocketService(url: URL(string: "https://glacial-temple-59524.herokuapp.com/")!)
    
    public var timeout: TimeInterval = 2.0
    
    
    public var userSocket: LiveDesignUserSocketProtocol?
    public var representativeSocket: LiveDesignRepresentativeSocketProtocol?
    
    fileprivate let url: URL
    
    private init(url: URL) {
        self.url = url
        super.init()
    }
    
    public func liveDesignUserSocket(_ completion: @escaping ((LiveDesignUserSocketProtocol?)->())) {
        SocketManager.connectedManager(url: url, config:  [.log(true), .reconnects(false)], timeout: self.timeout) { manager in
            if let manager = manager {
                self.userSocket = LiveDesignUserSocketManager(socket: manager.defaultSocket, onClose: { [weak self] socket in
                    self?.userSocket = nil
                })
                completion(self.userSocket)
            } else {
                self.userSocket = nil
                completion(nil)
            }
        }
    }
    
    public func liveDesignRepresentativeSocket(_ completion: @escaping ((LiveDesignRepresentativeSocketProtocol?)->())) {
        SocketManager.connectedManager(url: url, config:  [.log(true), .reconnects(false)], timeout: self.timeout) { manager in
            if let manager = manager {
                self.representativeSocket = LiveDesignRepresentativeSocketManager(socket: manager.defaultSocket, onClose: { [weak self] socket in
                    self?.representativeSocket = nil
                })
                completion(self.representativeSocket)
            } else {
                self.representativeSocket = nil
                completion(nil)
            }
        }
    }
}

fileprivate extension SocketManager {
    
    class func connectedManager(url: URL, config: SocketIOClientConfiguration, timeout: TimeInterval, _ completion: @escaping ((SocketManager?)->())) {
        let manager = SocketManager(socketURL: url, config: config)
        
        // catch connection event via socket
        manager.defaultSocket.on(clientEvent: .connect) { (_, _) in
            completion(manager)
        }
        
        // perform connection
        manager.connect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            if manager.status != .connected {
                manager.defaultSocket.removeAllHandlers()
                completion(nil)
            }
        }
        
    }
}
