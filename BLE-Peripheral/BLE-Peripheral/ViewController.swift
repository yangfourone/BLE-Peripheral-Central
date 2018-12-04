//
//  ViewController.swift
//  BLE-Peripheral
//
//  Created by yangfourone on 2018/12/4.
//  Copyright © 2018 41. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ViewController: NSViewController, CBPeripheralManagerDelegate {
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var textField: NSTextField!
    
    @IBAction func sendClick(_ sender: Any) {
        let string = textField.stringValue
        
        // update TextView
        if textView.string.isEmpty {
            textView.string = string
        } else {
            textView.string = textView.string + "\n" + string
        }
        // send data to central
        do {
            let data = string.data(using: .utf8)
            try sendData(data!, uuidString: C001_CHARACTERISTIC)
        } catch {
            print(error)
        }
        // clean textField
        textField.stringValue = ""
    }
    
    enum SendDataError: Error {
        case CharacteristicNotFound
    }
    
    // GATT
    let A001_SERVICE = "A001"
    let C001_CHARACTERISTIC = "C001"
    
    var peripheralManager: CBPeripheralManager?
    // 記錄所有的 characteristic
    var charDictionary = [String: CBMutableCharacteristic]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let queue = DispatchQueue.global()
        // trigger method 1
        peripheralManager = CBPeripheralManager(delegate: self, queue: queue)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    /** Method 1 **/
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // bluetooth open?
        guard peripheral.state == .poweredOn else {
            // print message to iOS device user
            print(peripheral.state.rawValue)
            return
        }
        
        var service: CBMutableService
        var characteristic: CBMutableCharacteristic
        var charArray = [CBCharacteristic]()
        
        /** setting service and characteristic **/
        service = CBMutableService(type: CBUUID(string: A001_SERVICE), primary: true)
        characteristic = CBMutableCharacteristic(
            type: CBUUID(string: C001_CHARACTERISTIC),
            properties: [.notifyEncryptionRequired, .write, .read],
            value: nil,
            permissions: [.writeEncryptionRequired, .readEncryptionRequired]
        )
        charDictionary[C001_CHARACTERISTIC] = characteristic
        
        // if there are two or more characteristics, add to Array by using append()
        charArray.append(characteristic)
        
        // put characteristic array into service
        service.characteristics = charArray
        // register service and trigger method 2
        peripheralManager?.add(service)
    }
    
    /** Method 2 **/
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            print("ERROR:{\(#file, #function)}\n")
            print(error!.localizedDescription)
            return
        }
        
        // the device name
        let deviceName = "MyDevice"
        // let central can scan this device and trigger method 3
        peripheral.startAdvertising(
            [CBAdvertisementDataServiceUUIDsKey: [service.uuid],
             CBAdvertisementDataLocalNameKey: deviceName]
        )
    }
    
    /** Method 3 **/
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("Start Advertising!")
    }
    
    /** Send Data to Central **/
    func sendData(_ data: Data, uuidString: String) throws {
        guard let characteristic = charDictionary[uuidString] else {
            // no this uuid
            throw SendDataError.CharacteristicNotFound
        }
        
        peripheralManager?.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
    }
    
    /** Central Subscription **/
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        if peripheral.isAdvertising {
            peripheral.stopAdvertising()
            print("Stop Advertising!")
        }
        
        if characteristic.uuid.uuidString == C001_CHARACTERISTIC {
            print("Subscribe to C001")
            do {
                let data = "Hello Central".data(using: .utf8)
                try sendData(data!, uuidString: C001_CHARACTERISTIC)
            } catch {
                print(error)
            }
        }
    }
    
    /** Cancel Central Subscription **/
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        if characteristic.uuid.uuidString == C001_CHARACTERISTIC {
            print("Unsubscribe to C001")
        }
    }
    
    /** Write data from Central to Peripheral **/
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard let at = requests.first else {
            return
        }
        
        guard let data = at.value else {
            return
        }
        
        if at.characteristic.uuid.uuidString == C001_CHARACTERISTIC {
            // if receive the message, send back a success message
            peripheral.respond(to: at, withResult: .success)
            
            let string = "> " + String(data: data, encoding: .utf8)!
            print(string)
            
            DispatchQueue.main.async {
                if self.textView.string.isEmpty {
                    self.textView.string = string
                } else {
                    self.textView.string = self.textView.string + "\n" + string
                }
            }
        }
    }
    
    /** receive Central's request to read data **/
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        request.value = nil
        if request.characteristic.uuid.uuidString == C001_CHARACTERISTIC {
            let data = "What do you want?".data(using: .utf8)
            request.value = data//textField.stringValue.data(using: .utf8)
        }
        
        // send data by respond
        peripheral.respond(to: request, withResult: .success)
    }
    
    
}

