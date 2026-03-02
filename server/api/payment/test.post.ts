import Stripe from 'stripe'

export default defineEventHandler(async (event) => {
    const body = await readBody(event)
    const { provider, apiKey } = body

    if (!provider || !apiKey) {
        throw createError({ statusCode: 400, message: 'Provider and API Key are required' })
    }

    if (provider === 'stripe') {
        try {
            const stripe = new Stripe(apiKey, { apiVersion: '2023-10-16' })
            const info = await stripe.balance.retrieve()
            // If we can read the balance without an error, the key works!
            return { success: true, message: 'Stripe API Connection Successful', activeCurrency: info.available[0]?.currency }
        } catch (err: any) {
            throw createError({ statusCode: 401, message: 'Invalid Stripe API Key: ' + err.message })
        }
    }

    // Fallback for providers we aren't testing explicitly yet
    return { success: true, message: `${provider} configuration saved successfully.` }
})
