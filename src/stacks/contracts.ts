import { AnchorMode, stringUtf8CV, PostConditionMode, StringUtf8CV } from "@stacks/transactions"
import { StacksTestnet } from "@stacks/network"
import { useMutation } from "@tanstack/react-query"
import { ContractCallMethods, namespaceContract } from "./utils"

export enum Fruit {
    Apple = "🍎",
    Orange = "🍊",
}

interface VoteFruitCall extends ContractCallMethods {
    vote: {
        functionName: "vote"
        functionArgs: [StringUtf8CV]
    },
}

export const voteFruitContract = namespaceContract<VoteFruitCall>("ST39MJ145BR6S8C315AG2BD61SJ16E208P1FDK3AK", "example-fruit-vote-contract")

export const useVoteFruitContract = () => useMutation((fruit: Fruit) => {
    return voteFruitContract.call.vote({
        network: new StacksTestnet(),
        anchorMode: AnchorMode.Any,
        functionName: "vote",
        functionArgs: [stringUtf8CV(fruit)],
        postConditionMode: PostConditionMode.Deny,
        postConditions: [],
    })
})
