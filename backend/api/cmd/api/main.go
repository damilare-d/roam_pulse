// Command api runs the RoamPulse backend HTTP server.
package main

import (
	"log"
	"net/http"
	"os"

	"roampulse/backend/internal/httpapi"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mux := http.NewServeMux()
	httpapi.RegisterHealthRoutes(mux)

	log.Printf("roampulse backend listening on :%s", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatal(err)
	}
}
