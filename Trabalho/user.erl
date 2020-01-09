-module(user).
-export([user/2]).

user(Sock, Room) ->
	receive
		{line, Data} ->
			gen_tcp:send(Sock, Data),
			user(Sock, Room);
		{tcp, _, Data} ->
			checkInterface(Data, Sock, Room),
			user(Sock, Room);
		{type, {Username, Password}} ->
			gen_tcp:send(Sock, "Put the type 0 for Importadores or something else to Fabricantes\n"),
			receive
			{tcp, _, T} ->
				Type = binary_to_list(T)
			end,
			Room ! {type, {Username, Password}, Type, self()},
			user(Sock, Room);
		{imp, Person} -> 
			gen_tcp:send(Sock, "authenticated with sucess Importador\nNow you can make offers\n"),
			importador:importador(Sock, Room, Person);
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
	io:format("O valor do que se recebeu em primeiro e ~p ~n", [D]),
	if
		D =:= "0\n" ->
			io:format("Entrei no dropwizard~n"),
			dropwizard:dropwizard(Sock, Room);
		D =:= "1\n" ->
			io:format("Entrou um utilizador pelo terminal"),
			Person = authentication(Sock),
			Room ! {aut, Person, self()};
		true ->
			gen_tcp:send("Errado\n")
	end.


authentication(Sock) ->
		gen_tcp:send(Sock, "Put the Credentials\n"),
		receive
			{tcp, _, User} ->
				U = binary_to_list(User),
				Username = string:trim(U),
				io:format("O valor do User e ~p ~n", [Username]),
				gen_tcp:send(Sock, "Coloque a palavra-passe\n")
		end,
		receive
			{tcp, _, Pass} ->
				P = binary_to_list(Pass),
				Password = string:trim(P),
				{Username, Password}
		end.