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
        // Check onboarding status
        const { data: profile } = await client
            .from('profiles')
            .select('onboarding_completed, role')
            .eq('id', user.value.id)
            .single()

        if (profile && !profile.onboarding_completed) {
            return navigateTo('/onboarding')
        }
        return navigateTo('/backoffice')
    }

    // If logged in and on protected route, check onboarding
    if (isProtected && user.value && to.path !== '/onboarding') {
        const { data: profile } = await client
            .from('profiles')
            .select('onboarding_completed')
            .eq('id', user.value.id)
            .single()

        if (profile && !profile.onboarding_completed) {
            return navigateTo('/onboarding')
        }
    }
})
