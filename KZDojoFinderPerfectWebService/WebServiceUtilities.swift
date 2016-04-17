//
//  WebServiceUtilities.swift
//  KZDojoFinderPerfectWebService
//
//  Created by Shane Whitehead on 17/04/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import PerfectLib
import PostgreSQL

/**
This is a set of functions designed to take much of the repeated, boiler plate code
and make into a series of simplified functions, with the intention of reducing the
general code need to process a web service request

The primary function is the:
	processWebServiceRequest(request, withParameters, usingDatabaseQuery, andParser, andRespondWith)

This should be considered the main entry point and is intended to provide a means by
which the database can be quiered, the results gathered, parsed and prepared and finally
sent back via the WebResponse as a web response

The method will also check to see if the required named parameters are part of the WebRequest

The utility also includes a "status" and "count" values for the json along with the processed
results of the call

The utility will also encode error states and return them (normally) as a 400 error

*/

enum DatabaseRequestError: ErrorType {
	case DatabaseConnectionError(String)
}

struct Query {
	let query: String
	let parameters: [String]
}

struct RequestResponse {
	let key: String
	let value: AnyObject
	let count: Int
}

/**
Provides the functionality for parsing the database results

The request parameters and values are supplied in case they are need for any
additional information

The function returns the RequestResponse which contains the json key to use,
the values to be retured and the number of values, which is added to the json
as the "count" parameter
*/
typealias ResultParser = (PGResult, [String: String]) throws -> RequestResponse

/**
Provides the functionality for building the actual query which is executed against
the database.

The request parameters and values are provide so that they can be bound to the
queries parameters based on the requirements of the query.

Returns the Query, including the query text and the parameters that are to be
bound to the queries parameters
*/
typealias DatabaseQuery = ([String: String]) -> Query

/**
This function makes the connection to the database, executes the query and processes the results
and returns a dictionary of values which can be encoded into a json response
*/
func processWebServiceRequestWithQuery(query: Query, withParameters parameters:[String: String], parser: ResultParser) throws -> [String: AnyObject] {
	let connection = PGConnection()
	defer {
		connection.close()
	}
	let status = connectToDatabase(connection)
	
	guard status == .OK else {
		throw DatabaseRequestError.DatabaseConnectionError("Failed to connect to database, responded with status of \(status)")
	}
	
	let results = connection.exec(query.query,
	                              params: query.parameters)
	let queryResponse = try parser(results, parameters)
	var jsonResults = [String: AnyObject]()
	jsonResults["status"] = "ok"
	jsonResults["count"] = queryResponse.count
	jsonResults[queryResponse.key] = queryResponse.value
	
	return jsonResults
}

/**
This function encodes the results of the request into the response
*/
func processWebServiceRequestWithQuery(query: Query, withRequestParameters parameters:[String: String], parser: ResultParser, andRespondWith response: WebResponse) {
	do {
		let requestResponse = try processWebServiceRequestWithQuery(
			query,
			withParameters: parameters,
			parser: parser)
		
		encodeResponse(requestResponse, forResponse: response)
	} catch let message {
		encodeErrorResponse(400, withMessage: "\(message)", forResponse: response)
	}
}

func processWebServiceRequest(request: WebRequest, withParameters parameters: [String], usingDatabaseQuery query: DatabaseQuery, andParser parser: ResultParser, andRespondWith response: WebResponse) {
	var parameterValues = [String: String]()
	for parameter in parameters {
		if let value = request.param(parameter) {
			parameterValues[parameter] = value
		}
	}
	
	guard parameterValues.count == parameters.count else {
		encodeErrorResponse(400, withMessage: "One or more missing parameters", forResponse: response)
		return;
	}
	
	processWebServiceRequestWithQuery(
		query(parameterValues),
		withRequestParameters: parameterValues,
		parser: parser,
		andRespondWith: response)
}
