-module(teste).

-export([count/0]).

count() ->

    {countserver, 'server@pedro'} ! {self(), "count"},
    io:format("Estou a espera"),
    receive

        {ok, Counter} ->

            io:format("Counter is at value: ~p~n", [Counter])

    end.