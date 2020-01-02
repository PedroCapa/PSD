-module(teste).

-export([count/1]).

count(Port) ->
		{ok, LSock} = gen_tcp:listen(Port, [binary, {active, false}, {reuseaddr, true}]),
		acceptor(LSock).

acceptor(LSock) ->
		{ok, Sock} = gen_tcp:accept(LSock),
		io:format("Alguem entrou~n"),
		spawn(fun() -> acceptor(LSock) end),
		recebe(Sock).

recebe(Sock) ->
    io:format("Estou a espera~n"),
	Counter = gen_tcp:recv(Sock, 0),
	io:format("Counter is at value: ~p~n", [Counter]),
	envia(Sock),
    recebe(Sock).

envia(Sock) ->
	Data = "Enviei a mensagem\n",
	gen_tcp:send(Sock, Data),
	io:format("Acabei de enviar uma mensagem~n", []).