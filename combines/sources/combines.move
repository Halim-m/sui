module combines::combines{
    use std::option::{Self, Option};

    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    //structs
    struct Shirt has key, store{
        id: UID,
        amount: u8,
    }

    struct Pant has key, store{
        id: UID,
        amount: u8,
    }

    struct Shoe has key, store{
        id: UID,
        amount: u8,
    }

    struct Combine has key{
        id: UID,
        shirt: Option<Shirt>,
        pant: Option<Pant>,
        shoe: Option<Shoe>,
        amount: u8,
    }

    //getters
    public fun get_combine_amount(self: &Combine): u8{
        self.amount
    }

    public fun get_shirt_amount(self: &Shirt): u8 {
        self.amount
    }

    public fun get_pant_amount(self: &Pant): u8 {
        self.amount
    }

    public fun get_shoe_amount(self: &Shoe): u8 {
        self.amount
    }

    //setters
    public entry fun create_shirt(amount: u8, ctx: &mut TxContext){
        let shirt = Shirt{
            id: object::new(ctx),
            amount,
        };
        transfer::transfer(shirt, tx_context::sender(ctx))
    }

    public entry fun create_pant(amount: u8, ctx: &mut TxContext){
        let pant = Pant{
            id: object::new(ctx),
            amount,
        };
        transfer::transfer(pant, tx_context::sender(ctx))
    }

    public entry fun create_combine(ctx: &mut TxContext){
        let combine = Combine{
            id: object::new(ctx),
            shirt: option::none(),
            pant: option::none(),
            shoe: option::none(),
            amount: 0
        };
        transfer::transfer(combine, tx_context::sender(ctx))
    }

    public entry fun wear_shirt(combine: &mut Combine, shirt: Shirt, ctx: &mut TxContext) {
        if (option::is_some(&combine.shirt)) {
            let old_shirt = option::extract(&mut combine.shirt);
            transfer::transfer(old_shirt, tx_context::sender(ctx));
        };
        combine.amount = combine.amount + shirt.amount;
        option::fill(&mut combine.shirt, shirt);
    }

    public entry fun wear_pant(combine: &mut Combine, pant: Pant, ctx: &mut TxContext) {
        if (option::is_some(&combine.pant)) {
            let old_pant = option::extract(&mut combine.pant);
            transfer::transfer(old_pant, tx_context::sender(ctx));
        };
        combine.amount = combine.amount + pant.amount;
        option::fill(&mut combine.pant, pant);
    }

    public entry fun wear_shoe(combine: &mut Combine, shoe: Shoe, ctx: &mut TxContext) {
        if (option::is_some(&combine.shoe)) {
            let old_shoe = option::extract(&mut combine.shoe);
            transfer::transfer(old_shoe, tx_context::sender(ctx));
        };
        combine.amount = combine.amount + shoe.amount;
        option::fill(&mut combine.shoe, shoe);
    }
}