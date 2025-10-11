use crate::{mock::*, Error, Event, AssetStatus};
use frame_support::{assert_noop, assert_ok, traits::Get};

#[test]
fn register_asset_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        let name = b"Test Token".to_vec();
        let symbol = b"TEST".to_vec();
        let description = b"A test token for testing".to_vec();
        let decimals = 18u8;
        let total_supply = 1_000_000_000_000_000_000_000u128; // 1000 tokens with 18 decimals
        let metadata = b"{}".to_vec();

        assert_ok!(AssetRegistryModule::register_asset(
            RuntimeOrigin::signed(1),
            name.clone(),
            symbol.clone(),
            description.clone(),
            decimals,
            total_supply,
            metadata.clone(),
            true, // is_transferable
            true, // is_mintable
            true, // is_burnable
        ));

        // Check that the asset was created
        let asset = AssetRegistryModule::assets(0).unwrap();
        assert_eq!(asset.owner, 1);
        assert_eq!(asset.name, name);
        assert_eq!(asset.symbol, symbol);
        assert_eq!(asset.description, description);
        assert_eq!(asset.decimals, decimals);
        assert_eq!(asset.total_supply, total_supply);
        assert_eq!(asset.status, AssetStatus::Pending);
        assert_eq!(asset.registered_at, 1);
        assert_eq!(asset.metadata, metadata);
        assert_eq!(asset.is_transferable, true);
        assert_eq!(asset.is_mintable, true);
        assert_eq!(asset.is_burnable, true);

        // Check that the next asset ID was incremented
        assert_eq!(AssetRegistryModule::next_asset_id(), 1);

        // Check that the asset count was updated
        assert_eq!(AssetRegistryModule::asset_count_by_owner(1), 1);

        // Check that the symbol mapping was created
        assert_eq!(AssetRegistryModule::asset_by_symbol(&symbol), Some(0));

        // Check that the ownership mapping was created
        assert!(AssetRegistryModule::assets_by_owner(1, 0).is_some());

        // Check that the event was emitted
        System::assert_last_event(Event::AssetRegistered {
            asset_id: 0,
            owner: 1,
            name,
            symbol,
        }.into());
    });
}

#[test]
fn register_asset_fails_with_empty_name() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            AssetRegistryModule::register_asset(
                RuntimeOrigin::signed(1),
                vec![], // empty name
                b"TEST".to_vec(),
                b"Description".to_vec(),
                18,
                1000,
                b"{}".to_vec(),
                true,
                true,
                true,
            ),
            Error::<Test>::AssetNameEmpty
        );
    });
}

#[test]
fn register_asset_fails_with_empty_symbol() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            AssetRegistryModule::register_asset(
                RuntimeOrigin::signed(1),
                b"Test Token".to_vec(),
                vec![], // empty symbol
                b"Description".to_vec(),
                18,
                1000,
                b"{}".to_vec(),
                true,
                true,
                true,
            ),
            Error::<Test>::AssetSymbolEmpty
        );
    });
}

#[test]
fn register_asset_fails_with_duplicate_symbol() {
    new_test_ext().execute_with(|| {
        let symbol = b"TEST".to_vec();

        // Register first asset
        assert_ok!(AssetRegistryModule::register_asset(
            RuntimeOrigin::signed(1),
            b"Test Token 1".to_vec(),
            symbol.clone(),
            b"Description 1".to_vec(),
            18,
            1000,
            b"{}".to_vec(),
            true,
            true,
            true,
        ));

        // Try to register second asset with same symbol
        assert_noop!(
            AssetRegistryModule::register_asset(
                RuntimeOrigin::signed(2),
                b"Test Token 2".to_vec(),
                symbol,
                b"Description 2".to_vec(),
                18,
                2000,
                b"{}".to_vec(),
                true,
                true,
                true,
            ),
            Error::<Test>::AssetSymbolExists
        );
    });
}

#[test]
fn register_asset_fails_with_invalid_decimals() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            AssetRegistryModule::register_asset(
                RuntimeOrigin::signed(1),
                b"Test Token".to_vec(),
                b"TEST".to_vec(),
                b"Description".to_vec(),
                19, // invalid decimals > 18
                1000,
                b"{}".to_vec(),
                true,
                true,
                true,
            ),
            Error::<Test>::InvalidDecimals
        );
    });
}

#[test]
fn register_asset_fails_with_zero_supply() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            AssetRegistryModule::register_asset(
                RuntimeOrigin::signed(1),
                b"Test Token".to_vec(),
                b"TEST".to_vec(),
                b"Description".to_vec(),
                18,
                0, // zero total supply
                b"{}".to_vec(),
                true,
                true,
                true,
            ),
            Error::<Test>::TotalSupplyZero
        );
    });
}

#[test]
fn approve_asset_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        // Register an asset first
        assert_ok!(AssetRegistryModule::register_asset(
            RuntimeOrigin::signed(1),
            b"Test Token".to_vec(),
            b"TEST".to_vec(),
            b"Description".to_vec(),
            18,
            1000,
            b"{}".to_vec(),
            true,
            true,
            true,
        ));

        // Approve the asset
        assert_ok!(AssetRegistryModule::approve_asset(
            RuntimeOrigin::signed(2), // approver
            0
        ));

        // Check that the asset status was updated
        let asset = AssetRegistryModule::assets(0).unwrap();
        assert_eq!(asset.status, AssetStatus::Approved);

        // Check that the event was emitted
        System::assert_last_event(Event::AssetApproved {
            asset_id: 0,
            approver: 2,
        }.into());
    });
}

#[test]
fn approve_asset_fails_with_nonexistent_asset() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            AssetRegistryModule::approve_asset(RuntimeOrigin::signed(1), 0),
            Error::<Test>::AssetNotFound
        );
    });
}

