use crate::{mock::*, Error, Event};
use frame_support::{assert_noop, assert_ok, traits::Get};

#[test]
fn create_proposal_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        let description = b"Test proposal".to_vec();
        let options = vec![b"Option A".to_vec(), b"Option B".to_vec()];
        let voting_period = 100u64;

        assert_ok!(VotingModule::create_proposal(
            RuntimeOrigin::signed(1),
            description.clone(),
            options.clone(),
            voting_period
        ));

        // Check that the proposal was created
        let proposal = VotingModule::proposals(0).unwrap();
        assert_eq!(proposal.proposer, 1);
        assert_eq!(proposal.description, description);
        assert_eq!(proposal.options, options);
        assert_eq!(proposal.start_block, 1);
        assert_eq!(proposal.end_block, 101);
        assert_eq!(proposal.is_active, true);

        // Check that the next proposal ID was incremented
        assert_eq!(VotingModule::next_proposal_id(), 1);

        // Check that the event was emitted
        System::assert_last_event(Event::ProposalCreated {
            proposal_id: 0,
            proposer: 1,
            description,
        }.into());
    });
}

#[test]
fn create_proposal_fails_with_no_options() {
    new_test_ext().execute_with(|| {
        let description = b"Test proposal".to_vec();
        let options = vec![];
        let voting_period = 100u64;

        assert_noop!(
            VotingModule::create_proposal(
                RuntimeOrigin::signed(1),
                description,
                options,
                voting_period
            ),
            Error::<Test>::NoOptions
        );
    });
}

#[test]
fn create_proposal_fails_with_too_many_options() {
    new_test_ext().execute_with(|| {
        let description = b"Test proposal".to_vec();
        let mut options = vec![];
        for i in 0..=MaxOptions::get() {
            options.push(format!("Option {}", i).into_bytes());
        }
        let voting_period = 100u64;

        assert_noop!(
            VotingModule::create_proposal(
                RuntimeOrigin::signed(1),
                description,
                options,
                voting_period
            ),
            Error::<Test>::TooManyOptions
        );
    });
}

#[test]
fn create_proposal_fails_with_description_too_long() {
    new_test_ext().execute_with(|| {
        let description = vec![b'a'; (MaxDescriptionLength::get() + 1) as usize];
        let options = vec![b"Option A".to_vec(), b"Option B".to_vec()];
        let voting_period = 100u64;

        assert_noop!(
            VotingModule::create_proposal(
                RuntimeOrigin::signed(1),
                description,
                options,
                voting_period
            ),
            Error::<Test>::DescriptionTooLong
        );
    });
}

#[test]
fn create_proposal_fails_with_invalid_voting_period() {
    new_test_ext().execute_with(|| {
        let description = b"Test proposal".to_vec();
        let options = vec![b"Option A".to_vec(), b"Option B".to_vec()];

        // Too short
        assert_noop!(
            VotingModule::create_proposal(
                RuntimeOrigin::signed(1),
                description.clone(),
                options.clone(),
                5u64
            ),
            Error::<Test>::InvalidVotingPeriod
        );

        // Too long
        assert_noop!(
            VotingModule::create_proposal(
                RuntimeOrigin::signed(1),
                description,
                options,
                2000u64
            ),
            Error::<Test>::InvalidVotingPeriod
        );
    });
}

#[test]
fn vote_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        // Create a proposal first
        let description = b"Test proposal".to_vec();
        let options = vec![b"Option A".to_vec(), b"Option B".to_vec()];
        let voting_period = 100u64;

        assert_ok!(VotingModule::create_proposal(
            RuntimeOrigin::signed(1),
            description,
            options,
            voting_period
        ));

        // Vote on the proposal
        assert_ok!(VotingModule::vote(
            RuntimeOrigin::signed(2),
            0,
            0
        ));

        // Check that the vote was recorded
        let vote = VotingModule::votes(0, 2).unwrap();
        assert_eq!(vote.option_index, 0);
        assert_eq!(vote.weight, 1);

        // Check that the vote result was updated
        assert_eq!(VotingModule::vote_results(0, 0), 1);
        assert_eq!(VotingModule::vote_results(0, 1), 0);

        // Check that the event was emitted
        System::assert_last_event(Event::VoteCast {
            proposal_id: 0,
            voter: 2,
            option_index: 0,
        }.into());
    });
}

