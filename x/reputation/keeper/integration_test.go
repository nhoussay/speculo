package keeper_test

import (
	"fmt"
	"testing"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/stretchr/testify/require"

	"speculod/x/reputation/keeper"
	"speculod/x/reputation/types"
)

// Mock keeper for cross-module testing
type MockPredictionKeeper struct {
	markets map[uint64]bool
}

func (m *MockPredictionKeeper) MarketExists(ctx sdk.Context, marketId uint64) bool {
	return m.markets[marketId]
}

type MockSettlementKeeper struct {
	votes map[string]map[string]uint64 // marketId -> user -> outcome
}

func (m *MockSettlementKeeper) GetVote(ctx sdk.Context, marketId string, user string) (uint64, bool) {
	if votes, exists := m.votes[marketId]; exists {
		if vote, userExists := votes[user]; userExists {
			return vote, true
		}
	}
	return 0, false
}

func TestReputationIntegration(t *testing.T) {
	f := initFixture(t)
	ctx := f.ctx

	t.Run("complete reputation lifecycle", func(t *testing.T) {
		// Test user reputation creation and adjustment
		userAddr := "cosmos1useraddress000000000000000000000000000000000000"
		groupId := "test-group"
		authority := f.keeper.GetAuthority()
		authorityStr, _ := f.addressCodec.BytesToString(authority)

		// Initial score should be 0
		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.False(t, found)
		require.Equal(t, "", score)

		// Adjust score positively
		msg := &types.MsgAdjustScore{
			Address:    userAddr,
			GroupId:    groupId,
			Adjustment: 10,
			Authority:  authorityStr,
		}
		msgServer := keeper.NewMsgServerImpl(f.keeper)
		_, err := msgServer.AdjustScore(ctx, msg)
		require.NoError(t, err)

		// Verify score was set
		score, found = f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "10", score)

		// Adjust score negatively
		msg.Adjustment = -3
		_, err = msgServer.AdjustScore(ctx, msg)
		require.NoError(t, err)

		// Verify score was reduced
		score, found = f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "7", score)

		// Test minimum score enforcement
		msg.Adjustment = -10
		_, err = msgServer.AdjustScore(ctx, msg)
		require.NoError(t, err)

		// Verify score doesn't go below 0
		score, found = f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "0", score)
	})

	t.Run("group isolation", func(t *testing.T) {
		userAddr := "cosmos1useraddress000000000000000000000000000000000000"
		group1 := "group-1"
		group2 := "group-2"
		authority := f.keeper.GetAuthority()
		authorityStr, _ := f.addressCodec.BytesToString(authority)

		// Set different scores for same user in different groups
		msg1 := &types.MsgAdjustScore{
			Address:    userAddr,
			GroupId:    group1,
			Adjustment: 5,
			Authority:  authorityStr,
		}
		msg2 := &types.MsgAdjustScore{
			Address:    userAddr,
			GroupId:    group2,
			Adjustment: 10,
			Authority:  authorityStr,
		}

		msgServer := keeper.NewMsgServerImpl(f.keeper)
		_, err := msgServer.AdjustScore(ctx, msg1)
		require.NoError(t, err)
		_, err = msgServer.AdjustScore(ctx, msg2)
		require.NoError(t, err)

		// Verify scores are isolated
		score1, found1 := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, group1)
		score2, found2 := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, group2)

		require.True(t, found1)
		require.True(t, found2)
		require.Equal(t, "5", score1)
		require.Equal(t, "10", score2)
	})

	t.Run("authority validation", func(t *testing.T) {
		userAddr := "cosmos1useraddress000000000000000000000000000000000000"
		groupId := "test-group"
		wrongAuthority := "cosmos1wronga00000000000000000000000000000000000"

		msg := &types.MsgAdjustScore{
			Address:    userAddr,
			GroupId:    groupId,
			Adjustment: 5,
			Authority:  wrongAuthority,
		}

		msgServer := keeper.NewMsgServerImpl(f.keeper)
		_, err := msgServer.AdjustScore(ctx, msg)
		require.Error(t, err)
		require.Contains(t, err.Error(), "invalid authority")
	})

	t.Run("multiple users same group", func(t *testing.T) {
		groupId := "shared-group"
		authority := f.keeper.GetAuthority()
		authorityStr, _ := f.addressCodec.BytesToString(authority)

		users := []string{
			"cosmos1user100000000000000000000000000000000000",
			"cosmos1user200000000000000000000000000000000000",
			"cosmos1user300000000000000000000000000000000000",
		}

		msgServer := keeper.NewMsgServerImpl(f.keeper)

		// Set different scores for each user
		for i, user := range users {
			msg := &types.MsgAdjustScore{
				Address:    user,
				GroupId:    groupId,
				Adjustment: int64(i+1) * 5,
				Authority:  authorityStr,
			}
			_, err := msgServer.AdjustScore(ctx, msg)
			require.NoError(t, err)
		}

		// Verify all scores are stored correctly
		for i, user := range users {
			score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), user, groupId)
			require.True(t, found)
			expectedScore := int64(i+1) * 5
			require.Equal(t, fmt.Sprintf("%d", expectedScore), score)
		}
	})
}

