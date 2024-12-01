//
//  NetworkService.swift
//  LEDLamp
//
//  Created by Oleksandr Fedko on 30.11.2024.
//

import Foundation
import Network

final class NetworkService {
    private let browser = NWBrowser(for: .bonjour(type: LedProtocol.serviceName, domain: "local."), using: .tcp)
    private var connection: NWConnection?
    
    func search() {
        browser.stateUpdateHandler = { state in
            if case NWBrowser.State.failed(let error) = state {
                print(error)
            }
        }
        
        browser.browseResultsChangedHandler = { _, changes in
            for change in changes {
                switch change {
                case .added(let peer):
                    self.establishConnection(with: peer.endpoint)
                case .removed(let peer):
                    if self.connection?.endpoint == peer.endpoint {
                        self.connection?.cancel()
                        self.connection = nil
                    }
                default:
                    break
                }
            }
        }
        
        browser.start(queue: .main)
    }
    
    func command(_ command: LedProtocol.Command, type: LedProtocol.MessageType = .command, data: Data? = nil) {
        do {
            let header = try LedProtocolHeader(function: command, type: type, dataLength: data?.count ?? 0)
            let message = NWProtocolFramer.Message(header: header, data: data)
            let context = NWConnection.ContentContext(identifier: "LedLampMessage", metadata: [message])
            connection?.send(content: nil, contentContext: context, isComplete: true, completion: .idempotent)
        }
        catch { print(error) }
    }
    
    // MARK: - Private
    private func establishConnection(with endpoint: NWEndpoint) {
        let parameters = NWParameters.tcp
        let frameOptions = NWProtocolFramer.Options(definition: LedProtocol.definition)
        parameters.defaultProtocolStack.applicationProtocols.insert(frameOptions, at: 0)
        connection = NWConnection(to: endpoint, using: parameters)
        connection?.stateUpdateHandler = { state in
            print(state)
            if case .ready = state {
                self.receiveMessageLoop()
            }
        }
        connection?.start(queue: .main)
        print(connection!)
    }
    
    private func receiveMessageLoop() {
        connection?.receiveMessage { content, contentContext, isComplete, error in
            if let decodedMessage = contentContext?.protocolMetadata(definition: LedProtocol.definition) as? NWProtocolFramer.Message {
//                self.message(.success(decodedMessage))
                print(decodedMessage)
            }
            
            if let err = error {
                print(err)
            }
            
            self.receiveMessageLoop()
        }
    }
}
