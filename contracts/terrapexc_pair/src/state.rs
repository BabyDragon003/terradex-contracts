use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use classic_terrapexc::asset::PairInfoRaw;
use cosmwasm_std::{Addr, CanonicalAddr};
}

pub const CONFIG: Item<Config> = Item::new("config");

pub const PAIR_INFO: Item<PairInfoRaw> = Item::new("pair_info");
