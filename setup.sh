#!/bin/bash

CONSUMER_DIR="$(cd apps/consumer-service && pwd)"
PRODUCER_DIR="$(cd apps/producer-service && pwd)"

#Parameters
ClUSTER_NAME="${1:-keda-sandbox}"
NAMESPACE="${2:-demo}"
LAGGING="${3:-5}" # Lagging threshhold of KEDA (default 10)
DO_DEPLOY=${4:-false}

#Constants
TOPIC="randomtopic"
CONSUMERID="consumer-service"
PRODUCERID="producer-service"

setup_metrics_server() {
    kubectl apply -f metric_server.yaml
}

setup_keda() {
    echo "Check existence of keda helm repo"
    KEDA_REPO_EXISTENCE=$(helm repo list | grep "https://kedacore.github.io/charts")

    if [ -z "${KEDA_REPO_EXISTENCE}" ]; then
        echo "keda helm chart repo is beding added"
        helm repo add kedacore https://kedacore.github.io/charts
    fi
    
    echo "Keda Operator is being deployed"
    kubectl create namespace keda || true
    helm install keda kedacore/keda --namespace keda || true
}

setup_kafka_cluster() {
    echo "Check existence of kafka helm repo"
    KAFKA_REPO_EXISTENCE=$(helm repo list | grep "https://confluentinc.github.io/cp-helm-charts")

    if [ -z "${KAFKA_REPO_EXISTENCE}" ]; then 
        echo "kafka helm chart repo is being added"
        helm repo add confluentinc https://confluentinc.github.io/cp-helm-charts/
    fi

    echo "Kafka cluster is being deployed"
    helm install --set cp-schema-registry.enabled=false,cp-kafka-rest.enabled=false,cp-kafka-connect.enabled=false,cp-ksql-server.enabled=false demo-kafka confluentinc/cp-helm-charts || true
}

wait_for_Kafka() {
    echo "Waiting for kafka cluster to be deployed successfully"
    kubectl wait --for=condition=available --timeout=300s deployment/demo-kafka-cp-control-center # to prevent topic to be generated before consumer deployed
    declare -a num=("0" "1" "2")
    for i in "${num[@]}"
    do
        kubectl wait --for=condition=ready --timeout=100s pod/demo-kafka-cp-kafka-${i}
        kubectl wait --for=condition=ready --timeout=100s pod/demo-kafka-cp-zookeeper-${i}
    done
}

create_topic() {
    sleep 20
    echo "Topic(${TOPIC}) is being created"
    kubectl exec -c cp-kafka-broker -it demo-kafka-cp-kafka-0 -- /bin/bash /usr/bin/kafka-topics --create --zookeeper demo-kafka-cp-zookeeper:2181 --topic ${TOPIC} --partitions 10 --replication-factor 1
}

build_consumer() {
    echo "build customer service"
    declare -A properties

    properties['consumerGroup']="consumerService"
    properties['topic']="$TOPIC"
    
    for prop in "${!properties[@]}"
    do 
        echo "${prop} - ${properties[$prop]}"
        # update application.properties
        sed -i "s,test.${prop}=\(.*\),test.${prop}=${properties[$prop]},g" ${CONSUMER_DIR}/src/main/resources/application.properties 
    done
    
    cd ${CONSUMER_DIR} && ./mvnw clean install -DskipTests
    # delete image => build & tag => push into kind
    docker rm -f ${CONSUMERID}
    docker rmi $(docker images | grep "${CONSUMERID}") || true
    docker build ${CONSUMER_DIR}/. -t ${CONSUMERID}
    kind load docker-image --name ${ClUSTER_NAME} ${CONSUMERID}
}

deploy_consumer() {
    echo "deploy customer service"
    sed -i "s,namespace:\(.*\),namespace: ${NAMESPACE},g" ${CONSUMER_DIR}/k8s/kustomization.yml
    sed -i "s,lagThreshold:\(.*\),lagThreshold: '${LAGGING}',g" ${CONSUMER_DIR}/k8s/scaled_object.yml
    
    kustomize build ${CONSUMER_DIR}/k8s | kubectl apply -f -
}

build_producer() {
    echo "build producer service"

    docker rm -f ${PRODUCERID}
    docker rmi $(docker images | grep "${PRODUCERID}") || true
    docker build ${PRODUCER_DIR}/. -t ${PRODUCERID}
    kind load docker-image --name ${ClUSTER_NAME} ${PRODUCERID}
}

deploy_producer() {
    echo "deploy producer service"
    kustomize build ${PRODUCER_DIR}/k8s | kubectl apply -f -
}

if [ "$DO_DEPLOY" = true ]; then
    deploy_consumer
    deploy_producer
else
    helm repo update
    setup_metrics_server
    setup_keda
    setup_kafka_cluster

    CONSUMER_EXISTENCE="$(kubectl get deployment --no-headers -o custom-columns=":metadata.name" | grep "consumer-service")"
    if [ -z "${CONSUMER_EXISTENCE}" ]; then
        build_consumer
        build_producer
        wait_for_Kafka
        create_topic
    fi
fi

echo "finished"