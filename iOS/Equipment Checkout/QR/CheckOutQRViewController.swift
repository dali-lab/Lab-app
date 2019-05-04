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
    static let tintColor = #colorLiteral(red: 0, green: 0.4871213436, blue: 0.5502281785, alpha: 1).cgColor
    @IBOutlet weak var qrImageView: UIImageView!
    
    let reader = QRCodeReader(metadataObjectTypes: [AVMetadataObject.ObjectType.qr])
    var readerView: QRCodeReaderView!
    var overlayView: CheckOutQRReaderLoadingOverlayView!
    var switchCamera: UIButton!
    
    var topLevelController: EquipmentScanAndListViewController? {
        return self.parent as? EquipmentScanAndListViewController
    }
    
    var enabled = false
    var processingString: String?
    var pastBadScans: [String] = []
    var inactive: Bool = false {
        didSet {
            DispatchQueue(label: "changeInactiveScanning").async {
                if self.inactive {
                    self.reader.stopScanning()
                } else if self.enabled {
                    self.reader.startScanning()
                }
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        qrImageView.image = qrImageView.image?.withRenderingMode(.alwaysTemplate)
        qrImageView.tintColor = UIColor.lightGray
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if enabled {
            reader.stopScanning()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        processingString = nil
        pastBadScans = []
        
        if enabled {
            reader.startScanning()
            readerView.overlay.strokeColor = #colorLiteral(red: 0, green: 0.4871213436, blue: 0.5502281785, alpha: 1)
        }
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        var constraints = [NSLayoutConstraint]()
        
        if enabled {
            constraints.append(readerView.leftAnchor.constraint(equalTo: view.leftAnchor))
            constraints.append(readerView.topAnchor.constraint(equalTo: view.topAnchor))
            constraints.append(readerView.bottomAnchor.constraint(equalTo: view.bottomAnchor))
            constraints.append(readerView.rightAnchor.constraint(equalTo: view.rightAnchor))
            
            constraints.append(switchCamera.topAnchor.constraint(equalTo: view.topAnchor, constant: 36))
            constraints.append(switchCamera.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16))
            
            constraints.append(switchCamera.heightAnchor.constraint(equalToConstant: 40))
            constraints.append(switchCamera.widthAnchor.constraint(equalToConstant: 40))
            
            constraints.append(overlayView.leftAnchor.constraint(equalTo: view.leftAnchor))
            constraints.append(overlayView.rightAnchor.constraint(equalTo: view.rightAnchor))
            constraints.append(overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor))
            constraints.append(overlayView.topAnchor.constraint(equalTo: view.topAnchor))
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - IBActions
    
    @IBAction func scanQRPressed(_ sender: UIButton) {
        enabled = true
        
        // Create a reader
        readerView = QRCodeReaderView(frame: self.view.frame)
        readerView.translatesAutoresizingMaskIntoConstraints = false
        readerView.clipsToBounds = true
        readerView.layer.insertSublayer(reader.previewLayer, at: 0)
        readerView.overlay.strokeColor = CheckOutQRViewController.tintColor
        readerView.overlay.lineWidth = 5
        
        // Button to switch cameras
        switchCamera = UIButton(frame: CGRect.zero)
        switchCamera.translatesAutoresizingMaskIntoConstraints = false
        switchCamera.setImage(UIImage(named: "cameraSwitchIcon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        switchCamera.imageView?.contentMode = .scaleAspectFit
        switchCamera.tintColor = UIColor(cgColor: CheckOutQRViewController.tintColor)
        switchCamera.addTarget(self, action: #selector(CheckOutQRViewController.switchDeviceInput), for: .touchUpInside)
        
        overlayView = CheckOutQRReaderLoadingOverlayView(frame: view.frame)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.loading = false
        
        view.addSubview(readerView)
        view.addSubview(switchCamera)
        view.addSubview(overlayView)
        
        navigationController?.setToolbarHidden(true, animated: true)
        
        reader.previewLayer.frame = view.bounds
        reader.startScanning()
        
        reader.setCompletionWith { (resultString) in
            self.didReceive(resultString: resultString)
        }
        updateViewConstraints()
    }
    
    @objc func switchDeviceInput() {
        self.reader.switchDeviceInput()
    }
    
    // MARK: - Helpers
    
    func didReceive(resultString: String?) {
        guard let string = resultString else {
            // If no result, return to normal tint color
            DispatchQueue.main.async {
                self.readerView.overlay.strokeColor = CheckOutQRViewController.tintColor
            }
            return
        }
        
        guard !pastBadScans.contains(string) else {
            // If this has already been scanned and failed, make it red
            DispatchQueue.main.async {
                self.readerView.overlay.strokeColor = UIColor.red.cgColor
            }
            return
        }
        
        // If already processing, ignore future results
        guard processingString == nil else {
            return
        }
        
        processingString = string
        // Found a result. Make the overlay green
        DispatchQueue.main.async {
            self.readerView.overlay.strokeColor = UIColor.green.cgColor
        }
        
        // After 0.5 seconds, if still loading, stop scanning and overlay
        //  to indicate it is still working
        let workItem = DispatchWorkItem(block: {
            self.reader.stopScanning()
            self.overlayView.set(loading: true, animated: true)
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        
        // Now actually check to see if it's real...
        DALIEquipment.equipment(for: string).onSuccess(block: { (equipment) in
            DispatchQueue.main.async {
                self.topLevelController?.showDetailView(for: equipment)
                self.overlayView.set(loading: false, animated: true)
            }
            workItem.cancel()
        }).onFail(block: { (error) in
            // Failed to find this equipment
            self.processingString = nil
            workItem.cancel()
            if case DALIError.General.Unfound = error {
                self.pastBadScans.append(string)
            }
            
            DispatchQueue.main.async {
                self.readerView.overlay.strokeColor = UIColor.red.cgColor
                self.alertFailure(with: error as? DALIError.General)
                self.overlayView.set(loading: false, animated: true)
            }
        })
    }
    
    /**
     Show an alert describing the error encountered
     */
    func alertFailure(with error: DALIError.General?) {
        // Default title and message
        var title = "Failed to scan"
        var message = "Something went wrong with scanning or finding this equipment for checkout"
        
        if let error = error {
            if case DALIError.General.Unprocessable = error {
                title = "Unprocessable QR"
                message = "This QR doesn't seem to be a DALI equipment code"
            } else if case DALIError.General.Unfound = error {
                title = "Equipment not found"
                message = "Failed to find this equipment. Perhaps it hasn't been registered yet?"
            }
        }
        
        // Show the alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
