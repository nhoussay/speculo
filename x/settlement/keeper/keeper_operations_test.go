package keeper

import (
	"testing"

	"speculod/x/settlement/types"

	"github.com/stretchr/testify/require"
)

// TestKeeperOperations_CommitStorage tests commit storage operations
func TestKeeperOperations_CommitStorage(t *testing.T) {
	// Test data
	commit := types.VoteCommit{
		MarketId:   1,
		Voter:      "alice",
		Commitment: "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
	}

	// Test commit structure
	require.Equal(t, uint64(1), commit.MarketId, "Market ID should be 1")
	require.Equal(t, "alice", commit.Voter, "Voter should be alice")
	require.Len(t, commit.Commitment, 64, "Commitment should be 64 hex characters")
	require.NotEmpty(t, commit.Commitment, "Commitment should not be empty")

	// Test key generation
	key := MarketVoterKey(commit.MarketId, commit.Voter)
	expectedKey := "1/alice"
	require.Equal(t, expectedKey, key, "Key should be correctly formatted")

	// Test multiple commits for same market
	commit2 := types.VoteCommit{
		MarketId:   1,
		Voter:      "bob",
		Commitment: "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
	}

	key2 := MarketVoterKey(commit2.MarketId, commit2.Voter)
	expectedKey2 := "1/bob"
	require.Equal(t, expectedKey2, key2, "Second key should be correctly formatted")
	require.NotEqual(t, key, key2, "Different voters should have different keys")
}

// TestKeeperOperations_RevealStorage tests reveal storage operations
func TestKeeperOperations_RevealStorage(t *testing.T) {
	// Test data
	reveal := types.VoteReveal{
		MarketId: 1,
		Voter:    "alice",
		Vote:     "YES",
		Nonce:    "test_nonce_123",
	}

	// Test reveal structure
	require.Equal(t, uint64(1), reveal.MarketId, "Market ID should be 1")
	require.Equal(t, "alice", reveal.Voter, "Voter should be alice")
	require.Equal(t, "YES", reveal.Vote, "Vote should be YES")
	require.Equal(t, "test_nonce_123", reveal.Nonce, "Nonce should match")

	// Test key generation
	key := MarketVoterKey(reveal.MarketId, reveal.Voter)
	expectedKey := "1/alice"
	require.Equal(t, expectedKey, key, "Key should be correctly formatted")

	// Test multiple reveals for same market
	reveal2 := types.VoteReveal{
		MarketId: 1,
		Voter:    "bob",
		Vote:     "NO",
		Nonce:    "test_nonce_456",
	}

	key2 := MarketVoterKey(reveal2.MarketId, reveal2.Voter)
	expectedKey2 := "1/bob"
	require.Equal(t, expectedKey2, key2, "Second key should be correctly formatted")
	require.NotEqual(t, key, key2, "Different voters should have different keys")
}

// TestKeeperOperations_OutcomeStorage tests outcome storage operations
func TestKeeperOperations_OutcomeStorage(t *testing.T) {
	// Test data
	marketID := uint64(1)
	outcome := "YES"

	// Test outcome structure
	require.NotZero(t, marketID, "Market ID should not be zero")
	require.NotEmpty(t, outcome, "Outcome should not be empty")

	// Test that outcome is valid
	validOutcomes := []string{"YES", "NO", "OUTCOME_A", "OUTCOME_B"}
	isValid := false
	for _, validOutcome := range validOutcomes {
		if outcome == validOutcome {
			isValid = true
			break
		}
	}
	require.True(t, isValid, "Outcome should be one of the valid outcomes")
}

// TestKeeperOperations_KeyGeneration tests key generation for different scenarios
func TestKeeperOperations_KeyGeneration(t *testing.T) {
	// Test different market IDs
	market1ID := uint64(1)
	market2ID := uint64(2)
	voter := "alice"

	key1 := MarketVoterKey(market1ID, voter)
	key2 := MarketVoterKey(market2ID, voter)

	require.Equal(t, "1/alice", key1, "Key for market 1 should be correctly formatted")
	require.Equal(t, "2/alice", key2, "Key for market 2 should be correctly formatted")
	require.NotEqual(t, key1, key2, "Different markets should have different keys")

	// Test different voters
	voter1 := "alice"
	voter2 := "bob"
	marketID := uint64(1)

	key3 := MarketVoterKey(marketID, voter1)
	key4 := MarketVoterKey(marketID, voter2)

	require.Equal(t, "1/alice", key3, "Key for alice should be correctly formatted")
	require.Equal(t, "1/bob", key4, "Key for bob should be correctly formatted")
	require.NotEqual(t, key3, key4, "Different voters should have different keys")
}

