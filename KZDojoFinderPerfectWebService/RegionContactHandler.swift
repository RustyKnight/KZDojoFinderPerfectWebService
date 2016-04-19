//
//  RegionContactHandler.swift
//  KZDojoFinderPerfectWebService
//
//  Created by Shane Whitehead on 20/04/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import PerfectLib
import PostgreSQL

func loadRegionContactDatabaseResultsFrom(results: PostgreSQL.PGResult) throws -> [[String: AnyObject]]{
	guard results.status() == PGResult.StatusType.TuplesOK else { throw DatabaseError.QueryFailed("Database query for Regional Contacts failed, database returned \(results.status())")}
	
	var rows = [[String: AnyObject]]()
	
	let fieldNames = loadResultsFieldNameMappingsFrom(results)
	for row in 0..<results.numTuples() {
		rows.append(loadRegionContactDatabaseResultsFrom(results, forRow: row, withFieldNames: fieldNames))
	}
	return rows
}

/**
Loads a single row of session results from the database results, the intention is to make it "easier" to load
results based on the needs of the caller, without having to further duplicate code where possible
*/
func loadRegionContactDatabaseResultsFrom(results: PostgreSQL.PGResult, forRow row: Int, withFieldNames fieldNames:[String: Int]) -> [String: AnyObject] {
	var values = [String: AnyObject]()
	
	let key = results.getFieldInt64(row, fieldIndex: fieldNames["key"]!)
	let phone = results.getFieldString(row, fieldIndex: fieldNames["phone"]!)
	let name = results.getFieldString(row, fieldIndex: fieldNames["name"]!)
	let facebook = results.getFieldString(row, fieldIndex: fieldNames["facebook"]!)
	let email = results.getFieldString(row, fieldIndex: fieldNames["email"]!)
	let region = results.getFieldInt64(row, fieldIndex: fieldNames["region"]!)
	
	values["key"] = Int(key)
	values["phone"] = phone
	values["name"] = name
	values["facebook"] = facebook
	values["email"] = email
	values["region"] = Int(region)
	
	return values
}

enum RegionContactError: ErrorType {
	case NoRecordFound(String)
	case TooManyRecordsFound(String)
}

class GetRegionContactHandler: RequestHandler {
	
	func queryForDataWithParameters(parameters: [String: String]) -> Query {
		return Query(query: "select * from regioncontacts where region = $1", parameters: [parameters["region"]!])
	}
	
	func parseDatabaseResults(results: PGResult, parameters: [String: String]) throws -> RequestResponse {
		let contact  = try loadRegionContactDatabaseResultsFrom(results)
		guard contact.count > 0 else {
			throw RegionContactError.NoRecordFound("Could not find any regional contact for region \(parameters["region"])")
		}
		guard contact.count == 1 else {
			throw RegionContactError.TooManyRecordsFound("Found more then one regional contact for region \(parameters["region"])?")
		}
		return RequestResponse(key: "contact", value: contact[0], count: contact.count)
	}
	
	func handleRequest(request: WebRequest, response: WebResponse) {
		
		defer {
			response.requestCompletedCallback()
		}
		
		processWebServiceRequest(request, withParameters: ["region"],
		                         usingDatabaseQuery: self.queryForDataWithParameters,
		                         andParser:	self.parseDatabaseResults,
		                         andRespondWith: response)
		
	}
}


