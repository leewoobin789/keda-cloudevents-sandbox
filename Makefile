CLUSTER_NAME = keda-sandbox
CLUSTER_FULL_NAME = kind-${CLUSTER_NAME}
NAMESPACE = demo
LAGGING ?= 5

NUM ?= 100

PRODUCER-POD-NAME= $(shell kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep "producer-service")

.PHONY: dep-setup kind-delete kind-setup cluster-setup producer-console producer-app

dep-setup: 
	bash setup.sh ${CLUSTER_NAME} ${NAMESPACE} ${LAGGING} false

enable-hpa:
	kubectl apply -f ./apps/consumer-service/k8s/normal_hpa.yml

enable-keda:
	kubectl apply -f ./apps/consumer-service/k8s/scaled_object.yml
	
kind-delete:
	kind delete cluster --name ${CLUSTER_NAME}

kind-setup:
	kind create cluster --config=./kind-config.yml
	kubectl config use-context ${CLUSTER_FULL_NAME}
	kubectl create namespace ${NAMESPACE}
	kubectl config set-context --current --namespace=$(NAMESPACE)
	kubectl create secret docker-registry regcred --docker-username=RANDOM --docker-password=RANDOM --docker-email=RANDOM
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.0/components.yaml

cluster-setup: kind-delete kind-setup dep-setup

deploy:
	bash setup.sh ${CLUSTER_NAME} ${NAMESPACE} ${LAGGING} true

producer-console:
	kubectl exec -c cp-kafka-broker -it demo-kafka-cp-kafka-0 -- /bin/bash /usr/bin/kafka-console-producer --broker-list localhost:9092 --topic randomtopic

producer-app:
	kubectl exec ${PRODUCER-POD-NAME} -- curl localhost:8080/send?number=${NUM}