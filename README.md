ZeroMq
	Ter um relogio para acordar quando a oferta terminar
	Quando acordar pedir ao servidor para lhe enviar para quem é que tem que enviar as notificações
	Quando receber a resposta enviar as notificações para os 

Acrescentar um Produto

	new,Prod,50,100,500,2020/12/31,

Realizar uma Negociacao
	
	offer,Pedro,Prod,20,500,

Para o dropwizard
	
	http://localhost:12345/catalogos/produtor/Pedro

Criar o protoc.java
	
	protoc --java_out=psd/src/main/proto/ psd/src/main/proto/protos.proto

Correr ficheiro java

	javac -cp psd/src/main/proto/protobuf-java-3.6.1.jar psd/src/main/java/terminal/*.java
	javac -cp psd/src/main/proto/protobuf-java-3.6.1.jar psd/src/main/java/restinterface/resources/*.java

	java -cp psd/src/main/proto/protobuf-java-3.6.1.jar:. [class] [args]

Criar o proto.erl
	
	# .../gpb/bin/protoc-erl -I. x.proto

Compilar proto
	
	erlc -I.../gpb/include x.erl