#[test]
fn reject_asset_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        // Register an asset first
        assert_ok!(AssetRegistryModule::register_asset(
            RuntimeOrigin::signed(1),
            b"Test Token".to_vec(),
            b"TEST".to_vec(),
            b"Description".to_vec(),
            18,
            1000,
            b"{}".to_vec(),
            true,
            true,
            true,
        ));

        let reason = b"Invalid asset".to_vec();

        // Reject the asset
        assert_ok!(AssetRegistryModule::reject_asset(
            RuntimeOrigin::signed(2), // rejector
            0,
            reason.clone()
        ));

        // Check that the asset status was updated
        let asset = AssetRegistryModule::assets(0).unwrap();
        assert_eq!(asset.status, AssetStatus::Rejected);

        // Check that the event was emitted
        System::assert_last_event(Event::AssetRejected {
            asset_id: 0,
            rejector: 2,
            reason,
        }.into());
    });
}

#[test]
fn suspend_asset_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        // Register and approve an asset first
        assert_ok!(AssetRegistryModule::register_asset(
            RuntimeOrigin::signed(1),
            b"Test Token".to_vec(),
            b"TEST".to_vec(),
            b"Description".to_vec(),
            18,
            1000,
            b"{}".to_vec(),
            true,
            true,
            true,
        ));

        assert_ok!(AssetRegistryModule::approve_asset(
            RuntimeOrigin::signed(2),
            0
        ));

        let reason = b"Suspicious activity".to_vec();

        // Suspend the asset
        assert_ok!(AssetRegistryModule::suspend_asset(
            RuntimeOrigin::signed(3), // suspender
            0,
            reason.clone()
        ));

        // Check that the asset status was updated
        let asset = AssetRegistryModule::assets(0).unwrap();
        assert_eq!(asset.status, AssetStatus::Suspended);

        // Check that the event was emitted
        System::assert_last_event(Event::AssetSuspended {
            asset_id: 0,
            suspender: 3,
            reason,
        }.into());
    });
}

#[test]
fn update_asset_metadata_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        // Register an asset first
        assert_ok!(AssetRegistryModule::register_asset(
            RuntimeOrigin::signed(1),
            b"Test Token".to_vec(),
            b"TEST".to_vec(),
            b"Description".to_vec(),
            18,
            1000,
            b"{}".to_vec(),
            true,
            true,
            true,
        ));

        let new_metadata = b"{\"website\": \"https://example.com\"}".to_vec();

        // Update metadata
        assert_ok!(AssetRegistryModule::update_asset_metadata(
            RuntimeOrigin::signed(1), // owner
            0,
            new_metadata.clone()
        ));

        // Check that the metadata was updated
        let asset = AssetRegistryModule::assets(0).unwrap();
        assert_eq!(asset.metadata, new_metadata);

        // Check that the event was emitted
        System::assert_last_event(Event::AssetMetadataUpdated {
            asset_id: 0,
            updater: 1,
        }.into());
    });
}

#[test]
fn update_asset_metadata_fails_when_not_owner() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        // Register an asset first
        assert_ok!(AssetRegistryModule::register_asset(
            RuntimeOrigin::signed(1),
            b"Test Token".to_vec(),
            b"TEST".to_vec(),
            b"Description".to_vec(),
            18,
            1000,
            b"{}".to_vec(),
            true,
            true,
            true,
        ));

        // Try to update metadata as non-owner
        assert_noop!(
            AssetRegistryModule::update_asset_metadata(
                RuntimeOrigin::signed(2), // not owner
                0,
                b"new metadata".to_vec()
            ),
            Error::<Test>::NotAssetOwner
        );
    });
}

#[test]
fn transfer_ownership_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        // Register an asset first
        assert_ok!(AssetRegistryModule::register_asset(
            RuntimeOrigin::signed(1),
            b"Test Token".to_vec(),
            b"TEST".to_vec(),
            b"Description".to_vec(),
            18,
            1000,
            b"{}".to_vec(),
            true,
            true,
            true,
        ));

        // Transfer ownership
        assert_ok!(AssetRegistryModule::transfer_ownership(
            RuntimeOrigin::signed(1), // current owner
            0,
            2 // new owner
        ));

        // Check that the ownership was transferred
        let asset = AssetRegistryModule::assets(0).unwrap();
        assert_eq!(asset.owner, 2);

        // Check that the ownership mappings were updated
        assert!(AssetRegistryModule::assets_by_owner(1, 0).is_none());
        assert!(AssetRegistryModule::assets_by_owner(2, 0).is_some());

        // Check that the counts were updated
        assert_eq!(AssetRegistryModule::asset_count_by_owner(1), 0);
        assert_eq!(AssetRegistryModule::asset_count_by_owner(2), 1);

        // Check that the event was emitted
        System::assert_last_event(Event::AssetOwnershipTransferred {
            asset_id: 0,
            from: 1,
            to: 2,
        }.into());
    });
}

#[test]
fn transfer_ownership_fails_when_not_owner() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        // Register an asset first
        assert_ok!(AssetRegistryModule::register_asset(
            RuntimeOrigin::signed(1),
            b"Test Token".to_vec(),
            b"TEST".to_vec(),
            b"Description".to_vec(),
            18,
            1000,
            b"{}".to_vec(),
            true,
            true,
            true,
        ));

        // Try to transfer ownership as non-owner
        assert_noop!(
            AssetRegistryModule::transfer_ownership(
                RuntimeOrigin::signed(2), // not owner
                0,
                3
            ),
            Error::<Test>::NotAssetOwner
        );
    });
}