#[test]
fn vote_fails_with_nonexistent_proposal() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            VotingModule::vote(RuntimeOrigin::signed(1), 0, 0),
            Error::<Test>::ProposalNotFound
        );
    });
}

#[test]
fn vote_fails_with_invalid_option() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        // Create a proposal first
        let description = b"Test proposal".to_vec();
        let options = vec![b"Option A".to_vec(), b"Option B".to_vec()];
        let voting_period = 100u64;

        assert_ok!(VotingModule::create_proposal(
            RuntimeOrigin::signed(1),
            description,
            options,
            voting_period
        ));

        // Try to vote with invalid option index
        assert_noop!(
            VotingModule::vote(RuntimeOrigin::signed(2), 0, 2),
            Error::<Test>::InvalidOptionIndex
        );
    });
}

#[test]
fn vote_fails_when_already_voted() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        // Create a proposal first
        let description = b"Test proposal".to_vec();
        let options = vec![b"Option A".to_vec(), b"Option B".to_vec()];
        let voting_period = 100u64;

        assert_ok!(VotingModule::create_proposal(
            RuntimeOrigin::signed(1),
            description,
            options,
            voting_period
        ));

        // Vote once
        assert_ok!(VotingModule::vote(
            RuntimeOrigin::signed(2),
            0,
            0
        ));

        // Try to vote again
        assert_noop!(
            VotingModule::vote(RuntimeOrigin::signed(2), 0, 1),
            Error::<Test>::AlreadyVoted
        );
    });
}

#[test]
fn end_proposal_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        // Create a proposal
        let description = b"Test proposal".to_vec();
        let options = vec![b"Option A".to_vec(), b"Option B".to_vec()];
        let voting_period = 100u64;

        assert_ok!(VotingModule::create_proposal(
            RuntimeOrigin::signed(1),
            description,
            options,
            voting_period
        ));

        // Cast some votes
        assert_ok!(VotingModule::vote(RuntimeOrigin::signed(2), 0, 0));
        assert_ok!(VotingModule::vote(RuntimeOrigin::signed(3), 0, 0));
        assert_ok!(VotingModule::vote(RuntimeOrigin::signed(4), 0, 1));

        // Move past the voting period
        System::set_block_number(102);

        // End the proposal
        assert_ok!(VotingModule::end_proposal(RuntimeOrigin::signed(5), 0));

        // Check that the proposal is no longer active
        let proposal = VotingModule::proposals(0).unwrap();
        assert_eq!(proposal.is_active, false);

        // Check that the event was emitted with the correct winning option
        System::assert_last_event(Event::ProposalEnded {
            proposal_id: 0,
            winning_option: Some(0), // Option A won with 2 votes
        }.into());
    });
}

#[test]
fn cancel_proposal_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        // Create a proposal
        let description = b"Test proposal".to_vec();
        let options = vec![b"Option A".to_vec(), b"Option B".to_vec()];
        let voting_period = 100u64;

        assert_ok!(VotingModule::create_proposal(
            RuntimeOrigin::signed(1),
            description,
            options,
            voting_period
        ));

        // Cancel the proposal
        assert_ok!(VotingModule::cancel_proposal(RuntimeOrigin::signed(1), 0));

        // Check that the proposal is no longer active
        let proposal = VotingModule::proposals(0).unwrap();
        assert_eq!(proposal.is_active, false);

        // Check that the event was emitted
        System::assert_last_event(Event::ProposalCancelled {
            proposal_id: 0,
        }.into());
    });
}

#[test]
fn cancel_proposal_fails_when_not_proposer() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);
        
        // Create a proposal
        let description = b"Test proposal".to_vec();
        let options = vec![b"Option A".to_vec(), b"Option B".to_vec()];
        let voting_period = 100u64;

        assert_ok!(VotingModule::create_proposal(
            RuntimeOrigin::signed(1),
            description,
            options,
            voting_period
        ));

        // Try to cancel by someone else
        assert_noop!(
            VotingModule::cancel_proposal(RuntimeOrigin::signed(2), 0),
            Error::<Test>::NotProposer
        );
    });
}