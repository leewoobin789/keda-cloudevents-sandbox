package controller

import (
	"encoding/json"
	"net/http"
)

type HandlerMethod string

const (
	POST   HandlerMethod = http.MethodPost
	GET    HandlerMethod = http.MethodGet
	PUT    HandlerMethod = http.MethodPut
	PATCH  HandlerMethod = http.MethodPatch
	DELETE HandlerMethod = http.MethodDelete
)

type HandlerInfo struct {
	Path   string
	Method HandlerMethod
}

type Handler interface {
	GetInfo() HandlerInfo
	Run(w http.ResponseWriter, r *http.Request)
}

func RespondwithJSON(w http.ResponseWriter, code int, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(int(code))
	json.NewEncoder(w).Encode(payload)
}

func RespondWithJSON(w http.ResponseWriter, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(int(http.StatusOK))
	json.NewEncoder(w).Encode(payload)
}
