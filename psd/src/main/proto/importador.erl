-module(importador).
-export([importador/5]).

-include("protos.hrl").

%importador(Sock, Room) ->
importador(Sock, Port1, Port2, Port3, Room) ->
	%Em vez de ter dois receive ter apenas um para o login
	receive
		{tcp, _, Auth} ->
			{_, Id, Password} = protos:decode_msg(Auth, 'Login'),
			Room ! {imp, {Id, Password}, self()}
	end,
	receive
		{aut, {Username, Result}} ->
			Send = {'LoginConfirmation', Result, Username},
			Enc = protos:encode_msg(Send),
			gen_tcp:send(Sock, Enc),
			if
				Result =:= false ->
					io:format("Importador: Enviei: ~p~n", [Result]),
					importador(Sock, Port1, Port2, Port3, Room);
				true ->
					{ok, Neg1} = gen_tcp:connect("127.0.0.1", Port1, [binary, {active,false}]),
					{ok, Neg2} = gen_tcp:connect("127.0.0.1", Port2, [binary, {active,false}]),
					{ok, Neg3} = gen_tcp:connect("127.0.0.1", Port3, [binary, {active,false}]),
					handleImportador(Sock, Neg1, Neg2, Neg3, Room, Username)
					%handleImportador(Sock, Room, Username)
			end
	end.

handleImportador(Sock, Neg1, Neg2, Neg3, Room, Username) ->
	receive
		{tcp, _, Data} ->
			Message = protos:decode_msg(Data, 'ImpSyn'),
			{'ImpSyn', Type} = Message,
			io:format("Importador: Recebi do importador: ~p~n", [Message]),
			handleRequest(Sock, Neg1, Neg2, Neg3, Room, Type, Username),
			handleImportador(Sock, Neg1, Neg2, Neg3, Room, Username);
		{tcp_closed, _} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.

handleRequest(Sock, Neg1, Neg2, Neg3, Room, Type, Username) ->
	if
		Type =:= 'OFFER' ->
			handleRequestOffer(Sock, Neg1, Neg2, Neg3, Room, Username);
		Type =:= 'FINISH'  ->
			handleRequestOver(Sock, Neg1, Neg2, Neg3, Room, Username)
	end.		

handleRequestOffer(Sock, Neg1, Neg2, Neg3, Room, Username) ->
	receive
		{tcp, _, Data} ->
			Message = protos:decode_msg(Data, 'Negotiation'),
			{'Negotiation', Fabricante, Product, Price, Amount, Time} = Message,
			[H | T] = Fabricante,
			SendSock = chooseSock(H, Neg1, Neg2, Neg3),
			
			%Criar e enviar Syn
			NegSyn = {'NegSyn', 'IMP_OFFER'},
			SendNegSyn = protos:encode_msg(NegSyn),
			gen_tcp:send(SendSock, SendNegSyn),

			%Enviar Pedido e receber resposta
			SendData = {'OfertaNegociador', Fabricante, Product, {'OfertaImp', Username, Amount, Price, Time, -1}},
			Enc = protos:encode_msg(SendData),
			gen_tcp:send(SendSock, Enc),
			io:format("Importador: Enviei para ~p o conteudo ~p~n", [SendSock, SendData]),

			{ok, Response} = gen_tcp:recv(SendSock, 0),
			Receive = protos:decode_msg(Response, 'BusinessConfirmation'),
			io:format("Importador: Recebi ~p~n", [Receive]),	

			Syn = {'ImpSyn', 'OFFER'},
			SendSyn = protos:encode_msg(Syn),
			gen_tcp:send(Sock, SendSyn),
			io:format("Importador: Enviei o syn para importador~p~n", [Syn]),
			timer:sleep(200),
			gen_tcp:send(Sock, Response),
			io:format("Importador: Enviei o request do Product~n~n~n");
		{tcp_closed} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.

handleRequestOver(Sock, Neg1, Neg2, Neg3, Room, Username) ->
	receive
		{tcp, _, Data} ->
			Message = protos:decode_msg(Data, 'Notification'),
			io:format("Importador: ~p~n", [Message]),
			{'Notification', Fabricante, Produto, Username} = Message,
			[H | T] = Fabricante,
			SendSock = chooseSock(H, Neg1, Neg2, Neg3),
			
			%Criar e enviar Syn
			NegSyn = {'NegSyn', 'IMP_OVER'},
			SendNegSyn = protos:encode_msg(NegSyn),
			gen_tcp:send(SendSock, SendNegSyn),
			timer:sleep(200),
			%Enviar Pedido e receber resposta
			gen_tcp:send(SendSock, Data),
			io:format("Importador: Já enviei para o Servidor"),

			{ok, Response} = gen_tcp:recv(SendSock, 0),
			Receive = protos:decode_msg(Response, 'ConfirmNegotiations'),
			io:format("Importador: Recebi ~p~n", [Receive]),	

			Syn = {'ImpSyn', 'FINISH'},
			SendSyn = protos:encode_msg(Syn),
			gen_tcp:send(Sock, SendSyn),
			io:format("Importador: Enviei syn para importador~n"),
			timer:sleep(200),
			gen_tcp:send(Sock, Response),
			io:format("Importador: Enviei o request do Over~n~n~n");
		{tcp_closed} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.

chooseSock(H, Neg1, Neg2, Neg3) ->
	if
		H >= 65, H =< 90 ->
			Res = Neg1;
		H >= 97, H =< 122 ->
			Res = Neg2;
		true ->
			Res = Neg3
	end,
	Res.