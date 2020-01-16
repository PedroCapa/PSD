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
				io:format("Fab: ~p   Imp~p~n", [Fab, Imp]),
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
				%Verifica se existe algum fabricante ou Importador com esse nome
				Fab = checkUsername(Username, Password, Fabricantes),
				Imp = checkUsername(Username, Password, Importadores),
				io:format("Fab: ~p   Imp~p~n", [Fab, Imp]),
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
						io:format("Deu erro~n"),
						Result = "erro",
						PID ! {aut, {Username, Result}},
						room(Importadores, Fabricantes)
				end;
			%Em principio vai ser para manter pq é so para colocar um produto
			{new, Fab, Prod, Min, Max, Price, Time, PID} ->
				io:format("Vou tratar no Produto: ~p~p~n", [Fab, Prod]),
				Contains = findUserProd(Fab, Prod, Fabricantes),
				if
					Contains =:= true ->
						Msg = "Ja contem esse produto a venda\n",
						PID ! {res, list_to_binary(Msg)},
						room(Importadores, Fabricantes);
					true ->
						Msg = Fab ++ "," ++ Prod ++ "," ++ Time ++ ",\n",
						Update = addProduct(Fab, Prod, Min, Max, Price, Time, Fabricantes),
						Res = maps:update(Fab, Update, Fabricantes),
						io:format("Adicionei o produto Fabricantes: ~p~nImportadores: ~p~n", [Res, Importadores]),
						PID ! {res, Msg},
						room(Importadores, Res)
				end;
			%Em principio vai ser para manter pq é so para acrescentar uma negociação
			{neg, Username, Fab, Prod, Ammount, Price, Time, PID} ->
				io:format("Vou tratar no Neg: ~p~p~p~n", [Username, Fab, Prod]),
				Contains = findUserOffer(Fab, Prod, Price, Ammount, Time, Fabricantes),
				if
					Contains =:= true ->
						Msg = Fab ++ "," ++ Prod ++ "," ++ "\n",
						Update = addNegocioFabricante(Fab, Username, Prod, Price, Ammount, Time, Fabricantes),
						Res = maps:update(Fab, Update, Fabricantes),
						Up = addNegocioImportador(Username, Fab, Prod, Price, Ammount, Time, Importadores),
						Imp = maps:update(Username, Up, Importadores),
						io:format("Adicionei o Negocio: Fabricantes: ~p~nImportadores: ~p~n", [Res, Imp]),
						PID ! {res, list_to_binary(Msg)},
						room(Imp, Res);
					true ->
						Msg = "Oferta não foi realizada com sucesso\n",
						PID ! {res, Msg},
						room(Importadores, Fabricantes)
				end;

			{finish, {Fabricante, Produto, Negociador}, PID} ->
				{Imp, Fab} = atualizaNegocio(Importadores, Fabricantes, Fabricante, Produto),
				
				{ok, {_, NewProducts}} = maps:find(Fabricante, Fab),
				Update = getProd(NewProducts, Produto),
				Neg = getNeg(Update),
				Status = negStatus(Neg, Negociador),
				PID ! {deal, Status},
				room(Imp, Fab);
			{over, {Fabricante, Produto}, PID} ->
				{Imp, Fab} = atualizaNegocio(Importadores, Fabricantes, Fabricante, Produto),
				
				{ok, {_, NewProducts}} = maps:find(Fabricante, Fab),
				Update = getProd(NewProducts, Produto),
				Accepted = getAcceptedOffers(Update),			%Vai buscar a lista de Negocios que foram aceites
				PID ! {deal, Accepted},
				room(Imp, Fab);
			{imp, Imp, PID} ->
				%Ir buscar o importador e quais são as ofertas que realizaou
				Res = getImp(Imp, Importadores),
				PID ! {res, Res},
				io:format("Chegeui ao Imp~n"),
				room(Importadores, Fabricantes);
			{negotiations, Fab, Prod, PID} ->
				%Vai buscar as negociações de um produto
				Res = getNegotiationsProduct(Fab, Prod, Fabricantes),
				PID ! {res, Res},
				io:format("Peguie nas negociações do produto~n"),
				room(Importadores, Fabricantes);
			{produtores, Fab, PID} ->
				%Ir buscar o Fabricante e os seus produtos
				io:format("O Fabricante é: ~p~n", [Fab]),
				Res = getProdutosFabricante(Fab, Fabricantes),
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

