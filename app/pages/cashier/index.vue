<script setup lang="ts">
definePageMeta({ layout: 'cashier' })

const { client, outletId, userId, profileReady } = useUserProfile()
const { formatPrice, symbol: currSymbol, loadCurrency } = useCurrency()

// Data from Supabase
const products = ref<any[]>([])
const categories = ref<string[]>(['All Items'])
const activeCategory = ref('All Items')
const searchQuery = ref('')
const loading = ref(true)

// Category icons
const categoryIcons: Record<string, string> = {
  'All Items': 'i-lucide-grid',
  'Coffee': 'i-lucide-coffee',
  'Tea': 'i-lucide-cup-soda',
  'Pastries': 'i-lucide-cake-slice',
  'Main Course': 'i-lucide-utensils-crossed',
  'Desserts': 'i-lucide-ice-cream-cone',
  'Cold Drinks': 'i-lucide-glass-water',
  'Food': 'i-lucide-utensils-crossed',
  'Beverages': 'i-lucide-coffee',
}

// Order State
const orderItems = ref<any[]>([])
const orderType = ref<'dine-in' | 'takeaway' | 'delivery'>('dine-in')
const orderNote = ref('')
const showNoteModal = ref(false)

// Variation Picker
const showVariationPicker = ref(false)
const pickingProduct = ref<any>(null)
const selectedVariations = ref<Record<string, any>>({})
const pickerQty = ref(1)

// Payment/Checkout Flow
const showCheckout = ref(false)
const paymentMethod = ref<'cash' | 'qris' | 'debit' | 'credit'>('cash')
const cashReceived = ref('')
const isProcessing = ref(false)

// Order Complete
const showSuccessModal = ref(false)
const completedOrder = ref<any>(null)

// Load products from Supabase
const loadProducts = async () => {
  if (!outletId.value) { loading.value = false; return }
  try {
    await loadCurrency(outletId.value)

    const { data } = await client
      .from('products')
      .select('*, categories(name)')
      .eq('outlet_id', outletId.value)
      .eq('is_active', true)
      .order('name')

    // Get variations for all products
    const productIds = (data || []).map((p: any) => p.id)
    let varMap: Record<string, any[]> = {}
    if (productIds.length > 0) {
      const { data: vars } = await client
        .from('product_variations')
        .select('*')
        .in('product_id', productIds)
        .order('sort_order')
      ;(vars || []).forEach((v: any) => {
        if (!varMap[v.product_id]) varMap[v.product_id] = []
        varMap[v.product_id].push(v)
      })
    }

    products.value = (data || []).map((p: any) => ({
      id: p.id,
      name: p.name,
      description: p.description || '',
      price: p.price,
      category: p.categories?.name || 'Other',
      image: p.image_url || null,
      stock: p.stock,
      variations: varMap[p.id] || []
    }))

    // Build categories
    const cats = new Set(products.value.map(p => p.category))
    categories.value = ['All Items', ...Array.from(cats)]
  } finally {
    loading.value = false
  }
}

watch(profileReady, (ready) => { if (ready) loadProducts() })

const filteredProducts = computed(() => {
  return products.value.filter(p => {
    const matchCategory = activeCategory.value === 'All Items' || p.category === activeCategory.value
    const matchSearch = p.name.toLowerCase().includes(searchQuery.value.toLowerCase())
    return matchCategory && matchSearch
  })
})

const subtotal = computed(() => orderItems.value.reduce((acc, item) => acc + (item.finalPrice * item.quantity), 0))
const tax = computed(() => Math.round(subtotal.value * 0.10))
const discount = computed(() => 0)
const total = computed(() => subtotal.value + tax.value - discount.value)
const change = computed(() => {
  const cash = parseFloat(cashReceived.value) || 0
  return Math.max(0, cash - total.value)
})
const canPay = computed(() => {
  if (paymentMethod.value === 'cash') {
    return (parseFloat(cashReceived.value) || 0) >= total.value
  }
  return true
})

