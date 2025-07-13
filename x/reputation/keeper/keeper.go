package keeper

import (
	"fmt"
	"strconv"

	"cosmossdk.io/collections"
	"cosmossdk.io/core/address"
	corestore "cosmossdk.io/core/store"
	"github.com/cosmos/cosmos-sdk/codec"
	sdk "github.com/cosmos/cosmos-sdk/types"

	"speculod/x/reputation/types"
)

type Keeper struct {
	storeService corestore.KVStoreService
	cdc          codec.Codec
	addressCodec address.Codec
	// Address capable of executing a MsgUpdateParams message.
	// Typically, this should be the x/gov module account.
	authority []byte

	Schema collections.Schema
	Params collections.Item[types.Params]

	// Reputation score storage
	ReputationScores collections.Map[string, types.ReputationScore]
}

func NewKeeper(
	storeService corestore.KVStoreService,
	cdc codec.Codec,
	addressCodec address.Codec,
	authority []byte,

) Keeper {
	if _, err := addressCodec.BytesToString(authority); err != nil {
		panic(fmt.Sprintf("invalid authority address %s: %s", authority, err))
	}

	sb := collections.NewSchemaBuilder(storeService)

	k := Keeper{
		storeService: storeService,
		cdc:          cdc,
		addressCodec: addressCodec,
		authority:    authority,

		Params:           collections.NewItem(sb, types.ParamsKey, "params", codec.CollValue[types.Params](cdc)),
		ReputationScores: collections.NewMap(sb, collections.NewPrefix("reputation_scores"), "reputation_scores", collections.StringKey, codec.CollValue[types.ReputationScore](cdc)),
	}

	schema, err := sb.Build()
	if err != nil {
		panic(err)
	}
	k.Schema = schema

	return k
}

// GetAuthority returns the module's authority.
func (k Keeper) GetAuthority() []byte {
	return k.authority
}

// GetReputationScore retrieves a reputation score for a user in a specific group
func (k Keeper) GetReputationScore(ctx sdk.Context, address string, groupId string) (string, bool) {
	key := fmt.Sprintf("%s:%s", address, groupId)
	score, err := k.ReputationScores.Get(ctx, key)
	if err != nil {
		return "0", false
	}
	return score.Score, true
}

// SetReputationScore stores a reputation score for a user in a specific group
func (k Keeper) SetReputationScore(ctx sdk.Context, address string, groupId string, score string) error {
	key := fmt.Sprintf("%s:%s", address, groupId)
	reputationScore := types.ReputationScore{
		Address: address,
		Score:   score,
		GroupId: groupId,
	}
	return k.ReputationScores.Set(ctx, key, reputationScore)
}

// AdjustReputationScore adjusts a user's reputation score in a specific group
func (k Keeper) AdjustReputationScore(ctx sdk.Context, address string, groupId string, adjustment int64) error {
	currentScoreStr, found := k.GetReputationScore(ctx, address, groupId)

	var currentScore int64
	if found {
		var err error
		currentScore, err = strconv.ParseInt(currentScoreStr, 10, 64)
		if err != nil {
			return fmt.Errorf("failed to parse current score: %w", err)
		}
	}

	newScore := currentScore + adjustment
	if newScore < 0 {
		newScore = 0 // Don't allow negative scores
	}

	newScoreStr := strconv.FormatInt(newScore, 10)
	return k.SetReputationScore(ctx, address, groupId, newScoreStr)
}
