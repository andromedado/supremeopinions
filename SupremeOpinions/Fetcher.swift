//
//  Fetcher.swift
//  SupremeOpinions
//
//  Created by Shad Downey on 3/8/15.
//
//

import Foundation

private let privateInstance : Fetcher = Fetcher()

class Fetcher : NSObject, NSURLSessionDelegate, NSURLSessionDataDelegate
{
    private let slipsURL = NSURL(string: "http://www.supremecourt.gov/opinions/slipopinions.aspx")!
    private var session : NSURLSession!
    private var tasks : [String : (NSURLSessionDataTask, [(NSData?, NSError?) -> ()])] = [:]

    class func instance () -> Fetcher {
        return privateInstance
    }

    override init() {
        super.init()
        self.session = NSURLSession(configuration: nil, delegate: self, delegateQueue: nil)
    }

    func fetch(#opinion: Opinion, callback:(NSData?, NSError?) -> ()) -> () {
        if (opinion.href?.absoluteString? == nil) {
            return
        }
        let url = opinion.href!
        let key = url.absoluteString!
        if var tuple = self.tasks[key] {
            tuple.1.append(callback)
            return
        }
        let task = self.session.dataTaskWithURL(url, completionHandler: { (data, res, err) -> Void in
            let tuple = privateInstance.tasks[key]!
            privateInstance.tasks.removeValueForKey(key)
            for callback in tuple.1 {
                callback(data, err)
            }
        })
        self.tasks[key] = (task, [callback])
        task.resume()
    }

    func fetchAvailableOpinions (completionBlock: (opinions:[Opinion]) -> ()) -> () {
        let task = self.session.dataTaskWithURL(self.slipsURL, completionHandler: { (data, res, err) -> Void in
            var opinions : [Opinion] = []
            if let resStr = NSString(data: data, encoding: NSUTF8StringEncoding) {
                opinions = Extractor.extract(resStr)
            }
            completionBlock(opinions: opinions)
        })
        task.resume()
    }

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        println("RESPONSE!")
    }

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        println("DATA!")
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        println("DONE!")
    }

}
