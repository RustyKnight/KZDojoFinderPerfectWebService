//
//  DojoHandler.swift
//  KZDojoFinderPerfectWebService
//
//  Created by Shane Whitehead on 15/04/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import PerfectLib
import PostgreSQL

/**
A series of specalised Dojo based errors
*/
enum DojoDatabaseError: ErrorType {
	case NoRecordFoundWithKey(String)
	case TooManyRecordsWithKey(String)
}

/**
This returns an array of rows stored in a simple dictionary which represent
the data for from the Dojos table in the database.
*/
func loadDojoDatabaseResultsFrom(results: PostgreSQL.PGResult) throws -> [[String: AnyObject]]{
	guard results.status() == PGResult.StatusType.TuplesOK else { throw DatabaseError.QueryFailed("Database query for Dojos failed, database returned \(results.status())")}

	var rows = [[String: AnyObject]]()

	let fieldNames = loadResultsFieldNameMappingsFrom(results)
	for row in 0..<results.numTuples() {
		rows.append(loadDojoDatabaseResultsFrom(results, forRow: row, withFieldNames: fieldNames))
	}
	return rows
}
//
///**
//Loads the field name mappings, mapping a name to a field index...
//because apparently you can only access fields from a result by index and not name
//*/
//func loadDojoFieldNameMappingsFrom(results: PostgreSQL.PGResult) -> [String: Int] {
//	var fieldNames = [String: Int]()
//	for col in 0..<results.numFields() {
//		fieldNames[results.fieldName(col)!] = col
//	}
//	return fieldNames;
//}

/**
Loads a single row of dojo results from the database results, the intention is to make it "easier" to load
results based on the needs of the caller, without having to further duplicate code where possible

When I figure out how to determine the column types, this will probably become a utility method in
the database utilities file
*/
func loadDojoDatabaseResultsFrom(results: PostgreSQL.PGResult, forRow row: Int, withFieldNames fieldNames:[String: Int]) -> [String: AnyObject] {
	var values = [String: AnyObject]()
	
	let key = results.getFieldInt64(row, fieldIndex: fieldNames["key"]!)
	let name = results.getFieldString(row, fieldIndex: fieldNames["name"]!)
	let address = results.getFieldString(row, fieldIndex: fieldNames["address"]!)
	let region = results.getFieldInt64(row, fieldIndex: fieldNames["region"]!)
	let latitude = results.getFieldDouble(row, fieldIndex: fieldNames["latitude"]!)
	let longitude = results.getFieldDouble(row, fieldIndex: fieldNames["longitude"]!)
	
	values["key"] = Int(key)
	values["name"] = name
	values["address"] = address
	values["region"] = Int(region)
	values["latitude"] = latitude
	values["longitude"] = longitude

	return values
}

/*
Helper function for loading a individual dojo by a given key
*/
func loadDojoByKey(key: String, fromConnection connection: PGConnection) throws -> [String: AnyObject]? {
	let results = connection.exec("select * from dojos where key = $1",
	                     params: [key])
	
	guard results.status() == PGResult.StatusType.TuplesOK else {
		throw DatabaseError.QueryFailed("Query for dojo by key (\(key)) failed, database returned \(results.status())")
	}
	
	let parsedResults = try loadDojoDatabaseResultsFrom(results);
	guard parsedResults.count == 0 else { throw DojoDatabaseError.NoRecordFoundWithKey("No dojos found with key \(key)") }
	guard parsedResults.count > 1 else { throw DojoDatabaseError.TooManyRecordsWithKey("More then one dojo found with key \(key)") }
	
	return parsedResults[0]
}


/*
Handler for getting the dojos within a specific region/area
*/
public class GetDojosWithinHandler: RequestHandler {
	
	public func handleRequest(request: WebRequest, response: WebResponse) {
		
		print("parms \(request.params())")
		
		let startLat = request.param("startLat")
		let startLon = request.param("startLon")
		let endLat = request.param("endLat")
		let endLon = request.param("endLon")
		
		if let startLat = startLat, let startLon = startLon, let endLat = endLat, let endLon = endLon {
			
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
				let results = connection.exec("select * from dojos where latitude < $1 and latitude > $2 and longitude > $3 and longitude < $4",
				                     params: [startLat, endLat, startLon, endLon])
				let dojos = try loadDojoDatabaseResultsFrom(results)
				
				var jsonResults = [String: AnyObject]()
				jsonResults["status"] = "ok"
				jsonResults["count"] = dojos.count
				jsonResults["dojos"] = dojos
				
				encodeResponse(jsonResults, forResponse: response)
			} catch let message {
				encodeErrorResponse(400, withMessage: "Failed to execute request: \(message)", forResponse: response)
			}
		
		} else {
			encodeErrorResponse(400, withMessage: "One or missing parameters", forResponse: response)
		}
		
		response.requestCompletedCallback()
	}
}
