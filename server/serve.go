package main

import (
	"bytes"

	// "github.com/gorilla/mux"

	"github.com/elazarl/go-bindata-assetfs"

	"log"
	"net/http"
)

var fs = http.FileServer(&assetfs.AssetFS{
	Asset:     Asset,
	AssetDir:  AssetDir,
	AssetInfo: AssetInfo,
})

func main() {
	http.HandleFunc("/", IndexHandle)
	http.Handle("/static/", fs)
	http.Handle("/static/css/", fs)
	http.Handle("/static/js/", fs)

	http.HandleFunc("/ws/", WSHandle)

	log.Fatal(http.ListenAndServe(":8080", nil))
}

func IndexHandle(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path == "/" {
		b := MustAsset("index.html")
		fi, _ := AssetInfo("index.html")
		http.ServeContent(w, r, "index.html", fi.ModTime(), bytes.NewReader(b))
		return
	}

	fs.ServeHTTP(w, r)
}
