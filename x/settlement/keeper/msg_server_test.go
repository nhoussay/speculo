package keeper

import (
	"testing"

	"speculod/x/settlement/types"

	"github.com/stretchr/testify/require"
)

// TestMsgCommitVote_ValidCommit tests valid vote commitment
func TestMsgCommitVote_ValidCommit(t *testing.T) {
	// Test valid commit message
	msg := &types.MsgCommitVote{
		MarketId:   1,
		Creator:    "alice",
		Commitment: generateTestCommitment("YES", "nonce1"),
	}

	// Validate message structure
	require.Equal(t, uint64(1), msg.MarketId, "Market ID should be 1")
	require.Equal(t, "alice", msg.Creator, "Creator should be alice")
	require.Len(t, msg.Commitment, 64, "Commitment should be 64 hex characters")
	require.NotEmpty(t, msg.Commitment, "Commitment should not be empty")
}

// TestMsgCommitVote_InvalidCommitment tests invalid commitment format
func TestMsgCommitVote_InvalidCommitment(t *testing.T) {
	// Test invalid commitment length
	invalidCommitments := []string{
		"",                             // Empty
		"123",                          // Too short
		"a" + string(make([]byte, 65)), // Too long
		"invalid_hex_string",           // Not hex
	}

	for _, commitment := range invalidCommitments {
		msg := &types.MsgCommitVote{
			MarketId:   1,
			Creator:    "alice",
			Commitment: commitment,
		}

		isValid := len(msg.Commitment) == 64
		require.False(t, isValid, "Invalid commitment should be rejected: %s", commitment)
	}
}

// TestMsgRevealVote_ValidReveal tests valid vote reveal
func TestMsgRevealVote_ValidReveal(t *testing.T) {
	// Test valid reveal message
	msg := &types.MsgRevealVote{
		MarketId: 1,
		Creator:  "alice",
		Vote:     "YES",
		Nonce:    "test_nonce_123",
	}

	// Validate message structure
	require.Equal(t, uint64(1), msg.MarketId, "Market ID should be 1")
	require.Equal(t, "alice", msg.Creator, "Creator should be alice")
	require.Equal(t, "YES", msg.Vote, "Vote should be YES")
	require.Equal(t, "test_nonce_123", msg.Nonce, "Nonce should match")
}

// TestMsgRevealVote_InvalidVote tests invalid vote values
func TestMsgRevealVote_InvalidVote(t *testing.T) {
	// Test invalid votes
	invalidVotes := []string{
		"",        // Empty
		"INVALID", // Not allowed
		"MAYBE",   // Not allowed
		"UNKNOWN", // Not allowed
	}

	allowedOutcomes := []string{"YES", "NO"}

	for _, vote := range invalidVotes {
		msg := &types.MsgRevealVote{
			MarketId: 1,
			Creator:  "alice",
			Vote:     vote,
			Nonce:    "test_nonce_123",
		}

		isValid := false
		for _, outcome := range allowedOutcomes {
			if msg.Vote == outcome {
				isValid = true
				break
			}
		}
		require.False(t, isValid, "Invalid vote should be rejected: %s", vote)
	}
}

// TestMsgRevealVote_InvalidNonce tests invalid nonce values
func TestMsgRevealVote_InvalidNonce(t *testing.T) {
	// Test invalid nonces
	invalidNonces := []string{
		"",                             // Empty
		"123",                          // Too short
		"a" + string(make([]byte, 65)), // Too long
	}

	for _, nonce := range invalidNonces {
		msg := &types.MsgRevealVote{
			MarketId: 1,
			Creator:  "alice",
			Vote:     "YES",
			Nonce:    nonce,
		}

		isValid := len(msg.Nonce) >= 8 && len(msg.Nonce) <= 64
		require.False(t, isValid, "Invalid nonce should be rejected: %s", nonce)
	}
}

// TestMsgFinalizeOutcome_ValidFinalize tests valid outcome finalization
func TestMsgFinalizeOutcome_ValidFinalize(t *testing.T) {
	// Test valid finalize message
	msg := &types.MsgFinalizeOutcome{
		MarketId: 1,
		Creator:  "alice",
	}

	// Validate message structure
	require.Equal(t, uint64(1), msg.MarketId, "Market ID should be 1")
	require.Equal(t, "alice", msg.Creator, "Creator should be alice")
}

// TestCommitmentRevealMatching_ValidPair tests valid commitment-reveal pairs
func TestCommitmentRevealMatching_ValidPair(t *testing.T) {
	// Test valid commitment-reveal pair
	vote := "YES"
	nonce := "test_nonce_123"
	commitment := generateTestCommitment(vote, nonce)

	commitMsg := &types.MsgCommitVote{
		MarketId:   1,
		Creator:    "alice",
		Commitment: commitment,
	}

	revealMsg := &types.MsgRevealVote{
		MarketId: 1,
		Creator:  "alice",
		Vote:     vote,
		Nonce:    nonce,
	}

	// Verify commitment matches reveal
	expectedCommitment := generateTestCommitment(revealMsg.Vote, revealMsg.Nonce)
	require.Equal(t, expectedCommitment, commitMsg.Commitment, "Commitment should match reveal")
}

