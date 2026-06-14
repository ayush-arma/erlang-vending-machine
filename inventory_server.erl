-module(inventory_server).
-behaviour(gen_server).

-export([
    start_link/0,
    get_price/1,
    check_stock/1,
    decrease_stock/1,
    get_items_below/1,
    purchase/2,
    restock_item/2,
    add_new_item/3
]).

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

get_price(Item) ->
    gen_server:call(?MODULE, {get_price, Item}).

check_stock(Item) ->
    gen_server:call(?MODULE, {check_stock, Item}).

get_items_below(PriceLim) ->
    gen_server:call(?MODULE, {get_items_below, PriceLim}).

purchase(Item, Cash) ->
    gen_server:call(?MODULE, {purchase, Item, Cash}).

decrease_stock(Item) ->
    gen_server:cast(?MODULE, {decrease_stock, Item}).

add_new_item(Item, Price, Quantity) ->
    gen_server:cast(?MODULE, {add_new_item, Item, Price, Quantity}).

restock_item(Item, Quantity) ->
    gen_server:cast(?MODULE, {restock_item, Item, Quantity}).


init(State) ->
    {ok, State}.

handle_call({get_price, Item}, _From, Map) ->
    Reply =
        case maps:find(Item, Map) of
            {ok, {Price, _Qty}} -> {ok, Price};
            error -> {error, not_found}
        end,
    {reply, Reply, Map};
handle_call({check_stock, Item}, _From, Map) ->
    Reply =
        case maps:find(Item, Map) of
            {ok, {_Price, Qty}} -> {ok, Qty};
            error -> {error, not_found}
        end,
    {reply, Reply, Map};
handle_call({get_items_below, PriceLim}, _From, Map) ->
    FilteredMap = maps:filter(
        fun(_Key, {Price, _Quantity}) -> Price =< PriceLim end,
        Map
    ),
    {reply, FilteredMap, Map};
handle_call({purchase, Item, Cash}, _From, Map) ->
    case maps:find(Item, Map) of
        {ok, {Price, Quantity}} when Quantity > 0 ->
            if
                Cash >= Price ->
                    NewState = Map#{Item := {Price, Quantity - 1}},
                    {reply, {ok, Cash - Price}, NewState};
                true ->
                    {reply, {error, insufficient_funds}, Map}
            end;
        {ok, {_Price, 0}} ->
            {reply, {error, out_of_stock}, Map};
        error ->
            {reply, {error, not_found}, Map}
    end.

handle_cast({decrease_stock, Item}, Map) ->
    case maps:find(Item, Map) of
        {ok, {Price, Quantity}} when Quantity > 0 ->
            {noreply, Map#{Item := {Price, Quantity - 1}}};
        _ ->
            %% Item doesn't exist or is already 0, do nothing safely
            {noreply, Map}
    end;
handle_cast({add_new_item, Item, Price, Quantity}, Map) ->
    case maps:is_key(Item, Map) of
        false -> {noreply, Map#{Item => {Price, Quantity}}};
        %% Already exists, ignore
        true -> {noreply, Map}
    end;
handle_cast({restock_item, Item, QuantityToAdd}, Map) ->
    case maps:find(Item, Map) of
        {ok, {Price, OldQuantity}} ->
            NewMap = Map#{Item := {Price, OldQuantity + QuantityToAdd}},
            {noreply, NewMap};
        error ->
            %% Can't restock what doesn't exist
            {noreply, Map}
    end;
handle_cast(_Msg, Map) ->
    {noreply, Map}.

terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.
