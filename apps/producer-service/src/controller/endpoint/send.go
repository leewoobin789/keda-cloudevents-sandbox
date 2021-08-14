package endpoint

import (
	"net/http"
	"os"
	"strconv"
	"time"

	"github.itergo.com/E947263/keda-cloudevents-sandbox/apps/producer-service/src/controller"
	"github.itergo.com/E947263/keda-cloudevents-sandbox/apps/producer-service/src/producer"
)

var TOPIC = os.Getenv("TOPIC")

type sendEndpoint struct {
	info     controller.HandlerInfo
	producer producer.CustomProducer
}

func newSendEndpoint(producer producer.CustomProducer) controller.Handler {
	return sendEndpoint{
		info: controller.HandlerInfo{
			Path:   "/send",
			Method: controller.GET,
		},
		producer: producer,
	}
}

func (e sendEndpoint) GetInfo() controller.HandlerInfo {
	return e.info
}

func (e sendEndpoint) Run(w http.ResponseWriter, r *http.Request) {
	Response := struct {
		Message string `json:"message"`
	}{
		Message: "successful",
	}

	strNum := r.URL.Query().Get("number")
	if len(strNum) == 0 {
		strNum = "1"
	}
	num, err := strconv.Atoi(strNum)
	if err != nil {
		Response.Message = err.Error()
		controller.RespondwithJSON(w, http.StatusNotAcceptable, Response)
	}

	msg := "randomMessage"

	for i := 0; i <= num; i++ {
		time.Sleep(time.Millisecond * 100)
		if err := e.producer.Send(TOPIC, msg); err != nil {
			Response.Message = err.Error()
			break
		}
	}

	controller.RespondWithJSON(w, Response)
}
