<script setup lang="ts">
definePageMeta({ layout: 'kitchen' })

const { client, outletId, profileReady } = useUserProfile()
const toast = useToast()

const activeOrders = ref<any[]>([])
const loading = ref(true)
let orderSubscription: any = null

// Fetch orders where status is 'processing' (Sent to kitchen)
const loadKitchenOrders = async () => {
  if (!outletId.value) return
  
  loading.value = true
  try {
    const { data } = await client
      .from('orders')
      .select('*, tables(table_number, color), order_items(*, product:products(name, image_url))')
      .eq('outlet_id', outletId.value)
      .eq('order_status', 'processing')
      .order('created_at', { ascending: true }) // Oldest first (FIFO)
      
    activeOrders.value = data || []
  } catch (err: any) {
    console.error('Error loading kitchen orders:', err)
  } finally {
    loading.value = false
  }
}

// Realtime sync for Kitchen
const subscribeToKitchenOrders = () => {
  if (!outletId.value || orderSubscription) return
  
  orderSubscription = client
    .channel('kitchen:orders')
    .on(
      'postgres_changes', 
      { event: '*', schema: 'public', table: 'orders', filter: `outlet_id=eq.${outletId.value}` }, 
      (payload: any) => {
        // Reload all orders to ensure consistent state and joined item data
        loadKitchenOrders()
        
        // Notify for new incoming tickets
        if (payload.new && payload.new.order_status === 'processing' && payload.old?.order_status !== 'processing') {
          toast.add({
            title: 'New Kitchen Ticket',
            description: `A new order has been sent to the kitchen.`,
            color: 'warning',
            icon: 'i-lucide-bell-ring'
          })
        }
      }
    )
    .subscribe()
}

onUnmounted(() => {
  if (orderSubscription) client.removeChannel(orderSubscription)
})

watch(profileReady, (ready) => { 
  if (ready) {
    loadKitchenOrders()
    subscribeToKitchenOrders()
  }
}, { immediate: true })

const getWaitTime = (createdAt: string) => {
  const diff = Date.now() - new Date(createdAt).getTime()
  const mins = Math.floor(diff / 60000)
  return mins
}

// Helper to update elapsed time every minute without re-fetching
const timeNow = ref(Date.now())
let intervalId: any
onMounted(() => {
  intervalId = setInterval(() => { timeNow.value = Date.now() }, 60000)
})
onUnmounted(() => clearInterval(intervalId))

const timeColor = (createdAt: string) => {
  const mins = getWaitTime(createdAt)
  if (mins >= 30) return 'text-red-600 bg-red-100 border-red-200'
  if (mins >= 15) return 'text-amber-600 bg-amber-100 border-amber-200'
  return 'text-emerald-700 bg-emerald-100 border-emerald-200'
}

const formatWaitTime = (createdAt: string) => {
  // Use timeNow to force reactivity update
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const _tick = timeNow.value
  const mins = getWaitTime(createdAt)
  if (mins < 1) return 'Just now'
  if (mins === 1) return '1 min'
  return `${mins} mins`
}

const processingOrderId = ref<string | null>(null)

const markOrderReady = async (orderId: string) => {
  processingOrderId.value = orderId
  try {
    const { error } = await (client as any)
      .from('orders')
      .update({ order_status: 'ready' })
      .eq('id', orderId)
      
    if (error) throw error
    
    // Remove from local list immediately for snappy UI
    activeOrders.value = activeOrders.value.filter(o => o.id !== orderId)
    toast.add({ title: 'Order marked as ready!', color: 'success', icon: 'i-lucide-check-circle' })
    
  } catch (err: any) {
    toast.add({ title: 'Failed to update order status', description: err.message, color: 'error' })
  } finally {
    processingOrderId.value = null
  }
}

const orderTypeLabels: Record<string, string> = {
  'dine-in': 'Dine-In',
  'takeaway': 'Takeaway',
  'delivery': 'Delivery'
}
</script>

