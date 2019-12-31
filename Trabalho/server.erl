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
		io:format("Trattei da situação~p~n", [Produtos]),
		receive
			{enter, Pid} ->
				io:format("userentered ~p~n", [Pid]),
				room(Importadores, Fabricantes, Produtos, Negocios);
			{aut, {Username, Password}, PID}  ->
				Fab = checkUsername(Username, Password, Fabricantes),
				Imp = checkUsername(Username, Password, Importadores),
				if
					%Mudar para o caso de ser Fabricante ou Importador
					Imp =:= true ->
						PID ! {imp, {Username, Password}},
						room(Importadores, Fabricantes, Produtos, Negocios);
					Fab =:= true ->
						PID ! {fab, {Username, Password}},
						room(Importadores, Fabricantes, Produtos, Negocios);
					Fab =:= false, Imp =:= false ->
						%Enviar a dizer que precisa de indicar se é Importador ou Fabricante
						PID ! {type, {Username, Password}},
						room(Importadores, Fabricantes, Produtos, Negocios);
					true ->
						io:format("Acertou miseravel"),
						PID ! {tcp, "", ""},
						room(Importadores, Fabricantes, Produtos, Negocios)
				end;
			%Adicionar outro pq ele colocou a dizer se era Fabricante ou Importador
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
				io:format("Entrei Ca dentro do Room e ja tem algum produto? ~p ~n", [Contains]),
				if
					Contains =:= true ->
						io:format("Ja encontrei esse produto a venda ~p ~n", [Contains]),
						Msg = "Ja contem esse produto a venda",
						PID ! {res, list_to_binary(Msg)},
						room(Importadores, Fabricantes, Produtos, Negocios);
					true ->
						Msg = "Adicionado com sucesso",
						PID ! {res, list_to_binary(Msg)},
						io:format("Produto adicionado ~p ~n", [Contains]),
						room(Importadores, Fabricantes, [{Username, Prod, Min, Max, Price, Time} | Produtos], Negocios)
				end;
			{neg, Username, Fab, Prod, Price, Quant, PID} ->
				Contains = findUserProd(Fab, Prod, Produtos),
				if
					Contains =:= true ->
						io:format("Esse fabricante não tem esse produto ~p ~n", [Contains]),
						Msg = "Esse fabricante não tem esse produto",
						PID ! {res, list_to_binary(Msg)},
						room(Importadores, Fabricantes, Produtos, Negocios);
					true ->
						Msg = "Oferta realizada com sucesso",
						PID ! {res, list_to_binary(Msg)},
						room(Importadores, Fabricantes, Produtos, [{Username, Fab, Prod, Price, Quant}|Negocios])
				end;
			{leave} ->
				io:format("userleft ~n", []),
				room(Importadores, Fabricantes, Produtos, Negocios);
				_ -> 
				io:format("Sai ~n", [])
		end.

user(Sock, Room) ->
	receive
		{line, Data} ->
			gen_tcp:send(Sock, Data),
			user(Sock, Room);
		{tcp, _, _} ->
			gen_tcp:send(Sock, "Put the Credentials"),
			Person = authentication(),
			Room ! {aut, Person, self()},
			user(Sock, Room);
		{type, {Username, Password}} ->
			gen_tcp:send(Sock, "Put the type 0 for Importadores or something else to Fabricantes"),
			receive
			{tcp, _, T} ->
				Type = binary_to_list(T)
			end,
			Room ! {type, {Username, Password}, Type, self()},
			user(Sock, Room);
		{imp, Person} -> 
			gen_tcp:send(Sock, "authenticated with sucess Importador"),
			importador(Sock, Room, Person);
		{fab, Person} -> 
			gen_tcp:send(Sock, "authenticated with sucess Fabricante"),
			fabricante(Sock, Room, Person);
		{tcp_closed, _} ->
			Room ! {leave};
		{tcp_error, _, _} ->
			Room ! {leave}
	end.

%Nesta parte o utilizador coloca as credenciais
authentication() ->
		receive
			{tcp, _, User} ->
				Username = binary_to_list(User)
		end,
		receive
			{tcp, _, Pass} ->
				Password = binary_to_list(Pass),
				{Username, Password}
		end.

%Depois de serem verificadas as credenciais o utilizador esta nesta parte
importador(Sock, Room, {Username, Password}) ->
		receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				importador(Sock, Room, {Username, Password});
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
			Res = newOffer(T, Username, Room, Sock);
		true -> 
			Res = false
	end,
	if
		Res =:= false ->
			io:format("Cheguei ao if~p~n", [Res]),
			Msg = "Invalido",
			gen_tcp:send(Sock, list_to_binary(Msg));
		true ->
			io:format("A resposta não é false")
	end.

newOffer(List, Username, Room, Sock) ->
	Size = length([X || X <- List]),
	io:format("Size: ~p ~n", [Size]),
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
			io:format("Cheguei ao if~p~n", [Res]),
			Msg = "Invalido",
			gen_tcp:send(Sock, list_to_binary(Msg));
		true ->
			io:format("A resposta não é false")
	end.

newProduct(List, Username, Room) ->
	Size = length([X || X <- List]),
	io:format("Size: ~p ~n", [Size]),
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
			io:format("Prod: ~p Min: ~p Max: ~p Price: ~p Time: ~p MinNumber:~p MaxNumber: ~p PriceNumber: ~p ~n", 
				[Prod, Min, Max, Price, Time, MinNumber, MaxNumber, PriceNumber]),
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
	io:format("O User e: ~p ~n", [Username]),
	if
		User =:= true ->
			Res = checkPassword(Username, Password, Map),
			Res;
		User =/= true ->
			false
	end.

checkPassword(Username, Password, Map)  ->
	{ok, P} = maps:find(Username, Map),
	io:format("A pass e: ~p ~n", [P]),
	if
		P =:= Password ->
			true;
		true ->
			untrue
	end.

checkType(Type) ->
	io:format("Type: ~p ~n", [Type]),
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