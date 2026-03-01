/**
 * Shared composable to reliably get the authenticated user's profile and outlet.
 * Works around the issue where useSupabaseUser() returns truthy but .id is undefined
 * during SSR/hydration by using client.auth.getUser() as fallback.
 */
export const useUserProfile = () => {
    const client = useSupabaseClient()
    const user = useSupabaseUser()
    const outletId = ref<string | null>(null)
    const outlet = ref<any>(null)
    const userId = ref<string | null>(null)
    const profile = ref<any>(null)
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

        const { data: profileData } = await client
            .from('profiles')
            .select('*, outlets(*)')
            .eq('id', uid)
            .single()

        profile.value = profileData
        outletId.value = profileData?.outlet_id || null
        outlet.value = profileData?.outlets || null
        profileReady.value = true
    }

    // Load on mount
    onMounted(loadProfile)

    // Also watch for user changes (e.g. after auth completes)
    watch(user, (val) => {
        if (val?.id && !outletId.value) loadProfile()
    })

    return { client, user, userId, outletId, outlet, profile, profileReady, loadProfile }
}

