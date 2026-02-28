export default defineNuxtRouteMiddleware(async (to) => {
    const user = useSupabaseUser()
    const client = useSupabaseClient()

    const protectedRoutes = ['/backoffice', '/cashier', '/onboarding']
    const isProtected = protectedRoutes.some(r => to.path.startsWith(r))
    const isAuthPage = to.path === '/login' || to.path === '/register'

    // If trying to access protected route without auth, redirect to login
    if (isProtected && !user.value) {
        return navigateTo('/login')
    }

    // If logged in and on auth page, redirect away
    if (isAuthPage && user.value) {
        return navigateTo('/backoffice')
    }

    // Check onboarding ONLY when navigating to backoffice or cashier (not on every route)
    if (isProtected && user.value && to.path !== '/onboarding') {
        // Use a cookie to cache onboarding status so we don't query on every navigation
        const onboardingDone = useCookie('onboarding_done')

        if (onboardingDone.value === 'true') return // Already verified

        const { data: profile } = await client
            .from('profiles')
            .select('onboarding_completed')
            .eq('id', user.value.id)
            .single()

        if (profile && !profile.onboarding_completed) {
            return navigateTo('/onboarding')
        }

        // Cache the result so we don't check again
        onboardingDone.value = 'true'
    }
})
