-module(user).
-export([user/2]).

-include ("protos.hrl").

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
	D = protos:decode_msg(Data, 'Syn'),
	checkSyn(D, Sock, Room).

checkSyn({_, D}, Sock, Room) ->
	if
		D =:= 'DROP' ->
			io:format("User: Entrei no dropwizard~n"),
			dropwizard:dropwizard(Sock, Room);
		D =:= 'FAB' ->
			io:format("User: Entrei no fabricante~n"),
			fabricante:fabricante(Sock, Room);
		D =:= 'IMP' ->
			io:format("User: Entrei no importador~n"),
			importador:importador(Sock, Room);
		true ->
			io:format("Something went"),
			gen_tcp:send(Sock, "Errado\n")
	end.