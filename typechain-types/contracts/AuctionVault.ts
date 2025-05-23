/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumberish,
  BytesLike,
  FunctionFragment,
  Result,
  Interface,
  EventFragment,
  AddressLike,
  ContractRunner,
  ContractMethod,
  Listener,
} from "ethers";
import type {
  TypedContractEvent,
  TypedDeferredTopicFilter,
  TypedEventLog,
  TypedLogDescription,
  TypedListener,
  TypedContractMethod,
} from "../common";

export interface AuctionVaultInterface extends Interface {
  getFunction(
    nameOrSignature:
      | "deposit"
      | "deposits"
      | "emergencyWithdraw"
      | "emergencyWithdrawalDelay"
      | "finalize"
      | "getDeposit"
      | "hasDeposit"
      | "operator"
      | "owner"
      | "pause"
      | "paused"
      | "refund"
      | "renounceOwnership"
      | "setEmergencyWithdrawalDelay"
      | "setOperator"
      | "transferOwnership"
      | "unpause"
  ): FunctionFragment;

  getEvent(
    nameOrSignatureOrTopic:
      | "Deposited"
      | "EmergencyWithdrawal"
      | "Finalized"
      | "OwnershipTransferred"
      | "Paused"
      | "Refunded"
      | "Unpaused"
      | "operatorUpdated"
  ): EventFragment;

