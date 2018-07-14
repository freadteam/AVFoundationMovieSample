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
    var selectedfilter = "CIPhotoEffectTonal"
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var processingLabel: UILabel!
    
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
    //録画開始
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {

    }
    
    //delegate、録画完了
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
       //-----------------------------------------------------------------
        SVProgressHUD.show()
        //フィルターをかける
        let asset = AVAsset(url: outputFileURL)
        let filter = CIFilter(name: selectedfilter)!
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

    @IBAction func selectFilter() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let alert1 = UIAlertAction(title: "CIPhotoEffectTonal", style: .destructive) { (action) in
            self.selectedfilter = "CIPhotoEffectTonal"
        }
        let alert2 = UIAlertAction(title: "CIMinimumComponent", style: .destructive) { (action) in
            self.selectedfilter = "CIMinimumComponent"
        }
        let alert3 = UIAlertAction(title: "CIPhotoEffectTonal", style: .destructive) { (action) in
            self.selectedfilter = "CIPhotoEffectTonal"
        }
        let alert4 = UIAlertAction(title: "CIColorPosterize", style: .destructive) { (action) in
            self.selectedfilter = "CIColorPosterize"
        }
        let alert5 = UIAlertAction(title: "CIPhotoEffectMono", style: .destructive) { (action) in
            self.selectedfilter = "CIPhotoEffectMono"
        }
        let alert6 = UIAlertAction(title: "CIPhotoEffectNoir", style: .destructive) { (action) in
            self.selectedfilter = "CIPhotoEffectNoir"
        }
        let alert7 = UIAlertAction(title: "CIColorPosterize", style: .destructive) { (action) in
            self.selectedfilter = "CIColorPosterize"
        }
        let alert8 = UIAlertAction(title: "CIMaskToAlpha", style: .destructive) { (action) in
            self.selectedfilter = "CIMaskToAlpha"
        }
        let alert9 = UIAlertAction(title: "CIColorMonochrome", style: .destructive) { (action) in
            self.selectedfilter = "CIColorMonochrome"
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(alert1)
        alertController.addAction(alert2)
        alertController.addAction(alert3)
        alertController.addAction(alert4)
        alertController.addAction(alert5)
        alertController.addAction(alert6)
        alertController.addAction(alert7)
        alertController.addAction(alert8)
        alertController.addAction(alert9)
        alertController.addAction(cancelAction)
        //ipadで必須
        alertController.popoverPresentationController?.sourceView = self.view
        let screenSize = UIScreen.main.bounds
        // ここで表示位置を調整
        // xは画面中央、yは画面下部になる様に指定
        alertController.popoverPresentationController?.sourceRect = CGRect(x: screenSize.size.width/2, y: screenSize.size.height, width: 0, height: 0)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