const handleProductClick = (product: any) => {
  if (product.variations && product.variations.length > 0) {
    pickingProduct.value = product
    selectedVariations.value = {}
    pickerQty.value = 1
    product.variations.forEach((v: any) => {
      const options = v.options || []
      if (options.length > 0) {
        selectedVariations.value[v.label] = options[0]
      }
    })
    showVariationPicker.value = true
  } else {
    addToOrder(product, 0, {})
  }
}

const pickerTotal = computed(() => {
  if (!pickingProduct.value) return 0
  const adj = Object.values(selectedVariations.value).reduce((s: number, o: any) => s + (o.price_adj || 0), 0)
  return (pickingProduct.value.price + adj) * pickerQty.value
})

const addToOrder = (product: any, priceAdj: number, variationSnapshot: any, qty = 1) => {
  const finalPrice = product.price + priceAdj
  const varKey = JSON.stringify(variationSnapshot)
  const existing = orderItems.value.find(item => item.id === product.id && JSON.stringify(item.variationSnapshot) === varKey)

  if (existing) {
    existing.quantity += qty
  } else {
    orderItems.value.push({
      id: product.id,
      name: product.name,
      price: product.price,
      finalPrice,
      quantity: qty,
      image: product.image,
      variationSnapshot,
      variationLabel: Object.entries(variationSnapshot).map(([k, v]: any) => v.name).join(', ')
    })
  }
}

const confirmVariation = () => {
  if (!pickingProduct.value) return
  const priceAdj = Object.values(selectedVariations.value).reduce((sum: number, opt: any) => sum + (opt.price_adj || 0), 0)
  addToOrder(pickingProduct.value, priceAdj, selectedVariations.value, pickerQty.value)
  showVariationPicker.value = false
  pickingProduct.value = null
}

const updateQuantity = (item: any, delta: number) => {
  const index = orderItems.value.findIndex(i => i.id === item.id && JSON.stringify(i.variationSnapshot) === JSON.stringify(item.variationSnapshot))
  if (index !== -1) {
    orderItems.value[index].quantity += delta
    if (orderItems.value[index].quantity <= 0) {
      orderItems.value.splice(index, 1)
    }
  }
}

const clearOrder = () => {
  if (orderItems.value.length === 0) return
  if (!confirm('Clear all items from the current order?')) return
  orderItems.value = []
  orderNote.value = ''
}

const openCheckout = () => {
  if (orderItems.value.length === 0) return
  paymentMethod.value = 'cash'
  cashReceived.value = ''
  showCheckout.value = true
}

// Numpad
const handleNumpad = (key: string) => {
  if (key === 'backspace') {
    cashReceived.value = cashReceived.value.slice(0, -1)
  } else if (key === '.') {
    if (!cashReceived.value.includes('.')) cashReceived.value += '.'
  } else {
    cashReceived.value += key
  }
}

const quickAmounts = computed(() => {
  const t = total.value
  return [
    { label: `${currSymbol.value}10`, value: 10 },
    { label: `${currSymbol.value}20`, value: 20 },
    { label: `${currSymbol.value}50`, value: 50 },
  ]
})

const processPayment = async () => {
  if (!userId.value || !outletId.value || !canPay.value) return
  isProcessing.value = true

  try {
    const receiptNumber = 'TRX-' + Date.now().toString().slice(-8)

    const { data: order, error: orderErr } = await client
      .from('orders')
      .insert({
        receipt_number: receiptNumber,
        outlet_id: outletId.value,
        cashier_id: userId.value,
        subtotal: subtotal.value,
        tax: tax.value,
        discount: 0,
        total: total.value,
        payment_method: paymentMethod.value,
        payment_status: 'paid',
        order_status: 'completed',
        order_type: orderType.value
      })
      .select()
      .single()

    if (orderErr) throw orderErr

    const items = orderItems.value.map(item => ({
      order_id: (order as any).id,
      product_id: item.id,
      quantity: item.quantity,
      unit_price: item.finalPrice,
      total_price: item.finalPrice * item.quantity,
      variation_snapshot: Object.keys(item.variationSnapshot).length > 0 ? item.variationSnapshot : null,
      notes: orderNote.value || null
    }))

    const { error: itemsErr } = await client.from('order_items').insert(items as any)
    if (itemsErr) throw itemsErr

    completedOrder.value = {
      receiptNumber,
      total: total.value,
      paymentMethod: paymentMethod.value,
      change: paymentMethod.value === 'cash' ? change.value : 0,
      items: [...orderItems.value],
      orderType: orderType.value
    }

    showCheckout.value = false
    showSuccessModal.value = true

  } catch (err: any) {
    alert('Failed to complete order: ' + (err.message || 'Unknown error'))
  } finally {
    isProcessing.value = false
  }
}

