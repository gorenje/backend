# Kafka Consumers

## Local testing

To test locally, you'll need to start kafka, zookeeper and redis

    # redis
    eval $(cat .env) ; docker-compose -f docker-compose/consumers.ruby.yml up ruby-consumers-db

    # kafka & zookeeper
    eval $(cat .env) ; docker-compose -f docker-compose/kafka-zookeeper.yml up

    # start ruby shell
    rake shell

that's about it.
