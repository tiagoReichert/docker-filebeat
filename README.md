# What is Filebeat?
Filebeat is a lightweight, open source shipper for log file data. As the next-generation Logstash Forwarder, Filebeat tails logs and quickly sends this information to Logstash for further parsing and enrichment.

> https://www.elastic.co/products/beats/filebeat

# Why this image?

This image uses the Docker API to collect the logs of all the running containers on the same machine and ship them to a Logstash. No need to install Filebeat manually on your host or inside your images. Just use this image to create a container that's going to handle everything for you :-)


# How to use this image
Start Filebeat as follows:

```
$ docker run -d 
   -v /var/run/docker.sock:/tmp/docker.sock -v /tmp/logs_$(hostname):/tmp
   -e LOGSTASH_HOST=127.0.0.1 -e LOGSTASH_PORT=5044 -e SHIPPER_NAME=$(hostname) -e LABALED_ONLY=true
   tiagoreichert/docker-filebeat
```

Three environment variables are needed:
* `LOGSTASH_HOST`: to specify on which server runs your Logstash
* `LOGSTASH_PORT`: to specify on which port listens your Logstash for beats inputs
* `SHIPPER_NAME`: to specify the Filebeat shipper name (deafult: the container ID) 
And one is optional:
* `LABALED_ONLY`: set this variable if you want to collect logs only from containers with the label `GATHER_LOGS`


The docker-compose service definition should look as follows:
```
filebeat:
  image: tiagoreichert/docker-filebeat
  restart: unless-stopped
  volumes:
   - /var/run/docker.sock:/tmp/docker.sock
   - /tmp/logs_$(hostname):/tmp
  environment:
   - LOGSTASH_HOST=127.0.0.1
   - LOGSTASH_PORT=5044
   - SHIPPER_NAME=$(hostname)
   - LABALED_ONLY=true
```


# Logstash configuration:

Configure the Beats input plugin as follows:

```
input {
  beats {
    port => 5044
  }
}
```

In order to have a `containerName` field and a cleaned `message` field, you have to declare the following filter:

```
filter {

  if [type] == "filebeat-docker-logs" {

    grok {
      match => { 
        "message" => "\[%{USERNAME:containerName}\] %{GREEDYDATA:message_remainder}"
      }
    }

    mutate {
      replace => { "message" => "%{message_remainder}" }
    }
    
    mutate {
      remove_field => [ "message_remainder" ]
    }

  }

}
```
Output example creating index with `containerName`:

```
output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "%{containerName}-%{+YYYY.MM.dd}"
  }
}
```
