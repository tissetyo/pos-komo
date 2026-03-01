<script setup lang="ts">
definePageMeta({ layout: 'order', auth: false })

const route = useRoute()
const token = route.params.token as string
const client = useSupabaseClient()

// State
const tableData = ref<any>(null)
const outlet = ref<any>(null)
const products = ref<any[]>([])
const categories = ref<string[]>([])
const activeCategory = ref('All')
const cart = ref<any[]>([])
const showCart = ref(false)
const showCheckout = ref(false)
const showSuccess = ref(false)
const completedOrderNumber = ref('')
const loading = ref(true)
const submitting = ref(false)
const errorMsg = ref('')

// Checkout form
const customerName = ref('')
const customerPhone = ref('')

// Load table + outlet + products
onMounted(async () => {
  // 1. Resolve token → table → outlet
  const { data: tbl, error: tblError } = await client
    .from('tables')
    .select('*, outlets(*)')
    .eq('qr_token', token)
    .eq('is_active', true)
    .single()

  if (tblError || !tbl) {
    errorMsg.value = 'This table is not available.'
    loading.value = false
    return
  }

  tableData.value = tbl
  outlet.value = tbl.outlets

  // 2. Load products for this outlet
  const { data: prods } = await client
    .from('products')
    .select('*, categories(name), product_variations(*)')
    .eq('outlet_id', tbl.outlet_id)
    .eq('is_active', true)
    .order('name')

  products.value = (prods || []).map((p: any) => ({
    ...p,
    category: p.categories?.name || 'Other',
    variations: p.product_variations || []
  }))

  const cats = [...new Set(products.value.map(p => p.category))]
  categories.value = ['All', ...cats]

  loading.value = false
})

// Filtering
const filteredProducts = computed(() => {
  if (activeCategory.value === 'All') return products.value
  return products.value.filter(p => p.category === activeCategory.value)
})

// Currency
const currencySymbol = computed(() => {
  const map: Record<string, string> = { MYR: 'RM', IDR: 'Rp', SGD: 'S$', USD: '$' }
  return map[outlet.value?.currency || 'MYR'] || 'RM'
})
const formatPrice = (amount: number) => `${currencySymbol.value}${amount.toFixed(2)}`

// Cart
const addToCart = (product: any) => {
  const existing = cart.value.find(c => c.id === product.id)
  if (existing) {
    existing.quantity++
  } else {
    cart.value.push({ ...product, quantity: 1 })
  }
}

const updateCartQty = (item: any, delta: number) => {
  item.quantity += delta
  if (item.quantity <= 0) {
    cart.value = cart.value.filter(c => c.id !== item.id)
  }
}

const removeFromCart = (item: any) => {
  cart.value = cart.value.filter(c => c.id !== item.id)
}

const cartCount = computed(() => cart.value.reduce((s, c) => s + c.quantity, 0))
const cartTotal = computed(() => cart.value.reduce((s, c) => s + c.price * c.quantity, 0))

// Checkout
const openCheckout = () => {
  showCart.value = false
  showCheckout.value = true
}

const canSubmit = computed(() => customerPhone.value.length >= 8 && cart.value.length > 0)

const placeOrder = async () => {
  if (!canSubmit.value || !tableData.value) return
  submitting.value = true

  try {
    // Generate receipt number
    const receiptNumber = `QR-${Date.now().toString(36).toUpperCase()}`

    // Compute totals
    const subtotal = cartTotal.value
    const sst = outlet.value?.sst || 0
    const serviceCharge = outlet.value?.service_charge || 0
    const taxAmount = Math.round(subtotal * sst / 100)
    const serviceAmount = Math.round(subtotal * serviceCharge / 100)
    const total = subtotal + taxAmount + serviceAmount

    // Create order
    const { data: order, error: orderErr } = await client.from('orders').insert({
      receipt_number: receiptNumber,
      outlet_id: tableData.value.outlet_id,
      table_id: tableData.value.id,
      source: 'qr',
      customer_name: customerName.value || null,
      customer_phone: customerPhone.value,
      subtotal,
      tax: taxAmount,
      total,
      payment_method: 'cash',
      payment_status: 'pending',
      order_status: 'new',
      order_type: 'dine-in'
    }).select().single()

    if (orderErr) throw orderErr

    // Create order items
    const items = cart.value.map(c => ({
      order_id: order.id,
      product_id: c.id,
      quantity: c.quantity,
      unit_price: c.price,
      total_price: c.price * c.quantity
    }))

    await client.from('order_items').insert(items)

    completedOrderNumber.value = receiptNumber
    showCheckout.value = false
    showSuccess.value = true
    cart.value = []
  } catch (err: any) {
    alert(err.message || 'Failed to place order')
  } finally {
    submitting.value = false
  }
}

const newOrder = () => {
  showSuccess.value = false
  customerName.value = ''
  customerPhone.value = ''
}
</script>

