NETWORK=mainnet
FUNCTION=$1
CATEGORY=$2
PARAM_1=$3
PARAM_2=$4
PARAM_3=$5
PASSWORD="passwordpassword"
ADDR_PRISM="terra13nf0puwmwwx3lp7jg52pverxjpx75fazpxyzch"
BURN_ADDR="terra1sk06e3dyexuq4shw77y3dsv480xv42mq73anxu"

TEST_TOKEN1="terra1uug8advt2q2tjl7630n448wgxznhku2fuaad2j"
TEST_TOKEN2="terra1yvju0vr6wqmwl6cd8frs9lujv0pry0q43uf5py"

case $NETWORK in
 devnet)
 NODE=""
 DENOM=""
 CHAIN_ID=""
 WALLET=""
 ADDR_ADMIN=$ADDR_PRISM
 GAS=0.001
 ;;
 testnet)
 NODE=""
 DENOM=""
 CHAIN_ID=rebel-2
 WALLET=""
 ADDR_ADMIN=$ADDR_PRISM
 GAS=0.001
 ;;
 mainnet)
NODE="https://terra-classic-rpc.publicnode.com:443"
# NODE="https://terra-rpc.easy2stake.com:443"
# NODE="https://terra.stakesystems.io:2053"
# NODE="https://terra-node.mcontrol.ml"
# NODE="http://public-node.terra.dev:26657"
# NODE="http://172.104.133.249:26657"
# NODE="http://93.66.103.120:26657"
# NODE="https://rpc-terra.synergynodes.com:443/"
 DENOM=uluna
 CHAIN_ID=columbus-5
 WALLET="--from prism"
 ADDR_ADMIN=$ADDR_PRISM
 GAS=0.001
 ;; 
esac

NODECHAIN="--node $NODE --chain-id $CHAIN_ID"
TXFLAG="$NODECHAIN --gas auto --gas-adjustment 1.5 --gas-prices 50uluna --broadcast-mode block --keyring-backend test -y"

RELEASE_DIR="release/"
INFO_DIR="info/"
INFONET_DIR=$INFO_DIR$NETWORK"/"
CODE_DIR=$INFONET_DIR"code/"
ADDRESS_DIR=$INFONET_DIR"address/"
CONTRACT_DIR="contracts/"
LIBRARY_DIR="libraries/"
TEMP_FILE="temp"
[ ! -d $RELEASE_DIR ] && mkdir $RELEASE_DIR
[ ! -d $INFO_DIR ] &&mkdir $INFO_DIR
[ ! -d $INFONET_DIR ] &&mkdir $INFONET_DIR
[ ! -d $CODE_DIR ] &&mkdir $CODE_DIR
[ ! -d $ADDRESS_DIR ] &&mkdir $ADDRESS_DIR

PEXC_FACTORY="terrapexc_factory"
PEXC_PAIR="terrapexc_pair"
PEXC_ROUTER="terrapexc_router"
PEXC_TOKEN="terrapexc_token"
PEXC_TRADING="terrapexc_trading"

CreatePath() {
    export GOROOT=/usr/local/go
    export GOPATH=$HOME/go
    export GO111MODULE=on
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
}

CreateEnv() {
    sudo apt-get update && sudo apt upgrade -y
    sudo apt-get install make build-essential gcc git jq chrony -y
    wget https://golang.org/dl/go1.18.1.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz
    rm -rf go1.18.1.linux-amd64.tar.gz

    export GOROOT=/usr/local/go
    export GOPATH=$HOME/go
    export GO111MODULE=on
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    
    rustup default stable
    rustup target add wasm32-unknown-unknown

    git clone https://github.com/classic-terra/core/
    cd core
    git fetch
    git checkout main
    make install
    cd ../
    rm -rf core
}

RustBuild() {
    echo "================================================="
    echo "Rust Optimize Build Start"
    
    rm -rf target
    
    cd contracts
    
    cd $CATEGORY
    RUSTFLAGS='-C link-arg=-s' cargo wasm
    cd ../../

    cp target/wasm32-unknown-unknown/release/$CATEGORY.wasm release/
}

