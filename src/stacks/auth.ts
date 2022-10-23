import { AppConfig, FinishedAuthData, showConnect, UserSession } from "@stacks/connect";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query"

export const userSession = new UserSession({
    appConfig: new AppConfig(["store_write", "publish_data"])
})

export function loadUserData() {
    return userSession.loadUserData()
}

export function connect() {
    return new Promise<FinishedAuthData>((resolve, reject) => {
        showConnect({
            appDetails: {
                name: "Next Stacks",
                icon: window.location.origin + "/vercel.svg",
            },
            onFinish: resolve,
            onCancel: reject,
            userSession,
        });
    })
}

export async function disconnect() {
    return userSession.signUserOut()
}

export const useUserData = () => useQuery(["stacks"], loadUserData, { retry: false })

export const useConnect = () => {
    const queryClient = useQueryClient()

    return useMutation(connect, {
        onSuccess() {
            return queryClient.invalidateQueries(["stacks"])
        }
    })
}

export const useDisconnect = () => {
    const queryClient = useQueryClient()

    return useMutation(disconnect, {
        onSuccess() {
            return queryClient.invalidateQueries(["stacks"])
        }
    })
}
