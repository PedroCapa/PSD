-module(importador).
-export([importador/2]).

-include("protos.hrl").

importador(Sock, Room) ->
%importador(Sock, Port1, Port2, Port3, Room) ->
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
					importador(Sock, Room);
				true ->
					%{ok, Neg1} = gen_tcp:connect("127.0.0.1", Port1, [binary, {active,false}]),
					%{ok, Neg2} = gen_tcp:connect("127.0.0.1", Port2, [binary, {active,false}]),
					%{ok, Neg3} = gen_tcp:connect("127.0.0.1", Port3, [binary, {active,false}]),
					%handleImportador(Sock, Neg1, Neg2, Neg3, Room, Username)
					handleImportador(Sock, Room, Username)
			end
	end.

handleImportador(Sock, Room, Username) ->
	receive
		{line, Data} ->
			gen_tcp:send(Sock, binary_to_list(Data)),
			handleImportador(Sock, Room, Username);
		{res, Confirmation, Fabricante, Produto} -> %%%---
			%So vai ser realizado o encode da resposta. 
			%Apenas uma mensagem já com o ZeroMQ para que,
			%o cliente só chegue e subscrever para o ZeroMQ
			Syn = {'ImpSyn', 'OFFER'},
			SendSyn = protos:encode_msg(Syn),
			gen_tcp:send(Sock, SendSyn),
			Data = {'BusinessConfirmation', Confirmation, Fabricante, Produto},
			Send = protos:encode_msg(Data),
			gen_tcp:send(Sock, Send),
			handleImportador(Sock, Room, Username);
		{deal, Data, Produto} -> 			
			%Recebe a resposta do Room por causa do ZeroMQ aqui so vai ser realizado encode e enviado um de cada vez
			Syn = {'ImpSyn', 'OVER'},
			SendSyn = protos:encode_msg(Syn),
			gen_tcp:send(Sock, SendSyn),
			io:format("Vou enviar ~p~n", [Data]),
			List = addType(Data, Produto),
			Send = {'ConfirmNegotiations', List},
			io:format("Send:~p~n", [Send]),
			Enc = protos:encode_msg(Send),
			gen_tcp:send(Sock, Enc),
			handleImportador(Sock, Room, Username);
		{tcp, _, Data} ->
			%Talvez seja necessário substituir pela receção de um syn
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			Message = protos:decode_msg(Data, 'ImpSyn'),
			{'ImpSyn', Type} = Message,
			io:format("Recebi do importador: ~p~n", [Message]),
			handleRequest(Sock, Room, Type, Username),
			handleImportador(Sock, Room, Username);
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			%io:format("Recebi do importador: ~p~n", [Data]),
			%List = string:tokens(binary_to_list(Data), ","),
			%handleRequest(List, Username, Room, Sock),
			%handleImportador(Sock, Room, Username);
		{tcp_closed, _} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.

handleRequest(Sock, Room, Type, Username) ->
	if
		Type =:= 'OFFER' ->
			handleRequestOffer(Sock, Room, Username);
		Type =:= 'OVER'  ->
			handleRequestOver(Sock, Room, Username)
	end.		

handleRequestOffer(Sock, Room, Username) ->
	receive
		{tcp, _, Data} ->
			Message = protos:decode_msg(Data, 'Negotiation'),
			{'Negotiation', Fabricante, Product, Price, Amount, Time} = Message,
			io:format("Message: ~p~n", [Message]),
			%[H | T] = ProdName,
			%SendSock = chooseSock(H, Neg1, Neg2, Neg3),
			%gen_tcp:send(SendSock, Data),
			%{ok, Response} = gen_tcp:recv(SendSock, 0),
			%gen_tcp:send(Sock, Response);
			Room ! {neg, Username, Fabricante, Product, Amount, Price, Time, self()};
		{tcp_closed} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.

handleRequestOver(Sock, Room, Username) ->
	receive
		{tcp, _, Data} ->
			Message = protos:decode_msg(Data, 'Notification'),
			{'Notification', Fabricante, Produto, Username} = Message,
			Room ! {finish, {Fabricante, Produto, Username}, self()};
		{tcp_closed} ->
			Room ! {leave, self()};
		{tcp_error, _, _} ->
			Room ! {leave, self()}
	end.

addType([],_) ->
	[];
addType([{A, B, C, D, E}|T], Produto) ->
	Rest = addType(T, Produto),
	[{'AceptedNegotiation' , A, Produto, B, C, D, E} | Rest].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
			io:format("Message: ~p~n", [Message]),
			[H | T] = Fabricante,
			SendSock = chooseSock(H, Neg1, Neg2, Neg3),
			%Criar e enviar Syn
			NegSyn = {'NegSyn', 'IMP_OFFER'},
			SendNegSyn = protos:encode_msg(NegSyn),
			gen_tcp:send(SendSock, SendNegSyn),
			%Enviar Pedido e receber resposta
			SendData = {'OfertaNegociador', Username, Product, {'OfertaImp', Username, Amount, Price, Time, -1}},
			Enc = protos:encode_msg(SendData),
			gen_tcp:send(SendSock, Enc),
			{ok, Response} = gen_tcp:recv(SendSock, 0),
			gen_tcp:send(Sock, Response);
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
			gen_tcp:send(Sock, Response);
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%handleRequest([H | T], Username, Room, Sock) ->
%	%Receber o pacohandleRequestOverte com os dados
%	%Decode Aqui e entrar no if de acordo com a variavel obtida anteriormente
%	if 
%		H =:= "offer"->
%			Res = newOffer(T, Username, Room);
%		H =:= "over" ->
%			Res = neg(T, Room);
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
%neg(List, Room) -> 
%	Size = length([X || X <- List]),
%	if
%		Size >= 3 ->
%			Fab = lists:nth(1, List),
%			Prod = lists:nth(2, List),
%			User = lists:nth(3, List),
%			Room ! {finish, {Fab, Prod, User}, self()},
%			Res = true;
%		true ->
%			io:format("Formato errado"),
%			Res = false
%	end,
%	Res.
%	%Altera a lista para n argumentos
%newOffer(List, Username, Room) ->
%	Size = length([X || X <- List]),
%	if 
%		Size >= 4 ->
%			Fab = lists:nth(1, List),
%			Prod = lists:nth(2, List),
%			Ammount = lists:nth(3, List),
%			Price = lists:nth(4, List),
%			Time = lists:nth(5, List),
%			AmmountNumber = [Char || Char <- Ammount, Char < $0 orelse Char > $9] == [],
%			PriceNumber = [Char || Char <- Price, Char < $0 orelse Char > $9] == [],
%			if 
%				AmmountNumber =:= true, PriceNumber =:= true ->
%					Room ! {neg, Username, Fab, Prod, Ammount, Price, Time, self()},
%					Res = true;
%			true ->
%				Res = false
%			end;
%		true ->
%			Res = false
%	end,
%	Res.
%	sendRes(Sock, []) -> 
%	gen_tcp:send(Sock, "Vou enviar os pedidos aceites\n");
%sendRes(Sock, [{Username, Price, Ammount, Time, State} |T]) ->
%	sendRes(Sock, T),
%	Send = "Username:" ++ Username ++ " Price: " ++ lists:flatten(io_lib:format("~p", [Price])) ++ 
%	"  Ammount: " ++ lists:flatten(io_lib:format("~p", [Ammount])) ++ "  Time: " ++ Time ++ 
%	"  State: " ++ lists:flatten(io_lib:format("~p", [State])) ++ "\n",
%	gen_tcp:send(Sock, Send).
