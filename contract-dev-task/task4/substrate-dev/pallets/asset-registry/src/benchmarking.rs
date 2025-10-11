//! Benchmarking setup for pallet-asset-registry

use super::*;

#[allow(unused)]
use crate::Pallet as AssetRegistry;
use frame_benchmarking::v2::*;
use frame_system::RawOrigin;

#[benchmarks]
mod benchmarks {
    use super::*;

    #[benchmark]
    fn register_asset() {
        let caller: T::AccountId = whitelisted_caller();
        let name = b"Test Token for Benchmarking".to_vec();
        let symbol = b"BENCH".to_vec();
        let description = b"A test token for benchmarking purposes".to_vec();
        let decimals = 18u8;
        let total_supply = 1_000_000_000_000_000_000_000u128;
        let metadata = b"{\"website\": \"https://example.com\"}".to_vec();

        #[extrinsic_call]
        register_asset(
            RawOrigin::Signed(caller.clone()),
            name,
            symbol.clone(),
            description,
            decimals,
            total_supply,
            metadata,
            true,
            true,
            true,
        );

        assert_eq!(AssetRegistry::<T>::next_asset_id(), 1);
        assert_eq!(AssetRegistry::<T>::asset_by_symbol(&symbol), Some(0));
    }

    #[benchmark]
    fn approve_asset() {
        let caller: T::AccountId = whitelisted_caller();
        let owner: T::AccountId = account("owner", 0, 0);
        
        // Setup: register an asset first
        let _ = AssetRegistry::<T>::register_asset(
            RawOrigin::Signed(owner).into(),
            b"Test Token".to_vec(),
            b"TEST".to_vec(),
            b"Description".to_vec(),
            18,
            1000,
            b"{}".to_vec(),
            true,
            true,
            true,
        );

        #[extrinsic_call]
        approve_asset(RawOrigin::Signed(caller), 0);

        let asset = AssetRegistry::<T>::assets(0).unwrap();
        assert_eq!(asset.status, AssetStatus::Approved);
    }

    #[benchmark]
    fn reject_asset() {
        let caller: T::AccountId = whitelisted_caller();
        let owner: T::AccountId = account("owner", 0, 0);
        
        // Setup: register an asset first
        let _ = AssetRegistry::<T>::register_asset(
            RawOrigin::Signed(owner).into(),
            b"Test Token".to_vec(),
            b"TEST".to_vec(),
            b"Description".to_vec(),
            18,
            1000,
            b"{}".to_vec(),
            true,
            true,
            true,
        );

        let reason = b"Invalid asset for benchmarking".to_vec();

        #[extrinsic_call]
        reject_asset(RawOrigin::Signed(caller), 0, reason);

        let asset = AssetRegistry::<T>::assets(0).unwrap();
        assert_eq!(asset.status, AssetStatus::Rejected);
    }

    #[benchmark]
    fn suspend_asset() {
        let caller: T::AccountId = whitelisted_caller();
        let owner: T::AccountId = account("owner", 0, 0);
        let approver: T::AccountId = account("approver", 0, 1);
        
        // Setup: register and approve an asset first
        let _ = AssetRegistry::<T>::register_asset(
            RawOrigin::Signed(owner).into(),
            b"Test Token".to_vec(),
            b"TEST".to_vec(),
            b"Description".to_vec(),
            18,
            1000,
            b"{}".to_vec(),
            true,
            true,
            true,
        );

        let _ = AssetRegistry::<T>::approve_asset(
            RawOrigin::Signed(approver).into(),
            0,
        );

        let reason = b"Suspicious activity detected".to_vec();

        #[extrinsic_call]
        suspend_asset(RawOrigin::Signed(caller), 0, reason);

        let asset = AssetRegistry::<T>::assets(0).unwrap();
        assert_eq!(asset.status, AssetStatus::Suspended);
    }

    #[benchmark]
    fn update_asset_metadata() {
        let caller: T::AccountId = whitelisted_caller();
        
        // Setup: register an asset first
        let _ = AssetRegistry::<T>::register_asset(
            RawOrigin::Signed(caller.clone()).into(),
            b"Test Token".to_vec(),
            b"TEST".to_vec(),
            b"Description".to_vec(),
            18,
            1000,
            b"{}".to_vec(),
            true,
            true,
            true,
        );

        let new_metadata = b"{\"website\": \"https://newexample.com\", \"description\": \"Updated metadata\"}".to_vec();

        #[extrinsic_call]
        update_asset_metadata(RawOrigin::Signed(caller), 0, new_metadata.clone());

        let asset = AssetRegistry::<T>::assets(0).unwrap();
        assert_eq!(asset.metadata, new_metadata);
    }

    #[benchmark]
    fn transfer_ownership() {
        let caller: T::AccountId = whitelisted_caller();
        let new_owner: T::AccountId = account("new_owner", 0, 0);
        
        // Setup: register an asset first
        let _ = AssetRegistry::<T>::register_asset(
            RawOrigin::Signed(caller.clone()).into(),
            b"Test Token".to_vec(),
            b"TEST".to_vec(),
            b"Description".to_vec(),
            18,
            1000,
            b"{}".to_vec(),
            true,
            true,
            true,
        );

        #[extrinsic_call]
        transfer_ownership(RawOrigin::Signed(caller.clone()), 0, new_owner.clone());

        let asset = AssetRegistry::<T>::assets(0).unwrap();
        assert_eq!(asset.owner, new_owner);
        assert_eq!(AssetRegistry::<T>::asset_count_by_owner(&caller), 0);
        assert_eq!(AssetRegistry::<T>::asset_count_by_owner(&new_owner), 1);
    }

    impl_benchmark_test_suite!(AssetRegistry, crate::mock::new_test_ext(), crate::mock::Test);
}