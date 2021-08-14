package producer

import (
	"encoding/json"
	"os"

	cloudevents "github.com/cloudevents/sdk-go/v2"
	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/google/uuid"
)

type CustomProducer interface {
	Send(topic string, msg string) error
}

type CustomKafkaProducer struct {
	producer *kafka.Producer
}

func NewCustomKafkaProducer(server string) CustomProducer {
	kafkaProducer, err := kafka.NewProducer(&kafka.ConfigMap{"bootstrap.servers": server})
	if err != nil {
		panic(err)
	}
	return CustomKafkaProducer{
		producer: kafkaProducer,
	}
}

func (k CustomKafkaProducer) Send(topic string, msg string) error {
	podName := os.Getenv("POD_NAME")
	msgId := uuid.New().String()

	event := cloudevents.NewEvent()
	err := event.SetData(cloudevents.TextPlain, msg)
	if err != nil {
		return err
	}

	event.SetID(msgId)
	event.SetSource(podName)
	event.SetType("github.itergo.com/E947263/keda-cloudevents-sandbox/apps/producer-service/producer/kafka")

	marshaled, err := json.Marshal(event)
	if err != nil {
		return err
	}
	return k.producer.Produce(&kafka.Message{
		TopicPartition: kafka.TopicPartition{Topic: &topic, Partition: kafka.PartitionAny},
		Value:          marshaled,
	}, nil)
}
