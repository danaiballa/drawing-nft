module drawing_ob::drawing{
  use std::option;
  use std::string::{Self, String};

  use sui::kiosk::Kiosk;
  use sui::object::{Self, UID};
  use sui::package;
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use sui::url::{Self, Url};

  use nft_protocol::collection;
  // use nft_protocol::fixed_price;
  use nft_protocol::mint_cap::MintCap;
  use nft_protocol::ob_kiosk;

  // one time witness for init

  struct DRAWING has drop {}

  struct Drawing has key, store {
    id: UID,
    url: Url,
    description: String,
    version: u64,
  }

  // TODO: add necessary fields to the display object
  fun init(otw: DRAWING, ctx: &mut TxContext){
    let artist = tx_context::sender(ctx);

    // Initialize a collection and a mint cap
    // (in order to create a mint cap using OB the id of the collection is necessary => having a collection in necessary)
    // collection will have unlimited supply (option::none() as 2nd argument)
    // when creating a collection an event is emitted automatically
    let (collection, mint_cap) = collection::create_with_mint_cap<DRAWING, Drawing>(&otw, option::none(), ctx);
    // transfer the mint cap to artist
    transfer::public_transfer(mint_cap, artist);
    // make collection a shared object
    transfer::public_share_object(collection);

    // claim publisher
    // claiming the publisher should be done AFTER creating collection & mint cap 
    // since claiming the publisher will consume the otw
    package::claim_and_keep(otw, ctx);

    // create a new kiosk using OB kiosk
    // the function below creates a kiosk and makes it a shared object
    ob_kiosk::create_for_sender(ctx);
  }

  // mint an nft and deposit it to an OB kiosk
  // but how do I set the price??
  public entry fun mint_and_deposit(_: &MintCap<Drawing>, url_bytes: vector<u8>, description_bytes: vector<u8>, version: u64, kiosk: &mut Kiosk, ctx: &mut TxContext){
    let drawing = Drawing { id: object::new(ctx), url: url::new_unsafe_from_bytes(url_bytes), description: string::utf8(description_bytes), version };
    ob_kiosk::deposit(kiosk, drawing, ctx);
  }

  // I did not find a way so far to purchase an item from a kiosk
  // so let's make a fixed price market


  



}