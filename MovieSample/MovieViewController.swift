//
//  MovieViewController.swift
//  MovieSample
//
//  Created by Ryo Endo on 2018/07/11.
//  Copyright © 2018年 Ryo Endo. All rights reserved.
//

import UIKit
import AVFoundation
//動画を保存するのに必要
import Photos

class MovieViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    var cameraDevices: AVCaptureDevice!
    var isRecoding = false
    var isBackCamera: Bool = true
    var fileOutput: AVCaptureMovieFileOutput?
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var startStopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpVideo(isBack: isBackCamera)
        screenInitialization()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpVideo(isBack: Bool) {
        // セッションのインスタンス生成
        let captureSession = AVCaptureSession()
        // isBack == True  -> Back Camera
        // iSBack == False -> Front Camera
        let devicePosition: AVCaptureDevice.Position = isBack ? .back : .front
        guard let videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: devicePosition) else {return}
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice)
        captureSession.addInput(videoInput)
        // 入力（マイク）
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {return}
        let audioInput = try! AVCaptureDeviceInput.init(device: audioDevice)
        captureSession.addInput(audioInput);
        // 出力（動画ファイル）
        fileOutput = AVCaptureMovieFileOutput()
        captureSession.addOutput(fileOutput!)
        // プレビュー
        let videoLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
        videoLayer.frame = previewView.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewView.layer.addSublayer(videoLayer)
        // セッションの開始
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    //delegate、録画完了？
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // ライブラリへの保存
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        }) { completed, error in
            if completed {
                print("Video is saved!")
            }
        }
    }
    
    func screenInitialization(){
        startStopButton.setImage(UIImage(named: isRecoding ? "startButton" : "stopButton"), for: .normal)
        headerView.alpha = isRecoding ? 0.6 : 1.0
        footerView.alpha = isRecoding ? 0.6 : 1.0
    }
    
    //カメラの切り替え
    @IBAction func changeCamera() {
         self.isBackCamera = !self.isBackCamera
        setUpVideo(isBack: isBackCamera)
    }
    
    // 録画の開始・停止ボタン
    @IBAction func tapStartStopButton(_ sender: Any) {
        if isRecoding { // 録画終了
            fileOutput?.stopRecording()
        }
        else{ // 録画開始
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory = paths[0] as String
            let filePath : String? = "\(documentsDirectory)/temp.mp4"
            let fileURL : NSURL = NSURL(fileURLWithPath: filePath!)
            fileOutput?.startRecording(to: (fileURL as URL?)!, recordingDelegate: self)
        }
        isRecoding = !isRecoding
        screenInitialization()
    }
}


