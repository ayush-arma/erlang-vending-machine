-module(inventory_server).
-behaviour(gen_server). 

-export([start_link/0,get_price/1,check_stock/1,decrease_stock/1]).

-export([init/1, handle_call/3, handle_cast/2]).

-define(INITIAL_VENDING_STATE,#{
    
    }).


start_link()->
    gen_server:start_link({local,?MODULE},?MODULE,[],[]).

init(State)->
    {ok,State}.

get_price(Item)->
    gen_server:call(?MODULE,{get_price,Item}).

check_stock(Item)->
    gen_server:call(?MODULE,{check_stock,Item}).

decrease_stock(Item)->
    gen_server:cast(?MODULE,{decrease_stock,Item}).

handle_call({get_price,Item},_From,Map)->
    {Price,_Quantity} = maps:get(Item, Map, {0,0}),
    {reply,Price};
handle_call({check_stock,Item},_From,Map)->
    {_Price,Quantity} = maps:get(Item, Map, {0,0}),
    {reply,Quantity}.

handle_cast({decrease_stock,Item},Map)->
    {Price,Quantity}=maps:get(Item,Map,{undefined,0}),
    case Price of 
        undefined ->
            {noreply,Map};
        _Anthing->
            NewMap=Map#{Item=>{Price,Quantity-1}},
            {noreply,NewMap}
        end.







