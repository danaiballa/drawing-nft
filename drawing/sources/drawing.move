module drawing::drawing{
  // I am an artist, I create drawings and I want to make NFTs of them
  // I want to sell my drawings in a kiosk

  use std::string::String;

  use sui::coin::{Coin};
  use sui::kiosk::{Self, Kiosk};
  use sui::object::{Self, ID, UID};
  use sui::package::{Self, Publisher};
  use sui::sui::SUI;
  use sui::transfer;
  use sui::transfer_policy::{Self, TransferPolicy};
  use sui::tx_context::{Self, TxContext};

  // one-time-witness for the publisher object
  struct DRAWING has drop {}

  // mint capability. I will be able to mint as many drawings as I want.
  struct MintCap has key, store {
    id: UID,
  }

  // drawing NFT
  // TODO: I want the drawing to have a timestamp
  // version field is dummy (and maybe not needed)
  struct Drawing has key, store {
    id: UID,
    url: String,
    description: String,
    version: u64,
  }

  // TODO: add necessary fields to display
  fun init(otw: DRAWING, ctx: &mut TxContext){

    // claim publisher
    package::claim_and_keep(otw, ctx);

    // create a mint cap
    let mint_cap = MintCap { id: object::new(ctx) };
    // transfer the mint cap to me
    transfer::transfer(mint_cap, tx_context::sender(ctx))
  }

  public fun mint(_: &MintCap, url: String, description: String,ctx: &mut TxContext): Drawing{
    Drawing { id: object::new(ctx), url, description, version: 1}
  }

  // I create kiosks to sell my drawings. My kiosks are shared objects
  // TODO: determine if this function requires some type of capability in its inputs
  // since right now anyone can call it
  // kiosk creation could have been done inside the init
  public fun create_kiosk(ctx: &mut TxContext){
    let (kiosk, kiosk_owner_cap) = kiosk::new(ctx);
    // transfer the kiosk owner cap to me
    transfer::public_transfer(kiosk_owner_cap, tx_context::sender(ctx));
    // make the kiosk a shared object
    transfer::public_share_object(kiosk);
  }

  // I list the Drawing type to a kiosk and make a shared transfer policy item. Kind of dummy for the time being
  // listing the drawing type could have probably been done in the init function as well,
  // no need for a separate function
  public fun list_drawing_type(publisher: &Publisher, ctx: &mut TxContext){
    let (transfer_policy, transfer_policy_cap) = transfer_policy::new<Drawing>(publisher, ctx);    
    transfer::public_transfer(transfer_policy_cap, tx_context::sender(ctx));
    transfer::public_share_object(transfer_policy)
  }

  // I can list a drawing in the kiosk by calling the kiosk::place_and_list function
  // see the test for that

  // you pay for it is confirmed you leave
  public fun purchase_drawing(kiosk: &mut Kiosk, id: ID, payment: Coin<SUI>, transfer_policy: &TransferPolicy<Drawing>, ctx: &mut TxContext){
    // the line below will abort if the payment is not equal to the one I set when I listed the item
    let (item, transfer_request) = kiosk::purchase(kiosk, id, payment);
    let (_, _, _) = transfer_policy::confirm_request(transfer_policy, transfer_request);
    transfer::transfer(item, tx_context::sender(ctx));
  }

  #[test_only]
  public fun init_test(otw: DRAWING, ctx: &mut TxContext){
    init(otw, ctx);
  }

  #[test_only]
  public fun get_otw_for_test(): DRAWING{
    DRAWING {}
  }

  #[test_only]
  public fun id(drawing: &Drawing): ID{
    object::uid_to_inner(&drawing.id)
  }
}