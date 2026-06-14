-module(inventory_server).
-behaviour(gen_server).

-export([start_link/0, get_price/1, check_stock/1, decrease_stock/1, get_items_below/1]).

-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    terminate/2,
    code_change/3
]).

-define(INITIAL_VENDING_STATE, #{
    coke => {25, 5},
    pepsi => {30, 3},
    water => {15, 10}
}).

start_link() ->
    io:format("inventory_server start_link() called~n"),
    gen_server:start_link({local, ?MODULE}, ?MODULE, ?INITIAL_VENDING_STATE, []).

init(State) ->
    {ok, State}.

get_price(Item) ->
    gen_server:call(?MODULE, {get_price, Item}).

check_stock(Item) ->
    gen_server:call(?MODULE, {check_stock, Item}).

get_items_below(PriceLim) ->
    gen_server:call(?MODULE, {get_items_below, PriceLim}).

decrease_stock(Item) ->
    gen_server:cast(?MODULE, {decrease_stock, Item}).

handle_call({get_price, Item}, _From, Map) ->
    {Price, _Quantity} = maps:get(Item, Map, {0, 0}),
    {reply, Price, Map};
handle_call({check_stock, Item}, _From, Map) ->
    {_Price, Quantity} = maps:get(Item, Map, {0, 0}),
    {reply, Quantity, Map};
handle_call({get_items_below, PriceLim}, _From, Map) ->
    FilteredMap = maps:filter(
        fun(_Key, {Price, _Quantity}) -> Price =< PriceLim end,
        Map
    ),
    {reply, FilteredMap, Map}.

handle_cast({decrease_stock, Item}, Map) ->
    {Price, Quantity} = maps:get(Item, Map, {undefined, 0}),
    case Quantity > 0 of
        false ->
            {noreply, Map};
        _Anthing ->
            NewMap = Map#{Item => {Price, Quantity - 1}},
            {noreply, NewMap}
    end;
handle_cast(_, Map) ->
    {noreply, Map}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
