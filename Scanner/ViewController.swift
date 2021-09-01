//
//  ViewController.swift
//  Scanner
//
//  Created by Clarence Montenegro on 8/27/21.
//

import UIKit
import AVFoundation

// MARK: My protocol
protocol ScannerViewDelegate {
	func scanningDidFail()
	func scanningSucceededWithCode(_ result: String?)
	func scanningDidStop()
}

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
	
	// MARK: Outlets
	@IBOutlet weak var myViewScanner: UIView!
	@IBOutlet weak var labelResult: UILabel!
	@IBOutlet weak var copyButton: UIButton!
	@IBOutlet weak var continueButton: UIButton!
	@IBOutlet weak var shareButton: UIButton!
	
	// MARK: Actions
	@IBAction func copyResult(_ sender: Any) {
		pasteboard.string = labelResult.text
		
		UIView.transition(with: view, duration: 0.4, options: .transitionCrossDissolve, animations:
							{
								let alert = UIAlertController(title: "Scanner", message: "The scanner result was copied to the clipboard.", preferredStyle: .alert)
								alert.addAction(UIAlertAction(title: "Ok", style: .default))
								self.present(alert, animated: true)
								
							}, completion: nil)
	}
	
	@IBAction func continueScanning(_ sender: Any) {
		UIView.transition(with: view, duration: 0.4, options: .transitionCrossDissolve, animations:
							{
								self.labelResult.text = String()
								self.disableButtons()
								
							}, completion: {_ in
								
								if (self.captureSession?.isRunning == false) {
									self.captureSession.startRunning()
								}
							})
	}
	
	@IBAction func shareText(_ sender: Any) {
		
		let activityController = UIActivityViewController(activityItems: ["\(labelResult.text ?? "") \nShared from Scanner."], applicationActivities: nil)
		present(activityController, animated: true, completion: nil)
	}
	
	
	// MARK: Variables
	var pasteboard = UIPasteboard.general
	var captureSession: AVCaptureSession!
	var previewLayer: AVCaptureVideoPreviewLayer!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setViewsStyle()
		
		captureSession = AVCaptureSession()
		
		// Find the default video device.
		guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
			return
		}
		
		let videoInput: AVCaptureDeviceInput
		
		do {
			videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
			
			if captureSession.canAddInput(videoInput) {
				captureSession.addInput(videoInput)
			} else {
				failed()
				return
			}
		} catch {
			return
		}
		
		let metadataOutput = AVCaptureMetadataOutput()
		
		if captureSession.canAddOutput(metadataOutput) {
			captureSession.addOutput(metadataOutput)
			
			metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
			metadataOutput.metadataObjectTypes = [.qr, .code128, .code39, .code93, .code39Mod43, .dataMatrix, .ean13, .ean8, .itf14, .pdf417]
		} else {
			failed()
			return
		}
		
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		previewLayer.frame = myViewScanner.layer.bounds
		previewLayer.videoGravity = .resizeAspectFill
		myViewScanner.layer.addSublayer(previewLayer)
		
		captureSession.startRunning()
	}
	
	func setViewsStyle() {
		myViewScanner.layer.cornerRadius = 10
		myViewScanner.layer.borderColor = UIColor.lightGray.cgColor
		myViewScanner.layer.borderWidth = 0.8
		
		disableButtons()
		copyButton.layer.cornerRadius = 20
		continueButton.layer.cornerRadius = 20
	}
	
	func failed() {
		let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
		ac.addAction(UIAlertAction(title: "OK", style: .default))
		present(ac, animated: true)
		captureSession = nil
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if (captureSession?.isRunning == false) {
			captureSession.startRunning()
		}
	}
	
	func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
		captureSession.stopRunning()
		
		if let metadataObject = metadataObjects.first {
			guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
			guard let stringValue = readableObject.stringValue else { return }
			AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
			found(code: stringValue)
		}
		
		dismiss(animated: true)
	}
	
	func found(code: String) {
		labelResult.text = code
		
		enableButtons()
	}
	
	func enableButtons() {
		copyButton.isEnabled = true
		continueButton.isEnabled = true
		shareButton.isEnabled = true
		
		copyButton.alpha = 1
		continueButton.alpha = 1
		shareButton.alpha = 1
	}
	
	func disableButtons() {
		copyButton.isEnabled = false
		continueButton.isEnabled = false
		shareButton.isEnabled = false
		
		copyButton.alpha = 0.5
		continueButton.alpha = 0.5
		shareButton.alpha = 0.5
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if (captureSession?.isRunning == true) {
			captureSession.stopRunning()
		}
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}
	
}

