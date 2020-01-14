-module(importador).
-export([importador/3]).

%Mudar apenas os send para aquele tipo especifico e encode
%Mudar a parte de receber em que é preciso fazer decode

importador(Sock, Room, {Username, Password}) ->
		receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				importador(Sock, Room, {Username, Password});
			{res, Data} ->
				io:format("Importador: Recebi a resposta ~p~n", [Data]),
				gen_tcp:send(Sock, binary_to_list(Data)),
				importador(Sock, Room, {Username, Password});
			{tcp, _, Data} ->
				List = string: tokens(binary_to_list(Data), ","),
				io:format("Importador: Recebi do importador ~p ~n", [List]),
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
		H =:= "over" ->
			Res = neg(T, Username, Room);
		true -> 
			Res = false
	end,
	if
		Res =:= false ->
			Msg = "Invalido\n",
			gen_tcp:send(Sock, list_to_binary(Msg));
		true ->
			io:format("~n")
	end.

neg(List, Username, Room) -> 
	io:format("Importador: A lista que recebi foi ~p~n", [List]), 
	Res = true,
	Res.

newOffer(List, Username, Room) ->
	Size = length([X || X <- List]),
	if 
		Size >= 4 ->
			Fab = lists:nth(1, List),
			Prod = lists:nth(2, List),
			Ammount = lists:nth(3, List),
			Price = lists:nth(4, List),
			Time = lists:nth(5, List),
			AmmountNumber = [Char || Char <- Ammount, Char < $0 orelse Char > $9] == [],
			PriceNumber = [Char || Char <- Price, Char < $0 orelse Char > $9] == [],
			if 
				AmmountNumber =:= true, PriceNumber =:= true ->
					Room ! {neg, Username, Fab, Prod, Ammount, Price, Time, self()},
					Res = true;
			true ->
				Res = false
			end;
		true ->
			Res = false
	end,
	Res.