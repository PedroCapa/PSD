-module(server).
-export([server/1, room/4]).

%-include("protos.hrl").

server(Port) ->
		Room = spawn(fun()-> room(#{}, #{}, [], []) end),
		{ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}]),
		acceptor(LSock, Room).

acceptor(LSock, Room) ->
		{ok, Sock} = gen_tcp:accept(LSock),
		spawn(fun() -> acceptor(LSock, Room) end),
		Room ! {enter, self()},
		user:user(Sock, Room).

%Dependendo daquilo que será feito talvez seja para guardar os PID para realizar notificações

room(Importadores, Fabricantes, Produtos, Negocios) ->
		receive
			{enter, _} ->
				io:format("userentered~n", []),
				room(Importadores, Fabricantes, Produtos, Negocios);
			%Vai ser so para verificar se existe ou não o utilizador no caso de a palavra passe estar incorreta apenas enviar resposta de erro 
			%Acrescentar qual foi o tipo que ele colocou
			{aut, {Username, Password}, PID}  ->
				%Verifica se existe algum fabricante ou Importador com esse nome
				Fab = checkUsername(Username, Password, Fabricantes),
				Imp = checkUsername(Username, Password, Importadores),
				if
					%No caso do Utilizador ser um Importador
					Imp =:= true ->
						PID ! {imp, {Username, Password}},
						room(Importadores, Fabricantes, Produtos, Negocios);
					%No caso do Utilizador ser um Fabricante
					Fab =:= true ->
						PID ! {fab, {Username, Password}},
						room(Importadores, Fabricantes, Produtos, Negocios);
					%No caso do Utilizador não existitgegen_tcpn_tcp
					Fab =:= false, Imp =:= false ->
						PID ! {type, {Username, Password}},
						room(Importadores, Fabricantes, Produtos, Negocios);
					%No caso de errar a palavra-passe
					%Mudar para outro sem ser tcp para que no caso de se ter enganado 
					true ->
						PID ! {tcp, "", ""},
						io:format("Enganou-se na palavra-passe~n"),
						room(Importadores, Fabricantes, Produtos, Negocios)
				end;
			%Acrescentar a lista de Fabricante/Importador no caso de não existir
			%Será para tirar esta parte porque ele ja vai dizer logo no inicio qual dos tipos é que ele escolheu
			{type, {Username, Password}, Type, PID} ->
				T = checkType(Type),
				if 
					T =:= true->
						PID ! {imp, {Username, Password}},
						io:format("Username: ~p ~n Password: ~p ~n", [Username, Password]),
						room(maps:merge(#{Username => Password}, Importadores), Fabricantes, Produtos, Negocios);
					true ->
						PID ! {fab, {Username, Password}},
						io:format("Username: ~p ~n Password: ~p ~n", [Username, Password]),
						room(Importadores, maps:merge(#{Username => Password}, Fabricantes), Produtos, Negocios)
				end;
			%Em principio vai ser para manter pq é so para colocar um produto
			{new, Username, Prod, Min, Max, Price, Time, PID} ->
				Contains = findUserProd(Username, Prod, Produtos),
				if
					Contains =:= true ->
						Msg = "Ja contem esse produto a venda\n",
						PID ! {res, list_to_binary(Msg)},
						room(Importadores, Fabricantes, Produtos, Negocios);
					true ->
						Msg = Username ++ "," ++ Prod ++ "," ++ Time ++ ",\n",
						PID ! {res, list_to_binary(Msg)},
						%Acrescentar uma lista de Negocios que aqui estara vazia
						room(Importadores, Fabricantes, [{Username, Prod, Min, Max, Price, Time} | Produtos], Negocios)
				end;
			%Em principio vai ser para manter pq é so para acrescentar uma negociação
			{neg, Username, Fab, Prod, Price, Quant, Time, PID} ->
				Contains = verifyOffer(Fab, Prod, Price, Quant, Time, Produtos),
				if
					Contains =:= true ->
						Msg = Fab ++ "," ++ Prod ++ "," ++ ",\n",
						PID ! {res, list_to_binary(Msg)},
						%Em vez de colocar assim Criar uma lista de negocios no produto
						%Criar uma função que adiciona o negocio ao produto e verifica se o pedido é aceite
						%Adicionar um campo que diz se o negocio e valido
						room(Importadores, Fabricantes, Produtos, [{Username, Fab, Prod, Price, Quant, Time}|Negocios]);
					true ->
						Msg = "Oferta não foi realizada com sucesso\n",
						PID ! {res, list_to_binary(Msg)},
						room(Importadores, Fabricantes, Produtos, Negocios)
				end;
			{imp, Imp, PID} ->
				%Ir buscar o importador e quais são as ofertas que realizaou
				Res = getImp(Imp, Negocios),
				PID ! {res, Res},
				io:format("Chegeui ao Imp~n"),
				room(Importadores, Fabricantes, Produtos, Negocios);
			{negotiations, Fab, PID} ->
				%Vai buscar as negociações de um produto
				Res = getNegotiations(Fab, Negocios),
				PID ! {res, Res},
				io:format("Peguie nas negociações do produto~n"),
				room(Importadores, Fabricantes, Produtos, Negocios);
			{produtores, Fab, PID} ->
				%Ir buscar o Fabricante e os seus produtos
				io:format("O Fabricante é: ~p~n", [Fab]),
				Res = getProdutos(Fab, Produtos),
				PID ! {res, Res},
				io:format("Chegeu ao Fab~n"),
				room(Importadores, Fabricantes, Produtos, Negocios);
			{leave, _} ->
				io:format("userleft ~n", []),
				room(Importadores, Fabricantes, Produtos, Negocios);
				_ -> 
				io:format("Sai ~n", []),
				room(Importadores, Fabricantes, Produtos, Negocios)
		end.

getImp(_, []) -> [];
getImp(Imp, [{Username, Fab, Prod, Price, Quant} | T]) ->
	Rest = getImp(Imp, T),
	if
		Imp =:= Username ->
			I = Username ++ "," ++ Fab ++ "," ++ Prod ++ "," ++ Price ++ "," ++ Quant ++ ",\n",
			Res = lists:append(Rest, [I]);
		true ->
			Res = Rest
	end,
	Res.

getProdutos(_, []) -> [];
getProdutos(Fab, [{Username, Prod, Min, Max, Price, Time} | T]) ->
	Rest = getProdutos(Fab, T),
	if
		Fab =:= Username ->
			P = Username ++ "," ++ Prod ++ "," ++ Min ++ "," ++ Max ++ "," ++ Price ++ "," ++ Time ++ ",\n",
			Res = lists:append(Rest, [P]);
		true ->
			Res = Rest
	end,
	Res.

getNegotiations(_, []) -> [];
getNegotiations(Fab, [{Username, Fabr, Prod, Price, Quant} | T]) ->
	Rest = getNegotiations(Fab, T),
	if
		Fab =:= Fabr ->
			I = Username ++ "," ++ Fab ++ "," ++ Prod ++ "," ++ Price ++ "," ++ Quant ++ ",\n",
			Res = lists:append(Rest, [I]);
		true ->
			Res = Rest
	end,
	Res.

checkUsername(Username, Password, Map) ->
	User = maps:is_key(Username, Map),
	if
		User =:= true ->
			Res = checkPassword(Username, Password, Map),
			Res;
		User =/= true ->
			false
	end.

checkPassword(Username, Password, Map)  ->
	{ok, P} = maps:find(Username, Map),
	if
		P =:= Password ->
			true;
		true ->
			untrue
	end.

checkType(Type) ->
	if
		Type =:= "0\n" ->
			true;
		true ->
			false
	end.

findUserProd(_, _, []) ->
	false;
findUserProd(Username, Product, [{User, Prod, _, _, _, _} | T]) ->
	if 
		User =:= Username, Product =:= Prod ->
			true;
		true ->
			findUserProd(Username, Prod, T)
	end.

verifyOffer(_, _, _, _, _, []) ->
	false;
verifyOffer(Username, Product, Pr, Quant, Ti, [{User, Prod, _, Max, Price, Time} | T]) ->
	Pri = [Char || Char <- Pr, Char < $0 orelse Char > $9] == [],
	Pro = [Char || Char <- Price, Char < $0 orelse Char > $9] == [],
	
	Q = [Char || Char <- Quant, Char < $0 orelse Char > $9] == [],
	M = [Char || Char <- Max, Char < $0 orelse Char > $9] == [],
	if
		User =:= Username, Product =:= Prod,  Pri >= Pro, Q =< M, Time > Ti->
			true;
		User =:= Username, Product =:= Prod ->
			false;
		true ->
			verifyOffer(Username, Prod, Ti, Pr, Quant, T)
	end.