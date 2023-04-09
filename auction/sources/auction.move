module auction::auction{
    use sui::coin::{Self, Coin};
    use sui::balance::Balance;
    use sui::sui::SUI;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self,TxContext};

    use auction::auction_helper::{Self, Auction};

    struct Bid has key{
        id: UID,
        bidder: address,
        auction_id: ID,
        bid: Balance<SUI>
    }

    public fun create_auction<T: key + store>(
        to_sell: T, auctioner: address, ctx: &mut TxContext
    ): ID {
        let auction = auction_helper::create_auction(to_sell, ctx);
        let id = object::id(&auction);
        auction_helper::transfer(auction, auctioner);
        id
    }

    public fun bid(
        coin: Coin<SUI>, auction_id: ID, auctioner: address, ctx: &mut TxContext
    ){
        let bid = Bid{
            id: object::new(ctx),
            bidder: tx_context::sender(ctx),
            auction_id,
            bid: coin::into_balance(coin),
        };
        transfer::transfer(bid, auctioner);
    }

    public entry fun update_auction<T: key + store>(
        auction: &mut Auction<T>, bid: Bid, ctx: &mut TxContext
    ){
        let Bid{
            id,
            bidder,
            auction_id,
            bid: balance
        } = bid;
        auction_helper::update_auction(auction, bidder, balance, ctx);

        object::delete(id);
    }

    public entry fun end_auction<T: key + store>(
        auction: Auction<T>, ctx: &mut TxContext
    ){
        auction_helper::end_auction(auction, ctx);
    }
}