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
use super::ICounter;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        counter: u32,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CounterIncreased: CounterIncreased,
        CounterDecreased: CounterDecreased,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CounterIncreased {
        counter: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CounterDecreased {
        counter: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState, init_value: u32) {
        self.counter.write(init_value);
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
            self.counter.write(init_counter - 1);
            let new_counter = self.counter.read();
            self.emit(CounterDecreased { counter: new_counter });
        }

        fn reset_counter(ref self: ContractState) {
            self.counter.write(0);
        }
    }
}
