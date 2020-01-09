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

Criar ficheiros:
	server.erl
	file.proto
	#Para compilar o file.proto utilizar o comando /gdp/bin/protoc-erl -I. x.proto

Tarefas
	Erlang
		Mudar o tipo dos numeros
		Verificar as ofertas

Acrescentar um Produto

	new,Prod,50,100,500,31/12/2020,
	
	
Realizar uma Negociacao
	
	offer,Pedro,Prod,20,500,

Para o dropwizard
	http://localhost:12345/catalogos/produtor/Pedro