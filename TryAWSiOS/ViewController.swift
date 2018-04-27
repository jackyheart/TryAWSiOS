//
//  ViewController.swift
//  TryAWSiOS
//
//  Created by PIXERF_SG_WS_12 on 26/4/18.
//  Copyright © 2018 PIXERF_SG_WS_12. All rights reserved.
//

import UIKit
import AWSDynamoDB
import AWSMobileClient
import AWSS3
import AWSLex

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var voiceBtn: AWSLexVoiceButton!
    

    
    override func viewDidLoad() {
       
        // Do any additional setup after loading the view, typically from a nib.
        
        //Lex
        // Set the bot configuration details
        // You can use the configuration constants defined in AWSConfiguration.swift file
        let botName = "BookTripMOBILEHUB"
        let botRegion: AWSRegionType = AWSRegionType.USEast1
        let botAlias = "$LATEST"
        
        // set up the configuration for AWS Voice Button
        let configuration = AWSServiceConfiguration(region: botRegion, credentialsProvider: AWSMobileClient.sharedInstance().getCredentialsProvider())
        let botConfig = AWSLexInteractionKitConfig.defaultInteractionKitConfig(withBotName: botName, botAlias: botAlias)
        
        // register the interaction kit client for the voice button using the AWSLexVoiceButtonKey constant defined in SDK
        AWSLexInteractionKit.register(with: configuration!, interactionKitConfiguration: botConfig, forKey: AWSLexVoiceButtonKey)
        
        super.viewDidLoad()
        self.voiceBtn.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        createNews()
    }
    
    @IBAction func readTapped(_ sender: Any) {
        readNews()
    }
    
    @IBAction func updateTapped(_ sender: Any) {
        updateNews()
    }
    
    @IBAction func deleteTapped(_ sender: Any) {
        deleteNews()
    }
    
    @IBAction func queryTapped(_ sender: Any) {
        queryNews()
    }
    
    @IBAction func uploadTapped(_ sender: Any) {
        uploadData()
    }
    
    @IBAction func downloadTapped(_ sender: Any) {
        downloadData()
    }
}

//Dynamo DB
extension ViewController {
    
    func createNews() {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        // Create data object using data models you downloaded from Mobile Hub
        let newsItem: News = News()
        
        /*
         var _articleId: String?
         var _author: String?
         var _category: String?
         var _content: String?
         var _creationDate: NSNumber?
         var _keywords: Set<String>?
         var _title: String?
         */
        
        newsItem._userId = AWSIdentityManager.default().identityId
        
        newsItem._articleId = "MyArticleId"
        newsItem._title = "MyTitleString"
        newsItem._author = "MyAuthor"
        newsItem._category = "MyCategory"
        newsItem._content = "MyContent"
        newsItem._keywords = ["key1", "key2", "key3"]
        newsItem._creationDate = NSDate().timeIntervalSince1970 as NSNumber
        
        //save a new item
        dynamoDBObjectMapper.save(newsItem) { (error) in
            if let error = error {
                print("Amazon DyanmoDB save error: \(error)")
                return
            }
            print("A new News item was saved!")
        }
    }
    
    func readNews() {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        // Create data object using data models you downloaded from Mobile Hub
        let newsItem: News = News();
        newsItem._userId = AWSIdentityManager.default().identityId
        
        dynamoDBObjectMapper.load(News.self, hashKey: newsItem._userId!, rangeKey: "MyArticleId") { (objectModel: AWSDynamoDBObjectModel?, error:Error?) in
            if let error = error {
                print("Amazon DynamoDB Read Error: \(error)")
                return
            }
            print("An item was read.")
        }
    }
    
