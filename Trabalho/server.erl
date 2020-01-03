-module(server).
-export([server/1]).

%Verificar novamente as partes de comunicação, por exemplo quando se recebe ou envia alguma coisa

server(Port) ->
		Room = spawn(fun()-> room(#{}, #{}, [], []) end),
		{ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}]),
		acceptor(LSock, Room).

acceptor(LSock, Room) ->
		{ok, Sock} = gen_tcp:accept(LSock),
		spawn(fun() -> acceptor(LSock, Room) end),
		Room ! {enter, self()},
		user(Sock, Room).

%Dependendo daquilo que será feito talvez seja para guardar os PID para realizar notificações

room(Importadores, Fabricantes, Produtos, Negocios) ->
		receive
			{enter, _} ->
				io:format("userentered~n", []),
				room(Importadores, Fabricantes, Produtos, Negocios);
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
					true ->
						PID ! {tcp, "", ""},
						room(Importadores, Fabricantes, Produtos, Negocios)
				end;
			%Acrescentar a lista de Fabricante/Importador no caso de não existir
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
			{new, Username, Prod, Min, Max, Price, Time, PID} ->
				Contains = findUserProd(Username, Prod, Produtos),
				if
					Contains =:= true ->
						io:format("Ja encontrei esse produto a venda ~p ~n", [Contains]),
						Msg = "Ja contem esse produto a venda\n",
						PID ! {res, list_to_binary(Msg)},
						room(Importadores, Fabricantes, Produtos, Negocios);
					true ->
						Msg = "Adicionado com sucesso\n",
						PID ! {res, list_to_binary(Msg)},
						io:format("Produto adicionado ~p ~n", [Contains]),
						room(Importadores, Fabricantes, [{Username, Prod, Min, Max, Price, Time} | Produtos], Negocios)
				end;
			{neg, Username, Fab, Prod, Price, Quant, PID} ->
				Contains = findUserProd(Fab, Prod, Produtos),
				if
					Contains =:= true ->
						Msg = "Esse fabricante tem esse produto\n",
						PID ! {res, list_to_binary(Msg)},
						room(Importadores, Fabricantes, Produtos, [{Username, Fab, Prod, Price, Quant}|Negocios]);
					true ->
						Msg = "Oferta não foi realizada com sucesso\n",
						PID ! {res, list_to_binary(Msg)},
						room(Importadores, Fabricantes, Produtos, Negocios)
				end;
			{imp, Imp, PID} ->
				%Ir buscar o importador
				Res = getImp(Imp, Negocios),
				PID ! {res, Res},
				io:format("Chegeui ao Imp~n");
			{negotiations, Fab, PID} ->
				Res = getNegotiations(Fab, Negocios),
				PID ! {res, Res},
				io:format("Peguie nas negociações do produto~n");
			{produtores, Fab, PID} ->
				%Ir buscar o Fabricante
				Res = getProdutos(Fab, Produtos),
				PID ! {res, Res},
				io:format("Chegeu ao Fab~n");
			{leave, _} ->
				io:format("userleft ~n", []),
				room(Importadores, Fabricantes, Produtos, Negocios);
				_ -> 
				io:format("Sai ~n", [])
		end.

getImp(_, []) -> [];
getImp(Imp, [{Username, Fab, Prod, Price, Quant} | T]) ->
	Rest = getImp(Imp, T),
	if
		Imp =:= Username ->
			I = Username ++ "," ++ Fab ++ "," ++ Prod ++ "," ++ Price ++ "," ++ Quant ++ ",",
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
			P = Username ++ "," ++ Prod ++ "," ++ Min ++ "," ++ Max ++ "," ++ Price ++ "," ++ Time ++ ",",
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
			I = Username ++ "," ++ Fab ++ "," ++ Prod ++ "," ++ Price ++ "," ++ Quant ++ ",",
			Res = lists:append(Rest, [I]);
		true ->
			Res = Rest
	end,
	Res.


