import { StringAsciiCV, PrincipalCV, UIntCV, ListCV, TupleCV } from "@stacks/transactions"
import { ContractCallMethods, ContractReadOnlyMethods, namespaceContract } from "./utils"

interface VotrCall extends ContractCallMethods {
    register: {
        functionName: "register"
        functionArgs: [
            StringAsciiCV, // organization name
            PrincipalCV, // address
        ]
    },
    createElection: {
        functionName: "create-election"
        functionArgs: [
            StringAsciiCV, // organization
            StringAsciiCV, // title
            UIntCV, // total voters
            ListCV<TupleCV<{ address: PrincipalCV, name: StringAsciiCV }>>, // contestants
        ]
    },
    authorizeVoters: {
        functionName: "authorize-voters"
        functionArgs: [
            StringAsciiCV, // organization
            UIntCV, // election-id
            ListCV<PrincipalCV>, // voters
        ]
    },
    startElection: {
        functionName: "start-election" // organization
        functionArgs: [
            StringAsciiCV, // organization
            UIntCV, // election-id
            UIntCV, // expiration
        ]
    },
    vote: {
        functionName: "vote"
        functionArgs: [
            StringAsciiCV, // organization
            UIntCV, // election-id
            PrincipalCV, // contestant
            UIntCV, // invitation id
        ]
    },
    endVote: {
        functionName: "end-vote"
        functionArgs: [
            StringAsciiCV, // organization
            UIntCV, // election-id
        ]
    },
}

interface VotrReadOnly extends ContractReadOnlyMethods {
    checkElection: {
        functionName: "check-election"
        functionArgs: [
            StringAsciiCV, // organization
            UIntCV, // election-id
        ],
        result: ListCV<TupleCV<{ address: PrincipalCV, name: StringAsciiCV, votes: UIntCV }>>
    }
}

export const votrContract = namespaceContract<VotrCall, VotrReadOnly>("ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM", "votr")
