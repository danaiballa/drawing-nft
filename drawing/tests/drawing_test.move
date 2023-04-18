#[test_only]
module drawing::drawing_test{
  use std::option;

  use sui::coin;
  use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
  use sui::package::Publisher;
  use sui::sui::SUI;
  use sui::test_scenario;
  use sui::transfer;
  use sui::transfer_policy::TransferPolicy;

  use drawing::drawing::{Drawing, Self, MintCap};

  const EObjectNotFound: u64 = 0;

  #[test]
  fun test_basic_flow(){
    let artist = @0x1;
    let user = @0x2;

    // test is initialized by artist
    let scenario_val = test_scenario::begin(artist);
    let scenario = &mut scenario_val;
    let otw = drawing::get_otw_for_test(); 
    drawing::init_test(otw, test_scenario::ctx(scenario));

    // next transaction by artist to mint an nft
    test_scenario::next_tx(scenario, artist);
    let mint_cap = test_scenario::take_from_address<MintCap>(scenario, artist);
    // use a dummy url :), I am not really an artist
    drawing::mint(&mint_cap, b"google.com", b"a test drawing", test_scenario::ctx(scenario));
    test_scenario::return_to_address(artist, mint_cap);

    // next transaction by artist to create a kiosk to sell the drawings
    test_scenario::next_tx(scenario, artist);
    drawing::create_kiosk(test_scenario::ctx(scenario));

    // next transaction by artist to list Drawing type to kiosk
    test_scenario::next_tx(scenario, artist);
    let publisher = test_scenario::take_from_address<Publisher>(scenario, artist);
    drawing::list_drawing_type(&publisher, test_scenario::ctx(scenario));
    test_scenario::return_to_address(artist, publisher);

    // next transaction by artist to list the nft in the kiosk
    test_scenario::next_tx(scenario, artist);
    let drawing = test_scenario::take_from_address<Drawing>(scenario, artist);
    // we save the id of the drawing for later
    let drawing_id = drawing::id(&drawing);
    let kiosk = test_scenario::take_shared<Kiosk>(scenario);
    let kiosk_owner_cap = test_scenario::take_from_address<KioskOwnerCap>(scenario, artist);
    kiosk::place_and_list(&mut kiosk, &kiosk_owner_cap, drawing, 2);
    test_scenario::return_shared(kiosk);
    test_scenario::return_to_address(artist, kiosk_owner_cap);

    // next transaction by user to buy the nft from the kiosk
    test_scenario::next_tx(scenario, user);
    // by trial-and-error I realized the user should give as input EXACTLY the price of the NFT
    // so I mint the price of the nft
    // but this could potentially be modified in the custom purchase function
    let coin_to_pay = coin::mint_for_testing<SUI>(2, test_scenario::ctx(scenario));
    let kiosk = test_scenario::take_shared<Kiosk>(scenario);
    let transfer_policy = test_scenario::take_shared<TransferPolicy<Drawing>>(scenario);
    // this is where we use the nft id in order to buy the nft
    drawing::purchase_drawing(&mut kiosk, drawing_id, coin_to_pay, &transfer_policy, test_scenario::ctx(scenario));
    test_scenario::return_shared(transfer_policy);
    test_scenario::return_shared(kiosk);

    // next transaction to make sure that user owns an nft now
    test_scenario::next_tx(scenario, user);
    assert!(test_scenario::has_most_recent_for_address<Drawing>(user), EObjectNotFound);

    // next transaction by artist to collect the profits
    test_scenario::next_tx(scenario, artist);
    let kiosk = test_scenario::take_shared<Kiosk>(scenario);
    let kiosk_owner_cap = test_scenario::take_from_address<KioskOwnerCap>(scenario, artist);
    let profits = kiosk::withdraw(&mut kiosk, &kiosk_owner_cap, option::none(), test_scenario::ctx(scenario));
    transfer::public_transfer(profits, artist);
    test_scenario::return_shared(kiosk);
    test_scenario::return_to_address(artist, kiosk_owner_cap);

    test_scenario::end(scenario_val);
  }  

}