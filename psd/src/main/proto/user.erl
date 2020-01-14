-module(user).
-export([user/2]).

%-include ("protos.hrl").

user(Sock, Room) ->
	receive
		{line, Data} ->
			gen_tcp:send(Sock, Data),
			user(Sock, Room);
		{tcp, _, Data} ->
			checkInterface(Data, Sock, Room),
			user(Sock, Room);

		%Criar um no caso da palavra-passe estar incorreta

		%Tirar esta parte porque pode enviar pela mensagem inicial
		{type, {Username, Password}} ->
			gen_tcp:send(Sock, "Put the type 0 for Importadores or something else to Fabricantes\n"),
			receive
			{tcp, _, T} ->
				Type = binary_to_list(T)
			end,
			Room ! {type, {Username, Password}, Type, self()},
			user(Sock, Room);
		%Pode ficar na mesma pq ele vai enviar qual o tipo
		%Para as duas abaixo mudar apenas o que é enviado, pois envia aquele request que esta no request
		{imp, Person} -> 
			gen_tcp:send(Sock, "authenticated with sucess Importador\nNow you can make offers\n"),
			importador:importador(Sock, Room, Person);
		%Pode ficar na mesma pq ele envia qual o tipo
		{fab, Person} -> 
			gen_tcp:send(Sock, "authenticated with sucess Fabricante\nNow you can add Products\n"),
			fabricante:fabricante(Sock, Room, Person);
		{tcp_closed, _} ->
			Room ! {leave};
		{tcp_error, _, _} ->
			Room ! {leave}
	end.


checkInterface(Data, Sock, Room) ->
	D = binary_to_list(Data),
	%Substituir aqui pelo tipo de pedido se o pedido for Importador/Negociador ou aqueles request
	%Em vez de 0 e 1 verificar o tipo é importador/negociador/rest
	if
		D =:= "0\n" ->
			io:format("User: Entrei no dropwizard~n"),
			dropwizard:dropwizard(Sock, Room);
		D =:= "1\n" ->
			Person = authentication(Sock),
			Room ! {aut, Person, self()};
		true ->
			gen_tcp:send("Errado\n")
	end.

%Mudar esta função para que apenas envia a mensagem para o Room e não esteja à espera do utilizador
authentication(Sock) ->
		gen_tcp:send(Sock, "Put the Credentials\n"),
		receive
			{tcp, _, User} ->
				U = binary_to_list(User),
				Username = string:trim(U),
				io:format("User: O valor do User e ~p ~n", [Username]),
				gen_tcp:send(Sock, "Coloque a palavra-passe\n")
		end,
		receive
			{tcp, _, Pass} ->
				P = binary_to_list(Pass),
				Password = string:trim(P),
				{Username, Password}
		end.