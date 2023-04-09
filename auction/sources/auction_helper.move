module auction::auction_helper{
    use std::option::{Self, Option};

    use sui::coin;
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;

    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self,TxContext};

    struct Bid has store {
        fund: Balance<SUI>,
        last_bidder: address,
    }

    struct Auction<T: key + store> has key{
        id: UID,
        to_sell: Option<T>,
        owner: address,
        bid: Option<Bid>,
    }

    public fun create_auction<T: key + store>(
        to_sell: T, ctx: &mut TxContext
    ):Auction<T> {
            Auction<T>{
                id: object::new(ctx),
                to_sell: option::some(to_sell),
                owner: tx_context::sender(ctx),
                bid: option::none(),
            }
    }
    

    public fun update_auction<T: key + store>(
        auction: &mut Auction<T>,
        bidder: address,
        fund: Balance<SUI>,
        ctx: &mut TxContext,
    ){
        if(option::is_none(&auction.bid)){
            let bid = Bid {
                fund,
                last_bidder: bidder,
            };
            option::fill(&mut auction.bid, bid);
        }else{
            let prev= option::borrow(&auction.bid);
            if(balance::value(&fund) > balance::value(&prev.fund)){
                let new = Bid{
                    fund,
                    last_bidder: bidder,
                };

                let Bid{
                    fund,
                    last_bidder,
                } = option::swap(&mut auction.bid, new);
                
                send_balance(fund, last_bidder, ctx);
            }
            else{
                send_balance(fund, bidder, ctx);
            }
        }
    }

    public fun end_auction<T: key + store>(
        auction: Auction<T>, ctx: &mut TxContext
    ) {
        let Auction { id, to_sell, owner, bid } = auction;
        object::delete(id);

        end(&mut to_sell, owner, &mut bid, ctx);

        option::destroy_none(bid);
        option::destroy_none(to_sell);
    }

    fun end<T: key + store>(
        to_sell: &mut Option<T>,
        owner: address,
        bid: &mut Option<Bid>,
        ctx: &mut TxContext
    ){
        let item = option::extract(to_sell);
        if(option::is_some<Bid>(bid)){
            let Bid{
                fund,
                last_bidder,
            } = option::extract(bid);
            send_balance(fund, owner, ctx);
            transfer::public_transfer(item, last_bidder);
        }else{
            transfer::public_transfer(item, owner);
        }
    }



    fun send_balance(balance: Balance<SUI>, to: address, ctx: &mut TxContext) {
        transfer::public_transfer(coin::from_balance(balance, ctx), to)
    }

    public fun transfer<T: key + store>(obj: Auction<T>, recipient: address) {
        transfer::transfer(obj, recipient)
    }
}