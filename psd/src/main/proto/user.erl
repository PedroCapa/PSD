-module(user).
-export([user/5]).

-include ("protos.hrl").

user(Sock, Port1, Port2, Port3, Room) ->
	receive
		{line, Data} ->
			gen_tcp:send(Sock, Data),
			user(Sock, Port1, Port2, Port3, Room);
		{tcp, _, Data} ->
			checkInterface(Data, Sock, Port1, Port2, Port3, Room);
		{tcp_closed, _} ->
			Room ! {leave};
		{tcp_error, _, _} ->
			Room ! {leave}
	end.


checkInterface(Data, Sock, Port1, Port2, Port3, Room) ->
	D = protos:decode_msg(Data, 'Syn'),
	checkSyn(D, Sock, Port1, Port2, Port3, Room).

checkSyn({_, D}, Sock, Port1, Port2, Port3, Room) ->
	if
		D =:= 'DROP' ->
			io:format("User: Entrei no dropwizard~n"),
			dropwizard:dropwizard(Sock, Room);
		D =:= 'FAB' ->
			io:format("User: Entrei no fabricante~n"),
			fabricante:fabricante(Sock, Port1, Port2, Port3, Room);
			%fabricante:fabricante(Sock, Room);
		D =:= 'IMP' ->
			io:format("User: Entrei no importador~n"),
			importador:importador(Sock, Port1, Port2, Port3, Room);
			%importador:importador(Sock, Room);
		true ->
			io:format("Something went"),
			gen_tcp:send(Sock, "Errado\n")
	end.