Upload() {
    echo "================================================="
    echo "Build $RELEASE_DIR$CATEGORY"
    
    cd contracts

    cd $CATEGORY
    RUSTFLAGS='-C link-arg=-s' cargo wasm    
    
    cd ../../
    cp target/wasm32-unknown-unknown/release/$CATEGORY.wasm release/
    sleep 3

    echo "-------------------------------------------------"
    echo "Upload $RELEASE_DIR$CATEGORY"

    # echo "terrad tx wasm store $RELEASE_DIR$CATEGORY".wasm" $WALLET $TXFLAG --output json"
    # JSON=$(terrad tx wasm store $RELEASE_DIR$CATEGORY".wasm" $WALLET $TXFLAG --output json)
    
    # echo $JSON > $INFONET_DIR$TEMP_FILE
    # sleep 2
    # sed -i 's/Invoke codeql //g' $INFONET_DIR$TEMP_FILE
    # sleep 2
    # UPLOADTX=$(cat $INFONET_DIR$TEMP_FILE | jq -r '.txhash')
    # CODE_ID=$(cat $INFONET_DIR$TEMP_FILE | jq -r '.logs[0].events[] | select(.type == "store_code") | .attributes[] | select(.key == "code_id") | .value')

    # echo "Upload txHash: "$UPLOADTX
    # echo "Code ID: "$CODE_ID
    # echo $CODE_ID > $CODE_DIR$CATEGORY

    echo "-------------------------------------------------"
    echo "Upload $RELEASE_DIR$CATEGORY"

    echo "terrad tx wasm store $RELEASE_DIR$CATEGORY".wasm" $WALLET $TXFLAG --output json | jq -r '.txhash'"
    UPLOADTX=$(terrad tx wasm store $RELEASE_DIR$CATEGORY".wasm" $WALLET $TXFLAG --output json | jq -r '.txhash')

    echo "Upload txHash: "$UPLOADTX
    echo "================================================="
    echo "GetCode"
	
    CODE_ID=""
    while [[ $CODE_ID == "" ]]
    do 
        sleep 3
        CODE_ID=$(terrad query tx $UPLOADTX $NODECHAIN --output json | jq -r '.logs[0].events[-1].attributes[1].value')
    done

    echo "Contract Code_id: "$CODE_ID
    #save to FILE_CODE_ID
    echo $CODE_ID > $CODE_DIR$CATEGORY
}

RemoveHistory() {
    rm -rf release
    rm -rf target
    rm -rf info
}

BatchUpload() {
    # CATEGORY=$PEXC_TOKEN
    # printf "y\n" | Upload
    # sleep 3

    CATEGORY=$PEXC_TRADING
    printf "y\n" | Upload
    sleep 3
}

Instantiate() {
    echo "================================================="
    echo "Instantiate Contract "$CATEGORY
    #read from FILE_CODE_ID
    CODE_ID=$(cat $CODE_DIR$CATEGORY)
    echo "Code id: " $CODE_ID

    MSG=$PARAM_1
    LABEL=$PARAM_2
    
    # JSON=$(terrad tx wasm instantiate $CODE_ID "$MSG" --admin $ADDR_ADMIN $WALLET $TXFLAG --output json)

    # echo $JSON > $INFONET_DIR$TEMP_FILE
    # sleep 2
    # sed -i 's/Invoke codeql //g' $INFONET_DIR$TEMP_FILE
    # sleep 2
    # TXHASH=$(cat $INFONET_DIR$TEMP_FILE | jq -r '.txhash')
    # CONTRACT_ADDR=$(cat $INFONET_DIR$TEMP_FILE | jq -r '.logs[0].events[0].attributes[-1].value')

    # echo "Instantiate txHash: "$TXHASH
    # echo "Contract Address: "$CONTRACT_ADDR
    # echo $CONTRACT_ADDR > $ADDRESS_DIR$CATEGORY

    TXHASH=$(terrad tx wasm instantiate $CODE_ID "$MSG" --admin $ADDR_ADMIN $WALLET $TXFLAG --output json | jq -r '.txhash')
    echo $TXHASH
    CONTRACT_ADDR=""
    while [[ $CONTRACT_ADDR == "" ]]
    do
        sleep 3
        CONTRACT_ADDR=$(terrad query tx $TXHASH $NODECHAIN --output json | jq -r '.logs[0].events[0].attributes[-1].value')
    done
    echo "Contract Address: " $CONTRACT_ADDR
    echo $CONTRACT_ADDR > $ADDRESS_DIR$CATEGORY
}

