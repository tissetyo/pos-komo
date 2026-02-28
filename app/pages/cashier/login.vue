<script setup lang="ts">
definePageMeta({ layout: 'default' })

const client = useSupabaseClient()
const user = useSupabaseUser()
const email = ref('')
const pin = ref(['', '', '', ''])
const pinInputs = ref<HTMLInputElement[]>([])
const error = ref('')
const loading = ref(false)

// If already logged in, go direct to cashier
onMounted(() => {
  if (user.value) {
    email.value = user.value.email || ''
  }
})

const handlePinInput = (index: number, event: Event) => {
  const target = event.target as HTMLInputElement
  const value = target.value.replace(/\D/g, '')
  pin.value[index] = value
  if (value && index < 3) {
    pinInputs.value[index + 1]?.focus()
  }
  // Auto-submit when all 4 digits entered
  if (index === 3 && value && pin.value.every(d => d)) {
    handleLogin()
  }
}

const handlePinKeydown = (index: number, event: KeyboardEvent) => {
  if (event.key === 'Backspace' && !pin.value[index] && index > 0) {
    pinInputs.value[index - 1]?.focus()
  }
}

const handleLogin = async () => {
  error.value = ''
  if (!email.value) { error.value = 'Please enter your email'; return }
  const pinString = pin.value.join('')
  if (pinString.length !== 4) { error.value = 'Please enter your 4-digit PIN'; return }

  loading.value = true
  try {
    // Look up the profile by email to verify PIN
    const { data: profiles } = await client
      .from('profiles')
      .select('id, pin, role, full_name')
      .eq('email', email.value)
      .single()

    if (!profiles) {
      error.value = 'Account not found'
      return
    }

    if (profiles.pin !== pinString) {
      error.value = 'Incorrect PIN'
      pin.value = ['', '', '', '']
      pinInputs.value[0]?.focus()
      return
    }

    // PIN is correct — if user is already logged in, go to cashier
    if (user.value) {
      navigateTo('/cashier')
    } else {
      // Need to sign in with email — but we need password for that
      // For cashier PIN flow, just redirect if already authenticated
      error.value = 'Please sign in from the main login first, then use PIN for quick cashier access.'
    }
  } catch (e: any) {
    error.value = 'Something went wrong. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen w-full flex">
    <!-- Left: Hero Image -->
    <div class="hidden lg:flex lg:w-1/2 bg-[#162456] relative overflow-hidden items-end">
      <div class="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent z-10" />
      <img
        src="https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80"
        alt="Coffee"
        class="absolute inset-0 w-full h-full object-cover opacity-60"
      />
      <div class="relative z-20 p-12">
        <div class="flex items-center gap-3 mb-4">
          <UIcon name="i-lucide-monitor" class="w-8 h-8 text-white" />
          <span class="text-2xl font-bold text-white">{{ 'POS System' }}</span>
        </div>
        <p class="text-white/80 text-lg max-w-md">
          Streamline your cafe operations with our secure, high-performance point of sale system.
        </p>
      </div>
    </div>

    <!-- Right: Login Form -->
    <div class="flex-1 flex items-center justify-center p-8 bg-gray-50">
      <div class="w-full max-w-md">
        <!-- Terminal badge -->
        <div class="flex justify-end mb-6">
          <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#162456] text-white text-xs font-medium">
            <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
            TERMINAL ACTIVE
          </span>
        </div>

        <h1 class="text-3xl font-bold text-gray-900 mb-2">Welcome Back</h1>
        <p class="text-gray-500 mb-8">Please sign in to your cashier account</p>

        <!-- Error -->
        <div v-if="error" class="mb-4 p-3 rounded-xl bg-red-50 text-red-600 text-sm flex items-center gap-2">
          <UIcon name="i-lucide-alert-circle" class="w-4 h-4 flex-shrink-0" />
          {{ error }}
        </div>

        <!-- Email -->
        <div class="mb-6">
          <label class="block text-xs font-semibold text-gray-500 tracking-wider mb-2">EMAIL</label>
          <div class="relative">
            <UIcon name="i-lucide-at-sign" class="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              v-model="email"
              type="email"
              placeholder="your@email.com"
              class="w-full h-14 pl-12 pr-4 rounded-xl border-2 border-gray-200 bg-white text-gray-900 text-sm focus:border-[#162456] focus:ring-2 focus:ring-[#162456]/20 outline-none transition-all"
            />
          </div>
        </div>

        <!-- PIN -->
        <div class="mb-8">
          <div class="flex items-center justify-between mb-2">
            <label class="block text-xs font-semibold text-gray-500 tracking-wider">SECURITY PIN</label>
            <button class="text-xs font-medium text-red-500 hover:text-red-600 transition-colors">Forgot PIN?</button>
          </div>
          <div class="flex justify-center gap-4">
            <input
              v-for="(_, i) in pin"
              :key="i"
              :ref="el => { if (el) pinInputs[i] = el as HTMLInputElement }"
              v-model="pin[i]"
              type="password"
              maxlength="1"
              inputmode="numeric"
              class="w-20 h-20 text-center text-2xl font-bold rounded-xl border-2 border-gray-200 bg-white text-gray-900 focus:border-[#162456] focus:ring-2 focus:ring-[#162456]/20 outline-none transition-all"
              @input="handlePinInput(i, $event)"
              @keydown="handlePinKeydown(i, $event)"
            />
          </div>
        </div>

        <!-- Submit -->
        <button
          class="w-full h-14 rounded-xl bg-[#162456] text-white font-semibold text-base flex items-center justify-center gap-2 hover:bg-[#1d2f6b] transition-colors disabled:opacity-50"
          :disabled="loading"
          @click="handleLogin"
        >
          <UIcon v-if="!loading" name="i-lucide-log-in" class="w-5 h-5" />
          <UIcon v-else name="i-lucide-loader-2" class="w-5 h-5 animate-spin" />
          Log In to Dashboard
        </button>

        <!-- Footer -->
        <div class="mt-8 pt-6 border-t border-gray-200 text-center">
          <div class="flex items-center justify-center gap-1.5 text-xs text-gray-400 mb-2">
            <UIcon name="i-lucide-lock" class="w-3.5 h-3.5" />
            Encrypted Session • Admin Access Only
          </div>
          <div class="flex items-center justify-center gap-4 text-xs text-gray-400">
            <span class="flex items-center gap-1">
              <UIcon name="i-lucide-globe" class="w-3.5 h-3.5" />
              English (US)
            </span>
            <span class="flex items-center gap-1">
              <UIcon name="i-lucide-help-circle" class="w-3.5 h-3.5" />
              Help Center
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
