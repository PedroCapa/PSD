Erlang
	Na parte do Erlang, que é o servidor, criar uma forma de guardar o estado do sistema
	Talvez enviar as coisas para o ProtoBuffer para ele traduzir o erlang para java.

	Na parte do cliente colocar a porta deve chegar para conectar com o servidor

Java
	Fazer a parte do cliente
	Na parte do cliente utilizar o dropwiazrd para receber as coisas do cliente enviar para o ProtoBuffer

ProtoBuffer
	Converter o Erlang -> para <- Java

Dropwizard/Rest
	Talvez so será utilizado o Rest para ver o catalogo
	Deverá ser feita com o dropwizard, ver se da para autenticar se n faz-se na???????

Tarefas sem o dropwizard:
	Guardar o estado dos clientes/ negociações no erlang
		- Talvez fazer primeiro so com o erlang em ambos os lados
		- Ver como será melhor realizar a estrutura do erlang
	Fazer a autenticação do cliente na parte do java
		- Basta ter dois input enviar para o protobuf e verificar no servidor
	Utilizar o protobuf para fazer a conversão entre linguagens


Criar ficheiros:
	server.erl
	file.proto
	#Para compilar o file.proto utilizar o comando /gdp/bin/protoc-erl -I. x.proto


Para correr o programa para já é preciso fazer:
epmd &
mvnc
mvnj -Dexec.mainClass=Test