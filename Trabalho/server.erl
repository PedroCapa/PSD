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
		user:user(Sock, Room).

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
						io:format("Enganou-se na palavra-passe~n"),
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
				io:format("Chegeui ao Imp~n"),
				room(Importadores, Fabricantes, Produtos, Negocios);
			{negotiations, Fab, PID} ->
				Res = getNegotiations(Fab, Negocios),
				PID ! {res, Res},
				io:format("Peguie nas negociações do produto~n"),
				room(Importadores, Fabricantes, Produtos, Negocios);
			{produtores, Fab, PID} ->
				%Ir buscar o Fabricante
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
	io:format("Username: ~p~n",[Username]),
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