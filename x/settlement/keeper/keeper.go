package keeper

import (
	"fmt"

	settlementtypes "speculod/x/settlement/types"

	"cosmossdk.io/collections"
	"cosmossdk.io/core/address"
	corestore "cosmossdk.io/core/store"
	"github.com/cosmos/cosmos-sdk/codec"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

// Helper to build composite key for (market_id, voter)
func MarketVoterKey(marketId uint64, voter string) string {
	return fmt.Sprintf("%d/%s", marketId, voter)
}

// Keeper struct (add fields for settlement storage)
type Keeper struct {
	storeService corestore.KVStoreService
	cdc          codec.Codec
	addressCodec address.Codec
	// Address capable of executing a MsgUpdateParams message.
	// Typically, this should be the x/gov module account.
	authority []byte

	Schema collections.Schema

	Params   collections.Item[settlementtypes.Params]
	Commits  collections.Map[string, settlementtypes.VoteCommit]
	Reveals  collections.Map[string, settlementtypes.VoteReveal]
	Outcomes collections.Map[uint64, string]
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

		Params:   collections.NewItem(sb, collections.NewPrefix("params"), "params", codec.CollValue[settlementtypes.Params](cdc)),
		Commits:  collections.NewMap(sb, collections.NewPrefix("commits"), "commits", collections.StringKey, codec.CollValue[settlementtypes.VoteCommit](cdc)),
		Reveals:  collections.NewMap(sb, collections.NewPrefix("reveals"), "reveals", collections.StringKey, codec.CollValue[settlementtypes.VoteReveal](cdc)),
		Outcomes: collections.NewMap(sb, collections.NewPrefix("outcomes"), "outcomes", collections.Uint64Key, collections.StringValue),
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

// GetParams returns the current parameters of the settlement module.
func (k Keeper) GetParams(ctx sdk.Context) settlementtypes.Params {
	params, err := k.Params.Get(ctx)
	if err != nil {
		return settlementtypes.DefaultParams()
	}
	return params
}

// SetParams sets the parameters of the settlement module.
func (k Keeper) SetParams(ctx sdk.Context, params settlementtypes.Params) {
	if err := k.Params.Set(ctx, params); err != nil {
		panic(err)
	}
}

// SetCommit stores a vote commit
func (k Keeper) SetCommit(ctx sdk.Context, commit settlementtypes.VoteCommit) {
	key := MarketVoterKey(commit.MarketId, commit.Voter)
	if err := k.Commits.Set(ctx, key, commit); err != nil {
		panic(err)
	}
}

// GetCommit fetches a vote commit
func (k Keeper) GetCommit(ctx sdk.Context, marketId uint64, voter string) (settlementtypes.VoteCommit, bool) {
	key := MarketVoterKey(marketId, voter)
	commit, err := k.Commits.Get(ctx, key)
	if err != nil {
		return settlementtypes.VoteCommit{}, false
	}
	return commit, true
}

// SetReveal stores a vote reveal
func (k Keeper) SetReveal(ctx sdk.Context, reveal settlementtypes.VoteReveal) {
	key := MarketVoterKey(reveal.MarketId, reveal.Voter)
	if err := k.Reveals.Set(ctx, key, reveal); err != nil {
		panic(err)
	}
}

// GetReveal fetches a vote reveal
func (k Keeper) GetReveal(ctx sdk.Context, marketId uint64, voter string) (settlementtypes.VoteReveal, bool) {
	key := MarketVoterKey(marketId, voter)
	reveal, err := k.Reveals.Get(ctx, key)
	if err != nil {
		return settlementtypes.VoteReveal{}, false
	}
	return reveal, true
}

// SetOutcome stores the final outcome for a market
func (k Keeper) SetOutcome(ctx sdk.Context, marketId uint64, outcome string) {
	if err := k.Outcomes.Set(ctx, marketId, outcome); err != nil {
		panic(err)
	}
}

// GetOutcome fetches the final outcome for a market
func (k Keeper) GetOutcome(ctx sdk.Context, marketId uint64) (string, bool) {
	outcome, err := k.Outcomes.Get(ctx, marketId)
	if err != nil {
		return "", false
	}
	return outcome, true
}

// GetAllReveals returns all reveals for a market
func (k Keeper) GetAllReveals(ctx sdk.Context, marketId uint64) []settlementtypes.VoteReveal {
	var reveals []settlementtypes.VoteReveal
	iterator, err := k.Reveals.Iterate(ctx, nil)
	if err != nil {
		return reveals
	}
	defer iterator.Close()
	for ; iterator.Valid(); iterator.Next() {
		key, err := iterator.Key()
		if err != nil {
			continue
		}
		if len(key) > 0 && key[:len(fmt.Sprintf("%d/", marketId))] == fmt.Sprintf("%d/", marketId) {
			val, err := iterator.Value()
			if err == nil {
				reveals = append(reveals, val)
			}
		}
	}
	return reveals
}

// InitGenesis initializes the module's state from a genesis state
func (k Keeper) InitGenesis(ctx sdk.Context, genState settlementtypes.GenesisState) error {
	// Initialize commits
	for _, commit := range genState.Commits {
		k.SetCommit(ctx, commit)
	}

	// Initialize reveals
	for _, reveal := range genState.Reveals {
		k.SetReveal(ctx, reveal)
	}

	// Initialize outcomes
	for _, outcome := range genState.Outcomes {
		k.SetOutcome(ctx, outcome.MarketId, outcome.Outcome)
	}

	return nil
}

// ExportGenesis exports the module's state to a genesis state
func (k Keeper) ExportGenesis(ctx sdk.Context) (*settlementtypes.GenesisState, error) {
	genesis := settlementtypes.DefaultGenesis()

	// Export commits
	commitsIterator, err := k.Commits.Iterate(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer commitsIterator.Close()
	for ; commitsIterator.Valid(); commitsIterator.Next() {
		commit, err := commitsIterator.Value()
		if err == nil {
			genesis.Commits = append(genesis.Commits, commit)
		}
	}

	// Export reveals
	revealsIterator, err := k.Reveals.Iterate(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer revealsIterator.Close()
	for ; revealsIterator.Valid(); revealsIterator.Next() {
		reveal, err := revealsIterator.Value()
		if err == nil {
			genesis.Reveals = append(genesis.Reveals, reveal)
		}
	}

	// Export outcomes
	outcomesIterator, err := k.Outcomes.Iterate(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer outcomesIterator.Close()
	for ; outcomesIterator.Valid(); outcomesIterator.Next() {
		marketId, err := outcomesIterator.Key()
		if err != nil {
			continue
		}
		outcome, err := outcomesIterator.Value()
		if err == nil {
			genesis.Outcomes = append(genesis.Outcomes, settlementtypes.MarketOutcome{
				MarketId: marketId,
				Outcome:  outcome,
			})
		}
	}

	return genesis, nil
}
