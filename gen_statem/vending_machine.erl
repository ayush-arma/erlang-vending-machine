-module(vending_machine).
-behaviour(gen_statem).

-export([
    start_link/0,
    select/1,
    insert_coin/1
]).

-export([
    init/1,
    callback_mode/0,
    idle/3,
    collecting_money/3,
    dispensing/3
]).



start_link()->
    gen_statem:start_link({local, ?MODULE}, ?MODULE, [], []).

select(Item)->
    Item.

insert_coin(Coin)->
    Coin.

init(_Anything) ->
    io:format("Vending Machine started: RED~n"),
    {ok, idle, #{}, [{state_timeout, 300, next}]}.