<template>
  <!-- Loading -->
  <div v-if="loading" class="flex items-center justify-center min-h-screen">
    <div class="text-center">
      <div class="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-4" />
      <p class="text-gray-500 text-sm">Loading menu...</p>
    </div>
  </div>

  <!-- Error -->
  <div v-else-if="errorMsg" class="flex items-center justify-center min-h-screen px-6">
    <div class="text-center">
      <UIcon name="i-lucide-alert-circle" class="w-12 h-12 text-red-400 mx-auto mb-4" />
      <h2 class="text-xl font-bold text-gray-900 mb-2">Oops!</h2>
      <p class="text-gray-500">{{ errorMsg }}</p>
    </div>
  </div>

  <!-- Success -->
  <div v-else-if="showSuccess" class="flex items-center justify-center min-h-screen px-6">
    <div class="text-center max-w-sm">
      <div class="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
        <UIcon name="i-lucide-check" class="w-10 h-10 text-green-600" />
      </div>
      <h2 class="text-2xl font-bold text-gray-900 mb-2">Order Placed!</h2>
      <p class="text-gray-500 mb-2">Your order has been sent to the kitchen.</p>
      <p class="text-sm font-mono text-gray-400 mb-8">{{ completedOrderNumber }}</p>
      <p class="text-lg font-semibold text-gray-900 mb-1">Table {{ tableData.table_number }}</p>
      <p class="text-gray-500 text-sm mb-8">Please wait while we prepare your food.</p>
      <UButton color="primary" label="Order More" icon="i-lucide-plus" block size="xl" class="rounded-xl font-bold" @click="newOrder" />
    </div>
  </div>

  <!-- Checkout -->
  <div v-else-if="showCheckout" class="min-h-screen bg-white">
    <!-- Header -->
    <div class="sticky top-0 bg-white border-b border-gray-100 px-4 py-3 flex items-center gap-3 z-10">
      <button @click="showCheckout = false" class="w-10 h-10 flex items-center justify-center rounded-xl hover:bg-gray-100">
        <UIcon name="i-lucide-arrow-left" class="w-5 h-5 text-gray-700" />
      </button>
      <h2 class="text-lg font-bold text-gray-900">Checkout</h2>
    </div>

    <div class="px-4 py-6 space-y-6 max-w-lg mx-auto">
      <!-- Order Summary -->
      <div>
        <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider mb-3">Your Order</h3>
        <div class="space-y-3">
          <div v-for="item in cart" :key="item.id" class="flex justify-between items-center">
            <div>
              <p class="font-medium text-gray-900">{{ item.name }}</p>
              <p class="text-sm text-gray-500">× {{ item.quantity }}</p>
            </div>
            <span class="font-semibold text-gray-900">{{ formatPrice(item.price * item.quantity) }}</span>
          </div>
        </div>
        <div class="border-t border-gray-200 mt-4 pt-4 flex justify-between">
          <span class="font-bold text-gray-900">Total</span>
          <span class="text-xl font-bold text-gray-900">{{ formatPrice(cartTotal) }}</span>
        </div>
      </div>

      <!-- Customer Info -->
      <div>
        <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider mb-3">Your Information</h3>
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Phone Number <span class="text-red-500">*</span></label>
            <input
              v-model="customerPhone"
              type="tel"
              inputmode="numeric"
              placeholder="e.g. 0123456789"
              class="w-full h-12 px-4 rounded-xl border border-gray-300 bg-white text-gray-900 text-base focus:ring-2 focus:ring-primary focus:border-primary outline-none"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Name <span class="text-gray-400 font-normal">(optional)</span></label>
            <input
              v-model="customerName"
              type="text"
              placeholder="e.g. John"
              class="w-full h-12 px-4 rounded-xl border border-gray-300 bg-white text-gray-900 text-base focus:ring-2 focus:ring-primary focus:border-primary outline-none"
            />
          </div>
        </div>
      </div>

      <UButton
        color="primary"
        block
        size="xl"
        class="rounded-xl font-bold"
        :disabled="!canSubmit"
        :loading="submitting"
        @click="placeOrder"
      >
        Place Order — {{ formatPrice(cartTotal) }}
      </UButton>
    </div>
  </div>

  <!-- Menu -->
  <div v-else class="min-h-screen pb-24">
    <!-- Header -->
    <div class="sticky top-0 bg-white z-20 border-b border-gray-100">
      <div class="px-4 py-4">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 bg-[#162456] rounded-xl flex items-center justify-center text-white font-bold text-sm">
            {{ tableData.table_number }}
          </div>
          <div>
            <h1 class="font-bold text-gray-900 text-lg">{{ outlet?.name || 'Menu' }}</h1>
            <p class="text-xs text-gray-500">Table {{ tableData.table_number }} · Dine-in</p>
          </div>
        </div>
      </div>

      <!-- Categories -->
      <div class="flex gap-2 px-4 pb-3 overflow-x-auto no-scrollbar">
        <button
          v-for="cat in categories"
          :key="cat"
          :class="['px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all',
            activeCategory === cat
              ? 'bg-[#162456] text-white'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          ]"
          @click="activeCategory = cat"
        >
          {{ cat }}
        </button>
      </div>
    </div>

    <!-- Product Grid -->
    <div class="px-4 py-4">
      <div v-if="filteredProducts.length === 0" class="text-center py-16">
        <UIcon name="i-lucide-search-x" class="w-12 h-12 text-gray-300 mx-auto mb-4" />
        <p class="text-gray-500">No items in this category.</p>
      </div>

      <div class="grid grid-cols-2 gap-3">
        <button
          v-for="product in filteredProducts"
          :key="product.id"
          class="bg-white rounded-2xl border border-gray-100 p-3 text-left hover:shadow-md transition-all active:scale-95"
          @click="addToCart(product)"
        >
          <div class="w-full aspect-square bg-gray-100 rounded-xl flex items-center justify-center mb-3">
            <img v-if="product.image_url" :src="product.image_url" class="w-full h-full object-cover rounded-xl" />
            <UIcon v-else name="i-lucide-image" class="w-8 h-8 text-gray-300" />
          </div>
          <h3 class="font-semibold text-gray-900 text-sm leading-tight line-clamp-2">{{ product.name }}</h3>
          <p class="text-primary font-bold text-sm mt-1">{{ formatPrice(product.price) }}</p>
        </button>
      </div>
    </div>

    <!-- Floating Cart Button -->
    <div v-if="cartCount > 0" class="fixed bottom-0 left-0 right-0 p-4 z-30">
      <button
        class="w-full bg-[#162456] text-white rounded-2xl px-6 py-4 flex items-center justify-between shadow-xl shadow-gray-900/20 active:scale-[0.98] transition-transform"
        @click="showCart = true"
      >
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 bg-white/20 rounded-lg flex items-center justify-center text-sm font-bold">{{ cartCount }}</div>
          <span class="font-semibold">View Cart</span>
        </div>
        <span class="font-bold text-lg">{{ formatPrice(cartTotal) }}</span>
      </button>
    </div>

    <!-- Cart Bottom Sheet -->
    <Teleport to="body">
      <Transition name="slide-up">
        <div v-if="showCart" class="fixed inset-0 z-50">
          <!-- Backdrop -->
          <div class="absolute inset-0 bg-black/40" @click="showCart = false" />

          <!-- Sheet -->
          <div class="absolute bottom-0 left-0 right-0 bg-white rounded-t-3xl max-h-[80vh] flex flex-col">
            <!-- Handle -->
            <div class="flex justify-center py-3">
              <div class="w-10 h-1 bg-gray-300 rounded-full" />
            </div>

            <div class="px-5 pb-2 flex items-center justify-between">
              <h3 class="text-lg font-bold text-gray-900">Your Cart</h3>
              <button class="text-sm text-red-500 font-semibold" @click="cart = []; showCart = false">Clear All</button>
            </div>

            <div class="flex-1 overflow-y-auto px-5 py-3 space-y-4">
              <div v-for="item in cart" :key="item.id" class="flex items-center gap-3">
                <div class="flex-1 min-w-0">
                  <p class="font-medium text-gray-900 text-sm truncate">{{ item.name }}</p>
                  <p class="text-sm text-gray-500">{{ formatPrice(item.price) }}</p>
                </div>
                <div class="flex items-center gap-2">
                  <button class="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center text-gray-600 font-bold" @click="updateCartQty(item, -1)">−</button>
                  <span class="w-6 text-center font-semibold text-sm">{{ item.quantity }}</span>
                  <button class="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center text-gray-600 font-bold" @click="updateCartQty(item, 1)">+</button>
                </div>
                <span class="font-semibold text-gray-900 text-sm w-20 text-right">{{ formatPrice(item.price * item.quantity) }}</span>
              </div>
            </div>

            <div class="border-t border-gray-100 px-5 py-4">
              <div class="flex justify-between mb-4">
                <span class="font-bold text-gray-900">Total</span>
                <span class="text-xl font-bold text-gray-900">{{ formatPrice(cartTotal) }}</span>
              </div>
              <UButton color="primary" block size="xl" class="rounded-xl font-bold" @click="openCheckout">
                Checkout — {{ formatPrice(cartTotal) }}
              </UButton>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
.line-clamp-2 { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

.slide-up-enter-active, .slide-up-leave-active { transition: all 0.3s ease; }
.slide-up-enter-from, .slide-up-leave-to { opacity: 0; }
.slide-up-enter-from .absolute.bottom-0,
.slide-up-leave-to .absolute.bottom-0 { transform: translateY(100%); }
</style>
