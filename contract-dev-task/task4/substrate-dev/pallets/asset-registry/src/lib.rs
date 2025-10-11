#![cfg_attr(not(feature = "std"), no_std)]

/// Edit this file to define custom logic or remove it if it is not needed.
/// Learn more about FRAME and the core library of Substrate FRAME pallets:
/// <https://docs.substrate.io/reference/frame-pallets/>
pub use pallet::*;

#[cfg(test)]
mod mock;

#[cfg(test)]
mod tests;

#[cfg(feature = "runtime-benchmarks")]
mod benchmarking;

pub mod weights;
pub use weights::*;

#[frame_support::pallet]
pub mod pallet {
    use super::*;
    use frame_support::{
        dispatch::{DispatchResult, DispatchResultWithPostInfo},
        pallet_prelude::*,
        traits::{Get, Randomness},
    };
    use frame_system::pallet_prelude::*;
    use sp_runtime::traits::{Saturating, Zero};
    use sp_std::vec::Vec;

    #[pallet::pallet]
    #[pallet::generate_store(pub(super) trait Store)]
    pub struct Pallet<T>(_);

    /// Configure the pallet by specifying the parameters and types on which it depends.
    #[pallet::config]
    pub trait Config: frame_system::Config {
        /// Because this pallet emits events, it depends on the runtime's definition of an event.
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// Type representing the weight of this pallet
        type WeightInfo: WeightInfo;

        /// Maximum length of asset name
        #[pallet::constant]
        type MaxAssetNameLength: Get<u32>;

        /// Maximum length of asset symbol
        #[pallet::constant]
        type MaxAssetSymbolLength: Get<u32>;

        /// Maximum length of asset description
        #[pallet::constant]
        type MaxAssetDescriptionLength: Get<u32>;

        /// Maximum length of asset metadata
        #[pallet::constant]
        type MaxAssetMetadataLength: Get<u32>;

        /// Maximum number of assets per owner
        #[pallet::constant]
        type MaxAssetsPerOwner: Get<u32>;
    }

    /// Asset status enumeration
    #[derive(Clone, PartialEq, Eq, Encode, Decode, RuntimeDebug, TypeInfo)]
    pub enum AssetStatus {
        /// Asset is pending approval
        Pending,
        /// Asset is approved and active
        Approved,
        /// Asset is rejected
        Rejected,
        /// Asset is suspended
        Suspended,
    }

    impl Default for AssetStatus {
        fn default() -> Self {
            AssetStatus::Pending
        }
    }

    /// Asset information
    #[derive(Clone, PartialEq, Eq, Encode, Decode, RuntimeDebug, TypeInfo)]
    pub struct AssetInfo<AccountId, BlockNumber> {
        /// Asset owner
        pub owner: AccountId,
        /// Asset name
        pub name: Vec<u8>,
        /// Asset symbol
        pub symbol: Vec<u8>,
        /// Asset description
        pub description: Vec<u8>,
        /// Asset decimals
        pub decimals: u8,
        /// Total supply
        pub total_supply: u128,
        /// Asset status
        pub status: AssetStatus,
        /// Registration block
        pub registered_at: BlockNumber,
        /// Asset metadata (JSON or other format)
        pub metadata: Vec<u8>,
        /// Whether the asset is transferable
        pub is_transferable: bool,
        /// Whether the asset is mintable
        pub is_mintable: bool,
        /// Whether the asset is burnable
        pub is_burnable: bool,
    }

    /// Storage for assets
    #[pallet::storage]
    #[pallet::getter(fn assets)]
    pub type Assets<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        u32,
        AssetInfo<T::AccountId, BlockNumberFor<T>>,
        OptionQuery,
    >;

    /// Storage for asset ownership
    #[pallet::storage]
    #[pallet::getter(fn assets_by_owner)]
    pub type AssetsByOwner<T: Config> = StorageDoubleMap<
        _,
        Blake2_128Concat,
        T::AccountId, // owner
        Blake2_128Concat,
        u32, // asset_id
        (),
        OptionQuery,
    >;

    /// Storage for asset count by owner
    #[pallet::storage]
    #[pallet::getter(fn asset_count_by_owner)]
    pub type AssetCountByOwner<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        T::AccountId,
        u32,
        ValueQuery,
    >;

    /// Storage for asset symbol to ID mapping
    #[pallet::storage]
    #[pallet::getter(fn asset_by_symbol)]
    pub type AssetBySymbol<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        Vec<u8>, // symbol
        u32, // asset_id
        OptionQuery,
    >;

    /// Next asset ID
    #[pallet::storage]
    #[pallet::getter(fn next_asset_id)]
    pub type NextAssetId<T> = StorageValue<_, u32, ValueQuery>;

