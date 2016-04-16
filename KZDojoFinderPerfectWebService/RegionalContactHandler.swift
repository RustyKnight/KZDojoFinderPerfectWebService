//
//  RegionalContactHandler.swift
//  KZDojoFinderPerfectWebService
//
//  Created by Shane Whitehead on 16/04/2016.
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


class GetRegionContactHandler: RequestHandler {
	
	func handleRequest(request: WebRequest, response: WebResponse) {
		
		defer {
			response.requestCompletedCallback()
		}
		
		print("parms \(request.params())")
		
		let region = request.param("region")
		
		if let region = region {
			
			let connection = PGConnection()
			defer {
				connection.close()
			}
			let status = connectToDatabase(connection)
			
			guard status == .OK else {
				encodeErrorResponse(400, withMessage: "Failed to connect to database, responded with status of \(status)", forResponse: response)
				return;
			}
			
			do {
				let results = connection.exec("select * from regioncontacts where region = $1",
				                              params: [region])
				let contact = try loadRegionContactDatabaseResultsFrom(results)

				guard contact.count > 0 else {
					encodeErrorResponse(400, withMessage: "Could not find any regional contact for region \(region)", forResponse: response)
					return;
				}
				guard contact.count == 1 else {
					encodeErrorResponse(400, withMessage: "Found more then one regional contact for region \(region)?", forResponse: response)
					return;
				}
				
				var jsonResults = [String: AnyObject]()
				jsonResults["status"] = "ok"
				jsonResults["count"] = contact.count
				jsonResults["contact"] = contact[0]
					
				encodeResponse(jsonResults, forResponse: response)
			} catch let message {
				encodeErrorResponse(400, withMessage: "Failed to execute request: \(message)", forResponse: response)
			}
			
		} else {
			encodeErrorResponse(400, withMessage: "One or missing parameters", forResponse: response)
		}
		
	}
}

