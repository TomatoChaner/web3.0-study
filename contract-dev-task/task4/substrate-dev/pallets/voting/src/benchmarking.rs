//! Benchmarking setup for pallet-voting

use super::*;

#[allow(unused)]
use crate::Pallet as Voting;
use frame_benchmarking::v2::*;
use frame_system::RawOrigin;

#[benchmarks]
mod benchmarks {
    use super::*;

    #[benchmark]
    fn create_proposal() {
        let caller: T::AccountId = whitelisted_caller();
        let description = b"Test proposal for benchmarking".to_vec();
        let options = vec![b"Option A".to_vec(), b"Option B".to_vec(), b"Option C".to_vec()];
        let voting_period = T::MinVotingPeriod::get();

        #[extrinsic_call]
        create_proposal(RawOrigin::Signed(caller), description, options, voting_period);

        assert_eq!(Voting::<T>::next_proposal_id(), 1);
    }

    #[benchmark]
    fn vote() {
        let caller: T::AccountId = whitelisted_caller();
        let proposer: T::AccountId = account("proposer", 0, 0);
        
        // Setup: create a proposal first
        let description = b"Test proposal for benchmarking".to_vec();
        let options = vec![b"Option A".to_vec(), b"Option B".to_vec()];
        let voting_period = T::MinVotingPeriod::get();
        
        let _ = Voting::<T>::create_proposal(
            RawOrigin::Signed(proposer).into(),
            description,
            options,
            voting_period,
        );

        #[extrinsic_call]
        vote(RawOrigin::Signed(caller.clone()), 0, 0);

        assert!(Voting::<T>::votes(0, &caller).is_some());
    }

    #[benchmark]
    fn end_proposal() {
        let caller: T::AccountId = whitelisted_caller();
        let proposer: T::AccountId = account("proposer", 0, 0);
        
        // Setup: create a proposal first
        let description = b"Test proposal for benchmarking".to_vec();
        let options = vec![b"Option A".to_vec(), b"Option B".to_vec()];
        let voting_period = T::MinVotingPeriod::get();
        
        let _ = Voting::<T>::create_proposal(
            RawOrigin::Signed(proposer).into(),
            description,
            options,
            voting_period,
        );

        // Fast forward past voting period
        let current_block = frame_system::Pallet::<T>::block_number();
        let end_block = current_block + voting_period + 1u32.into();
        frame_system::Pallet::<T>::set_block_number(end_block);

        #[extrinsic_call]
        end_proposal(RawOrigin::Signed(caller), 0);

        let proposal = Voting::<T>::proposals(0).unwrap();
        assert!(!proposal.is_active);
    }

    #[benchmark]
    fn cancel_proposal() {
        let caller: T::AccountId = whitelisted_caller();
        
        // Setup: create a proposal first
        let description = b"Test proposal for benchmarking".to_vec();
        let options = vec![b"Option A".to_vec(), b"Option B".to_vec()];
        let voting_period = T::MinVotingPeriod::get();
        
        let _ = Voting::<T>::create_proposal(
            RawOrigin::Signed(caller.clone()).into(),
            description,
            options,
            voting_period,
        );

        #[extrinsic_call]
        cancel_proposal(RawOrigin::Signed(caller), 0);

        let proposal = Voting::<T>::proposals(0).unwrap();
        assert!(!proposal.is_active);
    }

    impl_benchmark_test_suite!(Voting, crate::mock::new_test_ext(), crate::mock::Test);
}