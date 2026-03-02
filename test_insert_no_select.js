import { createClient } from '@supabase/supabase-js'
import dotenv from 'dotenv'
dotenv.config()

const supabaseUrl = process.env.SUPABASE_URL || process.env.NUXT_PUBLIC_SUPABASE_URL
const supabaseAnonKey = process.env.SUPABASE_KEY || process.env.NUXT_PUBLIC_SUPABASE_KEY

if (!supabaseUrl || !supabaseAnonKey) {
    console.error("Missing supabase credentials in env")
    process.exit(1)
}

const client = createClient(supabaseUrl, supabaseAnonKey)

async function test() {
    console.log("Testing insert on orders...")

    // Get an outlet id first since it's required
    const { data: outlets } = await client.from('outlets').select('id').limit(1)
    const outletId = outlets?.[0]?.id

    const { data, error } = await client.from('orders').insert({
        receipt_number: "TEST-" + Date.now(),
        outlet_id: outletId,
        source: 'qr',
        subtotal: 100,
        tax: 0,
        total: 100,
        payment_method: 'cash',
        payment_status: 'pending',
        order_status: 'new',
        order_type: 'dine-in'
    }) // WITHOUT .select()

    if (error) {
        console.error("Order Insert Error WITHOUT select():", error.message, error.details || '')
    } else {
        console.log("Order Insert Success WITHOUT select():", data)
    }
}

test()
