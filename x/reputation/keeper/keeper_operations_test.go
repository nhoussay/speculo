package keeper_test

import (
	"fmt"
	"testing"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/stretchr/testify/require"
)

func TestKeeperOperations(t *testing.T) {
	f := initFixture(t)
	ctx := f.ctx

	t.Run("score storage and retrieval", func(t *testing.T) {
		userAddr := "cosmos1keeper000000000000000000000000000000000000"
		groupId := "test-group"
		score := "42"

		// Test setting score
		f.keeper.SetReputationScore(ctx.(sdk.Context), userAddr, groupId, score)

		// Test retrieving score
		retrievedScore, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, score, retrievedScore)

		// Test non-existent score
		_, found = f.keeper.GetReputationScore(ctx.(sdk.Context), "nonexistent", groupId)
		require.False(t, found)
	})

	t.Run("score adjustment", func(t *testing.T) {
		userAddr := "cosmos1adjust000000000000000000000000000000000000"
		groupId := "test-group"

		// Test positive adjustment
		err := f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, 10)
		require.NoError(t, err)

		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "10", score)

		// Test negative adjustment
		err = f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, -3)
		require.NoError(t, err)

		score, found = f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "7", score)

		// Test adjustment below zero
		err = f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, -10)
		require.NoError(t, err)

		score, found = f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "0", score)
	})

	t.Run("authority operations", func(t *testing.T) {
		authority := f.keeper.GetAuthority()
		require.NotNil(t, authority)

		// Test authority string conversion
		authorityStr, err := f.addressCodec.BytesToString(authority)
		require.NoError(t, err)
		require.NotEmpty(t, authorityStr)
	})

	t.Run("multiple score operations", func(t *testing.T) {
		users := []string{
			"cosmos1multi100000000000000000000000000000000000",
			"cosmos1multi200000000000000000000000000000000000",
			"cosmos1multi300000000000000000000000000000000000",
		}
		groupId := "multi-group"

		// Set different scores for each user
		for i, user := range users {
			score := int64(i+1) * 5
			err := f.keeper.AdjustReputationScore(ctx.(sdk.Context), user, groupId, score)
			require.NoError(t, err)
		}

		// Verify all scores
		for i, user := range users {
			score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), user, groupId)
			require.True(t, found)
			expectedScore := int64(i+1) * 5
			require.Equal(t, fmt.Sprintf("%d", expectedScore), score)
		}
	})

	t.Run("group isolation operations", func(t *testing.T) {
		userAddr := "cosmos1group000000000000000000000000000000000000"
		group1 := "group-1"
		group2 := "group-2"

		// Set scores in different groups
		err := f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, group1, 15)
		require.NoError(t, err)
		err = f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, group2, 25)
		require.NoError(t, err)

		// Verify scores are isolated
		score1, found1 := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, group1)
		score2, found2 := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, group2)

		require.True(t, found1)
		require.True(t, found2)
		require.Equal(t, "15", score1)
		require.Equal(t, "25", score2)
	})

	t.Run("large score operations", func(t *testing.T) {
		userAddr := "cosmos1large000000000000000000000000000000000000"
		groupId := "test-group"

		// Test with large positive value
		err := f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, 1000000)
		require.NoError(t, err)

		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "1000000", score)

		// Test with large negative value
		err = f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, -999999)
		require.NoError(t, err)

		score, found = f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "1", score)
	})

	t.Run("zero score operations", func(t *testing.T) {
		userAddr := "cosmos1zero000000000000000000000000000000000000"
		groupId := "test-group"

		// Set initial score
		err := f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, 10)
		require.NoError(t, err)

		// Zero adjustment should not change score
		err = f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, 0)
		require.NoError(t, err)

		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "10", score)
	})

	t.Run("empty group operations", func(t *testing.T) {
		userAddr := "cosmos1empty000000000000000000000000000000000000"
		groupId := ""

		err := f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, 5)
		require.NoError(t, err)

		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "5", score)
	})
}

func TestScoreValidation(t *testing.T) {
	f := initFixture(t)
	ctx := f.ctx

	t.Run("minimum score enforcement", func(t *testing.T) {
		userAddr := "cosmos1min000000000000000000000000000000000000"
		groupId := "test-group"

		// Start with positive score
		err := f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, 10)
		require.NoError(t, err)

		// Try to reduce below zero
		err = f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, -15)
		require.NoError(t, err)

		// Verify score is clamped to zero
		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "0", score)
	})

	t.Run("score precision", func(t *testing.T) {
		userAddr := "cosmos1prec000000000000000000000000000000000000"
		groupId := "test-group"

		// Test with various score values
		testScores := []int64{0, 1, 10, 100, 1000, 10000, 100000}

		for _, testScore := range testScores {
			err := f.keeper.SetReputationScore(ctx.(sdk.Context), userAddr, groupId, fmt.Sprintf("%d", testScore))
			require.NoError(t, err)

			score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
			require.True(t, found)
			require.Equal(t, fmt.Sprintf("%d", testScore), score)
		}
	})
}

