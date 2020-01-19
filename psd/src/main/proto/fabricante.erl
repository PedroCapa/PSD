-module(fabricante).
-export([fabricante/2]).

-include("protos.hrl").

fabricante(Sock, Room) ->
%fabricante(Sock, Port1, Port2, Port3, Room) ->
	%Em vez de ter dois receive ter apenas um para o login
	receive
		{tcp, _, Auth} ->
			{_, Id, Password} = protos:decode_msg(Auth, 'Login'),
			Room ! {fab, {Id, Password}, self()}
	end,
	receive
		{aut, {Username, Result}} ->
			Send = {'LoginConfirmation', Result, Username},
			Enc = protos:encode_msg(Send),
			gen_tcp:send(Sock, Enc),
			if
				Result =:= false ->
					io:format("Enviei: ~p~n", [Result]),
					fabricante(Sock, Room);
				true ->
					%{ok, Neg1} = gen_tcp:connect("127.0.0.1", Port1, [binary, {active,false}]),
					%{ok, Neg2} = gen_tcp:connect("127.0.0.1", Port2, [binary, {active,false}]),
					%{ok, Neg3} = gen_tcp:connect("127.0.0.1", Port3, [binary, {active,false}]),
					%handleFabricante(Sock, Neg1, Neg2, Neg3, Room, Username)
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
		{deal, Data, Produto} ->
			%Recebe a resposta do Room por causa do ZeroMQ aqui so vai ser realizado encode e enviado um de cada vez
			Syn = {'FabSyn', 'OVER'},
			SendSyn = protos:encode_msg(Syn),
			gen_tcp:send(Sock, SendSyn),
			io:format("Vou enviar ~p~n", [Data]),
			List = addType(Data, Produto),
			Send = {'ConfirmNegotiations', List},
			io:format("Send:~p~n", [Send]),
			End = protos:encode_msg(Send),
			gen_tcp:send(Sock, End),
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
			{'Production', ProdName, Min, Max, Price, Time} = Message,
			%[H | T] = ProdName,
			%SendSock = chooseSock(H, Neg1, Neg2, Neg3),
			%gen_tcp:send(SendSock, Data),
			%{ok, Response} = gen_tcp:recv(SendSock, 0),
			%gen_tcp:send(Sock, Response);
			Room ! {new, Username, ProdName, Min, Max, Price, Time, self()};
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

addType([], _) ->
	[];
addType([{A, B, C, D, E}|T], Produto) ->
	Rest = addType(T, Produto),
	[{'AceptedNegotiation' , A, Produto, B, C, D, E} | Rest].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

handleFabricante(Sock, Neg1, Neg2, Neg3, Room, Username) ->
	receive
		{tcp, _, Data} ->
			Message = protos:decode_msg(Data, 'FabSyn'),
			{'FabSyn', Type} = Message,
			io:format("Recebi do fabricante: ~p~n", [Message]),
			handleRequest(Sock, Neg1, Neg2, Neg3, Room, Type, Username),
			handleFabricante(Sock, Neg1, Neg2, Neg3, Room, Username);
		{tcp_closed, _} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.


handleRequest(Sock, Neg1, Neg2, Neg3, Room, Type, Username) ->
	if
		Type =:= 'PRODUCT' ->
			handleRequestProduct(Sock, Neg1, Neg2, Neg3, Room, Username);
		Type =:= 'OVER' ->
			handleRequestOver(Sock, Neg1, Neg2, Neg3, Room)
	end.

handleRequestProduct(Sock, Neg1, Neg2, Neg3, Room, Username) ->
	receive
		{tcp, _, Data} ->
			Message = protos:decode_msg(Data, 'Production'),
			io:format("~p~n", [Message]),
			{'Production', ProdName, Min, Max, Price, Time} = Message,
			[H | T] = ProdName,
			SendSock = chooseSock(H, Neg1, Neg2, Neg3),
			%Criar e enviar Syn
			NegSyn = {'NegSyn', 'FAB_PROD'},
			SendNegSyn = protos:encode_msg(NegSyn),
			gen_tcp:send(SendSock, SendNegSyn),
			{ok, Syn} = gen_tcp:recv(SendSock, 0),
			%Enviar Pedido e receber resposta
			SendData = {'ProdutoNegociador', Username, {'Produto', ProdName, Min, Max, Price, Time}},
			Enc = protos:encode_msg(SendData),
			gen_tcp:send(SendSock, Enc),
			{ok, Response} = gen_tcp:recv(SendSock, 0),
			gen_tcp:send(Sock, Response);
		{tcp_closed} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.

handleRequestOver(Sock, Neg1, Neg2, Neg3, Room) ->
	receive
		{tcp, _, Data} ->
			Message = protos:decode_msg(Data, 'Notification'),
			io:format("~p~n", [Message]),
			{'Notification', Fabricante, Produto, Username} = Message,
			[H | T] = Fabricante,
			SendSock = chooseSock(H, Neg1, Neg2, Neg3),
			%Criar e enviar Syn
			NegSyn = {'NegSyn', 'FAB_OVER'},
			SendNegSyn = protos:encode_msg(NegSyn),
			gen_tcp:send(SendSock, SendNegSyn),
			{ok, Syn} = gen_tcp:recv(SendSock, 0),
			%Enviar Pedido e receber resposta
			gen_tcp:send(SendSock, Data),
			{ok, Response} = gen_tcp:recv(SendSock, 0),
			gen_tcp:send(Sock, Response);
		{tcp_closed} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.

chooseSock(H, Neg1, Neg2, Neg3) ->
	if
		H >= 65, 90 >= H ->
			Res = Neg1;
		H >= 97, H =< 122 ->
			Res = Neg2;
		true ->
			Res = Neg3
	end,
	Res.

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