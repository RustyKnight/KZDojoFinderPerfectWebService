//
//  GetRegionContactPictureHandler.swift
//  KZDojoFinderPerfectWebService
//
//  Created by Shane Whitehead on 19/04/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import PerfectLib
import PostgreSQL

/*
Handler for getting the dojos within a specific region/area
*/
public class GetRegionContactPictureHandler: RequestHandler {
	
	// I had been expermenting with the idea of using a BLOB and sending
	// the binrary image back directly, but there seems to be a problem
	// with counting the length of the BLOB for some reason, so instead
	// now I've base64 encoded the image before it's inserted into the
	// database
	
	func queryForDatabase(parameters: [String: String]) -> Query {
		return Query(query: "select picture, picturetype from regioncontacts where key = $1",
		             parameters: [parameters["key"]!])
	}
	
	func parseResults(results: PGResult, parameters: [String: String]) throws -> RequestResponse {
		guard results.status() == PGResult.StatusType.TuplesOK else { throw DatabaseError.QueryFailed("Database query for Dojos failed, database returned \(results.status())")}
		
		guard results.numTuples() >= 1 else { throw DatabaseError.TooManyRecordsFoundForQuery("More then one picture found for dojo") }
		
		let fieldNames = loadResultsFieldNameMappingsFrom(results)
		var response = [String: AnyObject]()
		// A 0 result is okay, we can accept that
		if results.numTuples() > 0 {
			response["picture"] = results.getFieldString(0, fieldIndex: fieldNames["picture"]!)
			response["type"] = results.getFieldString(0, fieldIndex: fieldNames["picturetype"]!)
		}
		
		return RequestResponse(key: "picture", value: response, count: 1)
	}
	
	public func handleRequest(request: WebRequest, response: WebResponse) {
		
		defer {
			response.requestCompletedCallback()
		}
		
		processWebServiceRequest(request, withParameters: ["key"],
		                         usingDatabaseQuery: self.queryForDatabase,
		                         andParser:	self.parseResults,
		                         andRespondWith: response)
	}
}
