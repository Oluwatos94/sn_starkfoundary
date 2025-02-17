#[starknet::interface]
trait ICounter<T> {
    fn get_counter(self: @T) -> u32;
    fn increase_counter(ref self: T);
    fn decrease_counter(ref self: T);
    fn reset_counter(ref self: T);
}

#[starknet::contract]
mod Counter {
    use starknet::event::EventEmitter;
    use starknet::ContractAddress;
    use openzeppelin_access::ownable::OwnableComponent;
    use super::ICounter;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        counter: u32,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CounterIncreased: CounterIncreased,
        CounterDecreased: CounterDecreased,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    pub struct CounterIncreased {
        counter: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CounterDecreased {
        counter: u32,
    }

    pub mod ERRORS {
        pub const NEGATIVE_COUNTER: felt252 = 'Counter can\'t be negative';
    }

    #[constructor]
    fn constructor(ref self: ContractState, init_value: u32, owner: ContractAddress) {
        self.counter.write(init_value);
        // Invoke ownable's `initializer`
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl CounterImpl of ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState) {
            let init_counter = self.counter.read();
            self.counter.write(init_counter + 1);
            let new_counter = self.counter.read();
            self.emit(CounterIncreased { counter: new_counter });
        }

        fn decrease_counter(ref self: ContractState) {
            let init_counter = self.counter.read();
            assert(init_counter > 0, ERRORS::NEGATIVE_COUNTER);
            self.counter.write(init_counter - 1);
            let new_counter = self.counter.read();
            self.emit(CounterDecreased { counter: new_counter });
        }

        fn reset_counter(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.counter.write(0);
        }
    }
}
