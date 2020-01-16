-module(importador).
-export([importador/2]).

%Mudar apenas os send para aquele tipo especifico e encode
%Mudar a parte de receber em que é preciso fazer decode

importador(Sock, Room) ->
	receive
		{tcp, _, Name} ->
			U = binary_to_list(Name),
			Id = string:trim(U)
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
				gen_tcp:send(Sock, Data),
				handleImportador(Sock, Room, Username);
			{deal, Data} -> 			%Dizer se o importador realizou ou não o negocio
				sendRes(Sock, Data),
				handleImportador(Sock, Room, Username);
			{tcp, _, Data} ->
				io:format("Recebi do importador: ~p~n", [Data]),
				List = string: tokens(binary_to_list(Data), ","),
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
			Res = neg(T, Room);
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

neg(List, Room) -> 
	Size = length([X || X <- List]),
	if
		Size >= 3 ->
			Fab = lists:nth(1, List),
			Prod = lists:nth(2, List),
			User = lists:nth(3, List),
			Room ! {finish, {Fab, Prod, User}, self()},
			Res = true;
		true ->
			io:format("Formato errado"),
			Res = false
	end,
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

sendRes(Sock, []) -> 
	gen_tcp:send(Sock, "Vou enviar os pedidos aceites\n");
sendRes(Sock, [{Username, Price, Ammount, Time, State} |T]) ->
	sendRes(Sock, T),
	Send = "Username:" ++ Username ++ " Price: " ++ lists:flatten(io_lib:format("~p", [Price])) ++ 
	"  Ammount: " ++ lists:flatten(io_lib:format("~p", [Ammount])) ++ "  Time: " ++ Time ++ 
	"  State: " ++ lists:flatten(io_lib:format("~p", [State])) ++ "\n",
	gen_tcp:send(Sock, Send).