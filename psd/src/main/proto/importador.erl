-module(importador).
-export([importador/2]).

%Mudar apenas os send para aquele tipo especifico e encode
%Mudar a parte de receber em que é preciso fazer decode

importador(Sock, Room) ->
	receive
		{tcp, _, Name} ->
			U = binary_to_list(Name),
			Id = string:trim(U),
			io:format("User: O valor do User e ~p ~n", [Id])
	end,
	receive
		{tcp, _, Pass} ->
			P = binary_to_list(Pass),
			Password = string:trim(P),
			Room ! {imp, {Id, Password}, self()}
	end,
	receive
		{aut, {Username, Result}} ->
			Send = Result ++ "," ++ Username ++ ",\n",
			if
				Result =:= "erro" ->
					gen_tcp:send(Sock, "-1\n"),
					importador(Sock, Room);
				true ->
					gen_tcp:send(Sock, Send),
					handleImportador(Sock, Room, Username)
			end
	end.

handleImportador(Sock, Room, Username) ->
		receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				handleImportador(Sock, Room, Username);
			{res, Data} ->
				io:format("Importador: Recebi a resposta ~p~n", [Data]),
				gen_tcp:send(Sock, binary_to_list(Data)),
				handleImportador(Sock, Room, Username);
			%{deal, _, Data} -> 			%Dizer se o importador realizou ou não o negocio
			{tcp, _, Data} ->
				List = string: tokens(binary_to_list(Data), ","),
				io:format("Importador: Recebi do importador ~p ~n", [List]),
				handleRequest(List, Username, Room, Sock),
				handleImportador(Sock, Room, Username);
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.


handleRequest([H | T], Username, Room, Sock) ->
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