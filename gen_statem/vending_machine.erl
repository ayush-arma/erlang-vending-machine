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
    idle/3
]).


callback_mode()->
    state_functions.

start_link()->
    gen_statem:start_link({local, ?MODULE}, ?MODULE, [], []).

select(Item)->
    Item.


init([]) ->
    {ok, idle, #{}}.

insert_coin({Pid,Coin})->
    gen_statem:call(Pid, {coin_inserted,Coin}).

idle({call, _From}, {coin_inserted,_CoinValue}, Data) ->
    io:format("Variables Received~p"+Data),
    Data.


