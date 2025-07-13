package types

import (
	"fmt"
	"strings"

	errorsmod "cosmossdk.io/errors"
	"github.com/cosmos/cosmos-sdk/codec"
	"github.com/cosmos/cosmos-sdk/types/address"
)

var (
	ErrInvalidRequest = errorsmod.Register(ModuleName, 1, "invalid request")
)

// PositionKey builds a unique key for a user position in a market
func PositionKey(marketID uint64, user string) []byte {
	return append([]byte("position/"), address.MustLengthPrefix([]byte(fmt.Sprintf("%d/%s", marketID, user)))...)
}

// OutcomeResult stores the final resolved outcome of a prediction market
type OutcomeResult struct {
	MarketId     uint64 `json:"market_id" yaml:"market_id"`
	WinningIndex uint32 `json:"winning_index" yaml:"winning_index"`
}

func ValidateOutcome(outcomes []string, vote string) error {
	for _, o := range outcomes {
		if strings.EqualFold(o, vote) {
			return nil
		}
	}
	return errorsmod.Wrapf(ErrInvalidRequest, "invalid vote: %s not in outcomes", vote)
}

// RegisterLegacyAminoCodec registers the legacy amino codec
func RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	// Nothing needed for now
}
