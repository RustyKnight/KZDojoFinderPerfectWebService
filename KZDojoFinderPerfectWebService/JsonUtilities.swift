//
//  JsonUtilities.swift
//  KZDojoFinderPerfectWebService
//
//  Created by Shane Whitehead on 15/04/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import PerfectLib

func encodeResponse(values: [String: AnyObject], forResponse response: WebResponse) {
	encodeResponse(values, forResponse: response, withStatus: 200, andMessage: "OK")
}

func encodeErrorResponse(errorCode: Int, withMessage: String, forResponse response: WebResponse) {
	
	var jsonResults = [String: AnyObject]()
	jsonResults["status"] = "error"
	jsonResults["count"] = 0
	jsonResults["error"] = withMessage
	
	encodeResponse(jsonResults, forResponse: response, withStatus: errorCode, andMessage: withMessage)
	
}

func encodeResponse(values: [String: AnyObject], forResponse response: WebResponse, withStatus: Int, andMessage: String) {
	
	let isValid = NSJSONSerialization.isValidJSONObject(values)
	if isValid {
		do {
			let dataFinal:NSData =  try NSJSONSerialization.dataWithJSONObject(values,
			                                                                   options: .PrettyPrinted)
			//			                                                                   options: NSJSONWritingOptions(rawValue: 0))
			let text = String(data: dataFinal, encoding: NSUTF8StringEncoding)
			if let text = text {
				response.addHeader("content-type", value: "application/json")
				response.appendBodyString(text)
				response.setStatus(withStatus, message: andMessage)
			} else {
				encodeErrorResponse(400, withMessage: "JSON encoding failed for unknown reason", forResponse: response)
			}
		} catch let message {
			encodeErrorResponse(400, withMessage: "\(message)", forResponse: response)
		}
	}
	
}