BatchInstantiate() {
    # CATEGORY=$PEXC_TOKEN
    # PARAM_1='{"name":"Test Ustc", "symbol":"TeUST", "decimals":6, "initial_balances":[{"address":"'$ADDR_ADMIN'", "amount":"1000000000000000"}], "mint":{"minter":"'$ADDR_ADMIN'"}, "marketing":{"marketing":"'$ADDR_ADMIN'","logo":{"url":"https://i.ibb.co/RTRwxfs/prism.png"}}}'
    # PARAM_2="TERRA"
    # printf "y\n" | Instantiate

    CATEGORY=$PEXC_TRADING
    PARAM_1='{"pair_list": [  {"from_asset": {"token": {"contract_addr": "'$TEST_TOKEN1'"}}, "to_asset": {"token": {"contract_addr": "'$TEST_TOKEN2'"}} }], "enabled": true}'
    PARAM_2="PEXC Trading"
    printf "y\n" | Instantiate
}

AddNativeTokenDecimal() {
    PARAM_1='{"add_native_token_decimals": {"denom": "uluna", "decimals": 6}}'
    printf "y\n" | terrad tx wasm execute $(cat $ADDRESS_DIR$PEXC_FACTORY) "$PARAM_1" $WALLET $TXFLAG
    sleep 5
    PARAM_1='{"add_native_token_decimals": {"denom": "uusd", "decimals": 6}}'
    printf "y\n" | terrad tx wasm execute $(cat $ADDRESS_DIR$PEXC_FACTORY) "$PARAM_1" $WALLET $TXFLAG
    sleep 5
}

CreatePair1() {
    echo "================================================="
    echo "Start Create Pair"
    PEXCM_1='{"create_pair": {"asset_infos":[{"token":{"contract_addr":"'$(cat $ADDRESS_DIR$PEXC_TOKEN)'"}}, {"native_token":{"denom":"uluna"}}]}}'
    printf "y\n" | terrad tx wasm execute $(cat $ADDRESS_DIR$PEXC_FACTORY) "$PARAM_1" $WALLET $TXFLAG
    sleep 5
    echo "End Create Pair"
}

IncreaseAllowance() {
    echo "================================================="
    echo "Increase Allowance"
    PARAM_1='{"increase_allowance": {"spender": "'$(cat $ADDRESS_DIR$PEXC_TRADING)'", "amount": "10000", "expires": {"never": {}}}}'
    printf "y\n" | terrad tx wasm execute $(cat $ADDRESS_DIR$PEXC_TOKEN) "$PARAM_1" $WALLET $TXFLAG
    sleep 5
    echo "End"
}

Allowance() {
    echo "================================================="
    echo "Allowance"
    PARAM_1='{"allowance": {"owner": "'$ADDR_ADMIN'", "spender": "'$(cat $ADDRESS_DIR$PEXC_PAIR)'"}}'
    printf "y\n" | terrad query wasm contract-store $(cat $ADDRESS_DIR$PEXC_TOKEN) "$PARAM_1" $NODECHAIN --output json
    sleep 5
    echo "End"
}

TokenTransfer() {
    echo "================================================="
    echo "Token Transfer"
    PARAM_1='{"transfer": {"recipient": "terra1skwluh72zg9yh0plwm6hukpz8c3v8c9s846xrg", "amount": "1000000000000"}}'
    printf "y\n" | terrad tx wasm execute $TEST_TOKEN1 "$PARAM_1" $WALLET $TXFLAG
    sleep 5
    echo "End"
}

TokenMint() {
    echo "================================================="
    echo "Token Mint"
    PARAM_1='{"mint": {"recipient": "'$ADDR_ADMIN'", "amount": "1000000"}}'
    printf "y\n" | terrad tx wasm execute $TEST_TOKEN1 "$PARAM_1" $WALLET $TXFLAG
    sleep 5
    echo "End"
}

##############################################
######                PAIR              ######
##############################################

AddLiquidity() {
    echo "================================================="
    echo "Start Add Liquidity"
    PEXCM_1='{"provide_liquidity": {"assets": [{"info": {"token":{"contract_addr":"'$(cat $ADDRESS_DIR$PEXC_TOKEN)'"}}, "amount": "10000"}, {"info": {"native_token":{"denom":"uluna"}}, "amount": "10"}]}}'
    echo "terrad tx wasm execute $(cat $ADDRESS_DIR$PEXC_PAIR) "$PARAM_1" 10uluna $WALLET $TXFLAG"
    printf "y\n" | terrad tx wasm execute $(cat $ADDRESS_DIR$PEXC_PAIR) "$PARAM_1" 10uluna $WALLET $TXFLAG
    sleep 5
    echo "End"
}