user(Sock, Room) ->
	receive
		{line, Data} ->
			gen_tcp:send(Sock, Data),
			user(Sock, Room);
		{tcp, _, Data} ->
			checkInterface(Data, Sock, Room),
			user(Sock, Room);
		{type, {Username, Password}} ->
			gen_tcp:send(Sock, "Put the type 0 for Importadores or something else to Fabricantes\n"),
			receive
			{tcp, _, T} ->
				Type = binary_to_list(T)
			end,
			Room ! {type, {Username, Password}, Type, self()},
			user(Sock, Room);
		{imp, Person} -> 
			gen_tcp:send(Sock, "authenticated with sucess Importador\nNow you can make offers\n"),
			importador(Sock, Room, Person);
		{fab, Person} -> 
			gen_tcp:send(Sock, "authenticated with sucess Fabricante\nNow you can add Products\n"),
			fabricante(Sock, Room, Person);
		{tcp_closed, _} ->
			Room ! {leave};
		{tcp_error, _, _} ->
			Room ! {leave}
	end.

checkInterface(Data, Sock, Room) ->
	D = binary_to_list(Data),
	if
		D =:= "0\n" ->
			dropwizard(Sock, Room);
		D =:= "1\n" ->
			Person = authentication(Sock),
			Room ! {aut, Person, self()};
		true ->
			gen_tcp:send("Errado\n")
	end.


%Nesta parte o utilizador coloca as credenciais
authentication(Sock) ->
		gen_tcp:send(Sock, "Put the Credentials\n"),
		receive
			{tcp, _, User} ->
				U = binary_to_list(User),
				Username = string:trim(U)
		end,
		receive
			{tcp, _, Pass} ->
				P = binary_to_list(Pass),
				Password = string:trim(P),
				{Username, Password}
		end.

%Criar aqui o dropwizard
dropwizard(Sock, Room) ->
	receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				dropwizard(Sock, Room);
			{res, Data} ->
				io:format("Recebi a resposta~p~n", [Data]),
				sendRes(Sock, Data),
				gen_tcp:send(Sock, "\n");
				%dropwizard(Sock, Room);
			{tcp, _, Data} ->
				List = string: tokens(binary_to_list(Data), ","),
				io:format("Recebi ~p ~n", [List]),
				handleDropwizard(List, Room, Sock),
				dropwizard(Sock, Room);
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.

handleDropwizard([H|T], Room, Sock) ->
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

%Verificar em todos eles se ele pediu um argumento

produtores(List, Room) ->
	Size = length([X || X <- List]),
	if
		Size >= 1 ->
			Fab = lists:nth(1, List),
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

sendRes(_, []) -> 
	io:format("");
sendRes(Sock, [H |T]) ->
	gen_tcp:send(Sock, binary_to_list(H)),
	sendRes(Sock, T).

%Depois de serem verificadas as credenciais o utilizador esta nesta parte
importador(Sock, Room, {Username, Password}) ->
		receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				importador(Sock, Room, {Username, Password});
			{res, Data} ->
				io:format("Recebi a resposta~p~n", [Data]),
				gen_tcp:send(Sock, binary_to_list(Data)),
				fabricante(Sock, Room, {Username, Password});
			{tcp, _, Data} ->
				List = string: tokens(binary_to_list(Data), ","),
				io:format("Recebi ~p ~n", [List]),
				handleImportador(List, Username, Room, Sock),
				importador(Sock, Room, {Username, Password});
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.


handleImportador([H | T], Username, Room, Sock) ->
	if 
		H =:= "offer"->
			Res = newOffer(T, Username, Room);
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

newOffer(List, Username, Room) ->
	Size = length([X || X <- List]),
	if 
		Size >= 4 ->
			Fab = lists:nth(1, List),
			Prod = lists:nth(2, List),
			Ammount = lists:nth(3, List),
			Price = lists:nth(4, List),
			AmmountNumber = [Char || Char <- Ammount, Char < $0 orelse Char > $9] == [],
			PriceNumber = [Char || Char <- Price, Char < $0 orelse Char > $9] == [],
			io:format("Prod: ~p Fab ~p Price: ~p Ammount: ~p AmmountNumber:~p ~n", 
				[Prod, Fab, Price, AmmountNumber, PriceNumber]),
			if 
				AmmountNumber =:= true, PriceNumber =:= true ->
					Room ! {neg, Username, Fab, Prod, Ammount, Price, self()},
					Res = true;
			true ->
				Res = false
			end;
		true ->
			Res = false
	end,
	Res.


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