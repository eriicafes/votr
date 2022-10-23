import { useUserData, useConnect, useDisconnect } from "@/stacks/auth"
import { Fruit, useVoteFruitContract } from "@/stacks/contracts"

export default function Home() {
  const user = useUserData()
  const connect = useConnect()
  const disconnect = useDisconnect()
  const contract = useVoteFruitContract()

  return (
    <div className="flex flex-col items-center justify-center gap-4 min-h-screen">
      <p className="font-bold text-xl">Hello Next Stacks</p>

      {user.isLoading ? (
        <p>Loading...</p>
      ) : user.isSuccess ? (
        <>
          <div className="flex flex-col items-center gap-1">
            <p className="text-sm text-gray-600">stxAddress</p>
            <p>{user.data.profile.stxAddress.testnet}</p>
          </div>

          <div className="flex items-center gap-4">
            <button
              className="bg-blue-600 text-white px-4 py-1.5 rounded-lg"
              onClick={() => contract.mutate(Fruit.Apple, {
                onSuccess(data) {
                  console.log("contract called:", data)
                }
              })}
            >
              Vote Apple
            </button>
            <button
              className="bg-blue-600 text-white px-4 py-1.5 rounded-lg"
              onClick={() => contract.mutate(Fruit.Orange, {
                onSuccess(data) {
                  console.log("contract called:", data)
                }
              })}
            >
              Vote Orange
            </button>
          </div>

          <button
            className="bg-blue-600 text-white px-4 py-1.5 rounded-lg"
            onClick={() => disconnect.mutate()}
          >
            Disconnect
          </button>
        </>
      ) : (
        <>
          <p>{(user.error as any).message}</p>

          <button
            className="bg-blue-600 text-white px-4 py-1.5 rounded-lg"
            onClick={() => connect.mutate()}
          >
            Connect
          </button>

          <div className="flex items-center gap-4">
            <button
              className="bg-blue-600 text-white px-4 py-1.5 rounded-lg"
              onClick={() => contract.mutate(Fruit.Apple)}
            >
              Vote Apple
            </button>
            <button
              className="bg-blue-600 text-white px-4 py-1.5 rounded-lg"
              onClick={() => contract.mutate(Fruit.Orange)}
            >
              Vote Orange
            </button>
          </div>
        </>
      )}
    </div>
  )
}
