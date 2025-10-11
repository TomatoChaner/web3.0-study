use crate as pallet_asset_registry;
use frame_support::{
    parameter_types,
    traits::{ConstU16, ConstU64, ConstU32},
};
use sp_core::H256;
use sp_runtime::{
    traits::{BlakeTwo256, IdentityLookup}, BuildStorage,
};

type Block = frame_system::mocking::MockBlock<Test>;

// Configure a mock runtime to test the pallet.
frame_support::construct_runtime!(
    pub enum Test
    {
        System: frame_system,
        AssetRegistryModule: pallet_asset_registry,
    }
);

impl frame_system::Config for Test {
    type BaseCallFilter = frame_support::traits::Everything;
    type BlockWeights = ();
    type BlockLength = ();
    type DbWeight = ();
    type RuntimeOrigin = RuntimeOrigin;
    type RuntimeCall = RuntimeCall;
    type Nonce = u64;
    type Hash = H256;
    type Hashing = BlakeTwo256;
    type AccountId = u64;
    type Lookup = IdentityLookup<Self::AccountId>;
    type Block = Block;
    type RuntimeEvent = RuntimeEvent;
    type BlockHashCount = ConstU64<250>;
    type Version = ();
    type PalletInfo = PalletInfo;
    type AccountData = ();
    type OnNewAccount = ();
    type OnKilledAccount = ();
    type SystemWeightInfo = ();
    type SS58Prefix = ConstU16<42>;
    type OnSetCode = ();
    type MaxConsumers = frame_support::traits::ConstU32<16>;
}

parameter_types! {
    pub const MaxAssetNameLength: u32 = 100;
    pub const MaxAssetSymbolLength: u32 = 20;
    pub const MaxAssetDescriptionLength: u32 = 1000;
    pub const MaxAssetMetadataLength: u32 = 2000;
    pub const MaxAssetsPerOwner: u32 = 100;
}

impl pallet_asset_registry::Config for Test {
    type RuntimeEvent = RuntimeEvent;
    type WeightInfo = ();
    type MaxAssetNameLength = MaxAssetNameLength;
    type MaxAssetSymbolLength = MaxAssetSymbolLength;
    type MaxAssetDescriptionLength = MaxAssetDescriptionLength;
    type MaxAssetMetadataLength = MaxAssetMetadataLength;
    type MaxAssetsPerOwner = MaxAssetsPerOwner;
}

// Build genesis storage according to the mock runtime.
pub fn new_test_ext() -> sp_io::TestExternalities {
    frame_system::GenesisConfig::<Test>::default().build_storage().unwrap().into()
}