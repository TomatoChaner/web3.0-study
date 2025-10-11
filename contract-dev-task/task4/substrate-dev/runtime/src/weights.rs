//! Runtime weights for custom pallets
//!
//! This file contains the weight definitions for all custom pallets in the runtime.
//! Weights are used to calculate transaction fees and prevent spam attacks.

pub mod pallet_voting {
    //! Weights for pallet_voting
    use frame_support::weights::Weight;

    pub trait WeightInfo {
        fn create_proposal() -> Weight;
        fn vote() -> Weight;
        fn end_proposal() -> Weight;
        fn cancel_proposal() -> Weight;
    }

    /// Default weights for voting pallet
    pub struct SubstrateWeight<T>(core::marker::PhantomData<T>);

    impl<T: frame_system::Config> WeightInfo for SubstrateWeight<T> {
        fn create_proposal() -> Weight {
            Weight::from_parts(50_000_000, 0)
                .saturating_add(T::DbWeight::get().reads(2))
                .saturating_add(T::DbWeight::get().writes(2))
        }

        fn vote() -> Weight {
            Weight::from_parts(30_000_000, 0)
                .saturating_add(T::DbWeight::get().reads(3))
                .saturating_add(T::DbWeight::get().writes(2))
        }

        fn end_proposal() -> Weight {
            Weight::from_parts(40_000_000, 0)
                .saturating_add(T::DbWeight::get().reads(2))
                .saturating_add(T::DbWeight::get().writes(1))
        }

        fn cancel_proposal() -> Weight {
            Weight::from_parts(25_000_000, 0)
                .saturating_add(T::DbWeight::get().reads(1))
                .saturating_add(T::DbWeight::get().writes(1))
        }
    }
}

pub mod pallet_asset_registry {
    //! Weights for pallet_asset_registry
    use frame_support::weights::Weight;

    pub trait WeightInfo {
        fn register_asset() -> Weight;
        fn approve_asset() -> Weight;
        fn reject_asset() -> Weight;
        fn suspend_asset() -> Weight;
        fn update_asset_metadata() -> Weight;
        fn transfer_ownership() -> Weight;
    }

    /// Default weights for asset registry pallet
    pub struct SubstrateWeight<T>(core::marker::PhantomData<T>);

    impl<T: frame_system::Config> WeightInfo for SubstrateWeight<T> {
        fn register_asset() -> Weight {
            Weight::from_parts(60_000_000, 0)
                .saturating_add(T::DbWeight::get().reads(3))
                .saturating_add(T::DbWeight::get().writes(3))
        }

        fn approve_asset() -> Weight {
            Weight::from_parts(35_000_000, 0)
                .saturating_add(T::DbWeight::get().reads(1))
                .saturating_add(T::DbWeight::get().writes(1))
        }

        fn reject_asset() -> Weight {
            Weight::from_parts(35_000_000, 0)
                .saturating_add(T::DbWeight::get().reads(1))
                .saturating_add(T::DbWeight::get().writes(1))
        }

        fn suspend_asset() -> Weight {
            Weight::from_parts(35_000_000, 0)
                .saturating_add(T::DbWeight::get().reads(1))
                .saturating_add(T::DbWeight::get().writes(1))
        }

        fn update_asset_metadata() -> Weight {
            Weight::from_parts(45_000_000, 0)
                .saturating_add(T::DbWeight::get().reads(1))
                .saturating_add(T::DbWeight::get().writes(1))
        }

        fn transfer_ownership() -> Weight {
            Weight::from_parts(40_000_000, 0)
                .saturating_add(T::DbWeight::get().reads(2))
                .saturating_add(T::DbWeight::get().writes(2))
        }
    }
}