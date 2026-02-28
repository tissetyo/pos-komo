/**
 * Shared composable to reliably get the authenticated user's profile and outlet ID.
 * Works around the issue where useSupabaseUser() returns truthy but .id is undefined
 * during SSR/hydration by using client.auth.getUser() as fallback.
 */
export const useUserProfile = () => {
    const client = useSupabaseClient()
    const user = useSupabaseUser()
    const outletId = ref<string | null>(null)
    const userId = ref<string | null>(null)
    const profileReady = ref(false)

    const loadProfile = async () => {
        // Try useSupabaseUser first
        let uid = user.value?.id

        // Fallback: get user from auth session
        if (!uid) {
            const { data } = await client.auth.getUser()
            uid = data?.user?.id
        }

        if (!uid) {
            profileReady.value = true
            return
        }

        userId.value = uid

        const { data: profile } = await client
            .from('profiles')
            .select('outlet_id')
            .eq('id', uid)
            .single()

        outletId.value = profile?.outlet_id || null
        profileReady.value = true
    }

    // Load on mount
    onMounted(loadProfile)

    // Also watch for user changes (e.g. after auth completes)
    watch(user, (val) => {
        if (val?.id && !outletId.value) loadProfile()
    })

    return { client, user, userId, outletId, profileReady, loadProfile }
}
