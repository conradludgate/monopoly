package main

import (
	// "github.com/gorilla/mux"
	"bytes"

	"github.com/elazarl/go-bindata-assetfs"

	"log"
	"net/http"
)

var fs = &assetfs.AssetFS{
	Asset:     Asset,
	AssetDir:  AssetDir,
	AssetInfo: AssetInfo,
}

func main() {

	r := http.NewServeMux()
	r.HandleFunc("/", IndexHandle)
	r.Handle("/static/", http.FileServer(fs))
	r.HandleFunc("/ws/", WSHandle)

	log.Fatal(http.ListenAndServe(":8080", r))
}

func IndexHandle(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path == "/" {
		b := MustAsset("index.html")
		fi, _ := AssetInfo("index.html")
		http.ServeContent(w, r, "index.html", fi.ModTime(), bytes.NewReader(b))
		return
	}

	http.FileServer(fs).ServeHTTP(w, r)
}
