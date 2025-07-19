package app

import (
	"encoding/json"

	"github.com/cosmos/cosmos-sdk/codec"
	bankexported "github.com/cosmos/cosmos-sdk/x/bank/exported"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
	genutiltypes "github.com/cosmos/cosmos-sdk/x/genutil/types"
)

// GenesisBalancesIterator implements the genutil GenesisBalancesIterator interface.
type GenesisBalancesIterator struct{}

// This assertion must be at the top level, outside any function.
var _ genutiltypes.GenesisBalancesIterator = GenesisBalancesIterator{}

// IterateGenesisBalances implements the required interface method.

func (GenesisBalancesIterator) IterateGenesisBalances(
	cdc codec.JSONCodec,
	appGenesis map[string]json.RawMessage,
	cb func(balance bankexported.GenesisBalance) (stop bool),
) {
	bankGenesisRaw, ok := appGenesis["bank"]
	if !ok {
		return
	}

	var bankGenesis banktypes.GenesisState
	if err := cdc.UnmarshalJSON(bankGenesisRaw, &bankGenesis); err != nil {
		return
	}

	for _, balance := range bankGenesis.Balances {
		if cb(balance) {
			break
		}
	}
}
