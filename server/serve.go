package main

import (
	// "github.com/gorilla/mux"

	"io"
	"log"
	"net/http"
)

func main() {
	// r := mux.NewRouter()
	r := http.NewServeMux()
	r.Handle("/", http.FileServer(http.Dir("src")))
	r.Handle("/static/", http.FileServer(http.Dir("src")))
	r.HandleFunc("/ws/", WSHandle)

	log.Fatal(http.ListenAndServe(":8080", r))
}

func WSHandle(w http.ResponseWriter, r *http.Request) {
	log.Println("Request!")
	io.WriteString(w, "Hello World!")
}
