import { serverSupabaseClient } from '#supabase/server'
import Stripe from 'stripe'

export default defineEventHandler(async (event) => {
    const body = await readBody(event)
    const { orderId } = body

    if (!orderId) {
        throw createError({ statusCode: 400, message: 'Order ID is required' })
    }

    const client = await serverSupabaseClient(event)

    // Fetch the order and its outlet's integrations
    const { data: order, error: orderErr } = await client
        .from('orders')
        .select('*, outlets(integrations, currency), order_items(quantity, unit_price, product:products(name))')
        .eq('id', orderId)
        .single()

    if (orderErr || !order) {
        throw createError({ statusCode: 404, message: 'Order not found' })
    }

    if (order.payment_status === 'paid') {
        throw createError({ statusCode: 400, message: 'Order is already paid' })
    }

    const integrations = (order.outlets as any)?.integrations || {}
    const stripeConfig = integrations.stripe

    if (!stripeConfig || !stripeConfig.connected || !stripeConfig.apiKey) {
        throw createError({ statusCode: 400, message: 'This store does not accept Stripe payments.' })
    }

    const stripe = new Stripe(stripeConfig.apiKey, { apiVersion: '2023-10-16' })
    const currency = ((order.outlets as any)?.currency || 'myr').toLowerCase()

    // Build line items for Stripe
    const lineItems = (order.order_items || []).map((item: any) => {
        return {
            price_data: {
                currency: currency,
                product_data: {
                    name: item.product?.name || 'Item',
                },
                unit_amount: Math.round(item.unit_price * 100), // Stripe uses smallest currency unit (cents)
            },
            quantity: item.quantity,
        }
    })

    // Add Tax if applicable
    if (order.tax > 0) {
        lineItems.push({
            price_data: {
                currency: currency,
                product_data: { name: 'Tax / Fee' },
                unit_amount: Math.round(order.tax * 100)
            },
            quantity: 1
        })
    }

    try {
        const session = await stripe.checkout.sessions.create({
            payment_method_types: ['card'],
            line_items: lineItems,
            mode: 'payment',
            success_url: `${process.env.NUXT_PUBLIC_SITE_URL || 'http://localhost:3000'}/payment/success?session_id={CHECKOUT_SESSION_ID}&order_id=${orderId}`,
            cancel_url: `${process.env.NUXT_PUBLIC_SITE_URL || 'http://localhost:3000'}/order/${order.qr_token || ''}`, // Assuming normal redirect handling later
            metadata: {
                orderId: orderId,
            },
        })

        return { url: session.url }
    } catch (err: any) {
        throw createError({ statusCode: 500, message: 'Stripe Session Error: ' + err.message })
    }
})
