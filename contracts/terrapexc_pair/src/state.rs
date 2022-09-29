use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use classic_terrapexc::asset::PairInfoRaw;
use cosmwasm_std::{Addr, CanonicalAddr};
use cw_storage_plus::Item;

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, JsonSchema)]
pub struct Config {
    pub owner: CanonicalAddr,
    pub treasury: Addr,
}

pub const CONFIG: Item<Config> = Item::new("config");

