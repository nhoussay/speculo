package keeper

import (
	"speculod/x/prediction/types"
	settlementtypes "speculod/x/settlement/types"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// MockPredictionKeeper implements PredictionKeeper interface for testing
type MockPredictionKeeper struct{}

func (m MockPredictionKeeper) GetPredictionMarket(ctx sdk.Context, marketId uint64) (types.PredictionMarket, bool) {
	// Mock implementation - return a PredictionMarket struct
	return types.PredictionMarket{
		Id:       marketId,
		Deadline: 0, // No deadline for testing
		Outcomes: []string{"Yes", "No"},
		GroupId:  "test-group",
		Question: "Test question",
		Status:   "active",
		Creator:  "test-creator",
	}, true
}

func (m MockPredictionKeeper) ValidateOutcome(outcomes []string, vote string) error {
	for _, outcome := range outcomes {
		if outcome == vote {
			return nil
		}
	}
	return settlementtypes.ErrInvalidVote
}

// MockReputationKeeper implements ReputationKeeper interface for testing
type MockReputationKeeper struct{}

func (m MockReputationKeeper) GetReputationScore(ctx sdk.Context, address string, groupId string) (string, bool) {
	// Mock implementation - return default score of "10"
	return "10", true
}

func (m MockReputationKeeper) AdjustReputationScore(ctx sdk.Context, address string, groupId string, adjustment int64) error {
	// Mock implementation - just log the adjustment
	ctx.Logger().Info("Mock reputation adjustment", "address", address, "groupId", groupId, "adjustment", adjustment)
	return nil
}
