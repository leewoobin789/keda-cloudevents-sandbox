package endpoint

import (
	"os"

	"github.itergo.com/E947263/keda-cloudevents-sandbox/apps/producer-service/src/controller"
	"github.itergo.com/E947263/keda-cloudevents-sandbox/apps/producer-service/src/producer"
)

func ReturnBundle() []controller.Handler {
	server := os.Getenv("KAFKA_SERVER")
	customProducer := producer.NewCustomKafkaProducer(server)
	return []controller.Handler{
		newSendEndpoint(customProducer),
		newhealthEndpoint(),
	}
}