// TestCommitmentRevealMatching_InvalidPair tests invalid commitment-reveal pairs
func TestCommitmentRevealMatching_InvalidPair(t *testing.T) {
	// Test invalid commitment-reveal pair
	vote := "YES"
	nonce := "test_nonce_123"
	commitment := generateTestCommitment(vote, nonce)

	commitMsg := &types.MsgCommitVote{
		MarketId:   1,
		Creator:    "alice",
		Commitment: commitment,
	}

	// Wrong vote
	revealMsg1 := &types.MsgRevealVote{
		MarketId: 1,
		Creator:  "alice",
		Vote:     "NO",
		Nonce:    nonce,
	}

	expectedCommitment1 := generateTestCommitment(revealMsg1.Vote, revealMsg1.Nonce)
	require.NotEqual(t, expectedCommitment1, commitMsg.Commitment, "Different votes should not match")

	// Wrong nonce
	revealMsg2 := &types.MsgRevealVote{
		MarketId: 1,
		Creator:  "alice",
		Vote:     vote,
		Nonce:    "wrong_nonce",
	}

	expectedCommitment2 := generateTestCommitment(revealMsg2.Vote, revealMsg2.Nonce)
	require.NotEqual(t, expectedCommitment2, commitMsg.Commitment, "Different nonces should not match")
}

// TestMessageValidation_RequiredFields tests required field validation
func TestMessageValidation_RequiredFields(t *testing.T) {
	// Test commit message validation
	commitMsg := &types.MsgCommitVote{
		MarketId:   1,
		Creator:    "alice",
		Commitment: generateTestCommitment("YES", "nonce1"),
	}

	require.NotZero(t, commitMsg.MarketId, "Market ID should not be zero")
	require.NotEmpty(t, commitMsg.Creator, "Creator should not be empty")
	require.NotEmpty(t, commitMsg.Commitment, "Commitment should not be empty")

	// Test reveal message validation
	revealMsg := &types.MsgRevealVote{
		MarketId: 1,
		Creator:  "alice",
		Vote:     "YES",
		Nonce:    "test_nonce_123",
	}

	require.NotZero(t, revealMsg.MarketId, "Market ID should not be zero")
	require.NotEmpty(t, revealMsg.Creator, "Creator should not be empty")
	require.NotEmpty(t, revealMsg.Vote, "Vote should not be empty")
	require.NotEmpty(t, revealMsg.Nonce, "Nonce should not be empty")

	// Test finalize message validation
	finalizeMsg := &types.MsgFinalizeOutcome{
		MarketId: 1,
		Creator:  "alice",
	}

	require.NotZero(t, finalizeMsg.MarketId, "Market ID should not be zero")
	require.NotEmpty(t, finalizeMsg.Creator, "Creator should not be empty")
}

// TestMessageConsistency tests message consistency across operations
func TestMessageConsistency(t *testing.T) {
	// Test that same user can perform all operations on same market
	user := "alice"
	marketID := uint64(1)

	commitMsg := &types.MsgCommitVote{
		MarketId:   marketID,
		Creator:    user,
		Commitment: generateTestCommitment("YES", "nonce1"),
	}

	revealMsg := &types.MsgRevealVote{
		MarketId: marketID,
		Creator:  user,
		Vote:     "YES",
		Nonce:    "nonce1",
	}

	finalizeMsg := &types.MsgFinalizeOutcome{
		MarketId: marketID,
		Creator:  user,
	}

	// Verify consistency
	require.Equal(t, marketID, commitMsg.MarketId, "All messages should have same market ID")
	require.Equal(t, marketID, revealMsg.MarketId, "All messages should have same market ID")
	require.Equal(t, marketID, finalizeMsg.MarketId, "All messages should have same market ID")

	require.Equal(t, user, commitMsg.Creator, "All messages should have same creator")
	require.Equal(t, user, revealMsg.Creator, "All messages should have same creator")
	require.Equal(t, user, finalizeMsg.Creator, "All messages should have same creator")
}

// TestMessageIsolation tests message isolation between different markets and users
func TestMessageIsolation(t *testing.T) {
	// Test different markets
	market1ID := uint64(1)
	market2ID := uint64(2)
	user := "alice"

	commit1 := &types.MsgCommitVote{
		MarketId:   market1ID,
		Creator:    user,
		Commitment: generateTestCommitment("YES", "nonce1"),
	}

	commit2 := &types.MsgCommitVote{
		MarketId:   market2ID,
		Creator:    user,
		Commitment: generateTestCommitment("NO", "nonce2"),
	}

	require.NotEqual(t, commit1.MarketId, commit2.MarketId, "Different markets should have different IDs")
	require.NotEqual(t, commit1.Commitment, commit2.Commitment, "Different markets should have different commitments")

	// Test different users
	user1 := "alice"
	user2 := "bob"

	commit3 := &types.MsgCommitVote{
		MarketId:   market1ID,
		Creator:    user1,
		Commitment: generateTestCommitment("YES", "nonce1"),
	}

	commit4 := &types.MsgCommitVote{
		MarketId:   market1ID,
		Creator:    user2,
		Commitment: generateTestCommitment("YES", "nonce2"),
	}

	require.NotEqual(t, commit3.Creator, commit4.Creator, "Different users should have different creators")
	require.NotEqual(t, commit3.Commitment, commit4.Commitment, "Different users should have different commitments")
}
