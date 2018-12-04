//
//  ViewController.swift
//  BLE-Central
//
//  Created by yangfourone on 2018/12/4.
//  Copyright © 2018 41. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var readDataClick: UIButton!
    @IBOutlet weak var sendClick: UIButton!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textView: UITextView!
    
    
    enum SendDataError:Error {
        case CharacteristicNotFound
    }
    
    // GATT
    let C001_CHARACTERISTIC = "C001"
    
    var centralManager: CBCentralManager!
    var connectPeripheral: CBPeripheral!
    var charDictionary = [String: CBCharacteristic]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        sendClick.layer.cornerRadius = 5
        sendClick.layer.borderColor = UIColor.blue.cgColor
        sendClick.layer.borderWidth = 2
        
        readDataClick.layer.cornerRadius = 5
        readDataClick.layer.borderColor = UIColor.blue.cgColor
        readDataClick.layer.borderWidth = 2
        
        let queue = DispatchQueue.global()
        // trigger method 1
        centralManager = CBCentralManager(delegate: self, queue: queue)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // check bluetooth 4.0
        guard central.state == .poweredOn else {
            return
        }
        
        // trigger method 2
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    /** Method 2 **/
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard let deviceName = peripheral.name else {
            return
        }
        print("Find BLE Device: \(deviceName)")
        
        guard deviceName.range(of: "MyDevice") != nil || deviceName.range(of: "MacBook") != nil  else {
            return
        }
        
        central.stopScan()
        
        connectPeripheral = peripheral
        connectPeripheral.delegate = self
        // trigger method 3
        central.connect(connectPeripheral, options: nil)
    }
    
    /** Method 3 **/
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        charDictionary = [:]
        peripheral.discoverServices(nil)
    }
    
    /** Method 4 **/
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("ERROR: \(#file, #function)")
            print(error!.localizedDescription)
            return
        }
        
        for service in peripheral.services! {
            // trigger method 5
            connectPeripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    /** Method 5 **/
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("ERROR: \(#file, #function)")
            print(error!.localizedDescription)
            return
        }
        
        for characteristic in service.characteristics! {
            let uuidString = characteristic.uuid.uuidString
            charDictionary[uuidString] = characteristic
            print("Find: \(uuidString)")
        }
    }
    
    /** Send data to Pheripheral **/
    func sendData(_ data: Data, uuidString: String, writeType: CBCharacteristicWriteType) throws {
        guard let characteristic = charDictionary[uuidString] else {
            throw SendDataError.CharacteristicNotFound
        }
        
        connectPeripheral.writeValue(data, for: characteristic, type: writeType)
    }
    
    /** error occur when data passing to peripheral **/
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Writing data error: \(error!)")
        }
    }
    
    /** Get data from Peripheral **/
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("ERROR: \(#file, #function)")
            print(error!)
            return
        }
        
        if characteristic.uuid.uuidString == C001_CHARACTERISTIC {
            let data = characteristic.value! as NSData
            let string = "> " + String(data: data as Data, encoding: .utf8)!
            print(string)
            
            DispatchQueue.main.async {
                if self.textView.text.isEmpty {
                    self.textView.text = string
                } else {
                    self.textView.text = self.textView.text + "\n" + string
                }
            }
        }
    }
    
    @IBAction func subscribeValue(_ sender: UISwitch) {
        connectPeripheral.setNotifyValue(sender.isOn, for: charDictionary[C001_CHARACTERISTIC]!)
    }
    
    @IBAction func sendClick(_ sender: Any) {
        let string = textField.text ?? ""
        if textView.text.isEmpty {
            textView.text = string
        } else {
            textView.text = textView.text + "\n" + string
        }
        
        do {
            let data = string.data(using: .utf8)
            try sendData(data!, uuidString: C001_CHARACTERISTIC, writeType: .withResponse)
        } catch {
            print(error)
        }
        // clean textField
        textField.text = ""
    }
    
    @IBAction func readDataClick(_ sender: Any) {
        let characteristic = charDictionary[C001_CHARACTERISTIC]!
        connectPeripheral.readValue(for: characteristic)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.3) {
            self.view.endEditing(true)
        }
    }
}

