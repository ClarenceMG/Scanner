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
	@IBOutlet weak var clearButton: UIButton!
	
	// MARK: Actions
	@IBAction func copyResult(_ sender: Any) {
		pasteboard.string = labelResult.text
		labelResult.text = String()
		
		if (captureSession?.isRunning == false) {
			captureSession.startRunning()
		}
	}
	
	@IBAction func clearResultLabel(_ sender: Any) {
		labelResult.text = String()
		
		if (captureSession?.isRunning == false) {
			captureSession.startRunning()
		}
		
		disableButtons()
	}
	
	// MARK: Variables
	var pasteboard = UIPasteboard.general
	var captureSession: AVCaptureSession!
	var previewLayer: AVCaptureVideoPreviewLayer!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setViewsStyle()
		
		captureSession = AVCaptureSession()
		
		// Find the default audio device.
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
			metadataOutput.metadataObjectTypes = [.qr, .code39]
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
		clearButton.layer.cornerRadius = 20
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
		clearButton.isEnabled = true
		
		copyButton.alpha = 1
		clearButton.alpha = 1
	}
	
	func disableButtons() {
		copyButton.isEnabled = false
		clearButton.isEnabled = false
		
		copyButton.alpha = 0.5
		clearButton.alpha = 0.5
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

