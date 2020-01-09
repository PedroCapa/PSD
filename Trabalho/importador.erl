-module(importador).
-export([importador/3]).

%Depois de serem verificadas as credenciais o utilizador esta nesta parte
importador(Sock, Room, {Username, Password}) ->
		receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				importador(Sock, Room, {Username, Password});
			{res, Data} ->
				io:format("Recebi a resposta~p~n", [Data]),
				gen_tcp:send(Sock, binary_to_list(Data)),
				fabricante:fabricante(Sock, Room, {Username, Password});
			{tcp, _, Data} ->
				List = string: tokens(binary_to_list(Data), ","),
				io:format("Recebi ~p ~n", [List]),
				handleImportador(List, Username, Room, Sock),
				importador(Sock, Room, {Username, Password});
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.


handleImportador([H | T], Username, Room, Sock) ->
	if 
		H =:= "offer"->
			Res = newOffer(T, Username, Room);
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

newOffer(List, Username, Room) ->
	Size = length([X || X <- List]),
	if 
		Size >= 4 ->
			Fab = lists:nth(1, List),
			Prod = lists:nth(2, List),
			Ammount = lists:nth(3, List),
			Price = lists:nth(4, List),
			AmmountNumber = [Char || Char <- Ammount, Char < $0 orelse Char > $9] == [],
			PriceNumber = [Char || Char <- Price, Char < $0 orelse Char > $9] == [],
			io:format("Prod: ~p Fab ~p Price: ~p Ammount: ~p AmmountNumber:~p ~n", 
				[Prod, Fab, Price, AmmountNumber, PriceNumber]),
			if 
				AmmountNumber =:= true, PriceNumber =:= true ->
					Room ! {neg, Username, Fab, Prod, Ammount, Price, self()},
					Res = true;
			true ->
				Res = false
			end;
		true ->
			Res = false
	end,
	Res.