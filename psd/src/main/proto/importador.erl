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
					io:format("Enviei: ~p~n", [Result]),
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
			io:format("Recebi do importador: ~p~n", [Message]),
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
		Type =:= 'OVER'  ->
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
			io:format("Enviei para ~p o syn ~p~n", [SendSock, NegSyn]),

			%Enviar Pedido e receber resposta
			SendData = {'OfertaNegociador', Fabricante, Product, {'OfertaImp', Username, Amount, Price, Time, -1}},
			Enc = protos:encode_msg(SendData),
			gen_tcp:send(SendSock, Enc),
			io:format("Enviei para ~p o conteudo ~p~n", [SendSock, SendData]),

			{ok, Response} = gen_tcp:recv(SendSock, 0),
			Receive = protos:decode_msg(Response, 'BusinessConfirmation'),
			io:format("Recebi ~p~n", [Receive]),			

			Syn = {'ImpSyn', 'OFFER'},
			SynEnc = protos:encode_msg(Syn),
			gen_tcp:send(Sock, SynEnc),
			io:format("Enviei o syn ~p~n", [Syn]),
			gen_tcp:send(Sock, Response),
			io:format("Enviei o request do Offer~n");
		{tcp_closed} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.

handleRequestOver(Sock, Neg1, Neg2, Neg3, Room, Username) ->
	receive
		{tcp, _, Data} ->
			Message = protos:decode_msg(Data, 'Notification'),
			{'Notification', Fabricante, Produto, Username} = Message,
			[H | T] = Fabricante,
			SendSock = chooseSock(H, Neg1, Neg2, Neg3),
			
			%Criar e enviar Syn
			NegSyn = {'NegSyn', 'IMP_OVER'},
			SendNegSyn = protos:encode_msg(NegSyn),
			gen_tcp:send(SendSock, SendNegSyn),
			%Enviar Pedido e receber resposta
			gen_tcp:send(SendSock, Data),
			
			{ok, Response} = gen_tcp:recv(SendSock, 0),
			Receive = protos:decode_msg(Response, 'ConfirmNegotiations'),
			io:format("Recebi ~p~n", [Receive]),

			Syn = {'ImpSyn', 'FINISH'},
			SendSyn = protos:encode_msg(Syn),
			gen_tcp:send(Sock, SendSyn),
			io:format("Enviei syn para cliente~n"),
			gen_tcp:send(Sock, Response),
			io:format("Enviei o request do Over~n");
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