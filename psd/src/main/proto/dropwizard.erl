-module(dropwizard).
-export([dropwizard/2, sendRes/2]).

%Mudar apenas os send para aquele tipo especifico e encode
%Mudar a parte de receber em que é preciso fazer decode

dropwizard(Sock, Room) ->
	receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				dropwizard(Sock, Room);
			{res, Data} ->
				io:format("Recebi a resposta que pretendia ~p~n", [Data]),
				sendRes(Sock, Data),
				io:format("Enviei tudo");
			{tcp, _, Data} ->
				List = string: tokens(binary_to_list(Data), ","),
				io:format("Recebi ~p ~n", [List]),
				handleDropwizard(List, Room, Sock),
				dropwizard(Sock, Room);
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.

handleDropwizard([H|T], Room, Sock) ->
	io:format("O pedido foi ~p ~n", [H]),
	if 
		H =:= "produtores" ->
			Res = produtores(T, Room);
		H =:= "negotiations" -> 
			Res = negotiations(T, Room);
		H =:= "imp" ->
			Res = imp(T, Room);
		true ->
			Res = false
	end,
	if
		Res =:= false ->
			Msg = "Invalido\n",
			gen_tcp:send(Sock, list_to_binary(Msg));
		true ->
			io:format("Colocou os argumentos certos~n")
	end.

produtores(List, Room) ->
	Size = length([X || X <- List]),
	if
		Size >= 1 ->
			Fab = lists:nth(1, List),
			io:format("Enviei ao master para que diga quais são os produtos do ~p~n", [Fab]),
			Room ! {produtores, Fab, self()},
			Res = true;
		true ->
			Res = false
	end,
	Res.

negotiations(List, Room) ->
	Size = length([X || X <- List]),
	if
		Size >= 1 ->
			Fab = lists:nth(1, List),
			Room ! {negotiations, Fab, self()},
			Res = true;
		true ->
			Res = false
	end,
	Res.

imp(List, Room) ->
	Size = length([X || X <- List]),
	if
		Size >= 1 ->
			Imp = lists:nth(1, List),
			Room ! {imp, Imp, self()},
			Res = true;
		true ->
			Res = false
	end,
	Res.

sendRes(Sock, []) -> 
	io:format("Enviei o \n"),
	gen_tcp:send(Sock, "\n");
sendRes(Sock, [H |T]) ->
 	io:format("O valor de H e: ~p~n", [H]),
	gen_tcp:send(Sock, H),
	sendRes(Sock, T).