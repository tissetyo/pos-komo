/**
 * Composable for currency formatting based on outlet settings.
 * Reads currency from useUserProfile's outletId and caches it.
 */
const CURRENCY_MAP: Record<string, { symbol: string; locale: string; code: string }> = {
    MYR: { symbol: 'RM', locale: 'en-MY', code: 'MYR' },
    IDR: { symbol: 'Rp', locale: 'id-ID', code: 'IDR' },
    SGD: { symbol: 'S$', locale: 'en-SG', code: 'SGD' },
    USD: { symbol: '$', locale: 'en-US', code: 'USD' },
    PHP: { symbol: '₱', locale: 'en-PH', code: 'PHP' },
    THB: { symbol: '฿', locale: 'th-TH', code: 'THB' },
}

// Global state shared across all pages
const currencyCode = ref('MYR')
const currencyLoaded = ref(false)

export const useCurrency = () => {
    const info = computed(() => CURRENCY_MAP[currencyCode.value] || CURRENCY_MAP.MYR)

    const formatPrice = (amount: number) => {
        const { symbol } = info.value
        return `${symbol}${amount.toLocaleString('en', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
    }

    const formatPriceShort = (amount: number) => {
        const { symbol } = info.value
        return `${symbol}${amount.toLocaleString('en', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`
    }

    const symbol = computed(() => info.value.symbol)

    const loadCurrency = async (outletId: string) => {
        if (currencyLoaded.value) return
        const client = useSupabaseClient()
        const { data } = await client.from('outlets').select('currency').eq('id', outletId).single()
        if (data?.currency) {
            currencyCode.value = data.currency
        }
        currencyLoaded.value = true
    }

    return { currencyCode, symbol, formatPrice, formatPriceShort, loadCurrency, info }
}
