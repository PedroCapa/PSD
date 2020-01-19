-module(fabricante).
-export([fabricante/5]).

-include("protos.hrl").

%fabricante(Sock, Room) ->
fabricante(Sock, Port1, Port2, Port3, Room) ->
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
					io:format("Fabricante: Enviei: ~p~n", [Result]),
					fabricante(Sock, Port1, Port2, Port3, Room);
				true ->
					{ok, Neg1} = gen_tcp:connect("127.0.0.1", Port1, [binary, {active,false}]),
					{ok, Neg2} = gen_tcp:connect("127.0.0.1", Port2, [binary, {active,false}]),
					{ok, Neg3} = gen_tcp:connect("127.0.0.1", Port3, [binary, {active,false}]),
					handleFabricante(Sock, Neg1, Neg2, Neg3, Room, Username)
					%handleFabricante(Sock, Room, Username)
			end
	end.

handleFabricante(Sock, Neg1, Neg2, Neg3, Room, Username) ->
	receive
		{tcp, _, Data} ->
			Message = protos:decode_msg(Data, 'FabSyn'),
			{'FabSyn', Type} = Message,
			io:format("Fabricante: Recebi do fabricante: ~p~n", [Message]),
			handleRequest(Sock, Neg1, Neg2, Neg3, Room, Type, Username),
			handleFabricante(Sock, Neg1, Neg2, Neg3, Room, Username);
		{tcp_closed, _} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.


handleRequest(Sock, Neg1, Neg2, Neg3, Room, Type, Username) ->
	io:format("Fabricante: Tipo do Syn ~p~n", [Type]),
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
			{'Production', ProdName, Min, Max, Price, Time} = Message,
			[H | T] = ProdName,
			SendSock = chooseSock(H, Neg1, Neg2, Neg3),

			%Criar e enviar Syn
			NegSyn = {'NegSyn', 'FAB_PROD'},
			SendNegSyn = protos:encode_msg(NegSyn),
			gen_tcp:send(SendSock, SendNegSyn),

			%Enviar Pedido e receber resposta
			SendData = {'ProdutoNegociador', Username, {'ProdutoFab', ProdName, Min, Max, Price, Time}},
			Enc = protos:encode_msg(SendData),
			gen_tcp:send(SendSock, Enc),
			io:format("Fabricante: Enviei para ~p o conteudo ~p~n", [SendSock, SendData]),

			{ok, Response} = gen_tcp:recv(SendSock, 0),
			Receive = protos:decode_msg(Response, 'BusinessConfirmation'),
			io:format("Fabricante: Recebi ~p~n", [Receive]),	

			Syn = {'FabSyn', 'PRODUCT'},
			SendSyn = protos:encode_msg(Syn),
			gen_tcp:send(Sock, SendSyn),
			timer:sleep(200),
			gen_tcp:send(Sock, Response),
			io:format("Fabricante: Enviei o request do Product~n~n~n");
		{tcp_closed} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.

handleRequestOver(Sock, Neg1, Neg2, Neg3, Room) ->
	receive
		{tcp, _, Data} ->
			Message = protos:decode_msg(Data, 'Notification'),
			io:format("Fabricante: ~p~n", [Message]),
			{'Notification', Fabricante, Produto, Username} = Message,
			[H | T] = Fabricante,
			SendSock = chooseSock(H, Neg1, Neg2, Neg3),
			
			%Criar e enviar Syn
			NegSyn = {'NegSyn', 'FAB_OVER'},
			SendNegSyn = protos:encode_msg(NegSyn),
			gen_tcp:send(SendSock, SendNegSyn),
			%Enviar Pedido e receber resposta
			gen_tcp:send(SendSock, Data),
			{ok, Response} = gen_tcp:recv(SendSock, 0),
			Receive = protos:decode_msg(Response, 'ConfirmNegotiations'),
			io:format("Fabricante: Recebi ~p~n", [Receive]),	

			Syn = {'FabSyn', 'OVER'},
			SendSyn = protos:encode_msg(Syn),
			gen_tcp:send(Sock, SendSyn),
			timer:sleep(200),
			gen_tcp:send(Sock, Response),
			io:format("Fabricante: Enviei o request do Over~n~n~n");
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
	io:format("Fabricante: Res: ~p  ~p~n~n~n", [H, Res]),
	Res.