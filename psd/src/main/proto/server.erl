-module(server).
-export([server/4, room/2]).

server(Port, Port1, Port2, Port3) ->
		Room = spawn(fun()-> room(#{}, #{}) end),
		{ok, LSock} = gen_tcp:listen(Port, [binary, {packet, 0}, {reuseaddr, true}, {active, true}]),
		acceptor(LSock, Port1, Port2, Port3, Room).

acceptor(LSock, Port1, Port2, Port3, Room) ->
		{ok, Sock} = gen_tcp:accept(LSock),
		spawn(fun() -> acceptor(LSock, Port1, Port2, Port3, Room) end),
		Room ! {enter, self()},
		user:user(Sock, Port1, Port2, Port3, Room).

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
						Result = true,
						PID ! {aut, {Username, Result}},
						room(Importadores, Fabricantes);
					%No caso do Utilizador não existir
					Fab =:= false, Imp =:= false ->
						Result = true,
						PID ! {aut, {Username, Result}},
						room(maps:merge(#{Username => Password}, Importadores), Fabricantes);
					%No caso de errar a palavra-passe
					true ->
						Result = false,
						PID ! {aut, {Username, Result}},
						room(Importadores, Fabricantes)
				end;
			{fab, {Username, Password}, PID}  ->
				%Verifica se existe algum fabricante ou Importador com esse nome
				Fab = checkUsername(Username, Password, Fabricantes),
				Imp = checkUsername(Username, Password, Importadores),
				if
					%No caso do Utilizador ser um Fabricante
					Fab =:= true ->
						Result = true,
						PID ! {aut, {Username, Result}},
						room(Importadores, Fabricantes);
					%No caso do Utilizador não existir
					Fab =:= false, Imp =:= false ->
						Result = true,
						PID ! {aut, {Username, Result}},
						room(Importadores, maps:merge(#{Username => Password}, Fabricantes));
					%No caso de errar a palavra-passe
					true ->
						io:format("Deu erro~n"),
						Result = false,
						PID ! {aut, {Username, Result}},
						room(Importadores, Fabricantes)
				end;
			{leave, _} ->
				io:format("userleft ~n", []),
				room(Importadores, Fabricantes);
				_ -> 
				io:format("Sai ~n", []),
				room(Importadores, Fabricantes)
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
	{ok, Pass} = maps:find(Username, Map),
	if
		Pass =:= Password ->
			true;
		true ->
			untrue
	end.