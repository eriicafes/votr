import { ContractCallRegularOptions, FinishedTxData, openContractCall } from "@stacks/connect"
import { ClarityValue, callReadOnlyFunction, ReadOnlyFunctionOptions } from "@stacks/transactions"

export type ContractCallSignature = { functionName: string, functionArgs: ClarityValue[] }
export type ContractCallMethods = Record<string, ContractCallSignature>
export type ContractCallOptions<Args extends ClarityValue[]> = Omit<ContractCallRegularOptions, "onFinish" | "onCancel" | "functionArgs"> & {
    functionArgs: Args
}

export type ContractReadOnlySignature = { functionName: string, functionArgs: ClarityValue[], result: ClarityValue }
export type ContractReadOnlyMethods = Record<string, ContractReadOnlySignature>
export type ContractReadOnlyOptions<Args extends ClarityValue[]> = Omit<ReadOnlyFunctionOptions, "functionArgs"> & {
    functionArgs: Args
}

// namespace
export type NamespacedContractCallOptions<Signature extends ContractCallSignature> = Omit<ContractCallOptions<Signature["functionArgs"]>, "contractAddress" | "contractName" | "functionName"> & {
    functionName: Signature["functionName"]
}
export type NamespacedContractCallFn<Signature extends ContractCallSignature> = (options: NamespacedContractCallOptions<Signature>) => Promise<FinishedTxData>
type NamespacedCall<Signatures extends Record<string, ContractCallSignature>> = { [K in keyof Signatures]: NamespacedContractCallFn<Signatures[K]> }

export type NamespacedContractReadOnlyOptions<Signature extends ContractReadOnlySignature> = Omit<ContractReadOnlyOptions<Signature["functionArgs"]>, "contractAddress" | "contractName" | "functionName"> & {
    functionName: Signature["functionName"]
}
export type NamespacedContractReadOnlyFn<Signature extends ContractReadOnlySignature> = (options: NamespacedContractReadOnlyOptions<Signature>) => Promise<Signature["result"]>
type NamespacedReadOnly<Signatures extends Record<string, ContractReadOnlySignature>> = { [K in keyof Signatures]: NamespacedContractCallFn<Signatures[K]> }

export type NamespacedContract<Call extends Record<string, ContractCallSignature>, ReadOnly extends Record<string, ContractReadOnlySignature>> = {
    call: NamespacedCall<Call>
    readOnly: NamespacedReadOnly<ReadOnly>
}

export function callContract<Args extends ClarityValue[]>(options: ContractCallOptions<Args>) {
    return new Promise<FinishedTxData>((resolve, reject) => {
        openContractCall({
            ...options,
            onFinish: resolve,
            onCancel: reject,
        })
    })
}

export function callReadOnly<Args extends ClarityValue[], Res extends ClarityValue>(options: ContractReadOnlyOptions<Args>) {
    return callReadOnlyFunction(options) as Promise<Res>
}

export function namespaceContract<
    Call extends Record<string, ContractCallSignature> = {},
    ReadOnly extends Record<string, ContractReadOnlySignature> = {},
>(contractAddress: string, contractName: string): NamespacedContract<Call, ReadOnly> {
    return {
        call: new Proxy({} as NamespacedCall<Call>, {
            get() {
                return (options: NamespacedContractCallOptions<ContractCallSignature>) => callContract({
                    ...options,
                    contractAddress,
                    contractName,
                })
            }
        }),
        readOnly: new Proxy({} as NamespacedReadOnly<ReadOnly>, {
            get() {
                return (options: NamespacedContractReadOnlyOptions<ContractReadOnlySignature>) => callReadOnly({
                    ...options,
                    contractAddress,
                    contractName,
                })
            }
        })
    }
}
