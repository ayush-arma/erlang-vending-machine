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
    coin_inserted/3

]).

callback_mode() ->
    state_functions.

start_link() ->
    gen_statem:start_link({local, ?MODULE}, ?MODULE, [], []).

select(Item) ->
    gen_statem:call(?MODULE, {select, Item}).

init([]) ->
    {ok, idle, #{}}.

insert_coin(Coin) ->
    gen_statem:call(?MODULE, {show_items, Coin}).

idle({call, From}, {show_items, CoinValue}, Data) ->
    io:format("Idle Called ~p ~p ~p",[From,CoinValue,Data]),
    Items = inventory_server:get_items_below(CoinValue),
    NewState = #{
        inserted => CoinValue,
        available => Items
    },
    {next_state, coin_inserted, NewState, [{reply, From, Items}]}.

coin_inserted({call,From},{Action,ItemName},State)->
    io:format("User wants to ~p the item ~p ~p ~n", [Action, ItemName, State]),
    {keep_state, State, [{reply, From, ok}]}.
