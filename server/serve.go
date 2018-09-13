package main

import (
	// "github.com/gorilla/mux"
	"github.com/elazarl/go-bindata-assetfs"

	"log"
	"net/http"
)

func main() {

	fs := &assetfs.AssetFS{
		Asset:     Asset,
		AssetDir:  AssetDir,
		AssetInfo: AssetInfo,
	}

	r := http.NewServeMux()
	r.Handle("/", http.FileServer(fs))
	r.Handle("/static/", http.FileServer(fs))
	r.HandleFunc("/ws/", WSHandle)

	log.Fatal(http.ListenAndServe(":8080", r))
}