    func updateNews() {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let newsItem:News = News()
        newsItem._userId = "unique-user-id"
        newsItem._articleId = "YourArticleId"
        newsItem._title = "This is the Title"
        newsItem._author = "B Smith"
        newsItem._creationDate = NSDate().timeIntervalSince1970 as NSNumber
        newsItem._category = "Local News"
        
        dynamoDBObjectMapper.save(newsItem) { (error) in
            if let error = error {
                print(" Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("An item was updated.")
        }
    }
    
    func deleteNews() {
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let itemToDelete = News()
        itemToDelete?._userId = "unique-user-id"
        itemToDelete?._articleId = "YourArticleId"
        
        dynamoDBObjectMapper.remove(itemToDelete!) { (error) in
            if let error = error {
                print(" Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("An item was deleted.")
        }
    }
    
    func queryNews() {
        
        // 1) Configure the query
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.keyConditionExpression = "#articleId >= :articleId AND #userId = :userId"
        
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
            "#articleId": "articleId"
        ]
        queryExpression.expressionAttributeValues = [
            ":articleId": "SomeArticleId",
            ":userId": "unique-user-id"
        ]
        
        // 2) Make the query
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.query(News.self, expression: queryExpression) { (output:AWSDynamoDBPaginatedOutput?, error:Error?) in
            if error != nil  {
                print("The request failed. Error: \(String(describing: error))")
            }
            
            if output != nil {
                for news in output!.items {
                    let newsItem = news as? News
                    print("\(newsItem!._title!)")
                }
            }
        }
    }
}

//S3
extension ViewController {
    
    func uploadData() {
        
        let image = UIImage(named: "patlabor")
        let imageData = UIImageJPEGRepresentation(image!, 0.8)
        let bucketName = "tryawsios-userfiles-mobilehub-502442966"
        let fileName = "patlabor"
    
        let progressView = UIProgressView()
        progressView.progress = 0.0
        
        let data:Data = imageData!// Data to be uploaded
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = { (task, progress) in
            DispatchQueue.main.async {
                //update progress bar
                print("upload progress: \(progress)")
                progressView.progress = Float(progress.fractionCompleted)
            }
        }
        
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async {
                //alert user for transfer completion
                //on failed uploads, show error
                if let error = error {
                    print("failed with error: \(error)")
                }
                else if progressView.progress.isEqual(to: 1.0) {
                    print("error: failed")
                } else {
                    print("upload success")
                }
            }
        }
        
        var refUploadTask: AWSS3TransferUtilityTask?
        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.uploadData(data,
                                   bucket: bucketName,
                                   key: fileName,
                                   contentType: "image/jpeg",
                                   expression: expression,
                                   completionHandler: completionHandler).continueWith { (task) -> Any? in
            if let error = task.error {
                print("error: \(error.localizedDescription)")
            }
            
            if let uploadTask = task.result {
                //do something with upload task
                refUploadTask = uploadTask
                print("upload task: \(task.result!)")
            }
            
            return nil
        }
    }
    
    func downloadData() {
        
        let bucketName = "tryawsios-userfiles-mobilehub-502442966"
        let fileName = "patlabor"
        
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = {(task, progress) in DispatchQueue.main.sync {
            //update progress bar
            print("download progress: \(progress)")
        }}
        
        var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
        completionHandler = { (task, URL, data, error) -> Void in
            DispatchQueue.main.async {
                print("download complete")
                
                if let data = data {
                    self.imageView.image = UIImage(data: data)
                }
            }
        }
        
        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.downloadData(fromBucket: bucketName,
                                     key: fileName,
                                     expression: expression,
                                     completionHandler: completionHandler).continueWith { (task) -> Any? in
                                        
                                        if let error = task.error {
                                            print("error: \(error.localizedDescription)")
                                        }
                                        
                                        if let _ = task.result {
                                            //do something w/ download task
                                            print("download task: \(task.result!)")
                                        }
                                        
                                        return nil
        }
    }
}

extension ViewController: AWSLexVoiceButtonDelegate {
    
    func voiceButton(_ button: AWSLexVoiceButton, on response: AWSLexVoiceButtonResponse) {
        // handle response from the voice button here
        print("on text output \(response.outputText!)")
    }
    
    func voiceButton(_ button: AWSLexVoiceButton, onError error: Error) {
        // handle error response from the voice button here
        print("error \(error)")
    }
}
