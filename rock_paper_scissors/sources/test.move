// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module rock_paper_scissors::test {
    use rock_paper_scissors::rps::{Self as Game, Game, PlayerTurn, Secret, ThePrize};
    use sui::test_scenario::{Self};
    use std::vector;
    use std::hash;

    #[test]
    fun test_rps() {
        let owner = @0xA1C05;
        let player_1 = @0xA55555;
        let player_2 = @0x590C;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        Game::new_game(player_1, player_2, test_scenario::ctx(scenario));

        test_scenario::next_tx(scenario, player_1);
        {
            let hash = hash(Game::rock(), b"^.^");
            Game::player_turn(owner, hash, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, owner);
        {
            let game = test_scenario::take_from_sender<Game>(scenario);
            let cap = test_scenario::take_from_sender<PlayerTurn>(scenario);

            assert!(Game::status(&game) == 0, 0);

            Game::add_hash(&mut game, cap);

            assert!(Game::status(&game) == 1, 0);

            test_scenario::return_to_sender(scenario, game);
        };

        test_scenario::next_tx(scenario, player_2);
        {
            let hash = hash(Game::scissors(), b"^.^");
            Game::player_turn(owner, hash, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, owner);
        {
            let game = test_scenario::take_from_sender<Game>(scenario);
            let cap = test_scenario::take_from_sender<PlayerTurn>(scenario);
            Game::add_hash(&mut game, cap);

            assert!(Game::status(&game) == 2, 0);

            test_scenario::return_to_sender(scenario, game);
        };

        test_scenario::next_tx(scenario, player_1);
        Game::reveal(owner, b"^.^", test_scenario::ctx(scenario));

        test_scenario::next_tx(scenario, owner);
        {
            let game = test_scenario::take_from_sender<Game>(scenario);
            let secret = test_scenario::take_from_sender<Secret>(scenario);
            Game::match_secret(&mut game, secret);

            assert!(Game::status(&game) == 3, 0);

            test_scenario::return_to_sender(scenario, game);
        };

        test_scenario::next_tx(scenario, player_2);
        Game::reveal(owner, b"^.^", test_scenario::ctx(scenario));

        test_scenario::next_tx(scenario, owner);
        {
            let game = test_scenario::take_from_sender<Game>(scenario);
            let secret = test_scenario::take_from_sender<Secret>(scenario);
            Game::match_secret(&mut game, secret);

            assert!(Game::status(&game) == 4, 0);

            Game::select_winner(game, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, player_1);
        let prize = test_scenario::take_from_sender<ThePrize>(scenario);
        test_scenario::return_to_sender(scenario, prize);
        test_scenario::end(scenario_val);
    }

    fun hash(gesture: u8, salt: vector<u8>): vector<u8> {
        vector::push_back(&mut salt, gesture);
        hash::sha2_256(salt)
    }
}