func TestReputationSettlementIntegration(t *testing.T) {
	f := initFixture(t)
	ctx := f.ctx

	// Mock settlement keeper
	mockSettlement := &MockSettlementKeeper{
		votes: make(map[string]map[string]uint64),
	}

	// Setup test scenario
	marketId := "market-1"
	users := []string{
		"cosmos1user100000000000000000000000000000000000",
		"cosmos1user200000000000000000000000000000000000",
		"cosmos1user300000000000000000000000000000000000",
	}
	groupId := "test-group"
	authority := f.keeper.GetAuthority()
	authorityStr, _ := f.addressCodec.BytesToString(authority)

	// Initialize reputation scores
	msgServer := keeper.NewMsgServerImpl(f.keeper)
	for i, user := range users {
		msg := &types.MsgAdjustScore{
			Address:    user,
			GroupId:    groupId,
			Adjustment: int64(i+1) * 10, // 10, 20, 30
			Authority:  authorityStr,
		}
		_, err := msgServer.AdjustScore(ctx, msg)
		require.NoError(t, err)
	}

	// Setup votes (user1 votes 0, user2 votes 1, user3 votes 0)
	mockSettlement.votes[marketId] = map[string]uint64{
		users[0]: 0,
		users[1]: 1,
		users[2]: 0,
	}

	// Simulate consensus outcome (outcome 0 wins)
	consensusOutcome := uint64(0)

	// Calculate reputation-weighted votes
	totalWeight := int64(0)
	consensusWeight := int64(0)

	for _, user := range users {
		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), user, groupId)
		require.True(t, found)

		// Parse score to int64
		var scoreInt int64
		_, err := fmt.Sscanf(score, "%d", &scoreInt)
		require.NoError(t, err)

		vote, _ := mockSettlement.GetVote(ctx.(sdk.Context), marketId, user)

		totalWeight += scoreInt
		if vote == consensusOutcome {
			consensusWeight += scoreInt
		}
	}

	// Verify reputation-weighted voting
	require.Equal(t, int64(60), totalWeight)     // 10 + 20 + 30
	require.Equal(t, int64(40), consensusWeight) // 10 + 30 (users who voted for consensus)

	// Simulate reputation adjustments based on voting accuracy
	for _, user := range users {
		vote, _ := mockSettlement.GetVote(ctx.(sdk.Context), marketId, user)

		var adjustment int64
		if vote == consensusOutcome {
			adjustment = 1 // Reward for voting with consensus
		} else {
			adjustment = -1 // Penalty for voting against consensus
		}

		msg := &types.MsgAdjustScore{
			Address:    user,
			GroupId:    groupId,
			Adjustment: adjustment,
			Authority:  authorityStr,
		}
		_, err := msgServer.AdjustScore(ctx, msg)
		require.NoError(t, err)
	}

	// Verify final scores
	expectedScores := []string{"11", "19", "31"} // +1, -1, +1
	for i, user := range users {
		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), user, groupId)
		require.True(t, found)
		require.Equal(t, expectedScores[i], score)
	}
}

func TestReputationPredictionIntegration(t *testing.T) {
	f := initFixture(t)
	ctx := f.ctx

	// Mock prediction keeper
	mockPrediction := &MockPredictionKeeper{
		markets: map[uint64]bool{
			1: true,
			2: true,
			3: false, // non-existent market
		},
	}

	// Test market existence validation
	require.True(t, mockPrediction.MarketExists(ctx.(sdk.Context), 1))
	require.True(t, mockPrediction.MarketExists(ctx.(sdk.Context), 2))
	require.False(t, mockPrediction.MarketExists(ctx.(sdk.Context), 3))

	// Test reputation-based market access
	userAddr := "cosmos1useraddress000000000000000000000000000000000000"
	groupId := "test-group"
	authority := f.keeper.GetAuthority()
	authorityStr, _ := f.addressCodec.BytesToString(authority)

	// Set initial reputation
	msg := &types.MsgAdjustScore{
		Address:    userAddr,
		GroupId:    groupId,
		Adjustment: 50,
		Authority:  authorityStr,
	}
	msgServer := keeper.NewMsgServerImpl(f.keeper)
	_, err := msgServer.AdjustScore(ctx, msg)
	require.NoError(t, err)

	// Verify reputation can be used for market access control
	score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
	require.True(t, found)
	require.Equal(t, "50", score)

	// Simulate reputation-based fee calculation
	var scoreInt int64
	_, err = fmt.Sscanf(score, "%d", &scoreInt)
	require.NoError(t, err)

	// Higher reputation = lower fees
	baseFee := int64(100)
	reputationDiscount := scoreInt / 10 // 5% discount
	actualFee := baseFee - reputationDiscount
	require.Equal(t, int64(95), actualFee)
}

