Compilar programa na pasta com o pom.xml
	
	mvn compile

Ativar gpb pasta onde esta rebar.config

	rebar get-deps
	rebar compile

Criar ficheiro proto.erl

	cd src/main/proto/
	../../../../gpb/gpb/bin/protoc-erl protos.proto
	erlc -I ../../../../gpb/gpb/include/ protos.erl

Correr erlang (Os três ultimos argumentos do server:server são as portas dos negociadores)
	
	erl
	c(server).
	c(user).
	c(fabricante).
	c(importador).
	server:server(9999, 9998, 9997, 9996).

Correr negociadores

	mvn exec:java -Dexec.mainClass=main.java.terminal.Negociador -Dexec.args="9998"
	mvn exec:java -Dexec.mainClass=main.java.terminal.Negociador -Dexec.args="9997"
	mvn exec:java -Dexec.mainClass=main.java.terminal.Negociador -Dexec.args="9996"

Correr ZeroMq
	
	mvn exec:java -Dexec.mainClass=main.java.terminal.ZeroMQ

Correr Fabricante
	
	mvn exec:java -Dexec.mainClass=main.java.terminal.Fabricante -Dexec.args="9999"

Correr Importador

	mvn exec:java -Dexec.mainClass=main.java.terminal.Importador -Dexec.args="9999"

Acrescentar um Produto(nome, min, max, price, data)

	Product,50,100,500,2020-12-31,

Realizar uma Negociacao(O nome do fabricante, O nome do produto, preco, quantidade)
	
	Pedro,Product,500,60,

Para correr o dropwizard
	
	mvn package

	java -jar target/psd-1.0-SNAPSHOT.jar server Server.yml

Para o dropwizard
	
	http://localhost:12345/catalogos/produtor/PMCC

	http://localhost:12345/catalogos/negocio/PMCC/chuteiras
	http://localhost:12345/catalogos/negocio/Luis/bolo