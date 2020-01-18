-module(dropwizard).
-export([dropwizard/2, sendRes/2]).

dropwizard(Sock, Room) ->
	receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				dropwizard(Sock, Room);
			{res, Data} ->
				io:format("Recebi a resposta que pretendia ~p~n", [Data]),
				SendData = addProductionType(Data),
				Send = {'ResponseDropProd', SendData},
				gen_tcp:send(Sock, Send),
			{tcp, _, Data} ->
				%Fazer decode aqui
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				Message = protos:decode_msg(Data, 'Dropwizard'),
				{'Dropwizard', Type, Username, Produto} = Message,
				handleDropwizard(Type, Username, Produto, Sock, Room),
				dropwizard(Sock, Room);
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				%List = string: tokens(binary_to_list(Data), ","),
				%io:format("Recebi ~p ~n", [List]),
				%handleDropwizard(List, Room, Sock),
				%dropwizard(Sock, Room);
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.


handleDropwizard(Type, Username, Produto, Sock, Room) ->
	if
		Type =:= 'PROD' ->
			handleDropwizardProd(Username, Produto, Sock, Room);
		Type =:= 'NEG'  ->
			handleDropwizardNeg(Username, Produto, Sock, Room);
		Type =:= 'IMP'  ->
			handleDropwizardImp(Username, Produto, Sock, Room)
	end.

handleDropwizardProd(Username, Produto, Sock, Room) ->
	Room ! {produtores, Username, self()},
	receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				dropwizard(Sock, Room);
			{res, Data} ->
				io:format("Recebi a resposta que pretendia ~p~n", [Data]),
				SendData = addProductionType(Data),
				Send = {'ResponseDropProd', SendData},
				gen_tcp:send(Sock, Send),
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.


%***É provável que seja necessário acrescentar o Produto na mensagem
handleDropwizardNeg(Username, Produto, Sock, Room) ->
	Room ! {negotiations, Username, self()},
	receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				dropwizard(Sock, Room);
			{res, Data} ->
				io:format("Recebi a resposta que pretendia ~p~n", [Data]),
				SendData = addNegotiationType(Data),
				Send = {'ResponseNegotiationDropwizard', SendData},
				gen_tcp:send(Sock, Send),
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.

handleDropwizardImp(Username, Produto, Sock, Room) ->
	Room ! {imp, Username, self()},
	receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				dropwizard(Sock, Room);
			{res, Data} ->
				io:format("Recebi a resposta que pretendia ~p~n", [Data]),
				SendData = addImporterType(Data),
				Send = {'ResponseImporterDropwizard', SendData},
				gen_tcp:send(Sock, Send),
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.

addProductionType([]) ->
	[];

addProductionType([H | T]) ->
	Type = addProdType(H),
	Res = addProductionType(T),
	[Type | Res].

addProdType({Product, Min, Max, Price, Date, _}) ->
	{'Production', Product, Min, Max, Price, Date}.


addImporterType([]) ->
	[];

addImporterType([H | T]) ->
	Type = addType(H),
	Res = addImporterType(T),
	[Type | Res].

addImpType({Username, Fabricante, Prod, Price, Quant, Time, State}) ->
	{'ImporterDropwizard', Fabricante, Prod, Price, Quant, Time, State}.


addNegotiationType([]) ->
	[];

addNegotiationType([H | T]) ->
	Type = addNegType(H),
	Res = addNegotiationType(T),
	[Type | Res].

addNegType({Username, Price, Amount, Data, State}) ->
	{'NegotiationDropwizard', Username, Price, Amount, Data, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

handleDropwizard([H|T], Room, Sock) ->
	io:format("O pedido foi ~p ~n", [H]),
	if 
		H =:= "produtores" ->
			Res = produtores(T, Room);
		H =:= "negotiations" -> 
			Res = negotiations(T, Room);
		H =:= "imp" ->
			Res = imp(T, Room);
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

produtores(List, Room) ->
	Size = length([X || X <- List]),
	if
		Size >= 1 ->
			Fab = lists:nth(1, List),
			io:format("Enviei ao master para que diga quais são os produtos do ~p~n", [Fab]),
			Room ! {produtores, Fab, self()},
			Res = true;
		true ->
			Res = false
	end,
	Res.

negotiations(List, Room) ->
	Size = length([X || X <- List]),
	if
		Size >= 1 ->
			Fab = lists:nth(1, List),
			Room ! {negotiations, Fab, self()},
			Res = true;
		true ->
			Res = false
	end,
	Res.

imp(List, Room) ->
	Size = length([X || X <- List]),
	if
		Size >= 1 ->
			Imp = lists:nth(1, List),
			Room ! {imp, Imp, self()},
			Res = true;
		true ->
			Res = false
	end,
	Res.

sendRes(Sock, []) -> 
	io:format("Enviei o \n"),
	gen_tcp:send(Sock, "\n");
sendRes(Sock, [H |T]) ->
 	io:format("O valor de H e: ~p~n", [H]),
	gen_tcp:send(Sock, H),
	sendRes(Sock, T).