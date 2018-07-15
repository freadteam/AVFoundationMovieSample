//
//  ViewController.swift
//  MovieSample
//
//  Created by Ryo Endo on 2018/07/11.
//  Copyright © 2018年 Ryo Endo. All rights reserved.
//

import UIKit
import AVFoundation
//動画を保存するのに必要
import Photos
//フィルター
import GPUImage

class ViewController: UIViewController,  AVCaptureFileOutputRecordingDelegate {

    var camera: GPUImageVideoCamera? = nil
        //GPUImageVideoCamera(sessionPreset: AVCaptureSession.Preset.vga640x480.rawValue, cameraPosition: .back)
    var filterGroup: GPUImageFilterGroup?
    var isBackCamera: Bool = true
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var changeCameraButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setVideo(isBack: isBackCamera)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setVideo(isBack: Bool) {
        
         let devicePosition: AVCaptureDevice.Position = isBack ? .back : .front
        camera = GPUImageVideoCamera(sessionPreset: AVCaptureSession.Preset.vga640x480.rawValue, cameraPosition: devicePosition)
        
        camera?.outputImageOrientation = .portrait
        let imageView = GPUImageView(frame: view.bounds)
        view.addSubview(imageView)
        //白黒
        let blackFilter = GPUImageGrayscaleFilter()
        // コントラスト
        let contrastFilter = GPUImageContrastFilter()
        contrastFilter.contrast = 1.0
        //filterを重ねる
        blackFilter.addTarget(contrastFilter)
        // フィルターグループ生成
        filterGroup = GPUImageFilterGroup()
        filterGroup?.addFilter(blackFilter)
        filterGroup?.addFilter(contrastFilter)
        filterGroup?.initialFilters = [blackFilter]
        filterGroup?.terminalFilter = contrastFilter
        camera?.addTarget(filterGroup)
        filterGroup?.addTarget(imageView)
        camera?.startCapture()
        
        imageView.addSubview(button)
        imageView.addSubview(changeCameraButton)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("test")
    }
    
    //カメラの切り替え
    @IBAction func changeCamera() {
        self.isBackCamera = !self.isBackCamera
        setVideo(isBack: isBackCamera)
    }
    
}

