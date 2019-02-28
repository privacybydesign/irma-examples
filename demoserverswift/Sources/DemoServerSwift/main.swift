import Foundation
import Kitura
import IrmaServerSwift

// Setup the IRMA server library.
try! Initialize(configuration: "{\"url\": \"http://localhost:8080/irma/\"}")

let router = Router()

router.all("/irma/*") { request, response, next in
	// Connect /irma to the IRMA server library
	
	// Capture body (note that the unwrapping of ? is doubled, due to also capturing any errors here that way)
	let Mbody = try? request.readString()
	let body : String = (Mbody ?? "") ?? ""
	
	// Extract and convert headers to a simple map
	var headerMap : [String:[String]] = [:]
	for (key, value) in request.headers {
		if value != nil {
			if headerMap[key] == nil {
				headerMap[key] = []
			}
			headerMap[key]!.append(value!)
		}
	}
	
	// Let the IRMA server library handle the actual request
	let Mres = try? HandleProtocolMessage(path: request.originalURL, method: request.method.rawValue, headers: headerMap, message: body)
	
	// Deal with errors
	guard let res = Mres else {
		response.send(status: .internalServerError)
		next()
		return
	}
	
	// And output the result
	guard let statuscode = HTTPStatusCode(rawValue: res.status) else {
		// There might be a mismatch in status code requested by the library and those available by kitura
		// This should never happen, and hopefully kitura will get a better mechanism for this in the future
		response.send(status: .internalServerError)
		next()
		return
	}
	response.status(statuscode)
	response.send(res.body)
	next()
}

router.get("/startSession") { request, response, next in
	// Start the session
	guard let (sessionptr, token) = try? StartSession(
		sessionRequest:"{\"type\": \"disclosing\", \"content\": [{\"label\": \"Naam\", \"attributes\": [\"irma-demo.MijnOverheid.fullName.firstname\"]}]}"
		) else {
		// Deal with problems (somewhat) gracefully
		response.send(status: .internalServerError)
		next()
		return
	}
	// And send the resulting session ptr and token to client
	let result = ["sessionptr": sessionptr, "token": token]
	response.send(json: result)
	next()
}

router.get("/fetch") { request, response, next in
	// See if the request actually has the data we need
	guard let token = request.urlURL.query else {
		response.send(status: .badRequest)
		next()
		return
	}
	// Fetch results (if available)
	guard let sesResult = try? GetSessionResult(token: token) else {
		response.send(status: .notFound)
		next()
		return
	}
	// Check if the session is actually in a useful state
	if (sesResult.status != "DONE") {
		// If not, we just return the status
		response.send(sesResult.status)
		next()
		return
	}
	// And disclose the first revealed attribute (this will be irma-demo.MijnOverheid.fullName.firstname, given our request)
	response.send(sesResult.disclosed[0].rawvalue)
	next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
