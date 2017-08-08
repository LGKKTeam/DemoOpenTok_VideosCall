//
//  ViewController.swift
//  DemoOpenTok
//
//  Created by Nguyen Minh on 8/7/17.
//  Copyright © 2017 ahdenglish. All rights reserved.
//

import UIKit
import OpenTok

// Replace with your OpenTok API key
var kApiKey = ""
// Replace with your generated session ID
var kSessionId = ""
// Replace with your generated token
var kToken = ""

class ViewController: UIViewController {
    
    var session: OTSession? // Step 1
    var publisher: OTPublisher? // Step 3
    var subscriber: OTSubscriber? // Step 5

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        let url = URL(string: "https://demoopentok2.herokuapp.com/session")
        let dataTask = session.dataTask(with: url!) {
            (data: Data?, response: URLResponse?, error: Error?) in
            
            guard error == nil, let data = data else {
                print(error!)
                return
            }
            
            let dict = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyHashable: Any]
            kApiKey = dict?["apiKey"] as? String ?? ""
            kSessionId = dict?["sessionId"] as? String ?? ""
            kToken = dict?["token"] as? String ?? ""
            self.connectToAnOpenTokSession()
            
            print("kApiKey: \(kApiKey)")
            print("kSessionId: \(kSessionId)")
            print("kToken: \(kToken)")
        }
        dataTask.resume()
        session.finishTasksAndInvalidate()
    }

    func connectToAnOpenTokSession() {
        session = OTSession(apiKey: kApiKey, sessionId: kSessionId, delegate: self)
        var error: OTError?
        session?.connect(withToken: kToken, error: &error)
        
        // Or disconnect session
//        session?.disconnect(&error)
        
        if error != nil {
            print(error!)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - OTSessionDelegate callbacks
// Step 2
extension ViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("The client connected to the OpenTok session.")
        // Checking whether a client has publish capabilities
        if (session.capabilities?.canPublish)! {
            // The client can publish.
            doPublish()
            
        } else {
            // The client cannot publish.
            // You may want to notify the user.
            print("The client cannot publish.")
        }
    }
    
    func doPublish() {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        guard let publisher = OTPublisher(delegate: self, settings: settings) else {
            return
        }
        
        self.publisher = publisher
        
        var error: OTError?
        session?.publish(publisher, error: &error)
        guard error == nil else {
            print(error!)
            return
        }
        
        guard let publisherView = publisher.view else {
            return
        }
        let screenBounds = UIScreen.main.bounds
        publisherView.frame = CGRect(x: screenBounds.width - 150 - 20, y: screenBounds.height - 150 - 20, width: 150, height: 150)
        view.addSubview(publisherView)
    }
    
    func stopPublish() {
        var error: OTError?
        session?.unpublish(publisher!, error: &error)
        if let error = error {
            print("Publishing failed with error: \(error)")
        }
    }
    
    func cleanupPublisher() {
        publisher?.view?.removeFromSuperview()
        publisher = nil
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("The client disconnected from the OpenTok session.")
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("The client failed to connect to the OpenTok session: \(error).")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        subscriber = OTSubscriber(stream: stream, delegate: self)
        doSubscribe()
    }
    
    func doSubscribe() {
        guard let subscriber = subscriber else {
            return
        }
        var error: OTError?
        session?.subscribe(subscriber, error: &error)
        guard error == nil else {
            print(error!)
            return
        }
        
        guard let subscriberView = subscriber.view else {
            return
        }
        subscriberView.frame = UIScreen.main.bounds
        view.insertSubview(subscriberView, at: 0)
    }
    
    func cleanupSubscriber() {
        subscriber?.view?.removeFromSuperview()
        subscriber = nil
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("A stream was destroyed in the session.")
    }
}

// MARK: - OTPublisherDelegate callbacks
// Step 4
extension ViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("The publisher failed: \(error)")
        cleanupPublisher()
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        cleanupPublisher()
    }
    
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        print("Now publishing.")
    }
}

// MARK: - OTSubscriberDelegate callbacks
extension ViewController: OTSubscriberDelegate {
    public func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        print("The subscriber did connect to the stream.")
    }
    
    public func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("The subscriber failed to connect to the stream.")
    }
}
