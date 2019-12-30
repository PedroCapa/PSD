-module(server).
-export([server/1]).

%Verificar novamente as partes de comunicação, por exemplo quando se recebe ou envia alguma coisa

server(Port) ->
		Room = spawn(fun()-> room(#{}, #{}) end),
		{ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}]),
		acceptor(LSock, Room).

acceptor(LSock, Room) ->
		{ok, Sock} = gen_tcp:accept(LSock),
		spawn(fun() -> acceptor(LSock, Room) end),
		Room ! {enter, self()},
		user(Sock, Room).

room(Importadores, Fabricantes) ->
		receive
			{enter, Pid} ->
				io:format("userentered ~p~n", [Pid]),
				room(Importadores, Fabricantes);
			{aut, {Username, Password}, PID}  ->
				Fab = checkUsername(Username, Password, Fabricantes),
				Imp = checkUsername(Username, Password, Importadores),
				io:format("~p   ~p ~n", [Fab, Imp]),
				if
					%Mudar para o caso de ser Fabricante ou Importador
					Imp =:= true ->
						io:format("O utilizador acertou as credenciais"),
						PID ! {imp, {Username, Password}},
						room(Importadores, Fabricantes);
					Fab =:= true ->
						io:format("O user acertou"),
						PID ! {fab, {Username, Password}},
						room(Importadores, Fabricantes);
					Fab =:= false, Imp =:= false ->
						%Enviar a dizer que precisa de indicar se é Importador ou Fabricante
						io:format("O utilizador registou-se"),
						PID ! {type, {Username, Password}},
						room(Importadores, Fabricantes);
					true ->
						io:format("Acertou miseravel"),
						PID ! {tcp, "", ""},
						room(Importadores, Fabricantes)
				end;
			%Adicionar outro pq ele colocou a dizer se era Fabricante ou Importador
			{type, {Username, Password}, Type, PID} ->
				T = checkType(Type),
				if 
					T =:= true->
						PID ! {imp, {Username, Password}},
						io:format("Username: ~p ~n Password: ~p ~n", [Username, Password]),
						room(maps:merge(#{Username => Password}, Importadores), Fabricantes);
					true ->
						PID ! {fab, {Username, Password}},
						io:format("Username: ~p ~n Password: ~p ~n", [Username, Password]),
						room(Importadores, maps:merge(#{Username => Password}, Fabricantes))
				end;
			{leave} ->
				io:format("userleft ~n", []),
				room(Importadores, Fabricantes);
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
				io:format("Recebi ~p~n", [binary_to_list(Data)]),
				importador(Sock, Room, {Username, Password});
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.

fabricante(Sock, Room, {Username, Password}) ->
		receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				fabricante(Sock, Room, {Username, Password});
			{tcp, _, Data} ->
				io:format("Recebi ~p~n", [binary_to_list(Data)]),
				fabricante(Sock, Room, {Username, Password});
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.

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