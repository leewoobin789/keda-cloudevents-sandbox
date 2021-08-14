package com.kedasandbox.consumerservice.components;

import java.io.IOException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@Transactional(readOnly = true)
public class KafkaConsumer {
    private final Logger logger = LoggerFactory.getLogger(KafkaConsumer.class);

    @KafkaListener(id = "${test.id}", topics = "${test.topic}", groupId = "${test.consumerGroup}")
    public void consume(String message) throws IOException, InterruptedException {
        logger.info(String.format("Consumed message -> %s", message));
        someWorkload();
    }
    
    private void someWorkload() throws InterruptedException {
        long millis = 5000;
        Thread.sleep(millis);
    }
}
