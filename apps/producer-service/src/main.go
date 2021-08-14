package main

import (
	"net/http"

	"github.com/gorilla/mux"
	"github.itergo.com/E947263/keda-cloudevents-sandbox/apps/producer-service/src/controller/endpoint"
)

var port string = "8080"

func main() {
	router := mux.NewRouter()

	handlers := endpoint.ReturnBundle()
	for _, h := range handlers {
		path := h.GetInfo().Path
		method := string(h.GetInfo().Method)
		router.HandleFunc(path, h.Run).Methods(method)
	}
	/*
		srv := &http.Server{
			Handler: router,
			Addr:    "127.0.0.1:" + port,
		}
	*/
	if err := http.ListenAndServe(":"+port, router); err != nil {
		panic(err)
	}
}
