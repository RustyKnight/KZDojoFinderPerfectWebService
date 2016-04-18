//
//  SessionHandler.swift
//  KZDojoFinderPerfectWebService
//
//  Created by Shane Whitehead on 16/04/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import PerfectLib
import PostgreSQL

enum SessionServiceError: ErrorType {
	case MissingDojoParameter(String)
}


func parseSessionDatabaseResultsFrom(results: PostgreSQL.PGResult) throws -> [[String: AnyObject]]{
	guard results.status() == PGResult.StatusType.TuplesOK else { throw DatabaseError.QueryFailed("Database query for Sessions failed, database returned \(results.status())")}
	
	var rows = [[String: AnyObject]]()
	
	let fieldNames = loadResultsFieldNameMappingsFrom(results)
	for row in 0..<results.numTuples() {
		rows.append(parseSessionDatabaseResultsFrom(results, forRow: row, withFieldNames: fieldNames))
	}
	return rows
}

/**
Loads a single row of session results from the database results, the intention is to make it "easier" to load
results based on the needs of the caller, without having to further duplicate code where possible
*/
func parseSessionDatabaseResultsFrom(results: PostgreSQL.PGResult, forRow row: Int, withFieldNames fieldNames:[String: Int]) -> [String: AnyObject] {
	var values = [String: AnyObject]()
	
	let sessionKey = results.getFieldInt64(row, fieldIndex: fieldNames["key"]!)
	let dojoKey = results.getFieldInt64(row, fieldIndex: fieldNames["dojokey"]!)
	let dow = results.getFieldInt64(row, fieldIndex: fieldNames["dayofweek"]!)
	let details = results.getFieldString(row, fieldIndex: fieldNames["details"]!)
	let endTime = results.getFieldInt64(row, fieldIndex: fieldNames["endtime"]!)
	let startTime = results.getFieldInt64(row, fieldIndex: fieldNames["starttime"]!)
	let type = results.getFieldInt64(row, fieldIndex: fieldNames["type"]!)
	
	values["sessionkey"] = Int(sessionKey)
	values["dojokey"] = Int(dojoKey)
	values["dayofweek"] = Int(dow)
	values["details"] = details
	values["endtime"] = Int(endTime)
	values["starttime"] = Int(startTime)
	values["type"] = Int(type)
	
	return values
}


class GetDojoSessionsHandler: RequestHandler {

	func queryForDatabase(parameters: [String: String]) -> Query {
		return Query(query: "select * from sessions where sessions.dojokey = $1",
		             parameters: [parameters["dojo"]!])
	}
	
	func parseResults(results: PGResult, parameters: [String: String]) throws -> RequestResponse {
		let dojos = try parseSessionDatabaseResultsFrom(results)
		return RequestResponse(key: "sessions", value: dojos, count: dojos.count)
	}
	
	func addDojoToResponse(connection: PGConnection, parameters: [String: String]) throws -> RequestResponse {
		guard let dojoKey = parameters["dojo"] else {
			throw SessionServiceError.MissingDojoParameter("Parameter for dojo key is missing")
		}
		let dojo = try loadDojoByKey(dojoKey, fromConnection: connection)
		return RequestResponse(key: "dojo", value: dojo, count: 1)
	}

	func handleRequest(request: WebRequest, response: WebResponse) {
		defer {
			response.requestCompletedCallback()
		}
		
		processWebServiceRequest(request, withParameters: ["dojo"],
		                         usingDatabaseQuery: self.queryForDatabase,
		                         andParser:	self.parseResults,
		                         andRespondWith: response,
		                         withAdditionalResponses: [self.addDojoToResponse])

//		print("parms \(request.params())")
//		
//		let dojoKey = request.param("dojo")
//		
//		if let dojoKey = dojoKey {
//
//			let connection = PGConnection()
//			defer {
//				connection.close()
//			}
//			let status = connectToDatabase(connection)
//			
//			guard status == .OK else {
//				encodeErrorResponse(400, withMessage: "Failed to connect to database, responded with status of \(status)", forResponse: response)
//				return;
//			}
//			
//			do {
//				let results = connection.exec("select * from sessions where sessions.dojokey = $1",
//				                     params: [dojoKey])
//				let sessions = try loadSessionDatabaseResultsFrom(results)
//				
//				do {
//					var jsonResults = [String: AnyObject]()
//					jsonResults["status"] = "ok"
//					jsonResults["count"] = sessions.count
//					jsonResults["dojo"] = try loadDojoByKey(dojoKey, fromConnection: connection)
//					jsonResults["sessions"] = sessions
//					
//					encodeResponse(jsonResults, forResponse: response)
//				} catch let message {
//					print("Failed to load dojo by key: \(dojoKey); \(message)")
//					encodeErrorResponse(400, withMessage: "Error while trying to load dojo properties: \(message)", forResponse: response)
//				}
//			} catch let message {
//				encodeErrorResponse(400, withMessage: "Failed to execute request: \(message)", forResponse: response)
//			}
//			
//		} else {
//			encodeErrorResponse(400, withMessage: "One or missing parameters", forResponse: response)
//		}
//		
//		response.requestCompletedCallback()
	}
}

