-module(user).
-export([user/2]).

%-include ("protos.hrl").

user(Sock, Room) ->
	receive
		{line, Data} ->
			gen_tcp:send(Sock, Data),
			user(Sock, Room);
		{tcp, _, Data} ->
			checkInterface(Data, Sock, Room);
		{tcp_closed, _} ->
			Room ! {leave};
		{tcp_error, _, _} ->
			Room ! {leave}
	end.


checkInterface(Data, Sock, Room) ->
	D = binary_to_list(Data),
	%Substituir aqui pelo tipo de pedido se o pedido for Importador/Negociador ou aqueles request
	%Em vez de 0 e 1 verificar o tipo é importador/negociador/rest
	if
		D =:= "0\n" ->
			io:format("User: Entrei no dropwizard~n"),
			dropwizard:dropwizard(Sock, Room);
		D =:= "1\n" ->
			Person = authentication(Sock, Room),
			Room ! {aut, Person, self()};
		true ->
			gen_tcp:send("Errado\n")
	end.

%Mudar esta função para que apenas envia a mensagem para o Room e não esteja à espera do utilizador
authentication(Sock, Room) ->
		receive
			{tcp, _, Data} ->
				D = binary_to_list(Data),
				if
					D =:= "fab\n" ->
						fabricante:fabricante(Sock, Room);
					true ->
						importador:importador(Sock, Room)
				end
		end.