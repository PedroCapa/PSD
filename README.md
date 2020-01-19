ZeroMq
	Ter um relogio para acordar quando a oferta terminar
	Quando acordar pedir ao servidor para lhe enviar para quem é que tem que enviar as notificações
	Quando receber a resposta enviar as notificações para os 

Acrescentar um Produto

	Product,50,100,500,2020-12-31,

Realizar uma Negociacao
	
	Pedro,Product,500,60,

Para o dropwizard
	
	http://localhost:12345/catalogos/produtor/PMCC

	http://localhost:12345/catalogos/negocio/PMCC/chuteiras
	http://localhost:12345/catalogos/negocio/Luis/bolo

	
	
Para correr o dropwizard
	
	mvn package

	java -jar target/psd-1.0-SNAPSHOT.jar server Server.yml

Criar o protoc.java
	
	protoc --java_out=psd/src/main/proto/ psd/src/main/proto/protos.proto

Servidor Erlang

	server:server(9999, 9998, 9997, 9996).

Correr ficheiro java

	javac -cp psd/src/main/proto/protobuf-java-3.6.1.jar psd/src/main/java/terminal/*.java
	javac -cp psd/src/main/proto/protobuf-java-3.6.1.jar psd/src/main/java/restinterface/resources/*.java

	java -cp psd/src/main/proto/protobuf-java-3.6.1.jar:. [class] [args]

Criar o proto.erl
	
	# .../gpb/bin/protoc-erl -I. x.proto

Compilar proto  
	
	cd .../src/main/proto/
	erlc -I.../gpb/include x.erl