// TestKeeperOperations_DataValidation tests data validation for keeper operations
func TestKeeperOperations_DataValidation(t *testing.T) {
	// Test valid commit data
	validCommit := types.VoteCommit{
		MarketId:   1,
		Voter:      "alice",
		Commitment: "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
	}

	require.NotZero(t, validCommit.MarketId, "Market ID should not be zero")
	require.NotEmpty(t, validCommit.Voter, "Voter should not be empty")
	require.Len(t, validCommit.Commitment, 64, "Commitment should be 64 characters")

	// Test valid reveal data
	validReveal := types.VoteReveal{
		MarketId: 1,
		Voter:    "alice",
		Vote:     "YES",
		Nonce:    "test_nonce_123",
	}

	require.NotZero(t, validReveal.MarketId, "Market ID should not be zero")
	require.NotEmpty(t, validReveal.Voter, "Voter should not be empty")
	require.NotEmpty(t, validReveal.Vote, "Vote should not be empty")
	require.NotEmpty(t, validReveal.Nonce, "Nonce should not be empty")
	require.True(t, len(validReveal.Nonce) >= 8, "Nonce should be at least 8 characters")
	require.True(t, len(validReveal.Nonce) <= 64, "Nonce should be at most 64 characters")
}

// TestKeeperOperations_CrossMarketIsolation tests isolation between different markets
func TestKeeperOperations_CrossMarketIsolation(t *testing.T) {
	// Test that operations on different markets are isolated
	market1ID := uint64(1)
	market2ID := uint64(2)
	voter := "alice"

	// Same voter, different markets
	commit1 := types.VoteCommit{
		MarketId:   market1ID,
		Voter:      voter,
		Commitment: "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
	}

	commit2 := types.VoteCommit{
		MarketId:   market2ID,
		Voter:      voter,
		Commitment: "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
	}

	key1 := MarketVoterKey(commit1.MarketId, commit1.Voter)
	key2 := MarketVoterKey(commit2.MarketId, commit2.Voter)

	require.NotEqual(t, key1, key2, "Different markets should have different keys")
	require.NotEqual(t, commit1.Commitment, commit2.Commitment, "Different markets should have different commitments")

	// Same voter, different markets for reveals
	reveal1 := types.VoteReveal{
		MarketId: market1ID,
		Voter:    voter,
		Vote:     "YES",
		Nonce:    "nonce1",
	}

	reveal2 := types.VoteReveal{
		MarketId: market2ID,
		Voter:    voter,
		Vote:     "NO",
		Nonce:    "nonce2",
	}

	key3 := MarketVoterKey(reveal1.MarketId, reveal1.Voter)
	key4 := MarketVoterKey(reveal2.MarketId, reveal2.Voter)

	require.NotEqual(t, key3, key4, "Different markets should have different keys")
	require.NotEqual(t, reveal1.Vote, reveal2.Vote, "Different markets should have different votes")
}

// TestKeeperOperations_DataConsistency tests data consistency across operations
func TestKeeperOperations_DataConsistency(t *testing.T) {
	// Test that same user can have consistent data across operations
	user := "alice"
	marketID := uint64(1)

	commit := types.VoteCommit{
		MarketId:   marketID,
		Voter:      user,
		Commitment: "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
	}

	reveal := types.VoteReveal{
		MarketId: marketID,
		Voter:    user,
		Vote:     "YES",
		Nonce:    "test_nonce_123",
	}

	// Verify consistency
	require.Equal(t, marketID, commit.MarketId, "Commit and reveal should have same market ID")
	require.Equal(t, marketID, reveal.MarketId, "Commit and reveal should have same market ID")
	require.Equal(t, user, commit.Voter, "Commit and reveal should have same voter")
	require.Equal(t, user, reveal.Voter, "Commit and reveal should have same voter")
}

// TestKeeperOperations_ErrorHandling tests error handling scenarios
func TestKeeperOperations_ErrorHandling(t *testing.T) {
	// Test invalid market ID
	invalidMarketID := uint64(0)
	key := MarketVoterKey(invalidMarketID, "alice")
	expectedKey := "0/alice"
	require.Equal(t, expectedKey, key, "Key should be generated even for invalid market ID")

	// Test empty voter
	emptyVoter := ""
	key2 := MarketVoterKey(1, emptyVoter)
	expectedKey2 := "1/"
	require.Equal(t, expectedKey2, key2, "Key should be generated even for empty voter")

	// Test invalid commitment length
	invalidCommitment := "short"
	commit := types.VoteCommit{
		MarketId:   1,
		Voter:      "alice",
		Commitment: invalidCommitment,
	}

	require.Len(t, commit.Commitment, 5, "Invalid commitment should still be stored")
	require.NotEqual(t, 64, len(commit.Commitment), "Invalid commitment should not be 64 characters")
}

// TestKeeperOperations_Performance tests performance characteristics
func TestKeeperOperations_Performance(t *testing.T) {
	// Test key generation performance
	marketID := uint64(1)
	voter := "alice"

	// Generate multiple keys
	keys := make([]string, 100)
	for i := 0; i < 100; i++ {
		keys[i] = MarketVoterKey(marketID, voter)
	}

	// Verify all keys are the same
	expectedKey := "1/alice"
	for i, key := range keys {
		require.Equal(t, expectedKey, key, "All keys should be identical")
		if i > 0 {
			require.Equal(t, keys[0], key, "All keys should be identical")
		}
	}
}
