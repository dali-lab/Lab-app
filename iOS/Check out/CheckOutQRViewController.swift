//
//  CheckOutQRViewController.swift
//  iOS
//
//  Created by John Kotz on 9/17/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import QRCodeReaderViewController
import DALI

class CheckOutQRViewController: UIViewController {
    let reader = QRCodeReader(metadataObjectTypes: [AVMetadataObject.ObjectType.qr])
    var readerView: QRCodeReaderView!
    var overlayView: CheckOutQRReaderLoadingOverlayView!
    var switchCameraButton: UIButton!
    
    var result: String?
    var failedLoadResults: [String] = []
    
    override func viewDidLoad() {
        readerView = QRCodeReaderView(frame: self.view.frame)
        readerView.translatesAutoresizingMaskIntoConstraints = false
        readerView.clipsToBounds = true
        readerView.layer.insertSublayer(reader.previewLayer, at: 0)
        readerView.overlay.strokeColor = #colorLiteral(red: 0, green: 0.4871213436, blue: 0.5502281785, alpha: 1)
//        readerView.overlay.lineWidth = 10
//        readerView.overlay.lineDashPattern = [20.0, 20.0];
        
        switchCameraButton = UIButton(frame: CGRect.zero)
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        switchCameraButton.setImage(UIImage(named: "cameraSwitchIcon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        switchCameraButton.imageView?.contentMode = .scaleAspectFit
        switchCameraButton.tintColor = #colorLiteral(red: 0, green: 0.4871213436, blue: 0.5502281785, alpha: 1)
        switchCameraButton.addTarget(self, action: #selector(CheckOutQRViewController.switchDeviceInput), for: .touchUpInside)
        
        self.overlayView = CheckOutQRReaderLoadingOverlayView(frame: self.view.frame)
        self.overlayView.translatesAutoresizingMaskIntoConstraints = false
        self.overlayView.loading = false
        
        self.view.addSubview(readerView)
        self.view.addSubview(switchCameraButton)
        self.view.addSubview(overlayView)
        
        self.navigationController?.setToolbarHidden(true, animated: true)
        
        reader.previewLayer.frame = self.view.bounds
        reader.startScanning()
        
        reader.setCompletionWith { (resultString) in
            if let resultString = resultString, self.result == nil, !self.failedLoadResults.contains(resultString) {
                self.result = resultString
                self.handleResultChange()
            }
        }
        self.updateViewConstraints()
    }
    
    func handleResultChange() {
        DispatchQueue.main.async {
            if let result = self.result {
                self.readerView.overlay.strokeColor = UIColor.green.cgColor
                print("QR SCAN RESULT: \(result)")
                
                let workItem = DispatchWorkItem(block: {
                    self.reader.stopScanning()
                    self.overlayView.set(loading: true, animated: true)
                })
                
                DALIEquipment.equipment(for: result).onSuccess(block: { (equipment) in
                    DispatchQueue.main.async {
                        self.showConfirmView(for: equipment)
                        workItem.cancel()
                    }
                }).onFail(block: { (error) in
                    DispatchQueue.main.async {
                        self.result = nil
                        self.readerView.overlay.strokeColor = UIColor.red.cgColor
                        
                        if let error = error as? DALIError.General, case DALIError.General.Unfound = error {
                            self.failedLoadResults.append(result)
                        }
                        self.showFailedGetEquipmentAlert(error: error as? DALIError.General)
                        workItem.cancel()
                    }
                })
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
            }
        }
    }
    
    func showConfirmView(for equipment: DALIEquipment) {
        self.performSegue(withIdentifier: "showEquipmentCheckoutConfirm", sender: equipment)
    }
    
    func showFailedGetEquipmentAlert(error: DALIError.General?) {
        var title = "Failed to scan"
        var message = "Something went wrong with scanning or finding this equipment for checkout"
        
        if let error = error {
            switch error {
            case .Unprocessable:
                title = "Unprocessable QR"
                message = "This QR doesn't seem to be a DALI equipment code"
                break
                
            case .Unfound:
                title = "Equipment not found"
                message = "Failed to find this equipment. Perhaps it hasn't been registered yet?"
                
            default:
                break
            }
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        reader.stopScanning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reader.startScanning()
        result = nil
        failedLoadResults = []
        self.readerView.overlay.strokeColor = #colorLiteral(red: 0, green: 0.4871213436, blue: 0.5502281785, alpha: 1)
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        var constraints = [NSLayoutConstraint]()
        
        constraints.append(self.readerView.leftAnchor.constraint(equalTo: self.view.leftAnchor))
        constraints.append(self.readerView.topAnchor.constraint(equalTo: self.view.topAnchor))
        constraints.append(self.readerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor))
        constraints.append(self.readerView.rightAnchor.constraint(equalTo: self.view.rightAnchor))
        
        if #available(iOS 11.0, *) {
            let constraint = switchCameraButton.topAnchor.constraintEqualToSystemSpacingBelow(self.view.safeAreaLayoutGuide.topAnchor, multiplier: 2.0)
            constraints.append(constraint)
            
            constraints.append(view.rightAnchor.constraintEqualToSystemSpacingAfter(switchCameraButton.rightAnchor, multiplier: 2.0))
        } else {
            constraints.append(switchCameraButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 16 + (self.navigationController?.navigationBar.bounds.height ?? 0)))
            constraints.append(view.rightAnchor.constraint(equalTo: switchCameraButton.rightAnchor, constant: 16))
        }
        
        constraints.append(switchCameraButton.heightAnchor.constraint(equalToConstant: 50))
        constraints.append(switchCameraButton.widthAnchor.constraint(equalToConstant: 50))
        
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func switchDeviceInput() {
        self.reader.switchDeviceInput()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let equipment = sender as? DALIEquipment, let destination = segue.destination as? CheckOutConfirmViewController {
            destination.equipment = equipment
        }
    }
}
