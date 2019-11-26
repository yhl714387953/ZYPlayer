//
//  VideoListController.swift
//  ZYPlayer-Swift
//
//  Created by 嘴爷 on 2019/11/26.
//  Copyright © 2019 嘴爷. All rights reserved.
//

import UIKit



class VideoListController: UIViewController, UITableViewDataSource,UITableViewDelegate {
    
    @IBOutlet weak var videoTableView: UITableView!

    open var callBack : ([String : String]) -> () = {param in }
    
    lazy var dataSource : [[String : String]] = {
        
        var videoList = [[String : String]]()
        let url = Bundle.main.path(forResource: "VideoList", ofType: "plist")
        if let myUrl = url {
            videoList = NSArray(contentsOfFile: myUrl) as! [[String : String]]
        }
        
        
        return videoList
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        print(dataSource)
        videoTableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "Cell")
        
        // Do any additional setup after loading the view.
    }
    
    
    //    MARK: dataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        let video = dataSource[indexPath.row]
        cell?.textLabel?.text = video["name"]
      
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let video = dataSource[indexPath.row]
        callBack(video)
        
        dismiss(animated: true) {
            
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