<template>
  <div class="h-full w-full p-4 md:p-6 overflow-x-auto custom-scrollbar flex items-start gap-4 md:gap-6 pb-8">
    
    <div v-if="loading" class="w-full h-full flex flex-col items-center justify-center">
      <UIcon name="i-lucide-loader-2" class="w-12 h-12 text-amber-500 animate-spin mb-4" />
      <p class="text-lg font-bold text-gray-700">Loading Orders...</p>
    </div>

    <div v-else-if="activeOrders.length === 0" class="w-full h-full flex flex-col items-center justify-center opacity-60">
      <div class="w-32 h-32 bg-gray-200 rounded-full flex items-center justify-center mb-6">
        <UIcon name="i-lucide-party-popper" class="w-16 h-16 text-gray-400" />
      </div>
      <h2 class="text-3xl font-black text-gray-800 tracking-tight mb-2">Kitchen is clear!</h2>
      <p class="text-xl text-gray-500 font-medium">No items currently queued for preparation.</p>
    </div>

    <!-- Kitchen Display Cards (Tickets) -->
    <template v-else>
      <div 
        v-for="order in activeOrders" 
        :key="order.id" 
        class="flex-shrink-0 w-[300px] md:w-[350px] bg-white rounded-2xl shadow-lg border border-gray-200/60 overflow-hidden flex flex-col max-h-full slide-enter relative"
      >
        <!-- Loading Overlay during status update -->
        <div v-if="processingOrderId === order.id" class="absolute inset-0 bg-white/70 backdrop-blur-sm z-10 flex flex-col items-center justify-center">
          <UIcon name="i-lucide-loader-2" class="w-8 h-8 animate-spin text-amber-500 mb-2" />
        </div>

        <!-- Ticket Header -->
        <div class="p-4 border-b border-gray-200 flex flex-col gap-2 relative z-0">
          <!-- Top Row: Type & Time -->
          <div class="flex items-center justify-between">
            <span class="bg-gray-100 text-gray-800 text-xs font-bold px-2.5 py-1 rounded-md uppercase tracking-wide border border-gray-200">
              {{ orderTypeLabels[order.order_type] || order.order_type }}
            </span>
            
            <div :class="['flex items-center gap-1.5 px-2.5 py-1 rounded-md border font-bold text-xs', timeColor(order.created_at)]">
              <UIcon name="i-lucide-clock" class="w-3.5 h-3.5" />
              {{ formatWaitTime(order.created_at) }}
            </div>
          </div>
          
          <!-- Middle Row: Identifiers -->
          <div class="flex items-center gap-3 mt-1">
            <div 
              v-if="order.tables"
              class="w-12 h-12 rounded-xl flex flex-col items-center justify-center shadow-inner text-white font-black"
              :style="{ background: order.tables.color || '#f59e0b' }"
            >
              <span class="text-[10px] leading-none opacity-80 uppercase pt-1">Table</span>
              <span class="text-xl leading-tight">{{ order.tables.table_number }}</span>
            </div>
            
            <div class="flex-1 min-w-0">
              <h3 class="font-black text-2xl text-gray-900 truncate leading-tight">{{ order.customer_name || 'Guest' }}</h3>
              <p class="text-sm font-mono text-gray-500 truncate">{{ order.receipt_number }}</p>
            </div>
          </div>
        </div>

        <!-- Order Items List -->
        <div class="flex-1 overflow-y-auto px-1 py-1 custom-scrollbar bg-gray-50 z-0">
          <div class="divide-y divide-gray-200/60">
            <div 
              v-for="item in order.order_items" 
              :key="item.id" 
              class="p-4 hover:bg-white transition-colors flex items-start gap-4"
            >
              <!-- Qty Box -->
              <div class="w-10 h-10 rounded-lg bg-gray-200 flex items-center justify-center flex-shrink-0 text-xl font-black text-gray-800 border border-gray-300 shadow-sm">
                {{ item.quantity }}
              </div>
              
              <!-- Item Details -->
              <div class="flex-1 pt-0.5 min-w-0">
                <h4 class="font-bold text-lg text-gray-900 leading-tight mb-1">{{ item.product?.name || 'Unknown Item' }}</h4>
                
                <!-- Variations -->
                <div v-if="item.variation_snapshot && Object.keys(item.variation_snapshot).length > 0" class="mt-1.5 space-y-1">
                  <div 
                    v-for="(val, key) in item.variation_snapshot" 
                    :key="key"
                    class="flex items-start gap-2"
                  >
                    <UIcon name="i-lucide-corner-down-right" class="w-3.5 h-3.5 text-amber-500 mt-0.5 flex-shrink-0" />
                    <span class="text-sm text-gray-700 font-semibold">{{ val.name }}</span>
                  </div>
                </div>
                
                <!-- Notes -->
                <div v-if="item.notes" class="mt-2 bg-yellow-50 border border-yellow-200 p-2.5 rounded-lg flex gap-2">
                  <UIcon name="i-lucide-message-square-text" class="w-4 h-4 text-yellow-600 mt-0.5 flex-shrink-0" />
                  <span class="text-sm font-bold text-yellow-800 italic leading-snug">{{ item.notes }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Action Footer -->
        <div class="p-4 border-t border-gray-200 bg-white shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)] z-0">
          <button 
            @click="markOrderReady(order.id)"
            class="w-full py-4 rounded-xl bg-amber-500 hover:bg-amber-600 text-white font-black text-lg tracking-wide uppercase transition-all shadow-md hover:shadow-lg flex items-center justify-center gap-2 active:scale-[0.98]"
          >
            <UIcon name="i-lucide-bell-ring" class="w-6 h-6" />
            Mark As Ready
          </button>
        </div>
        
      </div>
    </template>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: #cbd5e1;
  border-radius: 20px;
}

/* Subtle entrance animation for new tickets */
@keyframes slide-up {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}
.slide-enter {
  animation: slide-up 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
