//
//  NetworkService.swift
//  LEDLamp
//
//  Created by Oleksandr Fedko on 30.11.2024.
//

import Foundation
import Network

final class NetworkService: ObservableObject {
    @Published var state = LampState(red: 0, green: 0, blue: 0, brightness: 0, mode: .color, temperature: .tungsten100W)
    
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
                self.command(.get)
            }
        }
        connection?.start(queue: .main)
    }
    
    private func receiveMessageLoop() {
        connection?.receiveMessage { content, contentContext, isComplete, error in
            if let message = contentContext?.protocolMetadata(definition: LedProtocol.definition) as? NWProtocolFramer.Message {
                switch message.header.messageType {
                case .command:
                    break
                case .response:
                    if case .get = message.header.function, let data = message.data {
                        do {
                            self.state = try LampState.deserialize(data)
                        }
                        catch { print(error) }
                    }
                case .invalid:
                    break
                }
            }
            
            if let err = error {
                print(err)
            }
            
            self.receiveMessageLoop()
        }
    }
}
