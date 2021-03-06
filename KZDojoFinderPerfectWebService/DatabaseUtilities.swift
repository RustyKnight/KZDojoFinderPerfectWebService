//
//  DatabaseUtilities.swift
//  KZDojoFinderPerfectWebService
//
//  Created by Shane Whitehead on 15/04/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import PostgreSQL

/**
A "generic" set of database errors which might occur
*/
enum DatabaseError: ErrorType {
	case QueryFailed(String)
	case NoRecordsFoundForQuery(String)
	case TooManyRecordsFoundForQuery(String)
}


func connectToDatabase(pgConnection: PGConnection) -> PostgreSQL.PGConnection.StatusType {
	return pgConnection.connectdb("host=192.168.0.250 port=5432 dbname=DojoFinder user=postgres password=arrow01")
}


/**
Loads the field name mappings, mapping a name to a field index...
because apparently you can only access fields from a result by index and not name
*/
func loadResultsFieldNameMappingsFrom(results: PostgreSQL.PGResult) -> [String: Int] {
	var fieldNames = [String: Int]()
	for col in 0..<results.numFields() {
		fieldNames[results.fieldName(col)!] = col
	}
	return fieldNames;
}
