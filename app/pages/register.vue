<script setup lang="ts">
definePageMeta({
  layout: 'default'
})

const form = ref({
  storeName: '',
  ownerName: '',
  email: '',
  password: ''
})

const loading = ref(false)

const handleRegister = () => {
  loading.value = true
  setTimeout(() => {
    localStorage.setItem('isAuthenticated', 'true')
    localStorage.removeItem('hasSeenOnboarding') 
    navigateTo('/backoffice')
    loading.value = false
  }, 800)
}
</script>

<template>
  <div class="min-h-screen bg-[#F8FAFC] flex flex-col items-center justify-center p-4 font-sans">
    
    <div class="max-w-[420px] w-full p-10 bg-white rounded-[2.5rem] shadow-[0_8px_30px_rgb(0,0,0,0.04)] flex flex-col gap-6 transform transition-all border border-gray-100">
      
      <div class="text-center mb-2 mt-2">
        <div class="w-16 h-16 bg-[#E8F8F0] text-[#00E676] rounded-[1.25rem] flex items-center justify-center mx-auto mb-6">
          <UIcon name="i-lucide-store" class="w-8 h-8" />
        </div>
        <h1 class="text-[1.75rem] leading-tight font-extrabold text-[#0F172A] mb-3 tracking-tight">Create your Store</h1>
        <p class="text-[#64748B] text-sm font-medium">Join Komo POS and start managing your business today</p>
      </div>
      
      <form @submit.prevent="handleRegister" class="flex flex-col gap-3 mt-4">
        
        <div class="relative">
          <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-[#64748B]">
            <UIcon name="i-lucide-building" class="h-5 w-5" />
          </div>
          <input 
            v-model="form.storeName" 
            type="text" 
            placeholder="e.g. Komo Coffee Shop" 
            required
            class="block w-full pl-12 pr-4 py-3.5 bg-[#0F172A] border border-[#0F172A] rounded-[0.85rem] text-white placeholder-[#475569] focus:bg-[#1E293B] focus:border-[#00E676] focus:ring-1 focus:ring-[#00E676] outline-none transition-all focus:outline-none"
          />
        </div>

        <div class="relative">
          <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-[#64748B]">
            <UIcon name="i-lucide-user" class="h-5 w-5" />
          </div>
          <input 
            v-model="form.ownerName" 
            type="text" 
            placeholder="e.g. John Doe" 
            required
            class="block w-full pl-12 pr-4 py-3.5 bg-[#0F172A] border border-[#0F172A] rounded-[0.85rem] text-white placeholder-[#475569] focus:bg-[#1E293B] focus:border-[#00E676] focus:ring-1 focus:ring-[#00E676] outline-none transition-all focus:outline-none"
          />
        </div>
        
        <div class="relative">
          <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-[#64748B]">
            <UIcon name="i-lucide-mail" class="h-5 w-5" />
          </div>
          <input 
            v-model="form.email" 
            type="email" 
            placeholder="owner@store.com" 
            required
            class="block w-full pl-12 pr-4 py-3.5 bg-[#0F172A] border border-[#0F172A] rounded-[0.85rem] text-white placeholder-[#475569] focus:bg-[#1E293B] focus:border-[#00E676] focus:ring-1 focus:ring-[#00E676] outline-none transition-all focus:outline-none"
          />
        </div>
        
        <div class="relative">
          <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-[#64748B]">
            <UIcon name="i-lucide-lock" class="h-5 w-5" />
          </div>
          <input 
            v-model="form.password" 
            type="password" 
            placeholder="••••••••" 
            required
            class="block w-full pl-12 pr-4 py-3.5 bg-[#0F172A] border border-[#0F172A] rounded-[0.85rem] text-white placeholder-[#475569] focus:bg-[#1E293B] focus:border-[#00E676] focus:ring-1 focus:ring-[#00E676] outline-none transition-all focus:outline-none"
          />
        </div>
        
        <button 
          type="submit" 
          :disabled="loading"
          class="mt-6 w-full flex items-center justify-center py-4 px-4 border border-transparent rounded-xl shadow-sm text-[1.05rem] font-bold text-[#0F172A] bg-[#00E676] hover:bg-[#00C853] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#00E676] transition-colors disabled:opacity-70 disabled:cursor-not-allowed"
        >
          <UIcon v-if="loading" name="i-lucide-loader-2" class="animate-spin h-5 w-5 mr-2" />
          Create Account
        </button>
      </form>
      
      <div class="text-center text-[0.95rem] text-[#64748B] mt-2 mb-2 font-medium">
        Already have an account? 
        <NuxtLink to="/login" class="text-[#00E676] font-semibold hover:text-[#00C853] transition-colors ml-1">Sign In here</NuxtLink>
      </div>
      
    </div>
  </div>
</template>
