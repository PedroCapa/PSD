-module(server).
-export([server/1, room/2]).

%-include("protos.hrl").

server(Port) ->
		Room = spawn(fun()-> room(#{}, #{}) end),
		{ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}]),
		acceptor(LSock, Room).

acceptor(LSock, Room) ->
		{ok, Sock} = gen_tcp:accept(LSock),
		spawn(fun() -> acceptor(LSock, Room) end),
		Room ! {enter, self()},
		user:user(Sock, Room).

%Dependendo daquilo que será feito talvez seja para guardar os PID para realizar notificações

room(Importadores, Fabricantes) ->
		receive
			{enter, _} ->
				io:format("userentered~n", []),
				room(Importadores, Fabricantes);
			%Vai ser so para verificar se existe ou não o utilizador no caso de a palavra passe estar incorreta apenas enviar resposta de erro 
			%Acrescentar qual foi o tipo que ele colocou
			{imp, {Username, Password}, PID}  ->
				%Verifica se existe algum fabricante ou Importador com esse nome
				Fab = checkUsername(Username, Password, Fabricantes),
				Imp = checkUsername(Username, Password, Importadores),
				if
					%No caso do Utilizador ser um Importador
					Imp =:= true ->
						Result = "login",
						PID ! {aut, {Username, Result}},
						room(Importadores, Fabricantes);
					%No caso do Utilizador não existir
					Fab =:= false, Imp =:= false ->
						Result = "1",
						PID ! {aut, {Username, Result}},
						room(maps:merge(#{Username => {Password, []}}, Importadores), Fabricantes);
					%No caso de errar a palavra-passe
					true ->
						Result = "erro",
						PID ! {aut, {Username, Result}},
						room(Importadores, Fabricantes)
				end;
			{fab, {Username, Password}, PID}  ->
				io:format("Server: Username: ~p Password: ~p~n", [Username, Password]),
				%Verifica se existe algum fabricante ou Importador com esse nome
				Fab = checkUsername(Username, Password, Fabricantes),
				Imp = checkUsername(Username, Password, Importadores),
				if
					%No caso do Utilizador ser um Fabricante
					Fab =:= true ->
						Result = "login",
						PID ! {aut, {Username, Result}},
						room(Importadores, Fabricantes);
					%No caso do Utilizador não existir
					Fab =:= false, Imp =:= false ->
						Result = "1",
						PID ! {aut, {Username, Result}},
						room(Importadores, maps:merge(#{Username => {Password, []}}, Fabricantes));
					%No caso de errar a palavra-passe
					true ->
						Result = "erro",
						PID ! {aut, {Username, Result}},
						room(Importadores, Fabricantes)
				end;
			%Em principio vai ser para manter pq é so para colocar um produto
			{new, Fab, Prod, Min, Max, Price, Time, PID} ->
				Contains = findUserProd(Fab, Prod, Fabricantes),
				if
					Contains =:= true ->
						Msg = "Ja contem esse produto a venda\n",
						PID ! {res, list_to_binary(Msg)},
						room(Importadores, Fabricantes);
					true ->
						Msg = Fab ++ "," ++ Prod ++ "," ++ Time ++ ",\n",
						PID ! {res, list_to_binary(Msg)},
						Update = addProduct(Fab, Prod, Min, Max, Price, Time, Fabricantes),
						Res = maps:update(Fab, Update, Fabricantes),
						room(Importadores, Res)
				end;
			%Em principio vai ser para manter pq é so para acrescentar uma negociação
			{neg, Username, Fab, Prod, Ammount, Price, Time, PID} ->
				Contains = findUserOffer(Fab, Prod, Price, Ammount, Time, Fabricantes),
				if
					Contains =:= true ->
						Msg = Fab ++ "," ++ Prod ++ "," ++ "\n",
						Update = addNegocioFabricante(Fab, Username, Prod, Price, Ammount, Time, Fabricantes),
						Res = maps:update(Fab, Update, Fabricantes),
						Up = addNegocioImportador(Username, Prod, Price, Ammount, Time, Importadores),
						Imp = maps:update(Username, Up, Importadores),
						PID ! {res, list_to_binary(Msg)},
						room(Imp, Res);
					true ->
						Msg = "Oferta não foi realizada com sucesso\n",
						PID ! {res, list_to_binary(Msg)},
						room(Importadores, Fabricantes)
				end;
			{imp, Imp, PID} ->
				%Ir buscar o importador e quais são as ofertas que realizaou
				Res = getImp(Imp, Importadores),
				PID ! {res, Res},
				io:format("Chegeui ao Imp~n"),
				room(Importadores, Fabricantes);
			{negotiations, Fab, Prod, PID} ->
				%Vai buscar as negociações de um produto
				Res = getNegotiations(Fab, Prod, Fabricantes),
				PID ! {res, Res},
				io:format("Peguie nas negociações do produto~n"),
				room(Importadores, Fabricantes);
			{produtores, Fab, PID} ->
				%Ir buscar o Fabricante e os seus produtos
				io:format("O Fabricante é: ~p~n", [Fab]),
				Res = getProdutos(Fab, Fabricantes),
				PID ! {res, Res},
				io:format("Chegeu ao Fab~n"),
				room(Importadores, Fabricantes);
			{leave, _} ->
				io:format("userleft ~n", []),
				room(Importadores, Fabricantes);
				_ -> 
				io:format("Sai ~n", []),
				room(Importadores, Fabricantes)
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

%Mudar esta funcão pq vai receber uma lista de produtos e não uma lista de negocios
%Não mudar para ja porque talvez possa ser utilizado um MAP e não é preciso correr listas
getNegotiations(_, _, []) -> [];
getNegotiations(Fab, S, [{Username, Fabr, Prod, Price, Quant} | T]) ->
	Rest = getNegotiations(Fab, S, T),
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
	Pass = getPassword(P),
	if
		Pass =:= Password ->
			true;
		true ->
			untrue
	end.

findUserProd(Fab, Product, Map) ->
	io:format("Server: Map: ~p~n", [Map]),
	{ok, P} = maps:find(Fab, Map),
	findProd(P, Product).

findProd({_, []}, _) ->
	false;
findProd({Password, [{Prod, _, _, _, _, _}|T]}, Product) ->
	if 
		Product =:= Prod ->
			true;
		true ->
			findProd({Password, T}, Product)
	end.

addProduct(Fab, Prod, Min, Max, Price, Time, Fabricantes) ->
	{ok, P} = maps:find(Fab, Fabricantes),
	Password = getPassword(P),
	Products = getProds(P),
	Final = addProd(Prod, Min, Max, Price, Time, Products),
	{Password, Final}.

getPassword({Password, _}) ->
	Password.

getProds({_, Prod}) ->
	Prod.

addProd(Prod, Min, Max, Price, Time, Final) ->
	{A, _} = string:to_integer(Min),
	{B, _} = string:to_integer(Max),
	{C, _} = string:to_integer(Price),
	[{Prod, A, B, C, Time, []} | Final].

findUserOffer(Fab, Product, Pr, Ammount, Time, Fabricantes) ->
	User = maps:is_key(Fab, Fabricantes),
	if
		User =:= true ->
			{ok, P} = maps:find(Fab, Fabricantes),
			verifyOffer(Fab, Product, Pr, Ammount, Time, P);
		User =/= true ->
			false
	end.

verifyOffer(_, _, _, _, _, {_, []}) ->
	false;
verifyOffer(Fab, Product, Pr, Quant, Ti, {Password, [{Prod, _, Max, Price, Time, _} | T]}) ->
	
	Pri = [Char || Char <- Pr, Char < $0 orelse Char > $9] == [],
	Q = [Char || Char <- Quant, Char < $0 orelse Char > $9] == [],
	{E, _} = string:to_integer(Pr),
	{F, _} = string:to_integer(Quant),

	if
		Q =:= true, Pri =:= true, Product =:= Prod,  E >= Price, F =< Max, Time > Ti ->
			true;
		Product =:= Prod ->
			false;
		true ->
			verifyOffer(Fab, Product, Pr, Quant, Ti, {Password, T})
	end.

addNegocioFabricante(Fab, Username, Prod, Price, Quant, Time, Fabricantes) ->
	{ok, P} = maps:find(Fab, Fabricantes),
	Prods = getProds(P), %Vai buscar os produtos de um fabricante
	Pass = getPassword(P),
	Product = getProd(Prods, Prod), %Vai buscar o produto
	Neg = getNeg(Product), %Vai buscar os Negocios que se pretende inserir o negocio
	Final = putNegProd(Username, Price, Quant, Time, Neg, Product, Prods), %Lista que ja contem o negocio
	{Pass, Final}.

getProd([], _) ->
	[];
getProd([{Prod, Min, Max, Price, Quant, Neg} | T], Product) ->
	if
		Product =:= Prod ->
			{Prod, Min, Max, Price, Quant, Neg};
		true ->
			getProd(T, Product)
	end.

getNeg({_, _, _, _, _, Neg}) ->
	Neg.

putNegProd(Username, Price, Ammount, Time, Neg, {Name, Min, Max, Pri, Ti, Neg}, Prods) ->
	{A, _} = string:to_integer(Ammount),
	{P, _} = string:to_integer(Price),
	Negocios = addNegProd(Neg, Username, A, P, Time),
	Produto = {Name, Min, Max, Pri, Ti, Negocios},
	Final = replaceProd(Prods, Produto),
	Final.

addNegProd([], Username, Ammount, Price, Time) ->
	[{Username, Ammount, Price, Time, -1}];

addNegProd([{User, Quant, Value, Date, Status} | T], Username, Ammount, Price, Time) ->
	if
		Value > Price ->
			Rest = addNegProd(T, Username, Ammount, Price, Time),
			[{User, Quant, Value, Date, Status} | Rest];
		Value =:= Price, Quant < Ammount ->
			Rest = addNegProd(T, Username, Ammount, Price, Time),
			[{User, Quant, Value, Date, Status} | Rest];
		Value =:= Price, Ammount >= Quant ->
			[{Username, Ammount, Price, Time, -1}, {User, Quant, Value, Date, Status} | T];
		Value < Price ->
			[{Username, Ammount, Price, Time, -1}, {User, Quant, Value, Date, Status} | T]
	end.

replaceProd([], _) ->
	[];
replaceProd([{Name, Mi, Ma, Price, Time, Neg} | T], {P, Min, Max, Pri, Ti, Negocios}) ->
	if
		Name =:= P ->
			[{P, Min, Max, Pri, Ti, Negocios} | T];
		true ->
			Rest = replaceProd(T, {P, Min, Max, Pri, Ti, Negocios}),
			[{Name, Mi, Ma, Price, Time, Neg} | Rest]
	end.

addNegocioImportador(Username, Prod, Price, Quant, Time, Importadores) ->
	{ok, User} = maps:find(Username, Importadores),
	Password = getPassword(User),
	Negocios = getNegs(User), %Vamos buscar os negocios
	Final = addNeg(Password, Username, Prod, Price, Quant, Time, Negocios), %Vamos adicionar o negocio
	Final.

getNegs({_, Neg})->
	Neg.

addNeg(Password, Username, Prod, Price, Quant, Time, Negocios)->
	{Password, [{Username, Prod, Price, Quant, Time} | Negocios]}.