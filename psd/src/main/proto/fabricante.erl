-module(fabricante).
-export([fabricante/2]).

-include("protos.hrl").

fabricante(Sock, Room) ->
	%Em vez de ter dois receive ter apenas um para o login
	receive
		{tcp, _, Auth} ->
			Var = protos:decode_msg(Auth, 'Login'),
			io:format("Recebi ~p~n", [Var]),
			{_, Id, Password} = Var,
			Room ! {fab, {Id, Password}, self()}
	end,
	receive
		{aut, {Username, Result}} ->
			Send = {'LoginConfirmation', Result, Username},
			Enc = protos:encode_msg(Send),
			gen_tcp:send(Sock, Enc),
			if
				Result =:= "erro" ->
					io:format("Enviei: ~p~n", [Result]),
					fabricante(Sock, Room);
				true ->
					handleFabricante(Sock, Room, Username)
			end
	end.

handleFabricante(Sock, Room, Username) ->
	receive
		{line, Data} ->
			gen_tcp:send(Sock, binary_to_list(Data)),
			handleFabricante(Sock, Room, Username);
		{res, Confirmation, Fabricante, Produto} ->
			%So vai ser realizado o encode da resposta. 
			%Apenas uma mensagem já com o ZeroMQ para,
			%que o cliente só chegue e envie para o ZeroMQ
			Syn = {'FabSyn', 'PRODUCT'},
			SendSyn = protos:encode_msg(Syn),
			gen_tcp:send(Sock, SendSyn),
			Data = {'BusinessConfirmation', Confirmation, Fabricante, Produto},
			Send = protos:encode_msg(Data),
			gen_tcp:send(Sock, Send),
			io:format("Os dados que recebi foram: ~p~n", [Data]),
			handleFabricante(Sock, Room, Username);
		{deal, Data} ->
			%Recebe a resposta do Room por causa do ZeroMQ aqui so vai ser realizado encode e enviado um de cada vez
			Syn = {'FabSyn', 'OVER'},
			SendSyn = protos:encode_msg(Syn),
			gen_tcp:send(Sock, SendSyn),
			Data = {'ConfirmNegotiations', Data},
			Send = protos:encode_msg(Data),
			gen_tcp:send(Sock, Send),
			handleFabricante(Sock, Room, Username);
		{tcp, _, Data} ->
			%Aqui vai ser enviado o Syn para saber qual era a função usada
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			Message = protos:decode_msg(Data, 'FabSyn'),
			{'FabSyn', Type} = Message,
			io:format("Recebi do fabricante: ~p~n", [Message]),
			handleRequest(Sock, Room, Type, Username),
			handleFabricante(Sock, Room, Username);
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			%Vai deixar de ter uma lista. A lista vai ser tratado depois. Vai so ter uma variavel
			%io:format("Recebi do fabricante: ~p~n", [Data]),			%Em principio vai ser para retirar isto		
			%List = string: tokens(binary_to_list(Data), ","),			%Em principio vai ser para retirar isto
			%handleRequest(List, Username, Room, Sock),					%Vai ser chamada na mesma mas sem a List
			%handleFabricante(Sock, Room, Username);
		{tcp_closed, _} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.


handleRequest(Sock, Room, Type, Username) ->
	if
		Type =:= 'PRODUCT' ->
			handleRequestProduct(Sock, Room, Username);
		Type =:= 'OVER' ->
			handleRequestOver(Sock, Room)
	end.

handleRequestProduct(Sock, Room, Username) ->
	receive
		{tcp, _, Data} ->
			Message = protos:decode_msg(Data, 'Production'),
			io:format("~p~n", [Message]),
			{'Production', ProdName, Min, Max, Price, Data} = Message,
			Room ! {new, Username, ProdName, Min, Max, Price, Data, self()};
		{tcp_closed} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.

handleRequestOver(Sock, Room) ->
	receive
		{tcp, _, Data} ->
			Message = protos:decode_msg(Data, 'Notification'),
			io:format("~p~n", [Message]),
			{'Notification', Fabricante, Produto, Username} = Message,
			Room ! {over, {Fabricante, Produto}, self()};
		{tcp_closed} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%handleRequest([H | T], Username, Room, Sock) ->
%	%Receber o pacote com os dados
%	%Decode Aqui e entrar no if de acordo com a variavel obtida anteriormente
%	if 
%		H =:= "new"->
%			Res = newProduct(T, Username, Room);
%		H =:= "over"->
%			Res = negocios(T, Room);
%		true -> 
%			Res = false
%	end,
%	if
%		Res =:= false ->
%			Msg = "Invalido\n",
%			gen_tcp:send(Sock, list_to_binary(Msg));
%		true ->
%			io:format("~n")
%	end.
%	%Altera a lista para n argumentos
%negocios(List, Room) -> 
%	Size = length([X || X <- List]),
%	if
%		Size >= 2 ->
%			Fab = lists:nth(1, List),
%			Prod = lists:nth(2, List),
%			Room ! {over, {Fab, Prod}, self()},
%			Res = true;
%		true ->
%			io:format("Formato errado"),
%			Res = false
%	end,
%	Res.
%	
%Altera a lista para n argumentos
%newProduct(List, Username, Room) ->
%	Size = length([X || X <- List]),
%	if 
%		Size >= 5 ->
%			Prod = lists:nth(1, List),
%			Min = lists:nth(2, List),
%			Max = lists:nth(3, List),
%			Price = lists:nth(4, List),
%			Time = lists:nth(5, List),
%			MinNumber = [Char || Char <- Min, Char < $0 orelse Char > $9] == [],
%			MaxNumber = [Char || Char <- Max, Char < $0 orelse Char > $9] == [],
%			PriceNumber = [Char || Char <- Price, Char < $0 orelse Char > $9] == [],
%			if 
%				MinNumber =:= true, MaxNumber =:= true, PriceNumber =:= true ->
%					Room ! {new, Username, Prod, Min, Max, Price, Time, self()},
%					Res = true;
%			true ->
%				Res = false
%			end;
%		true ->
%			Res = false
%	end,
%	Res.
%	%Mudar esta função para que faça encode numa lista
%sendRes(Sock, []) -> 
%	gen_tcp:send(Sock, "Vou enviar os pedidos aceites\n");
%sendRes(Sock, [{Username, Price, Ammount, Time, State} |T]) ->
%	sendRes(Sock, T),
%	Send = "Username:" ++ Username ++ " Price: " ++ lists:flatten(io_lib:format("~p", [Price])) ++ 
%	"  Ammount: " ++ lists:flatten(io_lib:format("~p", [Ammount])) ++ "  Time: " ++ Time ++ 
%	"  State: " ++ lists:flatten(io_lib:format("~p", [State])) ++ "\n",
%	gen_tcp:send(Sock, Send).