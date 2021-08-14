FROM openjdk:11-jdk

COPY target/consumer-service*.jar /usr/local/bin/consumer-service.jar
WORKDIR /usr/local/bin/

CMD [ "sh", "-c", "java -jar consumer-service.jar"]