-module(fabricante).
-export([fabricante/3]).

fabricante(Sock, Room, {Username, Password}) ->
		receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				fabricante(Sock, Room, {Username, Password});
			{res, Data} ->
				io:format("Recebi a resposta~p~n", [Data]),
				gen_tcp:send(Sock, binary_to_list(Data)),
				fabricante(Sock, Room, {Username, Password});
			{tcp, _, Data} ->
				List = string: tokens(binary_to_list(Data), ","),
				io:format("Recebi ~p ~n", [List]),
				handleFabricante(List, Username, Room, Sock),
				fabricante(Sock, Room, {Username, Password});
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.

handleFabricante([H | T], Username, Room, Sock) ->
	if 
		H =:= "new"->
			Res = newProduct(T, Username, Room);
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

newProduct(List, Username, Room) ->
	Size = length([X || X <- List]),
	if 
		Size >= 5 ->
			Prod = lists:nth(1, List),
			Min = lists:nth(2, List),
			Max = lists:nth(3, List),
			Price = lists:nth(4, List),
			Time = lists:nth(5, List),
			MinNumber = [Char || Char <- Min, Char < $0 orelse Char > $9] == [],
			MaxNumber = [Char || Char <- Max, Char < $0 orelse Char > $9] == [],
			PriceNumber = [Char || Char <- Price, Char < $0 orelse Char > $9] == [],
			if 
				MinNumber =:= true, MaxNumber =:= true, PriceNumber =:= true ->
					Room ! {new, Username, Prod, Min, Max, Price, Time, self()},
					Res = true;
			true ->
				Res = false
			end;
		true ->
			Res = false
	end,
	Res.