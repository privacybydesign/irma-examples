package main

import "github.com/privacybydesign/irmago/server"
import "github.com/privacybydesign/irmago/server/irmaserver"

import "os"
import "fmt"
import "log"
import "net/http"
import "net/url"
import "encoding/json"

// Data structure for communication with frontend
type startResponse struct {
	SessionPtr string `json:"sessionptr"`
	Token      string `json:"token"`
}

// Basicu usage instructions
func printHelp() {
	fmt.Println("Usage: demosrv <public ip>")
}

// Handle request to start a session
func startHandler(w http.ResponseWriter, r *http.Request) {
	// Call StartSession to get sessionptr and token
	sessionptrObj, token, err := irmaserver.StartSession(`{"type": "disclosing", "content": [{"label": "Naam", "attributes": ["irma-demo.MijnOverheid.fullName.firstname"]}]}`, nil)

	if err != nil {
		fmt.Printf("Error: %s\n", err.Error())
		w.WriteHeader(500)
		return
	}

	// We need a string as sessionptr, so convert
	sessionptr, err := json.Marshal(sessionptrObj)

	if err != nil {
		fmt.Printf("Error: %s\n", err.Error())
		w.WriteHeader(500)
		return
	}

	// Return the results
	result := startResponse{
		SessionPtr: string(sessionptr),
		Token:      token,
	}

	encoder := json.NewEncoder(w)
	err = encoder.Encode(result)
	if err != nil {
		fmt.Printf("Error: %s\n", err.Error())
		w.WriteHeader(500)
		return
	}
}

// Get results for previously started session (session token is in querystring)
func resultHandler(w http.ResponseWriter, r *http.Request) {
	token, err := url.QueryUnescape(r.URL.RawQuery)

	if err != nil {
		fmt.Printf("Incorrect encoding of query\n")
		w.WriteHeader(400)
		return
	}

	// (Try to) get the results of the session queried.
	result := irmaserver.GetSessionResult(token)

	if result == nil {
		fmt.Printf("Non-existing session %s\n", token)
		w.WriteHeader(404)
		return
	}

	if result.Status != server.StatusDone {
		// A real server will want to do more error handling here.
		// For simplicity, we just return the status here
		fmt.Printf("Incomplete session %s\n", token)
		fmt.Fprintf(w, "%s", result.Status)
		return
	}

	fmt.Fprintf(w, "%s", *result.Disclosed[0].RawValue)
}

func main() {
	if len(os.Args) != 2 {
		printHelp()
		return
	}

	// Configure the server
	conf := &server.Configuration{}
	conf.URL = "http://" + os.Args[1] + ":8080/irma/"

	err := irmaserver.Initialize(conf)
	if err != nil {
		log.Fatal(err.Error())
		return
	}

	// Setup the routing structure of the server, and start
	http.HandleFunc("/irma/", irmaserver.HandlerFunc())
	http.HandleFunc("/startSession", startHandler)
	http.HandleFunc("/fetch", resultHandler)

	log.Fatal(http.ListenAndServe(":8080", nil))
}
