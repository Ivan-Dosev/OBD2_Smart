//
//  CoreBLE.swift
//  OBD2_Smart
//
//  Created by Dosi Dimitrov on 28.01.24.
//

import Foundation
import CoreBluetooth

/*
 private    var nameOBD2          : String = "IOS-Vlink"
 private    var serviceUUID       : String = "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2"
 private    var caracteristicUUID : String = "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F"
 */

class CoreBLE : NSObject, ObservableObject {
    
    private    var nameOBD2          : String = "989149728950"
    private    var serviceUUID       : String = "49535343-FE7D-4AE5-8FA9-9FAFD205E455"
    private    var caracteristicUUID : String = "49535343-1E4D-4BD9-BA61-23C647249616"
  //  private    var caracteristicUUID : String = "49535343-8841-43F4-A8D4-ECBE34729BB3"
   
 
    
    private    var centralManager: CBCentralManager!
    
    @Published var peripheral    : CBPeripheral?     = nil {
        didSet{
            if peripheral != nil {
                isVisible = true
            }
            else{
                isVisible = false
            }
        }
    }
    @Published var characteristic: CBCharacteristic? = nil
    @Published var isVisible     : Bool = false

    @Published var codeToRun     : String = ""
    @Published var connected     :  Bool = false
    @Published var isProgress    : Bool = false
    @Published var km            : [String] = [] {
        didSet{
            if km != nil {
                kmString = String((Int(km[0].dropFirst(4), radix: 16)! ))
            }
        }
    }
    @Published var vin           : [String] = [] {
        didSet{
            
            if vin != nil {
               // vinString  = String(vin[1].dropFirst(2) + vin[2].dropFirst(2) + vin[3].dropFirst(2))
               
                let components = Array(String(vin[1].dropFirst(2) + vin[2].dropFirst(2) + vin[3].dropFirst(2)))
                var text : String = ""
                var i = 0
                for  com in components {
                    i += 1
                    if i % 2 == 1{ text  +=   " " }
                                   text  +=  String(com)  
                }
                self.vinString = text
                print("vinString: \(vinString)")
            }
        }
    }
    
