-module(fabricante).
-export([fabricante/2]).

%Mudar apenas os send para aquele tipo especifico e encode
%Mudar a parte de receber em que é preciso fazer decode

fabricante(Sock, Room) ->
	receive
		{tcp, _, Name} ->
			U = binary_to_list(Name),
			Id = string:trim(U)
	end,
	receive
		{tcp, _, Pass} ->
			P = binary_to_list(Pass),
			Password = string:trim(P),
			Room ! {fab, {Id, Password}, self()}
	end,
	receive
		{aut, {Username, Result}} ->
			Send = Result ++ "," ++ Username ++ ",\n",
			io:format("Result: ~p~n", [Result]),
			if
				Result =:= "erro" ->
					io:format("Enviei: ~p~n", [Result]),
					gen_tcp:send(Sock, "-1\n"),
					fabricante(Sock, Room);
				true ->
					gen_tcp:send(Sock, Send),
					handleFabricante(Sock, Room, Username)
			end
	end.

handleFabricante(Sock, Room, Username) ->
		receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				handleFabricante(Sock, Room, Username);
			{res, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				handleFabricante(Sock, Room, Username);
			{deal, Data} ->		%Recebe a resposta do Room por causa do ZeroMQ
				io:format("Recebi Data: ~p~n", [Data]),
				sendRes(Sock, Data),
				handleFabricante(Sock, Room, Username);
			{tcp, _, Data} ->
				List = string: tokens(binary_to_list(Data), ","),
				handleRequest(List, Username, Room, Sock),
				handleFabricante(Sock, Room, Username);
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.

handleRequest([H | T], Username, Room, Sock) ->
	if 
		H =:= "new"->
			Res = newProduct(T, Username, Room);
		H =:= "over"->
			Res = negocios(T, Room);
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

%Colocar aqui o pedido para verificar quais são os negocios validos
negocios(List, Room) -> 
	Size = length([X || X <- List]),
	if
		Size >= 2 ->
			Fab = lists:nth(1, List),
			Prod = lists:nth(2, List),
			Room ! {over, {Fab, Prod}, self()},
			Res = true;
		true ->
			io:format("Formato errado"),
			Res = false
	end,
	Res.
	

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

sendRes(_, []) -> 
	gen_tcp(Sock, "Vou enviar os pedidos aceites~n");
sendRes(Sock, [{Username, Price, Ammount, Time, State} |T]) ->
	Send = "Username:" ++ Username ++ " Price: " ++ lists:flatten(io_lib:format("~p", [Price])) ++ 
	"  Ammount: " ++ lists:flatten(io_lib:format("~p", [Ammount])) ++ "  Time: " ++ Time ++ 
	"  State: " ++ lists:flatten(io_lib:format("~p", [State])) ++ "\n",
	gen_tcp:send(Sock, Send),
	sendRes(Sock, T).