getImp(Importador, Map) ->
	Exist = maps:is_key(Importador, Map),
	if
		Exist =:= true ->
			{ok, {_, Negotiations}} = maps:find(Importador, Map),
			getNegotiationsText(Negotiations);
		true ->
			"\n"
	end.

getNegotiationsText([]) -> "\n";
getNegotiationsText([{Username, Fabricante, Prod, Price, Quant, Data, Status}|T]) ->
	Rest = getNegotiationsText(T),
	Username ++ "," ++ Fabricante ++ "," ++ Prod ++ "," ++ lists:flatten(io_lib:format("~p", [Price])) ++ "," ++ 
	lists:flatten(io_lib:format("~p", [Quant])) ++ "," ++ Status ++ "," ++ Data ++ "," ++ lists:flatten(io_lib:format("~p", [Status])) ++ ",\n" ++ Rest.

getProdutosFabricante(Fab, Map) ->
	Exist = maps:is_key(Fab, Map),
	if
		Exist =:= true ->
			{ok, {_, Prod}} = maps:find(Fab, Map),
			getProdutosText(Prod);
		true ->
			"\n"
	end.

getProdutosText([]) -> "";
getProdutosText([{Username, Min, Max, Price, Time, State, _} | T]) ->
	Rest = getProdutosText(T),
	Username ++ "," ++ lists:flatten(io_lib:format("~p", [Min])) ++ "," ++ lists:flatten(io_lib:format("~p", [Max])) ++ "," ++ 
	lists:flatten(io_lib:format("~p", [Price])) ++ "," ++ Time ++ "," ++ lists:flatten(io_lib:format("~p", [State])) ++ ",\n" ++ Rest.

%Mudar esta funcão pq vai receber uma lista de produtos e não uma lista de negocios
%Não mudar para ja porque talvez possa ser utilizado um MAP e não é preciso correr listas

getNegotiationsProduct(Fab, Produto, Map) ->
	Exist = map:is_key(Fab, Map),
	if
		Exist =:= true ->
			{ok, {_, Produtos}} = maps:find(Fab, Map),
			Prod = getProd(Produtos, Produto),
			Neg = getNeg(Prod),
			getNegotiationsProductText(Neg);
		true ->
			"\n"
	end.

%Vai buscar os negocios de um Produto
getNegotiationsProductText([]) -> "\n";
getNegotiationsProductText([{Username, Price, Ammount, Data, Status}|T]) ->
	Rest = getNegotiationsProductText(T),
	Username ++ "," ++ lists:flatten(io_lib:format("~p", [Price])) ++ "," ++ lists:flatten(io_lib:format("~p", [Ammount])) ++ 
	"," ++ Data ++ "," ++ lists:flatten(io_lib:format("~p", [Status])) ++ ",\n" ++ Rest.

getAcceptedOffers(Produto) ->
	Neg = getNeg(Produto),
	acceptedOffers(Neg).

atualizaNegocio(Importadores, Fabricantes, Fabricante, Produto)->
				{ok, {Pass, Products}} = maps:find(Fabricante, Fabricantes), 	%Vai buscar o Fabricante com esse nome
				P = getProd(Products, Produto),									%Vai buscar o Produto
				Res = checkOver(P),												%Ve se os produtos já foram verificados
				if
					Res =:= false ->
						Prod = changeNegStatus(P),								%Vai mudar o produto
						Update = replaceProd(Products, Prod),					%Substitui o produto na lista de Produtos do fabricante
						Value = {Pass, Update},									
						New = maps:update(Fabricante, Value, Fabricantes),		%Da update ao valor
						
						%Ir buscar a lista que atualiza cada negocio
						Neg = getNeg(Prod),
						Imp = changeImportadores(Neg, Produto, Fabricante, Importadores),
						io:format("Depois do changeImportadores:~n 	 Fabricantes: ~p~n 		Importadores: ~p~n", [New, Imp]),
						{Imp, New};
					true ->
						{Importadores, Fabricantes}
				end.

