//
//  ViewController.swift
//  ZYPlayer-Swift
//
//  Created by 嘴爷 on 2019/11/26.
//  Copyright © 2019 嘴爷. All rights reserved.
//

import UIKit

import AVKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    
    
    
    var videoController : VideoListController?

    lazy var playerItem: AVPlayerItem = {
        
        let url = URL(string: "http://txmov2.a.yximgs.com/bs2/newWatermark/MTE3NjcxNzQ4MTg_zh_3.mp4")
        return AVPlayerItem(url: url!)
    }()
    
    lazy var player: AVPlayer = {
        
        return AVPlayer(playerItem: playerItem)
    }()
    
    lazy var playerLayer: AVPlayerLayer = {
        
        let p_layer = AVPlayerLayer(player: player)
        p_layer.videoGravity = .resizeAspect
        p_layer.backgroundColor = UIColor.black.cgColor
        return p_layer
    }()
    
    var disPlayLink: CADisplayLink?
    
    private var _isDragging = false
    private var _notificationInfos:[NSNotification.Name : Selector] = [:]
    private var _observerKeyPathes:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let originY = UIApplication.shared.statusBarFrame.height
        playerLayer.frame = CGRect(x: 0, y: originY, width: view.frame.width, height: 300)
        view.layer.addSublayer(playerLayer)
        
        addNotification()
        addObserverForPlayerItem()
        
        disPlayLink = CADisplayLink(target: self, selector: #selector(updateUI))
        disPlayLink?.add(to: RunLoop.current, forMode: .default)
        // Do any additional setup after loading the view.
    }
    
    func addObserverForPlayerItem(){
        _observerKeyPathes = [
            "status",                   //播放器状态变化
            "loadedTimeRanges",         //缓冲进度
            "playbackBufferEmpty",      // 缓冲区空了，需要等待数据
            "playbackLikelyToKeepUp"    //缓存足够播放的状态
        ]
        
        for item in _observerKeyPathes {

            playerItem.addObserver(self, forKeyPath: item , options: NSKeyValueObservingOptions.new, context: nil)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        switch keyPath {
        case "status":
//            print("状态改变")
//            print(playerItem.status)
            let duration = CMTimeGetSeconds(playerItem.duration)
            let minute = Int(duration) / 60
            let second = Int(duration) % 60
            totalTimeLabel.text = String(minute) + ":" + String(second)
            if playerItem.asset is AVURLAsset {
                imageView.image = getVideoPreViewAVAsset(asset: playerItem.asset as! AVURLAsset)
            }
    
        case "loadedTimeRanges":
//            print("进度改变")
            if let info = change {
                let ranges = info[.newKey] as! NSArray
//                print(ranges)
                let range = ranges.firstObject as! CMTimeRange
                let bufferDuration = CMTimeAdd(range.start , range.duration)
                progressView.progress = Float(CMTimeGetSeconds(bufferDuration) / CMTimeGetSeconds(playerItem.duration))
            }

        default:
            print("other")
        }

    }
    
    @objc func updateUI() {
        if _isDragging {
            
            return
        }
        
        let duration = CMTimeGetSeconds(self.playerItem.duration)
        if (duration <= 0) {
            return;
        }
        
        let currentTime = CMTimeGetSeconds(playerItem.currentTime())
        
        let minute = Int(currentTime) / 60
        let second = Int(currentTime) % 60
        currentTimeLabel.text = String(minute) + ":" + String(second)
//            [NSString stringWithFormat:@"%02d:%02d", (int)currentTime / 60, (int)currentTime % 60];
        
        slider.value = Float(currentTime) / Float(duration)
    }

    
    
    func addNotification() {
        _notificationInfos = [UIDevice.orientationDidChangeNotification: #selector(screenRotate),
                              NSNotification.Name.AVPlayerItemDidPlayToEndTime: #selector(playToEnd),
                              NSNotification.Name.AVPlayerItemFailedToPlayToEndTime: #selector(failedToPlay),
                              NSNotification.Name.AVPlayerItemPlaybackStalled: #selector(playbackStalled),
                              AVAudioSession.interruptionNotification: #selector(audioSessionInterruption),
                              AVAudioSession.routeChangeNotification: #selector(audioSessionRouteChange),
                              UIApplication.willResignActiveNotification: #selector(applicationWillResignActive),
                              UIApplication.didBecomeActiveNotification: #selector(applicationDidBecomeActive)
        ]
        
        for (key,value) in _notificationInfos {

            NotificationCenter.default.addObserver(self, selector: value, name: key, object: nil)
        }
        
    }
    
    //    MARK:notification
    //返回前台
    @objc func applicationDidBecomeActive (notification: Notification){
        print("applicationDidBecomeActive")
    }
    
    //进入后台
    @objc func applicationWillResignActive (notification: Notification){
        print("applicationWillResignActive")
    }

    //耳机插入和拔出的通知
    @objc func audioSessionRouteChange (notification: Notification){
        print("audioSessionRouteChange")
    }

    //声音被打断的通知（电话打来）
    @objc func audioSessionInterruption (notification: Notification){
        print("audioSessionInterruption")
    }

    //播放失败
    @objc func playbackStalled (notification: Notification){
        print("playbackStalled")
    }

    //异常中断
    @objc func failedToPlay (notification: Notification){
        print("failedToPlay")
    }

    //播放完成
    @objc func playToEnd (notification: Notification){
        print("playToEnd")
        print(notification)
        var time = player.currentTime()
        time.value = 0
        player .seek(to: time) { (finished: Bool) in
            print("seek到初始位置")
            self.player.play()
        }

    }

    //屏幕旋转
    @objc func screenRotate (notification: Notification){
        print("screenRotate")
        
        /*  UIDeviceOrientation.portrait
         case portrait // Device oriented vertically, home button on the bottom
         
         case portraitUpsideDown // Device oriented vertically, home button on the top
         
         case landscapeLeft // Device oriented horizontally, home button on the right
         
         case landscapeRight // Device oriented horizontally, home button on the left
         
         case faceUp // Device oriented flat, face up
         
         case faceDown // Device oriented flat, face down
         */
    }

    
    //    MARK: -IBAction
    @IBAction func setRate(_ sender: UISlider) {
        player.rate = sender.value//0暂停，超过2之后视频会卡住，音频不影响
    }
    @IBAction func play(_ sender: UISlider) {
        if sender.isSelected {
            player.pause()
        }else{
            self.player.play()
        }
        
        sender.isSelected = !sender.isSelected
    }
    @IBAction func sliderTouchDown(_ sender: UISlider) {
        _isDragging = true
    }
    @IBAction func sliderTouchUpInside(_ sender: UISlider) {
        _isDragging = false
        seekToPosion()
    }
    @IBAction func sliderTouchUpOutSide(_ sender: UISlider) {
        _isDragging = false
        seekToPosion()
    }
    
    @IBAction func sliderDrag(_ sender: UISlider) {
        let duration = CMTimeGetSeconds(self.playerItem.duration)
        if duration <= 0 {
            
            return
        }
        
        let currentTime = Float(duration) * sender.value
        currentTimeLabel.text = String(currentTime)
//        self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)currentTime / 60, (int)currentTime % 60];
    }
    
    //    MARK: pirvate method
    func seekToPosion(){
        let duration = CMTimeGetSeconds(playerItem.duration)
        let currentTime = Float(duration) * slider.value
        var time = player.currentTime()
        time.value = CMTimeValue(currentTime * Float(time.timescale))
        player.seek(to: time) { (finished: Bool) in
            print("seek到 \(currentTime) 位置")
        }
    }
    
    func changeVideo(info:[String:String]){
        let url = URL(string: info["url"]!)
        playerItem = AVPlayerItem(url: url!)
        player.replaceCurrentItem(with: playerItem)
    }
    
    // 获取视频第一帧
    func getVideoPreViewAVAsset (asset: AVURLAsset) -> UIImage {
        
        let assetGen = AVAssetImageGenerator(asset: asset)
        assetGen.appliesPreferredTrackTransform = true
        let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 600)
        
        let actualTime = UnsafeMutablePointer<CMTime>.allocate(capacity: 0)
        let image = try! assetGen.copyCGImage(at: time, actualTime: actualTime)
        let videoImage = UIImage(cgImage: image)
        
        return videoImage
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        /*
        guard segue.destination is VideoListController else {
            print("不是视频列表")
            return
        }
        */
        
        if segue.destination is VideoListController {
            
            videoController = segue.destination as? VideoListController
            videoController?.callBack = {
                (video: [String : String]) -> () in
                
                let name = video["name"]
                print(name!)
                self.changeVideo(info: video)
            }
        }
        
        
    }

}


