-module(vending_machine).
-behaviour(gen_statem).

%% API
-export([
    start_link/0,
    insert_coin/1,
    buy_item/1
]).

%% gen_statem Callbacks
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

%% --- Client API ---

insert_coin(CoinValue) ->
    gen_statem:call(?MODULE, {insert_coin, CoinValue}).

buy_item(ItemName) ->
    gen_statem:call(?MODULE, {buy, ItemName}).

%% --- Initialization ---

%% State Data is simply an integer representing the current credit balance
init([]) ->
    {ok, idle, 0}.

%% --- IDLE STATE ---
idle({call, From}, {insert_coin, CoinValue}, 0) ->
    io:format("Inserted first coin: ~p~n", [CoinValue]),

    %% Instantly fetch items affordable with this single coin to show user
    AvailableItems = inventory_server:get_items_below(CoinValue),

    %% Transition to coin_inserted and set balance to CoinValue
    {next_state, coin_inserted, CoinValue, [{reply, From, {ok, AvailableItems}}]}.

%% --- COIN INSERTED STATE ---

%% Clause 1: Accumulate cash balance
coin_inserted({call, From}, {insert_coin, CoinValue}, CurrentBalance) ->
    NewBalance = CurrentBalance + CoinValue,
    io:format("Added ~p. Total Balance: ~p~n", [CoinValue, NewBalance]),

    AvailableItems = inventory_server:get_items_below(NewBalance),
    {keep_state, NewBalance, [{reply, From, {ok, AvailableItems}}]};
%% Clause 2: Process Purchase
coin_inserted({call, From}, {buy, ItemName}, CurrentBalance) ->
    %% Let the central inventory server decide if the transaction is valid
    %% inventory_server:purchase/2 should check stock AND if CurrentBalance >= Price
    case inventory_server:purchase(ItemName, CurrentBalance) of
        {ok, Change} ->
            io:format("Purchased ~p successfully! Dispensing change: ~p~n", [ItemName, Change]),
            %% Transaction successful: clear money and return to idle
            {next_state, idle, 0, [{reply, From, {dispense, ItemName, change, Change}}]};
        {error, insufficient_funds} ->
            io:format("Not enough money for ~p!~n", [ItemName]),
            {keep_state, CurrentBalance, [{reply, From, {error, insufficient_funds}}]};
        {error, out_of_stock} ->
            io:format("~p is out of stock!~n", [ItemName]),
            {keep_state, CurrentBalance, [{reply, From, {error, out_of_stock}}]}
    end.