    /// Pallets use events to inform users when important changes are made.
    /// https://docs.substrate.io/main-docs/build/events-errors/
    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// A new asset has been registered
        AssetRegistered {
            asset_id: u32,
            owner: T::AccountId,
            name: Vec<u8>,
            symbol: Vec<u8>,
        },
        /// An asset has been approved
        AssetApproved {
            asset_id: u32,
            approver: T::AccountId,
        },
        /// An asset has been rejected
        AssetRejected {
            asset_id: u32,
            rejector: T::AccountId,
            reason: Vec<u8>,
        },
        /// An asset has been suspended
        AssetSuspended {
            asset_id: u32,
            suspender: T::AccountId,
            reason: Vec<u8>,
        },
        /// Asset metadata has been updated
        AssetMetadataUpdated {
            asset_id: u32,
            updater: T::AccountId,
        },
        /// Asset ownership has been transferred
        AssetOwnershipTransferred {
            asset_id: u32,
            from: T::AccountId,
            to: T::AccountId,
        },
    }

    // Errors inform users that something went wrong.
    #[pallet::error]
    pub enum Error<T> {
        /// Asset does not exist
        AssetNotFound,
        /// Asset name too long
        AssetNameTooLong,
        /// Asset symbol too long
        AssetSymbolTooLong,
        /// Asset description too long
        AssetDescriptionTooLong,
        /// Asset metadata too long
        AssetMetadataTooLong,
        /// Asset symbol already exists
        AssetSymbolExists,
        /// Not the asset owner
        NotAssetOwner,
        /// Asset not pending
        AssetNotPending,
        /// Asset not approved
        AssetNotApproved,
        /// Too many assets for this owner
        TooManyAssetsPerOwner,
        /// Invalid asset status
        InvalidAssetStatus,
        /// Asset name is empty
        AssetNameEmpty,
        /// Asset symbol is empty
        AssetSymbolEmpty,
        /// Invalid decimals (must be <= 18)
        InvalidDecimals,
        /// Total supply is zero
        TotalSupplyZero,
    }

    // Dispatchable functions allow users to interact with the pallet and invoke state changes.
    // These functions materialize as "extrinsics", which are often compared to transactions.
    // Dispatchable functions must be annotated with a weight and must return a DispatchResult.
    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Register a new asset
        #[pallet::call_index(0)]
        #[pallet::weight(T::WeightInfo::register_asset())]
        pub fn register_asset(
            origin: OriginFor<T>,
            name: Vec<u8>,
            symbol: Vec<u8>,
            description: Vec<u8>,
            decimals: u8,
            total_supply: u128,
            metadata: Vec<u8>,
            is_transferable: bool,
            is_mintable: bool,
            is_burnable: bool,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            // Validate inputs
            ensure!(!name.is_empty(), Error::<T>::AssetNameEmpty);
            ensure!(!symbol.is_empty(), Error::<T>::AssetSymbolEmpty);
            ensure!(
                name.len() <= T::MaxAssetNameLength::get() as usize,
                Error::<T>::AssetNameTooLong
            );
            ensure!(
                symbol.len() <= T::MaxAssetSymbolLength::get() as usize,
                Error::<T>::AssetSymbolTooLong
            );
            ensure!(
                description.len() <= T::MaxAssetDescriptionLength::get() as usize,
                Error::<T>::AssetDescriptionTooLong
            );
            ensure!(
                metadata.len() <= T::MaxAssetMetadataLength::get() as usize,
                Error::<T>::AssetMetadataTooLong
            );
            ensure!(decimals <= 18, Error::<T>::InvalidDecimals);
            ensure!(total_supply > 0, Error::<T>::TotalSupplyZero);

            // Check if symbol already exists
            ensure!(
                !AssetBySymbol::<T>::contains_key(&symbol),
                Error::<T>::AssetSymbolExists
            );

            // Check asset count limit per owner
            let current_count = Self::asset_count_by_owner(&who);
            ensure!(
                current_count < T::MaxAssetsPerOwner::get(),
                Error::<T>::TooManyAssetsPerOwner
            );

            let asset_id = Self::next_asset_id();
            let current_block = <frame_system::Pallet<T>>::block_number();

            let asset_info = AssetInfo {
                owner: who.clone(),
                name: name.clone(),
                symbol: symbol.clone(),
                description,
                decimals,
                total_supply,
                status: AssetStatus::Pending,
                registered_at: current_block,
                metadata,
                is_transferable,
                is_mintable,
                is_burnable,
            };

            Assets::<T>::insert(&asset_id, &asset_info);
            AssetsByOwner::<T>::insert(&who, &asset_id, ());
            AssetCountByOwner::<T>::insert(&who, current_count.saturating_add(1));
            AssetBySymbol::<T>::insert(&symbol, &asset_id);
            NextAssetId::<T>::put(asset_id.saturating_add(1));

            Self::deposit_event(Event::AssetRegistered {
                asset_id,
                owner: who,
                name,
                symbol,
            });

            Ok(())
        }

        /// Approve an asset (requires root or governance)
        #[pallet::call_index(1)]
        #[pallet::weight(T::WeightInfo::approve_asset())]
        pub fn approve_asset(
            origin: OriginFor<T>,
            asset_id: u32,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            let mut asset = Self::assets(&asset_id).ok_or(Error::<T>::AssetNotFound)?;
            ensure!(asset.status == AssetStatus::Pending, Error::<T>::AssetNotPending);

            asset.status = AssetStatus::Approved;
            Assets::<T>::insert(&asset_id, &asset);

            Self::deposit_event(Event::AssetApproved {
                asset_id,
                approver: who,
            });

            Ok(())
        }

        /// Reject an asset (requires root or governance)
        #[pallet::call_index(2)]
        #[pallet::weight(T::WeightInfo::reject_asset())]
        pub fn reject_asset(
            origin: OriginFor<T>,
            asset_id: u32,
            reason: Vec<u8>,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            let mut asset = Self::assets(&asset_id).ok_or(Error::<T>::AssetNotFound)?;
            ensure!(asset.status == AssetStatus::Pending, Error::<T>::AssetNotPending);

            asset.status = AssetStatus::Rejected;
            Assets::<T>::insert(&asset_id, &asset);

            Self::deposit_event(Event::AssetRejected {
                asset_id,
                rejector: who,
                reason,
            });

            Ok(())
        }

        /// Suspend an asset (requires root or governance)
        #[pallet::call_index(3)]
        #[pallet::weight(T::WeightInfo::suspend_asset())]
        pub fn suspend_asset(
            origin: OriginFor<T>,
            asset_id: u32,
            reason: Vec<u8>,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            let mut asset = Self::assets(&asset_id).ok_or(Error::<T>::AssetNotFound)?;
            ensure!(asset.status == AssetStatus::Approved, Error::<T>::AssetNotApproved);

            asset.status = AssetStatus::Suspended;
            Assets::<T>::insert(&asset_id, &asset);

            Self::deposit_event(Event::AssetSuspended {
                asset_id,
                suspender: who,
                reason,
            });

            Ok(())
        }

        /// Update asset metadata (only by owner)
        #[pallet::call_index(4)]
        #[pallet::weight(T::WeightInfo::update_asset_metadata())]
        pub fn update_asset_metadata(
            origin: OriginFor<T>,
            asset_id: u32,
            metadata: Vec<u8>,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            let mut asset = Self::assets(&asset_id).ok_or(Error::<T>::AssetNotFound)?;
            ensure!(asset.owner == who, Error::<T>::NotAssetOwner);
            ensure!(
                metadata.len() <= T::MaxAssetMetadataLength::get() as usize,
                Error::<T>::AssetMetadataTooLong
            );

            asset.metadata = metadata;
            Assets::<T>::insert(&asset_id, &asset);

            Self::deposit_event(Event::AssetMetadataUpdated {
                asset_id,
                updater: who,
            });

            Ok(())
        }

        /// Transfer asset ownership
        #[pallet::call_index(5)]
        #[pallet::weight(T::WeightInfo::transfer_ownership())]
        pub fn transfer_ownership(
            origin: OriginFor<T>,
            asset_id: u32,
            new_owner: T::AccountId,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            let mut asset = Self::assets(&asset_id).ok_or(Error::<T>::AssetNotFound)?;
            ensure!(asset.owner == who, Error::<T>::NotAssetOwner);

            // Check new owner's asset count limit
            let new_owner_count = Self::asset_count_by_owner(&new_owner);
            ensure!(
                new_owner_count < T::MaxAssetsPerOwner::get(),
                Error::<T>::TooManyAssetsPerOwner
            );

            // Update ownership
            let old_owner = asset.owner.clone();
            asset.owner = new_owner.clone();
            Assets::<T>::insert(&asset_id, &asset);

            // Update ownership mappings
            AssetsByOwner::<T>::remove(&old_owner, &asset_id);
            AssetsByOwner::<T>::insert(&new_owner, &asset_id, ());

            // Update counts
            let old_owner_count = Self::asset_count_by_owner(&old_owner);
            AssetCountByOwner::<T>::insert(&old_owner, old_owner_count.saturating_sub(1));
            AssetCountByOwner::<T>::insert(&new_owner, new_owner_count.saturating_add(1));

            Self::deposit_event(Event::AssetOwnershipTransferred {
                asset_id,
                from: old_owner,
                to: new_owner,
            });

            Ok(())
        }
    }

    impl<T: Config> Pallet<T> {
        /// Get asset details
        pub fn get_asset(asset_id: u32) -> Option<AssetInfo<T::AccountId, BlockNumberFor<T>>> {
            Self::assets(&asset_id)
        }

        /// Get assets by owner
        pub fn get_assets_by_owner(owner: &T::AccountId) -> Vec<u32> {
            AssetsByOwner::<T>::iter_prefix(owner)
                .map(|(asset_id, _)| asset_id)
                .collect()
        }

        /// Get asset by symbol
        pub fn get_asset_by_symbol(symbol: &[u8]) -> Option<u32> {
            Self::asset_by_symbol(symbol)
        }

        /// Check if asset exists
        pub fn asset_exists(asset_id: u32) -> bool {
            Assets::<T>::contains_key(&asset_id)
        }

        /// Check if asset is approved
        pub fn is_asset_approved(asset_id: u32) -> bool {
            if let Some(asset) = Self::assets(&asset_id) {
                asset.status == AssetStatus::Approved
            } else {
                false
            }
        }

        /// Get total number of assets
        pub fn total_assets() -> u32 {
            Self::next_asset_id()
        }
    }
}