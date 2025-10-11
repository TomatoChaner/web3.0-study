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

        /// Maximum number of options per proposal
        #[pallet::constant]
        type MaxOptions: Get<u32>;

        /// Maximum length of proposal description
        #[pallet::constant]
        type MaxDescriptionLength: Get<u32>;

        /// Minimum voting period in blocks
        #[pallet::constant]
        type MinVotingPeriod: Get<BlockNumberFor<Self>>;

        /// Maximum voting period in blocks
        #[pallet::constant]
        type MaxVotingPeriod: Get<BlockNumberFor<Self>>;
    }

    /// Proposal information
    #[derive(Clone, PartialEq, Eq, Encode, Decode, RuntimeDebug, TypeInfo)]
    pub struct ProposalInfo<AccountId, BlockNumber> {
        /// Proposal creator
        pub proposer: AccountId,
        /// Proposal description
        pub description: Vec<u8>,
        /// Voting options
        pub options: Vec<Vec<u8>>,
        /// Voting start block
        pub start_block: BlockNumber,
        /// Voting end block
        pub end_block: BlockNumber,
        /// Whether the proposal is active
        pub is_active: bool,
    }

    /// Vote information
    #[derive(Clone, PartialEq, Eq, Encode, Decode, RuntimeDebug, TypeInfo)]
    pub struct VoteInfo {
        /// Selected option index
        pub option_index: u32,
        /// Vote weight (could be balance-based in future)
        pub weight: u32,
    }

    /// Storage for proposals
    #[pallet::storage]
    #[pallet::getter(fn proposals)]
    pub type Proposals<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        u32,
        ProposalInfo<T::AccountId, BlockNumberFor<T>>,
        OptionQuery,
    >;

    /// Storage for votes
    #[pallet::storage]
    #[pallet::getter(fn votes)]
    pub type Votes<T: Config> = StorageDoubleMap<
        _,
        Blake2_128Concat,
        u32, // proposal_id
        Blake2_128Concat,
        T::AccountId, // voter
        VoteInfo,
        OptionQuery,
    >;

    /// Storage for vote results
    #[pallet::storage]
    #[pallet::getter(fn vote_results)]
    pub type VoteResults<T: Config> = StorageDoubleMap<
        _,
        Blake2_128Concat,
        u32, // proposal_id
        Blake2_128Concat,
        u32, // option_index
        u32, // vote_count
        ValueQuery,
    >;

    /// Next proposal ID
    #[pallet::storage]
    #[pallet::getter(fn next_proposal_id)]
    pub type NextProposalId<T> = StorageValue<_, u32, ValueQuery>;

    /// Pallets use events to inform users when important changes are made.
    /// https://docs.substrate.io/main-docs/build/events-errors/
    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// A new proposal has been created
        ProposalCreated {
            proposal_id: u32,
            proposer: T::AccountId,
            description: Vec<u8>,
        },
        /// A vote has been cast
        VoteCast {
            proposal_id: u32,
            voter: T::AccountId,
            option_index: u32,
        },
        /// A proposal has ended
        ProposalEnded {
            proposal_id: u32,
            winning_option: Option<u32>,
        },
        /// A proposal has been cancelled
        ProposalCancelled {
            proposal_id: u32,
        },
    }

    // Errors inform users that something went wrong.
    #[pallet::error]
    pub enum Error<T> {
        /// Proposal does not exist
        ProposalNotFound,
        /// Proposal is not active
        ProposalNotActive,
        /// Voting period has ended
        VotingPeriodEnded,
        /// Voting period has not started
        VotingPeriodNotStarted,
        /// Invalid option index
        InvalidOptionIndex,
        /// User has already voted
        AlreadyVoted,
        /// Too many options
        TooManyOptions,
        /// Description too long
        DescriptionTooLong,
        /// Invalid voting period
        InvalidVotingPeriod,
        /// Not the proposer
        NotProposer,
        /// No options provided
        NoOptions,
    }

    // Dispatchable functions allow users to interact with the pallet and invoke state changes.
    // These functions materialize as "extrinsics", which are often compared to transactions.
    // Dispatchable functions must be annotated with a weight and must return a DispatchResult.
    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Create a new proposal
        #[pallet::call_index(0)]
        #[pallet::weight(T::WeightInfo::create_proposal())]
        pub fn create_proposal(
            origin: OriginFor<T>,
            description: Vec<u8>,
            options: Vec<Vec<u8>>,
            voting_period: BlockNumberFor<T>,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            // Validate inputs
            ensure!(!options.is_empty(), Error::<T>::NoOptions);
            ensure!(
                options.len() <= T::MaxOptions::get() as usize,
                Error::<T>::TooManyOptions
            );
            ensure!(
                description.len() <= T::MaxDescriptionLength::get() as usize,
                Error::<T>::DescriptionTooLong
            );
            ensure!(
                voting_period >= T::MinVotingPeriod::get() &&
                voting_period <= T::MaxVotingPeriod::get(),
                Error::<T>::InvalidVotingPeriod
            );

            let proposal_id = Self::next_proposal_id();
            let current_block = <frame_system::Pallet<T>>::block_number();
            let end_block = current_block.saturating_add(voting_period);

            let proposal = ProposalInfo {
                proposer: who.clone(),
                description: description.clone(),
                options,
                start_block: current_block,
                end_block,
                is_active: true,
            };

            Proposals::<T>::insert(&proposal_id, &proposal);
            NextProposalId::<T>::put(proposal_id.saturating_add(1));

            Self::deposit_event(Event::ProposalCreated {
                proposal_id,
                proposer: who,
                description,
            });

            Ok(())
        }

        /// Cast a vote on a proposal
        #[pallet::call_index(1)]
        #[pallet::weight(T::WeightInfo::vote())]
        pub fn vote(
            origin: OriginFor<T>,
            proposal_id: u32,
            option_index: u32,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            let proposal = Self::proposals(&proposal_id).ok_or(Error::<T>::ProposalNotFound)?;
            ensure!(proposal.is_active, Error::<T>::ProposalNotActive);

            let current_block = <frame_system::Pallet<T>>::block_number();
            ensure!(current_block >= proposal.start_block, Error::<T>::VotingPeriodNotStarted);
            ensure!(current_block <= proposal.end_block, Error::<T>::VotingPeriodEnded);

            ensure!(
                option_index < proposal.options.len() as u32,
                Error::<T>::InvalidOptionIndex
            );

            ensure!(
                !Votes::<T>::contains_key(&proposal_id, &who),
                Error::<T>::AlreadyVoted
            );

            let vote_info = VoteInfo {
                option_index,
                weight: 1, // Simple 1-person-1-vote for now
            };

            Votes::<T>::insert(&proposal_id, &who, &vote_info);
            
            // Update vote results
            let current_count = Self::vote_results(&proposal_id, &option_index);
            VoteResults::<T>::insert(&proposal_id, &option_index, current_count.saturating_add(1));

            Self::deposit_event(Event::VoteCast {
                proposal_id,
                voter: who,
                option_index,
            });

            Ok(())
        }

        /// End a proposal (can be called by anyone after voting period)
        #[pallet::call_index(2)]
        #[pallet::weight(T::WeightInfo::end_proposal())]
        pub fn end_proposal(
            origin: OriginFor<T>,
            proposal_id: u32,
        ) -> DispatchResult {
            let _who = ensure_signed(origin)?;

            let mut proposal = Self::proposals(&proposal_id).ok_or(Error::<T>::ProposalNotFound)?;
            ensure!(proposal.is_active, Error::<T>::ProposalNotActive);

            let current_block = <frame_system::Pallet<T>>::block_number();
            ensure!(current_block > proposal.end_block, Error::<T>::VotingPeriodEnded);

            proposal.is_active = false;
            Proposals::<T>::insert(&proposal_id, &proposal);

            // Find winning option
            let mut max_votes = 0u32;
            let mut winning_option: Option<u32> = None;

            for i in 0..proposal.options.len() as u32 {
                let votes = Self::vote_results(&proposal_id, &i);
                if votes > max_votes {
                    max_votes = votes;
                    winning_option = Some(i);
                }
            }

            Self::deposit_event(Event::ProposalEnded {
                proposal_id,
                winning_option,
            });

            Ok(())
        }

        /// Cancel a proposal (only by proposer)
        #[pallet::call_index(3)]
        #[pallet::weight(T::WeightInfo::cancel_proposal())]
        pub fn cancel_proposal(
            origin: OriginFor<T>,
            proposal_id: u32,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            let mut proposal = Self::proposals(&proposal_id).ok_or(Error::<T>::ProposalNotFound)?;
            ensure!(proposal.is_active, Error::<T>::ProposalNotActive);
            ensure!(proposal.proposer == who, Error::<T>::NotProposer);

            proposal.is_active = false;
            Proposals::<T>::insert(&proposal_id, &proposal);

            Self::deposit_event(Event::ProposalCancelled {
                proposal_id,
            });

            Ok(())
        }
    }

    impl<T: Config> Pallet<T> {
        /// Get proposal details
        pub fn get_proposal(proposal_id: u32) -> Option<ProposalInfo<T::AccountId, BlockNumberFor<T>>> {
            Self::proposals(&proposal_id)
        }

        /// Get vote results for a proposal
        pub fn get_vote_results(proposal_id: u32) -> Vec<u32> {
            let proposal = match Self::proposals(&proposal_id) {
                Some(p) => p,
                None => return Vec::new(),
            };

            let mut results = Vec::new();
            for i in 0..proposal.options.len() as u32 {
                results.push(Self::vote_results(&proposal_id, &i));
            }
            results
        }

        /// Check if user has voted on a proposal
        pub fn has_voted(proposal_id: u32, account: &T::AccountId) -> bool {
            Votes::<T>::contains_key(&proposal_id, account)
        }
    }
}