  encodeFunctionData(
    functionFragment: "deposit",
    values: [BytesLike, AddressLike, AddressLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "deposits",
    values: [AddressLike, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "emergencyWithdraw",
    values: [BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "emergencyWithdrawalDelay",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "finalize",
    values: [BytesLike, AddressLike, AddressLike]
  ): string;
  encodeFunctionData(
    functionFragment: "getDeposit",
    values: [AddressLike, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "hasDeposit",
    values: [AddressLike, BytesLike]
  ): string;
  encodeFunctionData(functionFragment: "operator", values?: undefined): string;
  encodeFunctionData(functionFragment: "owner", values?: undefined): string;
  encodeFunctionData(functionFragment: "pause", values?: undefined): string;
  encodeFunctionData(functionFragment: "paused", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "refund",
    values: [BytesLike, AddressLike]
  ): string;
  encodeFunctionData(
    functionFragment: "renounceOwnership",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "setEmergencyWithdrawalDelay",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "setOperator",
    values: [AddressLike]
  ): string;
  encodeFunctionData(
    functionFragment: "transferOwnership",
    values: [AddressLike]
  ): string;
  encodeFunctionData(functionFragment: "unpause", values?: undefined): string;

  decodeFunctionResult(functionFragment: "deposit", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "deposits", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "emergencyWithdraw",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "emergencyWithdrawalDelay",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "finalize", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "getDeposit", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "hasDeposit", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "operator", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "pause", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "paused", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "refund", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "renounceOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setEmergencyWithdrawalDelay",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setOperator",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "transferOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "unpause", data: BytesLike): Result;
}

export namespace DepositedEvent {
  export type InputTuple = [
    auctionHash: BytesLike,
    bidder: AddressLike,
    amount: BigNumberish,
    token: AddressLike
  ];
  export type OutputTuple = [
    auctionHash: string,
    bidder: string,
    amount: bigint,
    token: string
  ];
  export interface OutputObject {
    auctionHash: string;
    bidder: string;
    amount: bigint;
    token: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace EmergencyWithdrawalEvent {
  export type InputTuple = [
    auctionHash: BytesLike,
    bidder: AddressLike,
    amount: BigNumberish,
    token: AddressLike
  ];
  export type OutputTuple = [
    auctionHash: string,
    bidder: string,
    amount: bigint,
    token: string
  ];
  export interface OutputObject {
    auctionHash: string;
    bidder: string;
    amount: bigint;
    token: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace FinalizedEvent {
  export type InputTuple = [
    auctionHash: BytesLike,
    seller: AddressLike,
    amount: BigNumberish,
    token: AddressLike
  ];
  export type OutputTuple = [
    auctionHash: string,
    seller: string,
    amount: bigint,
    token: string
  ];
  export interface OutputObject {
    auctionHash: string;
    seller: string;
    amount: bigint;
    token: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace OwnershipTransferredEvent {
  export type InputTuple = [previousOwner: AddressLike, newOwner: AddressLike];
  export type OutputTuple = [previousOwner: string, newOwner: string];
  export interface OutputObject {
    previousOwner: string;
    newOwner: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace PausedEvent {
  export type InputTuple = [account: AddressLike];
  export type OutputTuple = [account: string];
  export interface OutputObject {
    account: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace RefundedEvent {
  export type InputTuple = [
    auctionHash: BytesLike,
    bidder: AddressLike,
    amount: BigNumberish,
    token: AddressLike
  ];
  export type OutputTuple = [
    auctionHash: string,
    bidder: string,
    amount: bigint,
    token: string
  ];
  export interface OutputObject {
    auctionHash: string;
    bidder: string;
    amount: bigint;
    token: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace UnpausedEvent {
  export type InputTuple = [account: AddressLike];
  export type OutputTuple = [account: string];
  export interface OutputObject {
    account: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace operatorUpdatedEvent {
  export type InputTuple = [oldoperator: AddressLike, newoperator: AddressLike];
  export type OutputTuple = [oldoperator: string, newoperator: string];
  export interface OutputObject {
    oldoperator: string;
    newoperator: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export interface AuctionVault extends BaseContract {
  connect(runner?: ContractRunner | null): AuctionVault;
  waitForDeployment(): Promise<this>;

  interface: AuctionVaultInterface;

  queryFilter<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEventLog<TCEvent>>>;
  queryFilter<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEventLog<TCEvent>>>;

  on<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    listener: TypedListener<TCEvent>
  ): Promise<this>;
  on<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    listener: TypedListener<TCEvent>
  ): Promise<this>;

  once<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    listener: TypedListener<TCEvent>
  ): Promise<this>;
  once<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    listener: TypedListener<TCEvent>
  ): Promise<this>;

  listeners<TCEvent extends TypedContractEvent>(
    event: TCEvent
  ): Promise<Array<TypedListener<TCEvent>>>;
  listeners(eventName?: string): Promise<Array<Listener>>;
  removeAllListeners<TCEvent extends TypedContractEvent>(
    event?: TCEvent
  ): Promise<this>;

  deposit: TypedContractMethod<
    [
      auctionHash: BytesLike,
      bidder: AddressLike,
      token: AddressLike,
      amount: BigNumberish
    ],
    [void],
    "payable"
  >;

  deposits: TypedContractMethod<
    [arg0: AddressLike, arg1: BytesLike],
    [
      [string, string, bigint, boolean, bigint] & {
        bidder: string;
        token: string;
        amount: bigint;
        refunded: boolean;
        depositTime: bigint;
      }
    ],
    "view"
  >;

  emergencyWithdraw: TypedContractMethod<
    [auctionHash: BytesLike],
    [void],
    "nonpayable"
  >;

  emergencyWithdrawalDelay: TypedContractMethod<[], [bigint], "view">;

  finalize: TypedContractMethod<
    [auctionHash: BytesLike, seller: AddressLike, bidder: AddressLike],
    [void],
    "nonpayable"
  >;

  getDeposit: TypedContractMethod<
    [bidder: AddressLike, auctionHash: BytesLike],
    [
      [string, string, bigint, boolean, bigint] & {
        _bidder: string;
        _token: string;
        _amount: bigint;
        _refunded: boolean;
        _depositTime: bigint;
      }
    ],
    "view"
  >;

  hasDeposit: TypedContractMethod<
    [bidder: AddressLike, auctionHash: BytesLike],
    [boolean],
    "view"
  >;

  operator: TypedContractMethod<[], [string], "view">;

  owner: TypedContractMethod<[], [string], "view">;

  pause: TypedContractMethod<[], [void], "nonpayable">;

  paused: TypedContractMethod<[], [boolean], "view">;

  refund: TypedContractMethod<
    [auctionHash: BytesLike, bidder: AddressLike],
    [void],
    "nonpayable"
  >;

  renounceOwnership: TypedContractMethod<[], [void], "nonpayable">;

  setEmergencyWithdrawalDelay: TypedContractMethod<
    [_delay: BigNumberish],
    [void],
    "nonpayable"
  >;

  setOperator: TypedContractMethod<
    [_operator: AddressLike],
    [void],
    "nonpayable"
  >;

  transferOwnership: TypedContractMethod<
    [newOwner: AddressLike],
    [void],
    "nonpayable"
  >;

  unpause: TypedContractMethod<[], [void], "nonpayable">;

  getFunction<T extends ContractMethod = ContractMethod>(
    key: string | FunctionFragment
  ): T;

  getFunction(
    nameOrSignature: "deposit"
  ): TypedContractMethod<
    [
      auctionHash: BytesLike,
      bidder: AddressLike,
      token: AddressLike,
      amount: BigNumberish
    ],
    [void],
    "payable"
  >;
  getFunction(
    nameOrSignature: "deposits"
  ): TypedContractMethod<
    [arg0: AddressLike, arg1: BytesLike],
    [
      [string, string, bigint, boolean, bigint] & {
        bidder: string;
        token: string;
        amount: bigint;
        refunded: boolean;
        depositTime: bigint;
      }
    ],
    "view"
  >;
  getFunction(
    nameOrSignature: "emergencyWithdraw"
  ): TypedContractMethod<[auctionHash: BytesLike], [void], "nonpayable">;
  getFunction(
    nameOrSignature: "emergencyWithdrawalDelay"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "finalize"
  ): TypedContractMethod<
    [auctionHash: BytesLike, seller: AddressLike, bidder: AddressLike],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "getDeposit"
  ): TypedContractMethod<
    [bidder: AddressLike, auctionHash: BytesLike],
    [
      [string, string, bigint, boolean, bigint] & {
        _bidder: string;
        _token: string;
        _amount: bigint;
        _refunded: boolean;
        _depositTime: bigint;
      }
    ],
    "view"
  >;
  getFunction(
    nameOrSignature: "hasDeposit"
  ): TypedContractMethod<
    [bidder: AddressLike, auctionHash: BytesLike],
    [boolean],
    "view"
  >;
  getFunction(
    nameOrSignature: "operator"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "owner"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "pause"
  ): TypedContractMethod<[], [void], "nonpayable">;
  getFunction(
    nameOrSignature: "paused"
  ): TypedContractMethod<[], [boolean], "view">;
  getFunction(
    nameOrSignature: "refund"
  ): TypedContractMethod<
    [auctionHash: BytesLike, bidder: AddressLike],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "renounceOwnership"
  ): TypedContractMethod<[], [void], "nonpayable">;
  getFunction(
    nameOrSignature: "setEmergencyWithdrawalDelay"
  ): TypedContractMethod<[_delay: BigNumberish], [void], "nonpayable">;
  getFunction(
    nameOrSignature: "setOperator"
  ): TypedContractMethod<[_operator: AddressLike], [void], "nonpayable">;
  getFunction(
    nameOrSignature: "transferOwnership"
  ): TypedContractMethod<[newOwner: AddressLike], [void], "nonpayable">;
  getFunction(
    nameOrSignature: "unpause"
  ): TypedContractMethod<[], [void], "nonpayable">;

  getEvent(
    key: "Deposited"
  ): TypedContractEvent<
    DepositedEvent.InputTuple,
    DepositedEvent.OutputTuple,
    DepositedEvent.OutputObject
  >;
  getEvent(
    key: "EmergencyWithdrawal"
  ): TypedContractEvent<
    EmergencyWithdrawalEvent.InputTuple,
    EmergencyWithdrawalEvent.OutputTuple,
    EmergencyWithdrawalEvent.OutputObject
  >;
  getEvent(
    key: "Finalized"
  ): TypedContractEvent<
    FinalizedEvent.InputTuple,
    FinalizedEvent.OutputTuple,
    FinalizedEvent.OutputObject
  >;
  getEvent(
    key: "OwnershipTransferred"
  ): TypedContractEvent<
    OwnershipTransferredEvent.InputTuple,
    OwnershipTransferredEvent.OutputTuple,
    OwnershipTransferredEvent.OutputObject
  >;
  getEvent(
    key: "Paused"
  ): TypedContractEvent<
    PausedEvent.InputTuple,
    PausedEvent.OutputTuple,
    PausedEvent.OutputObject
  >;
  getEvent(
    key: "Refunded"
  ): TypedContractEvent<
    RefundedEvent.InputTuple,
    RefundedEvent.OutputTuple,
    RefundedEvent.OutputObject
  >;
  getEvent(
    key: "Unpaused"
  ): TypedContractEvent<
    UnpausedEvent.InputTuple,
    UnpausedEvent.OutputTuple,
    UnpausedEvent.OutputObject
  >;
  getEvent(
    key: "operatorUpdated"
  ): TypedContractEvent<
    operatorUpdatedEvent.InputTuple,
    operatorUpdatedEvent.OutputTuple,
    operatorUpdatedEvent.OutputObject
  >;

  filters: {
    "Deposited(bytes32,address,uint256,address)": TypedContractEvent<
      DepositedEvent.InputTuple,
      DepositedEvent.OutputTuple,
      DepositedEvent.OutputObject
    >;
    Deposited: TypedContractEvent<
      DepositedEvent.InputTuple,
      DepositedEvent.OutputTuple,
      DepositedEvent.OutputObject
    >;

    "EmergencyWithdrawal(bytes32,address,uint256,address)": TypedContractEvent<
      EmergencyWithdrawalEvent.InputTuple,
      EmergencyWithdrawalEvent.OutputTuple,
      EmergencyWithdrawalEvent.OutputObject
    >;
    EmergencyWithdrawal: TypedContractEvent<
      EmergencyWithdrawalEvent.InputTuple,
      EmergencyWithdrawalEvent.OutputTuple,
      EmergencyWithdrawalEvent.OutputObject
    >;

    "Finalized(bytes32,address,uint256,address)": TypedContractEvent<
      FinalizedEvent.InputTuple,
      FinalizedEvent.OutputTuple,
      FinalizedEvent.OutputObject
    >;
    Finalized: TypedContractEvent<
      FinalizedEvent.InputTuple,
      FinalizedEvent.OutputTuple,
      FinalizedEvent.OutputObject
    >;

    "OwnershipTransferred(address,address)": TypedContractEvent<
      OwnershipTransferredEvent.InputTuple,
      OwnershipTransferredEvent.OutputTuple,
      OwnershipTransferredEvent.OutputObject
    >;
    OwnershipTransferred: TypedContractEvent<
      OwnershipTransferredEvent.InputTuple,
      OwnershipTransferredEvent.OutputTuple,
      OwnershipTransferredEvent.OutputObject
    >;

    "Paused(address)": TypedContractEvent<
      PausedEvent.InputTuple,
      PausedEvent.OutputTuple,
      PausedEvent.OutputObject
    >;
    Paused: TypedContractEvent<
      PausedEvent.InputTuple,
      PausedEvent.OutputTuple,
      PausedEvent.OutputObject
    >;

    "Refunded(bytes32,address,uint256,address)": TypedContractEvent<
      RefundedEvent.InputTuple,
      RefundedEvent.OutputTuple,
      RefundedEvent.OutputObject
    >;
    Refunded: TypedContractEvent<
      RefundedEvent.InputTuple,
      RefundedEvent.OutputTuple,
      RefundedEvent.OutputObject
    >;

    "Unpaused(address)": TypedContractEvent<
      UnpausedEvent.InputTuple,
      UnpausedEvent.OutputTuple,
      UnpausedEvent.OutputObject
    >;
    Unpaused: TypedContractEvent<
      UnpausedEvent.InputTuple,
      UnpausedEvent.OutputTuple,
      UnpausedEvent.OutputObject
    >;

    "operatorUpdated(address,address)": TypedContractEvent<
      operatorUpdatedEvent.InputTuple,
      operatorUpdatedEvent.OutputTuple,
      operatorUpdatedEvent.OutputObject
    >;
    operatorUpdated: TypedContractEvent<
      operatorUpdatedEvent.InputTuple,
      operatorUpdatedEvent.OutputTuple,
      operatorUpdatedEvent.OutputObject
    >;
  };
}
