type Transaction = {
  id: string
  order: string
  transaction_type: string
  amount: number
  reason: string
}

type CreditPackage = {
  credits_amount: number
  price: number
  currency: string
  label: string
  package_id: string
  price_id: string
}

type BillingPageProps = {
  transactions: Transaction[]
  credits_balance: number
  credit_packages: CreditPackage[]
  company_id: string
}