acceptedOffers([]) ->
	[];
acceptedOffers([{Username, Price, Quant, Time, Status}|T]) ->
	Rest = acceptedOffers(T),
	if
		Status =:= 1 ->
			[{Username, Price, Quant, Time, Status} | Rest];
		true ->
			Rest
	end.

negStatus([], _) ->
	[];
negStatus([{Username, Price, Ammount, Time, Status}|T], User) ->
	Rest = negStatus(T, User),
	if
		Username =:= User ->
			[{Username, Price, Ammount, Time, Status} | Rest];
		true ->
			Rest
	end.

changeNegStatus({Product, Min, Max, Price, Time, _, Neg}) ->
	Produced = checkEnough(Neg, Min),
	if 
		Produced =:= true ->
			Negocio = changeNeg(Neg, Max),
			{Product, Min, Max, Price, Time, 1, Negocio};
		true ->
			Negocio = changeNegImpossible(Neg),
			{Product, Min, Max, Price, Time, 0, Negocio}
	end.

checkEnough([], Min) ->
	if
		Min > 0 ->
			false;
		true ->
			true
	end;
checkEnough([{_, _, Ammount, _, _}|T], Min) ->
	if
		Min - Ammount < 0 ->
			true;
		true ->
			checkEnough(T, Min - Ammount)
	end.

changeNeg([], _) ->
	[];
changeNeg([{Username, Price, Ammount, Time, _} | T], Max) ->
	if
		Max - Ammount >= 0  ->
			New = Max - Ammount,
			Rest = changeNeg(T, New),
			[{Username, Price, Ammount, Time, 1} | Rest];
		true ->
			Rest = changeNeg(T, Max),
			[{Username, Price, Ammount, Time, 0} | Rest]	
	end.

changeNegImpossible([]) ->
	[];
changeNegImpossible([{Username, Price, Ammount, Time, _} | T]) ->
	Rest = changeNegImpossible(T),
	[{Username, Price, Ammount, Time, 0} | Rest].

%	Negocios: que foram alterados
%	Prod: 	Nome do produto
changeImportadores([], _, _, Importadores) -> Importadores;
%A lista são os negocios no Fabricante que vão ser alteradas
changeImportadores([{Username, Price, Quant, Time, Status}| T], Prod, Fabricante, Importadores) ->
	{ok, {Password, Neg}} = maps:find(Username, Importadores), %Vai buscar os Negocios do Importador
	NewNeg = atualizaStatus(Username, Fabricante, Prod, Price, Quant, Time, Status, Neg),	%Vai atualizar o Negocio com aquilo tudo igual
	NewImp = maps:update(Username, {Password, NewNeg}, Importadores),
	changeImportadores(T, Prod, Fabricante, NewImp).

atualizaStatus(_, _, _, _, _, _, _, []) -> [];
atualizaStatus(Username, Fabricante, Prod, Price, Quant, Time, Status, [{User, Fab, Product, Value, Ammount, Data, Validation} | T]) ->
	if
		User =:= Username, Prod =:= Product, Price =:= Value, Quant =:= Ammount, Time =:= Data, Validation =:= -1, Fabricante =:= Fab ->
			[{Username, Fabricante, Prod, Price, Quant, Time, Status}| T];
		true ->
			Rest = atualizaStatus(Username, Fabricante, Prod, Price, Quant, Time, Status, T),
			[{User, Fab, Product, Value, Ammount, Data, Validation}| Rest]
	end.

checkOver({_, _, _, _, _, Status, _}) ->
	if 
		Status =:= 1 ->
			true;
		Status =:= 0 ->
			true;
		true ->
			false
	end.

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
	{ok, {Pass, _}} = maps:find(Username, Map),
	if
		Pass =:= Password ->
			true;
		true ->
			untrue
	end.

findUserProd(Fab, Product, Map) ->
	{ok, {_, P}} = maps:find(Fab, Map),
	existProd(P, Product).

existProd([], _) ->
	false;
