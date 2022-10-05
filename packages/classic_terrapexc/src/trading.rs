use crate::asset::AssetInfo;
use cosmwasm_std::{Addr, Uint128};
use cw20::Cw20ReceiveMsg;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, JsonSchema)]
pub struct InstantiateMsg {
    pub pair_list: Vec<PairInfo>,
    pub enabled: bool,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct MatchOrderResponse {
    pub buyer: Addr,
    pub seller: Addr,
    pub move_amount: Uint128,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct TraderInfo {
    pub id: String,
    pub address: Addr,
    pub order_stock_amount: Uint128,
    pub current_stock_amount: Uint128,
    pub price: Uint128,
}

#[derive(Serialize, Deserialize, Clone, PartialEq, JsonSchema, Debug)]
pub struct TraderListResponse {
    pub traders: Vec<TraderInfo>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum ExecuteMsg {
    /// UpdateConfig update relevant code IDs
    UpdateConfig {
        owner: Option<String>,
        pair_list: Option<Vec<PairInfo>>,
        enabled: Option<bool>,
    },
    Order {
        order: TraderRecord,
        add_order: Option<TraderRecord>,
        update_order: Option<TraderRecord>,
        remove_orders: Option<Vec<TraderRecord>>,
    },
    Cancel {
        order_id: String,
        is_buy: bool,
    },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum ReceiveMsg {}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum QueryMsg {
    Config {},
    Now {},
    ListOrders {
        is_buy: bool,
        start_after: Option<String>,
        limit: Option<u32>,
    },
}

// We define a custom struct for each query response
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct ConfigResponse {
    pub owner: String,
    pub pair_list: Vec<PairInfo>,
    pub enabled: bool,
}

/// We currently take no arguments for migrations
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct MigrateMsg {}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct PairInfo {
    pub from_asset: AssetInfo,
    pub to_asset: AssetInfo,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct TestBalanceResponse {
    pub balance: Uint128,
}
