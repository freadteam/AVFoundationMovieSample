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
import SVProgressHUD

class MovieViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    var cameraDevices: AVCaptureDevice!
    var isRecoding = false
    var isBackCamera: Bool = true
    var fileOutput: AVCaptureMovieFileOutput?
    var filterArray = ["CIPhotoEffectTonal", "CIMinimumComponent", "CIColorPosterize", "CIPhotoEffectMono", "CIPhotoEffectNoir", "CIColorPosterize", "CIMaskToAlpha", "CIColorMonochrome"]
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var processingLabel: UILabel!
    @IBOutlet weak var filterLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpVideo(isBack: isBackCamera)
        screenInitialization()
        filterLabel.text = filterArray.first!
        headerView.addSubview(filterLabel)
        
        //swipe
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(MovieViewController.didSwipe(_:)))
        rightSwipe.direction = .right
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action:  #selector(MovieViewController.didSwipe(_:)))
        leftSwipe.direction = .left
        // swipe動作の追加
        view.addGestureRecognizer(rightSwipe)
        view.addGestureRecognizer(leftSwipe)
    }
    //swipe時の挙動
    @objc func didSwipe(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == .right {
            print("right")
            self.filterArray.append(filterArray.first!)
            self.filterArray.removeFirst()
        } else if sender.direction == .left {
            print("left")
            self.filterArray.insert(filterArray.last!, at: 0)
            self.filterArray.removeLast()
        }
        filterLabel.text = filterArray.first!
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
    //録画開始
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {

    }
    
    //delegate、録画完了
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
       //-----------------------------------------------------------------
        SVProgressHUD.show()
        //フィルターをかける
        let asset = AVAsset(url: outputFileURL)
        let filter = CIFilter(name: filterArray.first!)!
        filter.setDefaults()
        // a: ドット風の白黒
        //CIMinimumComponent：白黒
        //CIPhotoEffectTonal: いい感じの白黒
        //CIColorPosterize：　油絵
        //CIPhotoEffectMono:濃い白黒
        //CIPhotoEffectNoir：白黒
        //CIColorPosterize
        //CIMaskToAlpha：油絵
        //CIColorMonochrome
        let videoComposition = AVVideoComposition(asset: asset) { request in
            filter.setValue(request.sourceImage, forKey: kCIInputImageKey)
            let output = filter.outputImage!.cropped(to: request.sourceImage.extent)
            
            //加工にかかる時間
            let cmTime = request.compositionTime
            let value = cmTime.value
            let timeScale = cmTime.timescale
            let processingTime = Int(value)/Int(timeScale)
              DispatchQueue.main.async {
            self.processingLabel.text = String(processingTime)
            }
            request.finish(with: output, context: nil)
            
        }
        let tmpURL = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("video.mp4")
        
        try? FileManager.default.removeItem(at: tmpURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            fatalError()
        }
        
        exportSession.outputURL = tmpURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        
        //ライブラリに保存
        exportSession.exportAsynchronously {
            UISaveVideoAtPathToSavedPhotosAlbum(tmpURL.path, nil, nil, nil)
             SVProgressHUD.dismiss()
            SVProgressHUD.showSuccess(withStatus: "保存完了")
        }
        // ライブラリへ保存する（処理なし）
//        PHPhotoLibrary.shared().performChanges({
//            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
//        }) { completed, error in
//            if completed {
//                print("Video is saved!")
//            }
//        }
    }
    
    
    func screenInitialization(){
        startStopButton.setImage(UIImage(named: isRecoding ? "square.png" : "circle.png"), for: .normal)
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
        } else { // 録画開始
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
