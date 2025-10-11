# Custom Pallets Documentation

This document provides comprehensive documentation for the custom pallets implemented in this Substrate blockchain.

## Table of Contents

1. [Voting Pallet](#voting-pallet)
2. [Asset Registry Pallet](#asset-registry-pallet)

---

# Voting Pallet

The Voting Pallet provides a democratic governance system that allows users to create proposals and vote on them. This pallet enables decentralized decision-making within the blockchain network.

## Overview

The Voting Pallet implements a simple yet effective voting mechanism where:
- Any user can create proposals with multiple options
- All users can vote on active proposals
- Proposals have configurable voting periods
- Results are automatically tallied when voting ends

## Architecture

### Storage Items

#### Proposals
```rust
pub type Proposals<T> = StorageMap<
    _,
    Blake2_128Concat,
    u32,                    // ProposalId
    ProposalInfo<T>,        // Proposal details
    OptionQuery
>;
```

#### Votes
```rust
pub type Votes<T> = StorageDoubleMap<
    _,
    Blake2_128Concat,
    u32,                    // ProposalId
    Blake2_128Concat,
    T::AccountId,           // Voter account
    u32,                    // Selected option index
    OptionQuery
>;
```

#### VoteResults
```rust
pub type VoteResults<T> = StorageMap<
    _,
    Blake2_128Concat,
    u32,                    // ProposalId
    BoundedVec<u32, T::MaxOptions>,  // Vote counts for each option
    ValueQuery
>;
```

### Data Structures

#### ProposalInfo
```rust
pub struct ProposalInfo<T: Config> {
    pub description: BoundedVec<u8, T::MaxDescriptionLength>,
    pub options: BoundedVec<BoundedVec<u8, T::MaxOptionLength>, T::MaxOptions>,
    pub start_block: T::BlockNumber,
    pub end_block: T::BlockNumber,
    pub proposer: T::AccountId,
    pub status: ProposalStatus,
}
```

#### ProposalStatus
```rust
pub enum ProposalStatus {
    Active,
    Ended,
    Cancelled,
}
```

## Extrinsics

### create_proposal
Creates a new voting proposal.

**Parameters:**
- `description`: Proposal description
- `options`: Available voting options
- `voting_period`: Duration in blocks

### vote
Casts a vote on an active proposal.

**Parameters:**
- `proposal_id`: ID of the proposal
- `option_index`: Index of the selected option

### end_proposal
Manually ends a proposal and tallies results.

**Parameters:**
- `proposal_id`: ID of the proposal to end

### cancel_proposal
Cancels an active proposal (only by proposer).

**Parameters:**
- `proposal_id`: ID of the proposal to cancel

## Events

- `ProposalCreated`: New proposal created
- `VoteCast`: Vote cast on proposal
- `ProposalEnded`: Proposal voting ended
- `ProposalCancelled`: Proposal cancelled

## Errors

- `ProposalNotFound`: Proposal doesn't exist
- `ProposalNotActive`: Proposal is not in active state
- `VotingPeriodEnded`: Voting period has ended
- `AlreadyVoted`: User has already voted
- `InvalidOption`: Selected option doesn't exist
- `NotProposer`: Only proposer can perform this action

---

# Asset Registry Pallet

The Asset Registry Pallet provides a comprehensive system for registering, managing, and tracking digital assets on the blockchain. It implements a complete asset lifecycle with approval workflows, metadata management, and ownership controls.

## Overview

The Asset Registry Pallet enables:
- Decentralized asset registration by any user
- Administrative approval workflow for asset validation
- Comprehensive asset metadata management
- Ownership transfer and tracking
- Asset status management (pending, approved, rejected, suspended)

## Architecture

### Storage Items

#### Assets
```rust
pub type Assets<T> = StorageMap<
    _,
    Blake2_128Concat,
    u32,                    // AssetId
    AssetInfo<T>,           // Asset information
    OptionQuery
>;
```

#### AssetsByOwner
```rust
pub type AssetsByOwner<T> = StorageMap<
    _,
    Blake2_128Concat,
    T::AccountId,           // Owner account
    BoundedVec<u32, T::MaxAssetsPerOwner>,  // List of owned asset IDs
    ValueQuery
>;
```

#### AssetCountByOwner
```rust
pub type AssetCountByOwner<T> = StorageMap<
    _,
    Blake2_128Concat,
    T::AccountId,           // Owner account
    u32,                    // Number of assets owned
    ValueQuery
>;
```

### Data Structures

#### AssetInfo
```rust
pub struct AssetInfo<T: Config> {
    pub name: BoundedVec<u8, T::MaxNameLength>,
    pub symbol: BoundedVec<u8, T::MaxSymbolLength>,
    pub description: BoundedVec<u8, T::MaxDescriptionLength>,
    pub owner: T::AccountId,
    pub status: AssetStatus,
    pub created_at: T::BlockNumber,
    pub updated_at: T::BlockNumber,
}
```

#### AssetStatus
```rust
pub enum AssetStatus {
    Pending,
    Approved,
    Rejected,
    Suspended,
}
```

## Extrinsics

### register_asset
Registers a new asset in the registry.

**Parameters:**
- `name`: Asset name
- `symbol`: Asset symbol
- `description`: Asset description

### approve_asset
Approves a pending asset (admin only).

**Parameters:**
- `asset_id`: ID of the asset to approve

### reject_asset
Rejects a pending asset (admin only).

**Parameters:**
- `asset_id`: ID of the asset to reject

### suspend_asset
Suspends an approved asset (admin only).

**Parameters:**
- `asset_id`: ID of the asset to suspend

### update_asset_metadata
Updates asset metadata (owner only).

**Parameters:**
- `asset_id`: ID of the asset
- `name`: New name (optional)
- `symbol`: New symbol (optional)
- `description`: New description (optional)

### transfer_ownership
Transfers asset ownership.

**Parameters:**
- `asset_id`: ID of the asset
- `new_owner`: New owner account

## Events

- `AssetRegistered`: New asset registered
- `AssetApproved`: Asset approved by admin
- `AssetRejected`: Asset rejected by admin
- `AssetSuspended`: Asset suspended by admin
- `AssetMetadataUpdated`: Asset metadata updated
- `OwnershipTransferred`: Asset ownership transferred

## Errors

- `AssetNotFound`: Asset doesn't exist
- `NotOwner`: Only asset owner can perform this action
- `NotAdmin`: Only admin can perform this action
- `InvalidStatus`: Invalid asset status for operation
- `AssetAlreadyExists`: Asset with same name/symbol exists
- `MaxAssetsPerOwnerExceeded`: Owner has too many assets

## Asset Lifecycle

1. **Registration**: User registers asset (status: Pending)
2. **Review**: Admin reviews and approves/rejects
3. **Active**: Approved assets can be used
4. **Maintenance**: Metadata updates, ownership transfers
5. **Suspension**: Admin can suspend if needed

## Usage Examples

### Registering an Asset
```rust
// Register a new asset
let result = AssetRegistry::register_asset(
    origin,
    b"MyToken".to_vec().try_into().unwrap(),
    b"MTK".to_vec().try_into().unwrap(),
    b"A sample token for testing".to_vec().try_into().unwrap(),
);
```

### Approving an Asset
```rust
// Admin approves asset
let result = AssetRegistry::approve_asset(admin_origin, asset_id);
```

### Updating Metadata
```rust
// Owner updates asset description
let result = AssetRegistry::update_asset_metadata(
    owner_origin,
    asset_id,
    None, // name unchanged
    None, // symbol unchanged
    Some(b"Updated description".to_vec().try_into().unwrap()),
);
```

## Security Considerations

- Only admins can approve, reject, or suspend assets
- Only asset owners can update metadata or transfer ownership
- Asset names and symbols should be unique
- Proper validation of input parameters
- Rate limiting for asset registration