const startNewOrder = () => {
  orderItems.value = []
  orderNote.value = ''
  completedOrder.value = null
  showSuccessModal.value = false
}

const orderTypeLabels = { 'dine-in': 'DI', 'takeaway': 'TA', 'delivery': 'DL' }
const orderTypeNames = { 'dine-in': 'Dine-in', 'takeaway': 'Takeaway', 'delivery': 'Delivery' }
</script>

<template>
  <div class="flex h-full w-full">

    <!-- CHECKOUT VIEW -->
    <div v-if="showCheckout" class="flex h-full w-full">
      <!-- Left: Order Summary -->
      <div class="w-[380px] bg-white border-r border-gray-200 flex flex-col shrink-0">
        <div class="px-5 py-4 border-b border-gray-200 flex items-center gap-3">
          <button @click="showCheckout = false" class="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center hover:bg-gray-200 transition-colors">
            <UIcon name="i-lucide-arrow-left" class="w-4 h-4 text-gray-600" />
          </button>
          <div>
            <h2 class="font-bold text-lg text-gray-900">Order #{{ Date.now().toString().slice(-4) }}</h2>
            <p class="text-xs text-gray-500">{{ new Date().toLocaleTimeString('en', { hour: '2-digit', minute: '2-digit' }) }}</p>
          </div>
          <span class="ml-auto bg-[#162456] text-white text-xs font-bold px-3 py-1 rounded-lg uppercase">
            {{ (orderTypeNames as any)[orderType] }}
          </span>
        </div>

        <!-- Items -->
        <div class="flex-1 overflow-y-auto px-5 py-4 space-y-4 custom-scrollbar">
          <div v-for="item in orderItems" :key="item.id + JSON.stringify(item.variationSnapshot)" class="flex items-start gap-3">
            <div class="w-12 h-12 rounded-xl overflow-hidden bg-gray-100 flex-shrink-0">
              <img v-if="item.image" :src="item.image" class="w-full h-full object-cover" />
              <div v-else class="w-full h-full flex items-center justify-center">
                <UIcon name="i-lucide-coffee" class="w-5 h-5 text-gray-400" />
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex justify-between items-start">
                <h4 class="font-semibold text-sm text-gray-900">{{ item.name }}<span v-if="item.variationLabel" class="text-xs text-gray-500"> ({{ item.variationLabel }})</span></h4>
                <span class="font-semibold text-sm text-gray-900 ml-2 whitespace-nowrap">{{ formatPrice(item.finalPrice) }}</span>
              </div>
              <p v-if="item.variationLabel" class="text-[10px] text-gray-400">• {{ item.variationLabel }}</p>
              <span class="inline-flex items-center bg-gray-100 rounded-md px-2 py-0.5 text-xs font-semibold text-gray-600 mt-1">×{{ item.quantity }}</span>
            </div>
          </div>
        </div>

        <!-- Totals -->
        <div class="border-t border-gray-200 px-5 py-4 space-y-2">
          <div class="flex justify-between text-sm"><span class="text-gray-500">Subtotal</span><span class="text-gray-900">{{ formatPrice(subtotal) }}</span></div>
          <div class="flex justify-between text-sm"><span class="text-gray-500">Tax (10%)</span><span class="text-gray-900">{{ formatPrice(tax) }}</span></div>
          <div class="flex justify-between text-sm"><span class="text-gray-500">Discount</span><span class="text-gray-900">-{{ formatPrice(discount) }}</span></div>
          <div class="border-t border-dashed border-gray-200 pt-3 mt-2">
            <div class="flex justify-between items-center">
              <span class="font-bold text-gray-900">Total Amount</span>
              <span class="text-2xl font-bold text-gray-900">{{ formatPrice(total) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Center: Payment Methods + Numpad -->
      <div class="flex-1 bg-gray-50 flex flex-col p-8">
        <!-- Payment Methods -->
        <div class="mb-6">
          <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4">Payment Method</h3>
          <div class="grid grid-cols-4 gap-3">
            <button v-for="pm in ([
              { id: 'cash', icon: 'i-lucide-banknote', label: 'Cash' },
              { id: 'credit', icon: 'i-lucide-credit-card', label: 'Credit' },
              { id: 'debit', icon: 'i-lucide-smartphone', label: 'Debit' },
              { id: 'qris', icon: 'i-lucide-qr-code', label: 'Scan' }
            ] as const)"
              :key="pm.id"
              @click="paymentMethod = pm.id as any"
              :class="[
                'flex flex-col items-center gap-2 p-4 rounded-xl border-2 transition-all',
                paymentMethod === pm.id
                  ? 'border-[#162456] bg-[#162456] text-white shadow-md'
                  : 'border-gray-200 bg-white text-gray-600 hover:border-gray-300'
              ]"
            >
              <UIcon :name="pm.icon" class="w-6 h-6" />
              <span class="text-xs font-semibold">{{ pm.label }}</span>
            </button>
          </div>
        </div>

        <!-- Cash Entry with Numpad -->
        <div v-if="paymentMethod === 'cash'" class="flex-1 flex flex-col">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider">Cash Entry</h3>
            <div class="flex gap-2">
              <button v-for="qa in quickAmounts" :key="qa.value" @click="cashReceived = qa.value.toString()"
                class="px-4 py-1.5 text-xs font-semibold bg-white border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                {{ qa.label }}
              </button>
            </div>
          </div>

          <!-- Numpad Grid -->
          <div class="grid grid-cols-3 gap-3 max-w-sm">
            <button v-for="key in ['1','2','3','4','5','6','7','8','9']" :key="key"
              @click="handleNumpad(key)"
              class="h-16 rounded-xl bg-white border border-gray-200 text-xl font-semibold text-gray-800 hover:bg-gray-50 active:bg-gray-100 transition-colors shadow-sm">
              {{ key }}
            </button>
            <button @click="handleNumpad('backspace')"
              class="h-16 rounded-xl bg-white border border-gray-200 flex items-center justify-center hover:bg-gray-50 active:bg-gray-100 transition-colors shadow-sm">
              <UIcon name="i-lucide-delete" class="w-6 h-6 text-gray-600" />
            </button>
            <button @click="handleNumpad('0')"
              class="h-16 rounded-xl bg-white border border-gray-200 text-xl font-semibold text-gray-800 hover:bg-gray-50 active:bg-gray-100 transition-colors shadow-sm">0</button>
            <button @click="handleNumpad('.')"
              class="h-16 rounded-xl bg-white border border-gray-200 text-xl font-semibold text-gray-800 hover:bg-gray-50 active:bg-gray-100 transition-colors shadow-sm">.</button>
          </div>
        </div>

        <!-- Non-cash placeholder -->
        <div v-else class="flex-1 flex items-center justify-center">
          <div class="text-center text-gray-400">
            <UIcon name="i-lucide-credit-card" class="w-16 h-16 mx-auto mb-4 opacity-30" />
            <p class="font-medium">Present {{ paymentMethod === 'qris' ? 'QR code' : 'card' }} to terminal</p>
            <p class="text-sm mt-1">Waiting for payment confirmation...</p>
          </div>
        </div>

        <!-- Complete Order Button -->
        <button
          @click="processPayment"
          :disabled="!canPay || isProcessing"
          class="mt-6 w-full flex items-center justify-between py-5 px-6 rounded-xl bg-[#162456] text-white font-bold text-lg hover:bg-[#1d2f6b] transition-colors disabled:opacity-50"
        >
          <span class="flex items-center gap-2">
            <UIcon v-if="isProcessing" name="i-lucide-loader-2" class="w-5 h-5 animate-spin" />
            Complete Order
          </span>
          <span>{{ formatPrice(total) }} →</span>
        </button>
      </div>

      <!-- Right: Transaction Details -->
      <div class="w-72 bg-white border-l border-gray-200 flex flex-col p-6 shrink-0">
        <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider mb-8">Transaction Details</h3>

        <div class="space-y-6 flex-1">
          <div>
            <p class="text-sm text-gray-500 mb-1">Total Due</p>
            <p class="text-2xl font-bold text-gray-900">{{ formatPrice(total) }}</p>
          </div>
          <div>
            <p class="text-sm text-gray-500 mb-1">Tendered</p>
            <p class="text-2xl font-bold text-gray-900">{{ formatPrice(parseFloat(cashReceived) || 0) }}</p>
          </div>
          <div v-if="(parseFloat(cashReceived) || 0) >= total" class="pt-4 border-t border-gray-200">
            <p class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">Change Due</p>
            <p class="text-3xl font-bold text-gray-900">{{ formatPrice(change) }}</p>
            <p class="text-xs text-gray-400 mt-1">Please return change to customer.</p>
          </div>
        </div>
      </div>
    </div>

    <!-- MAIN POS VIEW -->
    <template v-else>
      <!-- Left Sidebar: Categories -->
      <aside class="w-44 bg-white border-r border-gray-200 flex flex-col shrink-0">
        <div class="px-4 py-4">
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider">Categories</p>
        </div>
        <nav class="flex-1 px-2 space-y-1 overflow-y-auto">
          <button
            v-for="cat in categories"
            :key="cat"
            @click="activeCategory = cat"
            :class="[
              'w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all text-left',
              activeCategory === cat
                ? 'bg-[#162456] text-white shadow-md'
                : 'text-gray-600 hover:bg-gray-100'
            ]"
          >
            <UIcon :name="categoryIcons[cat] || 'i-lucide-tag'" class="w-5 h-5 flex-shrink-0" />
            {{ cat }}
          </button>
        </nav>

        <!-- Order Type Selector -->
        <div class="p-3 border-t border-gray-100">
          <p class="text-[10px] font-semibold text-gray-400 uppercase mb-2">Order Type</p>
          <div class="flex gap-1">
            <button
              v-for="type in (['dine-in', 'takeaway', 'delivery'] as const)"
              :key="type"
              @click="orderType = type"
              :class="[
                'flex-1 py-2 text-xs font-semibold rounded-lg transition-colors text-center',
                orderType === type ? 'bg-[#162456] text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
              ]"
            >
              {{ (orderTypeLabels as any)[type] }}
            </button>
          </div>
        </div>
      </aside>

      <!-- Center: Product Grid -->
      <div class="flex-1 flex flex-col p-5 overflow-hidden bg-gray-50/50">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h2 class="text-xl font-bold text-gray-900">Choose Order</h2>
            <p class="text-sm text-gray-500">Select items to add</p>
          </div>
          <span class="bg-emerald-50 text-emerald-700 text-xs font-semibold px-3 py-1.5 rounded-full border border-emerald-200">
            {{ filteredProducts.length }} items
          </span>
        </div>

        <div v-if="loading" class="flex-1 flex items-center justify-center">
          <UIcon name="i-lucide-loader-2" class="w-8 h-8 animate-spin text-gray-400" />
        </div>

        <div v-else-if="filteredProducts.length === 0" class="flex-1 flex items-center justify-center">
          <div class="text-center text-gray-400">
            <UIcon name="i-lucide-package" class="w-12 h-12 mx-auto mb-3 opacity-40" />
            <p class="text-lg font-medium mb-1">No products found</p>
            <UButton to="/backoffice/products" color="primary" variant="soft" label="Go to Products" icon="i-lucide-arrow-right" />
          </div>
        </div>

        <div v-else class="flex-1 overflow-y-auto pr-1 custom-scrollbar">
          <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            <div
              v-for="product in filteredProducts"
              :key="product.id"
              class="bg-[#162456] rounded-2xl overflow-hidden cursor-pointer hover:shadow-lg transition-all duration-200 transform hover:-translate-y-1 group flex flex-col"
              @click="handleProductClick(product)"
            >
              <div class="aspect-[4/3] w-full relative overflow-hidden">
                <img v-if="product.image" :src="product.image" :alt="product.name" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
                <div v-else class="w-full h-full flex items-center justify-center bg-[#1d2f6b]">
                  <UIcon name="i-lucide-coffee" class="w-12 h-12 text-blue-300/30" />
                </div>
                <span class="absolute top-3 left-3 bg-emerald-500 text-white text-xs font-bold px-2.5 py-1 rounded-lg shadow-md">
                  {{ formatPrice(product.price) }}
                </span>
                <span v-if="product.variations.length > 0" class="absolute top-3 right-3 bg-purple-500 text-white text-[10px] font-bold px-2 py-0.5 rounded-md">
                  {{ product.variations.length }} options
                </span>
              </div>
              <div class="p-3">
                <h3 class="font-semibold text-white text-sm leading-tight line-clamp-1">{{ product.name }}</h3>
                <p class="text-blue-200/50 text-xs mt-1 line-clamp-1">{{ product.description || product.category }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Right Sidebar: Order Summary -->
      <div class="w-80 lg:w-96 bg-white border-l border-gray-200 flex flex-col shrink-0">
        <div class="px-5 py-4 border-b border-gray-100">
          <div class="flex items-center justify-between">
            <h2 class="font-bold text-lg text-gray-900">Current Order</h2>
            <span class="bg-[#162456] text-white text-xs font-bold w-8 h-8 rounded-lg flex items-center justify-center">
              {{ (orderTypeLabels as any)[orderType] }}
            </span>
          </div>
          <p class="text-xs text-gray-500 mt-1">{{ (orderTypeNames as any)[orderType] }} • {{ orderItems.length }} item{{ orderItems.length !== 1 ? 's' : '' }}</p>
        </div>

        <div class="flex-1 overflow-y-auto px-4 py-3 custom-scrollbar space-y-3">
          <div v-if="orderItems.length === 0" class="flex flex-col items-center justify-center h-full text-center text-gray-400 space-y-4">
            <UIcon name="i-lucide-shopping-cart" class="w-12 h-12 text-gray-200" />
            <div>
              <p class="text-sm font-medium">Order is empty</p>
              <p class="text-xs mt-1">Select items from the menu to get started.</p>
            </div>
          </div>

          <div v-for="item in orderItems" :key="item.id + JSON.stringify(item.variationSnapshot)" class="flex items-center gap-3">
            <div class="w-12 h-12 rounded-xl overflow-hidden bg-gray-100 flex-shrink-0">
              <img v-if="item.image" :src="item.image" :alt="item.name" class="w-full h-full object-cover" />
              <div v-else class="w-full h-full flex items-center justify-center"><UIcon name="i-lucide-coffee" class="w-5 h-5 text-gray-400" /></div>
            </div>
            <div class="flex-1 min-w-0">
              <h4 class="font-semibold text-sm text-gray-900 truncate">{{ item.name }}</h4>
              <p v-if="item.variationLabel" class="text-[10px] text-purple-600 font-medium">{{ item.variationLabel }}</p>
              <p class="text-xs text-gray-500">{{ formatPrice(item.finalPrice) }}</p>
            </div>
            <div class="flex items-center gap-1 bg-gray-50 rounded-lg border border-gray-200 px-1 py-0.5">
              <button class="w-7 h-7 flex items-center justify-center text-gray-500 hover:bg-gray-200 rounded transition-colors" @click.stop="updateQuantity(item, -1)">
                <UIcon name="i-lucide-minus" class="w-3.5 h-3.5" />
              </button>
              <span class="w-6 text-center text-sm font-semibold text-gray-900">{{ item.quantity }}</span>
              <button class="w-7 h-7 flex items-center justify-center text-gray-500 hover:bg-gray-200 rounded transition-colors" @click.stop="updateQuantity(item, 1)">
                <UIcon name="i-lucide-plus" class="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        </div>

        <!-- Totals & Actions -->
        <div class="border-t border-gray-200 p-5">
          <div class="space-y-2 mb-4">
            <div class="flex justify-between text-sm"><span class="text-gray-500">Subtotal</span><span class="font-medium text-gray-900">{{ formatPrice(subtotal) }}</span></div>
            <div class="flex justify-between text-sm"><span class="text-gray-500">Discount</span><span class="font-medium text-gray-900">{{ formatPrice(discount) }}</span></div>
            <div class="flex justify-between text-sm"><span class="text-gray-500">Tax (10%)</span><span class="font-medium text-gray-900">{{ formatPrice(tax) }}</span></div>
            <div class="border-t border-dashed border-gray-200 my-2 pt-2">
              <div class="flex justify-between items-center">
                <span class="font-semibold text-gray-900">Total</span>
                <span class="font-bold text-2xl text-gray-900">{{ formatPrice(total) }}</span>
              </div>
            </div>
          </div>

          <div class="flex gap-3 mb-3">
            <button class="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl border-2 border-gray-200 text-gray-600 font-semibold text-sm hover:bg-gray-50 transition-colors disabled:opacity-40" :disabled="orderItems.length === 0" @click="clearOrder">
              Hold Order
            </button>
            <button class="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl border-2 border-gray-200 text-gray-600 font-semibold text-sm hover:bg-gray-50 transition-colors" @click="showNoteModal = true">
              Add Note
            </button>
          </div>

          <button
            @click="openCheckout"
            class="w-full flex items-center justify-center gap-3 py-4 rounded-xl bg-[#162456] text-white font-bold text-lg hover:bg-[#1d2f6b] transition-colors disabled:opacity-50"
            :disabled="orderItems.length === 0"
          >
            <UIcon name="i-lucide-wallet" class="w-5 h-5" />
            Checkout
          </button>
        </div>
      </div>
    </template>

    <!-- Variation Picker Modal (Redesigned) -->
    <UModal v-model:open="showVariationPicker">
      <template #content>
        <div class="p-6 bg-white max-w-lg" v-if="pickingProduct">
          <!-- Header: Product info -->
          <div class="flex items-center justify-between mb-6">
            <div class="flex items-center gap-4">
              <div class="w-14 h-14 rounded-xl overflow-hidden bg-gray-100 flex-shrink-0">
                <img v-if="pickingProduct.image" :src="pickingProduct.image" class="w-full h-full object-cover" />
                <div v-else class="w-full h-full flex items-center justify-center"><UIcon name="i-lucide-coffee" class="w-6 h-6 text-gray-400" /></div>
              </div>
              <div>
                <h3 class="text-lg font-bold text-gray-900">{{ pickingProduct.name }}</h3>
                <p v-if="pickingProduct.description" class="text-xs text-gray-500">{{ pickingProduct.description }}</p>
                <p class="text-sm font-semibold text-gray-900 mt-0.5">{{ formatPrice(pickingProduct.price) }}</p>
              </div>
            </div>
            <button @click="showVariationPicker = false" class="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center hover:bg-gray-200 transition-colors">
              <UIcon name="i-lucide-x" class="w-4 h-4 text-gray-500" />
            </button>
          </div>

          <!-- Variation Groups -->
          <div class="space-y-5">
            <div v-for="variation in pickingProduct.variations" :key="variation.id">
              <p class="text-sm font-bold text-gray-700 mb-2.5 flex items-center gap-1.5">
                <span>{{ variation.label }}</span>
              </p>
              <div class="flex flex-wrap gap-2">
                <button
                  v-for="option in (variation.options || [])"
                  :key="option.name"
                  @click="selectedVariations[variation.label] = option"
                  :class="[
                    'px-5 py-2.5 rounded-xl text-sm font-medium border-2 transition-all',
                    selectedVariations[variation.label]?.name === option.name
                      ? 'border-[#162456] bg-[#162456] text-white'
                      : 'border-gray-200 text-gray-700 hover:border-gray-400'
                  ]"
                >
                  {{ option.name }}
                  <span v-if="option.price_adj > 0" class="text-xs ml-1 opacity-70">+{{ formatPrice(option.price_adj) }}</span>
                </button>
              </div>
            </div>
          </div>

          <!-- Footer: Qty + Add to Cart -->
          <div class="flex items-center justify-between mt-6 pt-5 border-t border-gray-100">
            <div class="flex items-center gap-3 bg-gray-100 rounded-xl px-2 py-1">
              <button @click="pickerQty = Math.max(1, pickerQty - 1)" class="w-9 h-9 rounded-lg flex items-center justify-center hover:bg-gray-200 transition-colors">
                <UIcon name="i-lucide-minus" class="w-4 h-4 text-gray-600" />
              </button>
              <span class="w-8 text-center text-lg font-bold text-gray-900">{{ pickerQty }}</span>
              <button @click="pickerQty++" class="w-9 h-9 rounded-lg flex items-center justify-center hover:bg-gray-200 transition-colors">
                <UIcon name="i-lucide-plus" class="w-4 h-4 text-gray-600" />
              </button>
            </div>
            <button @click="confirmVariation" class="flex-1 ml-4 py-3.5 rounded-xl bg-[#162456] text-white font-bold text-sm hover:bg-[#1d2f6b] transition-colors flex items-center justify-center gap-2">
              Add to Cart
              <span class="bg-white/20 px-2 py-0.5 rounded-md text-xs">{{ formatPrice(pickerTotal) }}</span>
            </button>
          </div>
        </div>
      </template>
    </UModal>

    <!-- Note Modal -->
    <UModal v-model:open="showNoteModal">
      <template #content>
        <div class="p-6 bg-white">
          <h3 class="text-base font-semibold text-gray-900 mb-4">Order Note</h3>
          <UTextarea v-model="orderNote" placeholder="Special instructions, allergies, etc." autoresize class="w-full" />
          <div class="flex justify-end gap-3 mt-4">
            <UButton color="neutral" variant="ghost" label="Cancel" @click="showNoteModal = false" />
            <UButton color="primary" label="Save Note" @click="showNoteModal = false" />
          </div>
        </div>
      </template>
    </UModal>

    <!-- Order Success Modal -->
    <UModal v-model:open="showSuccessModal">
      <template #content>
        <div class="p-8 bg-white text-center min-w-[400px]" v-if="completedOrder">
          <div class="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <UIcon name="i-lucide-check" class="w-10 h-10 text-green-600" />
          </div>
          <h3 class="text-xl font-bold text-gray-900 mb-1">Order Complete!</h3>
          <p class="text-sm text-gray-500 mb-6">{{ completedOrder.receiptNumber }}</p>

          <div class="bg-gray-50 rounded-xl p-4 text-left space-y-2 mb-6">
            <div v-for="item in completedOrder.items" :key="item.id" class="flex justify-between text-sm">
              <span class="text-gray-600">{{ item.name }} <span v-if="item.variationLabel" class="text-purple-600">({{ item.variationLabel }})</span> × {{ item.quantity }}</span>
              <span class="font-medium text-gray-900">{{ formatPrice(item.finalPrice * item.quantity) }}</span>
            </div>
            <div class="border-t border-dashed border-gray-300 pt-2 mt-2">
              <div class="flex justify-between font-bold text-lg">
                <span>Total</span>
                <span>{{ formatPrice(completedOrder.total) }}</span>
              </div>
            </div>
            <div class="flex justify-between text-sm text-gray-500">
              <span>Method</span>
              <span class="capitalize font-medium">{{ completedOrder.paymentMethod }}</span>
            </div>
            <div v-if="completedOrder.change > 0" class="flex justify-between text-sm text-green-600">
              <span>Change</span>
              <span class="font-bold">{{ formatPrice(completedOrder.change) }}</span>
            </div>
          </div>

          <button @click="startNewOrder" class="w-full py-4 rounded-xl bg-[#162456] text-white font-bold text-lg hover:bg-[#1d2f6b] transition-colors">
            New Order
          </button>
        </div>
      </template>
    </UModal>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: #cbd5e1;
  border-radius: 20px;
}
</style>
