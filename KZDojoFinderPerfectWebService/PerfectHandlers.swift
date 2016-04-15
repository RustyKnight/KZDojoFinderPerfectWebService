//
//  PerfectHandlers.swift
//  KZDojoFinderPerfectWebService
//
//  Created by Shane Whitehead on 15/04/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import PerfectLib
import PostgreSQL

public func PerfectServerModuleInit() {
	
	print("Module Init :)")
	// Install the built-in routing handler.
	// This is required by Perfect to initialize everything
	Routing.Handler.registerGlobally()
	
	Routing.Routes["GET", "/dojosWithin"] = { _ in
		return GetDojosWithinHandler()
	}
	
	Routing.Routes["GET", "/sessionsForDojo"] = { _ in
		return GetDojoSessionsHandler()
	}
}