    @Published var kmString      : String = ""
    @Published var vinString      : String = ""
    
    
    private var buffer = Data()
    var sendMessageCompletion: (([String]?, Error?) -> Void)?
  
    
  

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }

     func decode_VIN(response: String) async -> String {
        // Find the index of the occurrence of "49 02"
        guard let prefixIndex = response.range(of: "49 02")?.upperBound else {
            print("Prefix not found in the response")
            return ""
        }
        // Extract the VIN hex string after "49 02"
        let vinHexString = response[prefixIndex...]
            .split(separator: " ")
            .joined() // Remove spaces
    
        // Convert the hex string to ASCII characters
        var asciiString = ""
        var hex = vinHexString
        while !hex.isEmpty {
            let startIndex = hex.startIndex
            let endIndex = hex.index(startIndex, offsetBy: 2)
    
            if let hexValue = UInt8(hex[startIndex..<endIndex], radix: 16) {
                let unicodeScalar = UnicodeScalar(hexValue)
                asciiString.append(Character(unicodeScalar))
            } else {
                print("Error converting hex to UInt8")
            }
            hex.removeFirst(2)
        }
        // Remove non-alphanumeric characters from the VIN
        let vinNumber = asciiString.replacingOccurrences(
            of: "[^a-zA-Z0-9]",
            with: "",
            options: .regularExpression
        )
        // getvininfo
        return vinNumber
    }
    
    private func decodeVIN(response: String) async -> String {
        // Find the index of the occurrence of "49 02"
        guard let prefixIndex = response.range(of: "49 02")?.upperBound else {
            print("Prefix not found in the response")
            return ""
        }
        // Extract the VIN hex string after "49 02"
        let vinHexString = response[prefixIndex...]
            .split(separator: " ")
            .joined() // Remove spaces
    
        // Convert the hex string to ASCII characters
        var asciiString = ""
        var hex = vinHexString
        while !hex.isEmpty {
            let startIndex = hex.startIndex
            let endIndex = hex.index(startIndex, offsetBy: 2)
    
            if let hexValue = UInt8(hex[startIndex..<endIndex], radix: 16) {
                let unicodeScalar = UnicodeScalar(hexValue)
                asciiString.append(Character(unicodeScalar))
            } else {
                print("Error converting hex to UInt8")
            }
            hex.removeFirst(2)
        }
        // Remove non-alphanumeric characters from the VIN
        let vinNumber = asciiString.replacingOccurrences(
            of: "[^a-zA-Z0-9]",
            with: "",
            options: .regularExpression
        )
        // getvininfo
        return vinNumber
    }
    
    @MainActor
    func adapterInitialization() async throws {
        
        var number : String = "0"
        self.isProgress = true
        for command in OBDCommands.allCases {
            
            print("OBD command: \(command.hex)")
            switch command {
             
            case .ATD, .ATZ, .ATE0 , .ATL0 , .ATS0 , .ATH0:
                            do{
                                let _ = try await sendMessageAsyncArda(command.hex)
                            }catch(let error){ throw error }
            case .ATDPN:
                             do{
                                 let protocolNumber = try await sendMessageAsyncArda(command.hex)
                                 number = protocolNumber[0]
                             }catch(let error){ throw error }
            case .ATSP:
                            print("number: \(number)")
                            do{
                                _ = try await sendMessageAsyncArda( command.hex + number)
                            }catch(let error) { throw error }
            case .vin:
                
                              do{
                                  self.vin = try await sendMessageAsyncArda(command.hex)
                                
                              }catch(let error){ throw error }
            case .distance:
                              do{
                                  self.km = try await sendMessageAsyncArda(command.hex)
                              
                              }catch(let error){ throw error }
            }

        }
        self.isProgress = false
    }
    
    
    func okResponse(message: String) async throws -> [String] {
        let response = try await self.sendMessageAsyncArda(message)
        if response.contains("OK") {
            return response
        } else {
           
            throw SetupError.invalidResponse
        }
    }
    
    
    func sendMessageAsyncArda(_ message: String, characteristic: CBCharacteristic? = nil) async throws -> [String] {
        // ... (sending message logic)
      
        let message = "\(message)\r"

        guard let connectedPeripheral = self.peripheral,
              let characteristic = self.characteristic,
              let data = message.data(using: .ascii
              ) else { return ["..."]}

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String], Error>) in
 
                self.sendMessageCompletion = { response, error in
                    if let response = response {
                        continuation.resume(returning: response)

                    } else if let error = error {
                        continuation.resume(throwing: SetupError.invalidResponse)

                    }
            }

            connectedPeripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
    
    func didUpdateValueArda(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, error: Error?) {

        guard let characteristicValue = characteristic.value else { return }
        
        if characteristicValue == self.characteristic?.value {
          
            processReceivedDataArda(characteristicValue, completion: sendMessageCompletion)
        }
    }
    
    func processReceivedDataArda(_ data: Data, completion: (([String]?, Error?) -> Void)?) {
        
        buffer.append(data)
        guard var string = String(data: buffer, encoding: .utf8) else {
         
            buffer.removeAll()
            return
        }

        if string.contains(">") ||  string.contains(codeToRun){

            string = string
                .replacingOccurrences(of: "\u{00}", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Split into lines while removing empty lines
            var lines = string
                .components(separatedBy: .newlines)
                .filter { !$0.isEmpty }

            // remove the last line
            lines.removeLast()
            print("🐸 \(lines)")
            completion?(lines, nil)
            buffer.removeAll()
        }
    }
    

    func disconnectPeripheral() {
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            self.connected = false
            self.characteristic = nil
            
        }
    }
    
    func connectTo(peripheral: CBPeripheral) {
        
        self.isProgress = true
        centralManager.connect(peripheral)
        centralManager.stopScan()
    }
}

extension CoreBLE: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager,didDiscover peripheral: CBPeripheral,advertisementData: [String : Any],rssi RSSI: NSNumber) {
        
        //   nameOBD2 :      "IOS-Vlink"
        if peripheral.name == nameOBD2 {
            self.peripheral = peripheral

          //  central.connect(peripheral, options: nil)
          //  central.stopScan()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("connected to \(peripheral.name ?? "unnamed")")
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: serviceUUID)])
        //                                          serviceUUID : String = "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2"
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral) {
       
     
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        guard error == nil else { return }
 
    }
}


extension CoreBLE: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("service: \(service.uuid)")
            peripheral.discoverCharacteristics([CBUUID(string: caracteristicUUID)], for: service)
          //                     caracteristicUUID : String = "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F"
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic in service.characteristics ?? [] {
            print("characteristic: \(characteristic.uuid)")
            if (String(describing: characteristic.uuid)) == caracteristicUUID {
                
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.discoverDescriptors(for: characteristic)
                self.characteristic =  characteristic
                self.isProgress = false
                self.connected  = true
            }
        }

    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
          didUpdateValueArda(peripheral, characteristic: characteristic, error: error)
    }
}