RemoveLiquidity() {
    echo "================================================="
    echo "Start Remove Liquidity"
    PARAM_1='{"send": {"contract": "'$(cat $ADDRESS_DIR$PEXC_PAIR)'", amount: "10", msg: {}}}'
    PARAM_2='LP_TOKEN'
    echo "terrad tx wasm execute $(cat $ADDRESS_DIR$PEXC_PAIR) "$PARAM_1" 10uluna $WALLET $TXFLAG"
    printf "y\n" | terrad tx wasm execute $(cat $ADDRESS_DIR$PEXC_PAIR) "$PARAM_1" 10uluna $WALLET $TXFLAG
    sleep 5
    echo "End"
}


#################################################
######                Trading              ######
#################################################
GetConfig() {
    echo "================================================="
    echo "Start"
    PARAM_1='{"config": {}}'
    printf "y\n" | terrad query wasm contract-store $(cat $ADDRESS_DIR$PEXC_TRADING) "$PARAM_1" $NODECHAIN --output json
    sleep 5
    echo "End"
}

BuyOrder() {
    echo "================================================="
    echo "Start"
    PARAM_1='{"order": {"order": {"address": "'$ADDR_PRISM'", "pair_id": "0", "order_stock_amount": "10000000", "current_stock_amount": "10000000", "price": "9000000"}, "is_buy": true, "match_id": "" }}'

    echo "terrad tx wasm execute $(cat $ADDRESS_DIR$PEXC_TRADING) "$PARAM_1" 10uluna $WALLET $TXFLAG"
    printf "y\n" | terrad tx wasm execute $(cat $ADDRESS_DIR$PEXC_TRADING) "$PARAM_1" 10uluna $WALLET $TXFLAG
    sleep 5
    echo "End"
}

SellOrder() {
    echo "================================================="
    echo "Start"
    PARAM_1='{"order": {"order": {"address": "'$ADDR_PRISM'", "pair_id": "0", "order_stock_amount": "5000000", "current_stock_amount": "5000000", "price": "9000000"}, "is_buy": false, "match_id": "1683906783terra13nf0puwmwwx3lp7jg52pverxjpx75fazpxyzch" }}'

    echo "terrad tx wasm execute $(cat $ADDRESS_DIR$PEXC_TRADING) "$PARAM_1" 10uluna $WALLET $TXFLAG"
    printf "y\n" | terrad tx wasm execute $(cat $ADDRESS_DIR$PEXC_TRADING) "$PARAM_1" 10uluna $WALLET $TXFLAG
    sleep 5
    echo "End"
}

GetOrderList() {
    echo "================================================="
    echo "Start"
    PARAM_1='{"list_orders": {"is_buy": true }}'
    printf "y\n" | terrad query wasm contract-store $(cat $ADDRESS_DIR$PEXC_TRADING) "$PARAM_1" $NODECHAIN --output json
    sleep 5
    echo "End"
}

BuyApprove() {
    echo "================================================="
    echo "Increase Allowance"
    PARAM_1='{"increase_allowance": {"spender": "'$(cat $ADDRESS_DIR$PEXC_TRADING)'", "amount": "90000000", "expires": {"never": {}}}}'
    printf "y\n" | terrad tx wasm execute $TEST_TOKEN1 "$PARAM_1" $WALLET $TXFLAG
    sleep 5
    echo "End"
}

SellApprove() {
    echo "================================================="
    echo "Increase Allowance"
    PARAM_1='{"increase_allowance": {"spender": "'$(cat $ADDRESS_DIR$PEXC_TRADING)'", "amount": "5000000", "expires": {"never": {}}}}'
    printf "y\n" | terrad tx wasm execute $TEST_TOKEN2 "$PARAM_1" $WALLET $TXFLAG
    sleep 5
    echo "End"
}

Allowance() {
    echo "================================================="
    echo "Allowance"
    PARAM_1='{"allowance": {"owner": "terra1skwluh72zg9yh0plwm6hukpz8c3v8c9s846xrg", "spender": "'$(cat $ADDRESS_DIR$PEXC_TRADING)'"}}'
    printf "y\n" | terrad query wasm contract-store $TEST_TOKEN2 "$PARAM_1" $NODECHAIN --output json
    sleep 5
    echo "End"
}

TransferNative() {
    echo "================================================="
    echo "Transfer Native"    
    printf "y\n" | terrad tx bank send prism terra1z3td9crpcs7khgu4z9dd3ulefare2yrh72qpmv 1000000uluna $TXFLAG
    sleep 5
    echo "End"
}

#################################### End of Function ###################################################
if [[ $FUNCTION == "" ]]; then
    BatchUpload
    # sleep 3
    # BatchInstantiate
else
    $FUNCTION
fi