existProd([{Prod, _, _, _, _, _, _}|T], Product) ->
	if 
		Product =:= Prod ->
			true;
		true ->
			existProd(T, Product)
	end.

addProduct(Fab, Prod, Min, Max, Price, Time, Fabricantes) ->
	{ok, {Password, Products}} = maps:find(Fab, Fabricantes),
	Final = addProd(Prod, Min, Max, Price, Time, Products),
	{Password, Final}.

addProd(Prod, Min, Max, Price, Time, Final) ->
	{A, _} = string:to_integer(Min),
	{B, _} = string:to_integer(Max),
	{C, _} = string:to_integer(Price),
	[{Prod, A, B, C, Time, -1, []} | Final].

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
verifyOffer(Fab, Product, Pr, Quant, Ti, {Password, [{Prod, _, Max, Price, Time, -1, _} | T]}) ->
	
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
	{ok, {Pass, Prods}} = maps:find(Fab, Fabricantes),
	Product = getProd(Prods, Prod), %Vai buscar o produto
	Neg = getNeg(Product), %Vai buscar os Negocios que se pretende inserir o negocio
	Final = putNegProd(Username, Price, Quant, Time, Neg, Product, Prods), %Lista que ja contem o negocio
	{Pass, Final}.

getProd([], _) ->
	[];
getProd([{Prod, Min, Max, Price, Time, Status, Neg} | T], Product) ->
	if
		Product =:= Prod ->
			{Prod, Min, Max, Price, Time, Status, Neg};
		true ->
			getProd(T, Product)
	end.

getNeg({_, _, _, _, _, _, Neg}) ->
	Neg.

putNegProd(Username, Price, Ammount, Time, Neg, {Name, Min, Max, Pri, Ti, Status, Neg}, Prods) ->
	{A, _} = string:to_integer(Ammount),
	{P, _} = string:to_integer(Price),
	Negocios = addNegProd(Neg, Username, P, A, Time),
	Produto = {Name, Min, Max, Pri, Ti, Status, Negocios},
	replaceProd(Prods, Produto).

addNegProd([], Username, Price, Ammount, Time) ->
	[{Username, Price, Ammount, Time, -1}];

addNegProd([{User, Value, Quant, Date, Status} | T], Username, Price, Ammount, Time) ->
	if
		Value > Price ->
			Rest = addNegProd(T, Username, Price, Ammount, Time),
			[{User, Value, Quant, Date, Status} | Rest];
		Value =:= Price, Quant < Ammount ->
			Rest = addNegProd(T, Username, Price, Ammount, Time),
			[{User, Value, Quant, Date, Status} | Rest];
		Value =:= Price, Ammount >= Quant ->
			[{Username, Price, Ammount, Time, -1}, {User, Value, Quant, Date, Status} | T];
		Value < Price ->
			[{Username, Price, Ammount, Time, -1}, {User, Value, Quant, Date, Status} | T]
	end.

replaceProd([], _) ->
	[];
replaceProd([{Name, Mi, Ma, Price, Time, Sta, Neg} | T], {P, Min, Max, Pri, Ti, Status, Negocios}) ->
	if
		Name =:= P ->
			[{P, Min, Max, Pri, Ti, Status, Negocios} | T];
		true ->
			Rest = replaceProd(T, {P, Min, Max, Pri, Ti, Status, Negocios}),
			[{Name, Mi, Ma, Price, Time, Sta, Neg} | Rest]
	end.
%Adicionar o status quando fizer o Rest
addNegocioImportador(Username, Fabricante, Prod, Price, Quant, Time, Importadores) ->
	{ok, {Password, Negocios}} = maps:find(Username, Importadores),
	addNeg(Password, Username, Fabricante, Prod, Price, Quant, Time, Negocios). %Vamos adicionar o negocio

%Status é depois do tempo
addNeg(Password, Username, Fabricante, Prod, Price, Quant, Time, Negocios)->
	{P, _} = string:to_integer(Price),
	{Q, _} = string:to_integer(Quant),
	{Password, [{Username, Fabricante, Prod, P, Q, Time, -1} | Negocios]}.