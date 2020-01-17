-module(user).
-export([user/2]).

%-include ("protos.hrl").

user(Sock, Room) ->
	receive
		{line, Data} ->
			gen_tcp:send(Sock, Data),
			user(Sock, Room);
		{tcp, _, Data} ->
			checkInterface(Data, Sock, Room);
		{tcp_closed, _} ->
			Room ! {leave};
		{tcp_error, _, _} ->
			Room ! {leave}
	end.


checkInterface(Data, Sock, Room) ->
	D = binary_to_list(Data),
	%Aqui fazer decode da mensagem e verificar o tipo
	%Enviar para o tipo correspondente
	if
		D =:= "drop\n" ->
			io:format("User: Entrei no dropwizard~n"),
			dropwizard:dropwizard(Sock, Room);
		D =:= "fab\n" ->
			fabricante:fabricante(Sock, Room);
		D =:= "imp\n" ->
			importador:importador(Sock, Room);
		true ->
			gen_tcp:send("Errado\n")
	end.