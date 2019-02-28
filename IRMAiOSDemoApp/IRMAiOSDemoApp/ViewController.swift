//
//  ViewController.swift
//  IRMAiOSDemoApp
//
//  Created by David on 1/22/19.
//  Copyright © 2019 Example. All rights reserved.
//

import UIKit
import irmaios

class ViewController: UIViewController {
    enum SessionState {
        case Initial
        case Starting
        case Waiting
        case Fetching
        case Done
    }
    struct SessionMessage: Codable {
        var token: String
        var sessionptr: String
    }
    
    var state: SessionState = SessionState.Initial
    var status: String = "Ready"
    var sessionMsg: SessionMessage = SessionMessage(token: "", sessionptr: "")
    var recvToken: String = ""
    
    @IBOutlet weak var output: UILabel!
    @IBOutlet weak var input: UIButton!
    
    func handleToken(_ token: String) {
        state = SessionState.Fetching
        status = "Fetching result..."
        updateStatus()
        input.setTitle("Reset", for: .normal)
        recvToken = token
        performSelector(inBackground: #selector(fetchResults), with: nil)
    }
    
    @objc func fetchResults() {
        // Handle the result of the irma session, this will be application specific!
        //
        // Here we just query the server for the disclosed attribute and display it
        // but you might want to do different things here, such as letting the server
        // return an access token.
        //
        // In a production app, this is also where you handle sessions that were
        // cancelled or gave an error. Here, that just results in the text ERROR or
        // CANCELLED being returned by the server and being displayed.

    	// Do an http request to get the results.
        var resultURLBuilder = URLComponents()
        resultURLBuilder.scheme = "http"
        resultURLBuilder.host = "localhost"
        resultURLBuilder.port = 8080
        resultURLBuilder.path = "/fetch"
        resultURLBuilder.query = recvToken
        
        if let url = resultURLBuilder.url {
            if let result = try? String(contentsOf: url) {
            	// And display the response from the server
                status = "Result: " + result
            } else {
                status = "Error: Could not fetch results"
            }
            performSelector(onMainThread: #selector(updateStatus), with: nil, waitUntilDone: false)
        } else {
            status = "Error: Internal"
            performSelector(onMainThread: #selector(updateStatus), with: nil, waitUntilDone: false)
        }
    }
    
    @IBAction func onInputPress() {
        if state == SessionState.Initial {
            status = "Starting irma session..."
            updateStatus()
            input.setTitle("Reset", for: .normal)
            state = SessionState.Starting
            // All the actual work is done in a background thread.
            performSelector(inBackground: #selector(startSession), with: nil)
        } else {
            reset()
        }
    }
    
    @objc func startSession() {
        // We ask the server for a session.
        let urlString : String = "http://localhost:8080/startSession"
        
        if let url = URL(string : urlString) {
            if let data = try? Data(contentsOf: url) {
                let decoder = JSONDecoder()
                // We get back a token known to the server (so it can give us
                // results later), and the session pointer (which the irma app
                // needs to start the actual irma transaction).
                if let sesMsg = try? decoder.decode(SessionMessage.self, from: data) {
                    sessionMsg = sesMsg
                    performSelector(onMainThread: #selector(openSession), with: nil, waitUntilDone: false)
                } else {
                    status = "Error: Could not decode session start message"
                    performSelector(onMainThread: #selector(updateStatus), with: nil, waitUntilDone: false)
                }
            } else {
                status = "Error: Could not fetch session"
                performSelector(onMainThread: #selector(updateStatus), with:nil, waitUntilDone: false)
            }
        } else {
            status = "Error: Could not convert string to URL object"
            performSelector(onMainThread: #selector(updateStatus), with: nil, waitUntilDone: false)
        }
    }
    
    @objc func openSession() {
        if state == SessionState.Starting {
            state = SessionState.Waiting
            
            // Construct an url for returning to this app
            let retURLString = "irmatest:retdemo?" + sessionMsg.token
            
            // And start the irma_mobile app
            if StartIRMA(sessionPointer:sessionMsg.sessionptr, returnURL: retURLString) {
                status = "Waiting..."
            } else {
                status = "Error: Internal error"
            }
            updateStatus()
        }
    }
    
    @objc func updateStatus() {
        output.text = status
    }
    
    func reset() {
        state = SessionState.Initial
        output.text = "Ready"
        input.setTitle("Start session", for: .normal)
    }
}

