
rm -f *.beam

rm -f *.dump

erlc *.erl

erl -eval "inventory_server:start_link(), 
vending_machine:start_link(),
vending_machine:insert_coin(40),
vending_machine:buy_item(coke). "


