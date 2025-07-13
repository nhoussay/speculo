package types

import (
	"context"
	"speculod/x/prediction/types"

	"cosmossdk.io/core/address"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

// AuthKeeper defines the expected interface for the Auth module.
type AuthKeeper interface {
	AddressCodec() address.Codec
	GetAccount(context.Context, sdk.AccAddress) sdk.AccountI // only used for simulation
	// Methods imported from account should be defined here
}

// BankKeeper defines the expected interface for the Bank module.
type BankKeeper interface {
	SpendableCoins(context.Context, sdk.AccAddress) sdk.Coins
	// Methods imported from bank should be defined here
}

// PredictionKeeper defines the expected interface for the Prediction module.
type PredictionKeeper interface {
	GetPredictionMarket(ctx sdk.Context, marketId uint64) (types.PredictionMarket, bool)
	ValidateOutcome(outcomes []string, vote string) error
}

// ReputationKeeper defines the expected interface for the Reputation module.
type ReputationKeeper interface {
	GetReputationScore(ctx sdk.Context, address string, groupId string) (string, bool)
	AdjustReputationScore(ctx sdk.Context, address string, groupId string, adjustment int64) error
}

// ParamSubspace defines the expected Subspace interface for parameters.
type ParamSubspace interface {
	Get(context.Context, []byte, interface{})
	Set(context.Context, []byte, interface{})
}