func TestStressReputationOperations(t *testing.T) {
	f := initFixture(t)
	ctx := f.ctx

	authority := f.keeper.GetAuthority()
	authorityStr, _ := f.addressCodec.BytesToString(authority)
	msgServer := keeper.NewMsgServerImpl(f.keeper)

	t.Run("concurrent score adjustments", func(t *testing.T) {
		userAddr := "cosmos1stress000000000000000000000000000000000000"
		groupId := "stress-group"

		// Perform many rapid adjustments
		for i := 0; i < 100; i++ {
			msg := &types.MsgAdjustScore{
				Address:    userAddr,
				GroupId:    groupId,
				Adjustment: 1,
				Authority:  authorityStr,
			}
			_, err := msgServer.AdjustScore(ctx, msg)
			require.NoError(t, err)
		}

		// Verify final score
		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "100", score)
	})

	t.Run("multiple groups stress test", func(t *testing.T) {
		userAddr := "cosmos1multigroup000000000000000000000000000000000"

		// Create many groups and set scores
		for i := 0; i < 50; i++ {
			groupId := fmt.Sprintf("stress-group-%d", i)
			msg := &types.MsgAdjustScore{
				Address:    userAddr,
				GroupId:    groupId,
				Adjustment: int64(i + 1),
				Authority:  authorityStr,
			}
			_, err := msgServer.AdjustScore(ctx, msg)
			require.NoError(t, err)
		}

		// Verify all scores are stored correctly
		for i := 0; i < 50; i++ {
			groupId := fmt.Sprintf("stress-group-%d", i)
			score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
			require.True(t, found)
			expectedScore := fmt.Sprintf("%d", i+1)
			require.Equal(t, expectedScore, score)
		}
	})
}

func TestReputationEdgeCases(t *testing.T) {
	f := initFixture(t)
	ctx := f.ctx

	authority := f.keeper.GetAuthority()
	authorityStr, _ := f.addressCodec.BytesToString(authority)
	msgServer := keeper.NewMsgServerImpl(f.keeper)

	t.Run("zero adjustment", func(t *testing.T) {
		userAddr := "cosmos1zero000000000000000000000000000000000000"
		groupId := "test-group"

		// Set initial score
		msg := &types.MsgAdjustScore{
			Address:    userAddr,
			GroupId:    groupId,
			Adjustment: 10,
			Authority:  authorityStr,
		}
		_, err := msgServer.AdjustScore(ctx, msg)
		require.NoError(t, err)

		// Zero adjustment should not change score
		msg.Adjustment = 0
		_, err = msgServer.AdjustScore(ctx, msg)
		require.NoError(t, err)

		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "10", score)
	})

	t.Run("large score values", func(t *testing.T) {
		userAddr := "cosmos1large000000000000000000000000000000000000"
		groupId := "test-group"

		// Test with large positive value
		msg := &types.MsgAdjustScore{
			Address:    userAddr,
			GroupId:    groupId,
			Adjustment: 1000000,
			Authority:  authorityStr,
		}
		_, err := msgServer.AdjustScore(ctx, msg)
		require.NoError(t, err)

		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "1000000", score)

		// Test with large negative value
		msg.Adjustment = -999999
		_, err = msgServer.AdjustScore(ctx, msg)
		require.NoError(t, err)

		score, found = f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "1", score)
	})

	t.Run("empty group id", func(t *testing.T) {
		userAddr := "cosmos1empty000000000000000000000000000000000000"
		groupId := ""

		msg := &types.MsgAdjustScore{
			Address:    userAddr,
			GroupId:    groupId,
			Adjustment: 5,
			Authority:  authorityStr,
		}
		_, err := msgServer.AdjustScore(ctx, msg)
		require.NoError(t, err)

		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "5", score)
	})
}
