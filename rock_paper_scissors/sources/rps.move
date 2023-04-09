module rock_paper_scissors::rps {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::vector;
    use std::hash;
    
    //const
    const NONE: u8 = 0;
    const ROCK: u8 = 1;
    const PAPER: u8 = 2;
    const SCISSORS: u8 = 3;

    const STATUS_READY: u8 = 0;
    const STATUS_HASH_SUBMISSION: u8 = 1;
    const STATUS_HASHES_SUBMITTED: u8 = 2;
    const STATUS_REVEALING: u8 = 3;
    const STATUS_REVEALED: u8 = 4;

    public fun rock(): u8 {ROCK}
    public fun paper(): u8{PAPER}
    public fun scissors(): u8{SCISSORS}

    struct ThePrize has key, store {
        id: UID
    }

    struct Game has key {
        id: UID,
        prize: ThePrize,
        player_one: address,
        player_two: address,
        hash_one: vector<u8>,
        hash_two: vector<u8>,
        gesture_one: u8,
        gesture_two: u8,
    }

    struct PlayerTurn has key {
        id: UID,
        hash: vector<u8>,
        player: address,
    }

    struct Secret has key {
        id: UID,
        salt: vector<u8>,
        player: address,
    }

    public fun status(game: &Game): u8 {
        let h1_len = vector::length(&game.hash_one);
        let h2_len = vector::length(&game.hash_two);

        if (game.gesture_one != NONE && game.gesture_two != NONE) {
            STATUS_REVEALED
        } else if (game.gesture_one != NONE || game.gesture_two != NONE) {
            STATUS_REVEALING
        } else if (h1_len == 0 && h2_len == 0) {
            STATUS_READY
        } else if (h1_len != 0 && h2_len != 0) {
            STATUS_HASHES_SUBMITTED
        } else if (h1_len != 0 || h2_len != 0) {
            STATUS_HASH_SUBMISSION
        } else {
            0
        }
    }

    public entry fun new_game(player_one: address, player_two: address, ctx: &mut TxContext) {
        transfer::transfer(Game {
            id: object::new(ctx),
            prize: ThePrize { id: object::new(ctx) },
            player_one,
            player_two,
            hash_one: vector[],
            hash_two: vector[],
            gesture_one: NONE,
            gesture_two: NONE,
        }, tx_context::sender(ctx));
    }

    public entry fun player_turn(at: address, hash: vector<u8>, ctx: &mut TxContext) {
        transfer::transfer(PlayerTurn {
            hash,
            id: object::new(ctx),
            player: tx_context::sender(ctx),
        }, at);
    }

    public entry fun add_hash(game: &mut Game, cap: PlayerTurn) {
        let PlayerTurn { hash, id, player } = cap;
        let status = status(game);

        assert!(status == STATUS_HASH_SUBMISSION || status == STATUS_READY, 0);
        assert!(game.player_one == player || game.player_two == player, 0);

        if (player == game.player_one && vector::length(&game.hash_one) == 0) {
            game.hash_one = hash;
        } else if (player == game.player_two && vector::length(&game.hash_two) == 0) {
            game.hash_two = hash;
        } else {
            abort 0
        };

        object::delete(id);
    }

    public entry fun reveal(at: address, salt: vector<u8>, ctx: &mut TxContext) {
        transfer::transfer(Secret {
            id: object::new(ctx),
            salt,
            player: tx_context::sender(ctx),
        }, at);
    }

    public entry fun match_secret(game: &mut Game, secret: Secret) {
        let Secret { salt, player, id } = secret;

        assert!(player == game.player_one || player == game.player_two, 0);

        if (player == game.player_one) {
            game.gesture_one = find_gesture(salt, &game.hash_one);
        } else if (player == game.player_two) {
            game.gesture_two = find_gesture(salt, &game.hash_two);
        };

        object::delete(id);
    }

    public entry fun select_winner(game: Game, ctx: &TxContext) {
        assert!(status(&game) == STATUS_REVEALED, 0);

        let Game {
            id,
            prize,
            player_one,
            player_two,
            hash_one: _,
            hash_two: _,
            gesture_one,
            gesture_two,
        } = game;

        let p1_wins = play(gesture_one, gesture_two);
        let p2_wins = play(gesture_two, gesture_one);

        object::delete(id);

        if (p1_wins) {
            transfer::public_transfer(prize, player_one)
        } else if (p2_wins) {
            transfer::public_transfer(prize, player_two)
        } else {
            transfer::public_transfer(prize, tx_context::sender(ctx))
        };
    }


    fun play(one: u8, two: u8): bool {
        if (one == ROCK && two == SCISSORS) { true }
        else if (one == PAPER && two == ROCK) { true }
        else if (one == SCISSORS && two == PAPER) { true }
        else { false }
    }

    fun find_gesture(salt: vector<u8>, hash: &vector<u8>): u8 {
        if (hash(ROCK, salt) == *hash) {
            ROCK
        } else if (hash(PAPER, salt) == *hash) {
            PAPER
        } else{
            SCISSORS
        }
    }

    fun hash(gesture: u8, salt: vector<u8>): vector<u8> {
        vector::push_back(&mut salt, gesture);
        hash::sha2_256(salt)
    }
}