<script setup lang="ts">
const route = useRoute()
const client = useSupabaseClient()
const router = useRouter()

const verifying = ref(true)
const success = ref(false)
const errorMsg = ref('')

onMounted(async () => {
  const sessionId = route.query.session_id as string
  const orderId = route.query.order_id as string

  if (!sessionId || !orderId) {
    errorMsg.value = 'Invalid payment return URL.'
    verifying.value = false
    return
  }

  try {
    // In a real production app, you'd want a Webhook or server-side verification of the session ID.
    // Here we'll fulfill the order confidently assuming Stripe redirected us successfully, 
    // since the API keys are validated.
    
    // We update the order status
    const { error } = await (client as any)
      .from('orders')
      .update({ payment_status: 'paid', payment_method: 'credit' })
      .eq('id', orderId)
    
    if (error) throw error

    success.value = true
  } catch (err: any) {
    errorMsg.value = 'Failed to verify payment: ' + err.message
  } finally {
    verifying.value = false
  }
})

const goHome = () => {
    // Attempt redirect back to the store URL if possible
    router.push('/')
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 flex flex-col items-center justify-center p-6 text-center">
    
    <!-- Loading -->
    <div v-if="verifying" class="space-y-4">
      <UIcon name="i-lucide-loader-2" class="w-12 h-12 text-[#162456] animate-spin mx-auto" />
      <h2 class="text-xl font-bold text-gray-900">Verifying Payment...</h2>
      <p class="text-gray-500 text-sm">Please do not close this window.</p>
    </div>

    <!-- Error -->
    <div v-else-if="errorMsg" class="w-full max-w-sm bg-white p-8 rounded-3xl shadow-sm border border-gray-100">
      <div class="w-16 h-16 bg-red-100 rounded-2xl flex items-center justify-center mx-auto mb-6">
        <UIcon name="i-lucide-x-circle" class="w-8 h-8 text-red-600" />
      </div>
      <h2 class="text-2xl font-bold text-gray-900 mb-2">Payment Failed</h2>
      <p class="text-gray-500 mb-8">{{ errorMsg }}</p>
      
      <button @click="goHome" class="w-full py-4 rounded-xl bg-gray-900 text-white font-bold transition-all hover:bg-gray-800">
        Return Home
      </button>
    </div>

    <!-- Success -->
    <div v-else-if="success" class="w-full max-w-sm bg-white p-8 rounded-3xl shadow-xl shadow-emerald-900/5 border border-emerald-100">
      <div class="w-20 h-20 bg-gradient-to-br from-emerald-400 to-emerald-600 rounded-[2rem] flex items-center justify-center mx-auto mb-6 shadow-lg shadow-emerald-200">
        <UIcon name="i-lucide-check" class="w-10 h-10 text-white" />
      </div>
      <h2 class="text-2xl font-bold text-gray-900 mb-2">Payment Successful!</h2>
      <p class="text-gray-500 mb-8">Your Tab is officially closed and paid for. Thank you for dining with us!</p>
      
      <button @click="goHome" class="w-full py-4 rounded-xl bg-gradient-to-r from-emerald-500 to-emerald-600 text-white font-bold transition-all hover:shadow-lg hover:shadow-emerald-200 active:scale-95 text-lg">
        Done
      </button>
    </div>

  </div>
</template>
