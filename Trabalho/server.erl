-module(server).
-export([server/1]).

server(Port) ->
		Room = spawn(fun()-> room([]) end),
		{ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}]),
		acceptor(LSock, Room).

acceptor(LSock, Room) ->
		{ok, Sock} = gen_tcp:accept(LSock),
		spawn(fun() -> acceptor(LSock, Room) end),
		Room ! {enter, self()},
		user(Sock, Room).

room(Users) ->
		receive
			{enter, Pid} ->
				io:format("userentered ~n", []),
				Pid ! {tcp, "", ""},
				room(Users);
			{aut, {Username, Password}, PID}  ->
				CheckUsername = containsUsername(Username, Users),
				CheckPassword = containsPassword(Username, Users, Password),
				if
					CheckUsername =:= true, CheckPassword =:= true -> 
						PID ! {sucess, {Username, Password}},
						room(Users);
					CheckUsername =:= true, CheckPassword =:= false -> 
						PID ! {tcp, "", ""},
						room(Users);
					CheckUsername =:= false -> 
						PID ! {sucess, {Username, Password}}, 
						room([{Username, Password} | Users]) 
				end;
			{leave} ->
				io:format("userleft ~n", []),
				room(Users);
				_ -> 
				io:format("Sai da sala ~n", [])
		end.

user(Sock, Room) ->
	receive
		{line, Data} ->
			gen_tcp:send(Sock, Data),
			user(Sock, Room);
		{tcp, _, _} ->
			gen_tcp:send(Sock, "Put the credentials"),
			Person = authentication(),
			Room ! {aut, Person, self()},
			user(Sock, Room);
		{sucess, Person} -> 
			gen_tcp:send(Sock, "authenticated with sucess"),
			authenticated(Sock, Room, Person);
		{tcp_closed, _} ->
			Room ! {leave};
		{tcp_error, _, _} ->
			Room ! {leave}
	end.

authentication() ->
		receive
			{tcp, _, Data} ->
				Username = binary_to_list(Data)
		end,
		receive
			{tcp, _, Pass} ->
				Password = binary_to_list(Pass),
				{Username, Password}
		end.

authenticated(Sock, Room, {Username, Password}) ->
		receive
			{line, Data} ->
				gen_tcp:send(Sock, binary_to_list(Data)),
				authenticated(Sock, Room, {Username, Password});
			{tcp, _, Data} ->
				Room ! {line, Data, self(), Username},
				authenticated(Sock, Room, {Username, Password});
			{tcp_closed, _} ->
				Room ! {leave, self()};
			{tcp_error, _, _} ->
				Room ! {leave, self()}
		end.

containsUsername(_, []) -> false;
containsUsername(Username, [{Name, _} | Tail]) ->
		if Username == Name -> true;
			true -> containsUsername(Username, Tail)
		end.

containsPassword(_, [], _) -> false;
containsPassword(Username, [{Name, Pass} | Tail], Password) ->
		if Username == Name,  Pass == Password ->
					true;
				Username == Name,  Pass =:= Password ->
					false;
				true ->
					containsUsername(Username, Tail)
		end.