func TestReputationWeighting(t *testing.T) {
	f := initFixture(t)
	ctx := f.ctx

	t.Run("weighted voting simulation", func(t *testing.T) {
		users := []string{
			"cosmos1weight100000000000000000000000000000000000",
			"cosmos1weight200000000000000000000000000000000000",
			"cosmos1weight300000000000000000000000000000000000",
		}
		groupId := "weight-group"

		// Set different reputation scores
		scores := []int64{10, 20, 30}
		for i, user := range users {
			err := f.keeper.AdjustReputationScore(ctx.(sdk.Context), user, groupId, scores[i])
			require.NoError(t, err)
		}

		// Simulate weighted voting
		totalWeight := int64(0)
		for _, user := range users {
			score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), user, groupId)
			require.True(t, found)

			var scoreInt int64
			_, err := fmt.Sscanf(score, "%d", &scoreInt)
			require.NoError(t, err)

			totalWeight += scoreInt
		}

		require.Equal(t, int64(60), totalWeight) // 10 + 20 + 30
	})

	t.Run("consensus alignment", func(t *testing.T) {
		userAddr := "cosmos1consensus000000000000000000000000000000000000"
		groupId := "consensus-group"

		// Set initial score
		err := f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, 50)
		require.NoError(t, err)

		// Simulate voting with consensus (reward)
		err = f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, 1)
		require.NoError(t, err)

		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "51", score)

		// Simulate voting against consensus (penalty)
		err = f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, -1)
		require.NoError(t, err)

		score, found = f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "50", score)
	})
}

func TestPenaltySystem(t *testing.T) {
	f := initFixture(t)
	ctx := f.ctx

	t.Run("penalty for wrong votes", func(t *testing.T) {
		userAddr := "cosmos1penalty000000000000000000000000000000000000"
		groupId := "penalty-group"

		// Set initial score
		err := f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, 20)
		require.NoError(t, err)

		// Apply penalty for wrong vote
		err = f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, -1)
		require.NoError(t, err)

		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "19", score)
	})

	t.Run("penalty below zero protection", func(t *testing.T) {
		userAddr := "cosmos1penaltyzero000000000000000000000000000000000000"
		groupId := "penalty-group"

		// Set low score
		err := f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, 1)
		require.NoError(t, err)

		// Apply penalty that would go below zero
		err = f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, -5)
		require.NoError(t, err)

		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "0", score)
	})
}

func TestScoreRetrieval(t *testing.T) {
	f := initFixture(t)
	ctx := f.ctx

	t.Run("score retrieval for non-existent user", func(t *testing.T) {
		userAddr := "cosmos1nonexistent000000000000000000000000000000000000"
		groupId := "test-group"

		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.False(t, found)
		require.Equal(t, "", score)
	})

	t.Run("score retrieval for non-existent group", func(t *testing.T) {
		userAddr := "cosmos1user000000000000000000000000000000000000"
		groupId := "non-existent-group"

		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.False(t, found)
		require.Equal(t, "", score)
	})

	t.Run("score retrieval after deletion", func(t *testing.T) {
		userAddr := "cosmos1delete000000000000000000000000000000000000"
		groupId := "test-group"

		// Set score
		err := f.keeper.AdjustReputationScore(ctx.(sdk.Context), userAddr, groupId, 10)
		require.NoError(t, err)

		// Verify score exists
		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "10", score)

		// Set score to zero (effectively delete)
		err = f.keeper.SetReputationScore(ctx.(sdk.Context), userAddr, groupId, "0")
		require.NoError(t, err)

		// Verify score is zero
		score, found = f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, "0", score)
	})
}

func TestScoreStorage(t *testing.T) {
	f := initFixture(t)
	ctx := f.ctx

	t.Run("score storage persistence", func(t *testing.T) {
		userAddr := "cosmos1persist000000000000000000000000000000000000"
		groupId := "test-group"
		score := "42"

		// Store score
		f.keeper.SetReputationScore(ctx.(sdk.Context), userAddr, groupId, score)

		// Retrieve score
		retrievedScore, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, score, retrievedScore)

		// Update score
		newScore := "100"
		f.keeper.SetReputationScore(ctx.(sdk.Context), userAddr, groupId, newScore)

		// Verify updated score
		retrievedScore, found = f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		require.True(t, found)
		require.Equal(t, newScore, retrievedScore)
	})

	t.Run("multiple score storage", func(t *testing.T) {
		users := []string{
			"cosmos1multi100000000000000000000000000000000000",
			"cosmos1multi200000000000000000000000000000000000",
			"cosmos1multi300000000000000000000000000000000000",
		}
		groupId := "multi-group"

		// Store scores for multiple users
		for i, user := range users {
			score := fmt.Sprintf("%d", (i+1)*10)
			f.keeper.SetReputationScore(ctx.(sdk.Context), user, groupId, score)
		}

		// Verify all scores are stored correctly
		for i, user := range users {
			expectedScore := fmt.Sprintf("%d", (i+1)*10)
			score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), user, groupId)
			require.True(t, found)
			require.Equal(t, expectedScore, score)
		}
	})
}
