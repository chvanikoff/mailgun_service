# MGS

Sending email:
```
mix mgs.send <json>
# Example:
mix mgs.send "{\"to\":\"recepient@mailserver.tld\",\"subject\":\"testing mail service\",\"template\":\"welcome\"}"
```

Sending email via HTTP:
```bash
curl -H "Content-Type: application/json" -u username:password -d $JSON http://localhost:4000/api/v1/email
# Example:
curl -H "Content-Type: application/json" -u username:password -d "{\"to\":\"chvanikoff@gmail.com\",\"subject\":\"testing mail service\",\"template\":\"password_reset\",\"assigns\":{\"name\":\"Roman\",\"link\":\"qwe\"}}" http://localhost:4000/api/v1/email
```

RabbitMQ installation:

```bash
docker run -p 15672:15672 -p 5672:5672 -d --hostname mgs-rabbit --name mgs-rabbit rabbitmq:3.7-management
```

Sample command to put a message into RabbitMQ from cli (assuming default RabbitMQ installation described above):
```bash
curl -XPOST -d'{"properties":{},"routing_key":"mgs_queue","payload":$JSON,"payload_encoding":"string"}' http://guest:guest@localhost:15672/api/exchanges/%2f/mgs_exchange/publish
# Example:
curl -XPOST -d'{"properties":{},"routing_key":"mgs_queue","payload":"{\"to\":\"recepient@mailserver.tld\",\"subject\":\"testing mail service\",\"template\":\"welcome\"}","payload_encoding":"string"}' http://guest:guest@localhost:15672/api/exchanges/%2f/mgs_exchange/publish
```