import React, { useState } from 'react'
import {
  Button,
  Pagination,
  Spacer,
  Spinner,
  Table,
  TableBody,
  TableCell,
  TableColumn,
  TableHeader,
  TableRow,
  Select,
  RadioGroup,
  Radio,
  cn,
  Chip,
  Switch,
} from '@nextui-org/react'

const BillingPage: React.FC<LiveReactComponentProps<BillingPageProps>> = ({
  props: { transactions, credits_balance, credit_packages, company_id },
  pushEvent,
}) => {
  const ADD_CREDITS_TYPES = ['PURCHASE', 'PROMOTION', 'AFFILIATES', 'SUPPORT']
  const NEGATIVE_REMOVE_CREDITS_TYPES = ['REFUND', 'CHARGEBACK']

  const PLANS = {
    starter: {
      id: 'starter',
      name: 'Starter',
      monthly: 29,
      yearly: 290,
      description: 'Perfect for freelancers and small teams',
      features: {
        'Monthly credits': '10,000',
        Workflows: '10',
        Triggers: '5 active',
        'Plomb AI task runs': '100',
        'Magic Forms': '1 active',
        Seats: '3',
        'Role-based access': 'No',
        'Simultaneous executions': '2',
        'Data retention days': '30',
        'Provider Tasks': 'Public integrations',
        'API access': 'Read-only',
        Support: 'Basic',
      },
    },
    professional: {
      id: 'professional',
      name: 'Professional',
      monthly: 99,
      yearly: 990,
      description: 'Ideal for growing businesses',
      features: {
        'Monthly credits': '50,000',
        Workflows: '50',
        Triggers: '20 active',
        'Plomb AI task runs': '500',
        'Magic Forms': '5 active',
        Seats: '10',
        'Role-based access': 'Yes',
        'Simultaneous executions': '5',
        'Data retention days': '90',
        'Provider Tasks': 'Public integrations',
        'API access': 'Full access',
        Support: 'Priority',
      },
    },
    enterprise: {
      id: 'enterprise',
      name: 'Enterprise',
      description: 'Custom solutions for large organizations',
      features: {
        'Monthly credits': 'Unlimited',
        Workflows: 'Custom',
        Triggers: 'Unlimited',
        'Plomb AI task runs': 'Custom',
        'Magic Forms': 'Custom',
        Seats: 'Unlimited',
        'Role-based access': 'Yes',
        'Simultaneous executions': 'Custom',
        'Data retention days': 'Custom',
        'Provider Tasks': 'Public + custom integrations',
        'API access': 'Full access',
        Support: '24/7 Dedicated',
      },
    },
  }

  const defaultCreditPackage = credit_packages[3]

  const [selectedPackage, setSelectedPackage] =
    useState<CreditPackage>(defaultCreditPackage)
  const [page, setPage] = useState(1)
  const TABLE_ROWS_PER_PAGE = 10

  const [billingInterval, setBillingInterval] = useState<'monthly' | 'yearly'>(
    'monthly'
  )

  const handlePackageSelect = (pkg: CreditPackage) => {
    setSelectedPackage(pkg)
  }

  const handleBuyCredits = () => {
    if (selectedPackage) {
      pushEvent('react.buy_credits', {
        price_id: selectedPackage.price_id,
      })
    }
  }

  const getTransactionAmountClass = (transactionType: string) => {
    if (ADD_CREDITS_TYPES.includes(transactionType)) {
      return 'text-success'
    } else {
      return 'text-danger'
    }
  }

  const getTransactionTypeClass = (transactionType: string) => {
    if (NEGATIVE_REMOVE_CREDITS_TYPES.includes(transactionType)) {
      return 'text-danger'
    }
  }

  const items = React.useMemo(() => {
    const start = (page - 1) * TABLE_ROWS_PER_PAGE
    const end = start + TABLE_ROWS_PER_PAGE
    return transactions.slice(start, end)
  }, [page, transactions])

  const pages = React.useMemo(() => {
    if (transactions?.length) {
      return Math.ceil(transactions.length / TABLE_ROWS_PER_PAGE)
    } else {
      return 0
    }
  }, [transactions?.length, TABLE_ROWS_PER_PAGE])

  const onPageChange = (page: number) => {
    setPage(page)
  }

  const handlePlanClick = (planId: string) => () => {
    pushEvent('react.select_plan', {
      plan_id: planId,
      billing_interval: billingInterval,
    })
  }

  return (
    <div className='flex flex-col justify-center items-center align-center'>
      <h2 className='text-2xl text-primary'>
        Balance : {credits_balance} credits
      </h2>
      <Spacer y={16} />
      <div className='w-full max-w-6xl mx-auto px-4 sm:px-6'>
        <div className='flex justify-center mb-8'>
          <div className='flex items-center gap-2 sm:gap-4'>
            <span className='text-sm sm:text-base'>Monthly</span>
            <Switch
              defaultSelected={billingInterval === 'yearly'}
              size='lg'
              onChange={(e) =>
                setBillingInterval(e.target.checked ? 'yearly' : 'monthly')
              }
            >
              <span className='text-sm sm:text-base'>Yearly (10% off)</span>
            </Switch>
          </div>
        </div>

        <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6'>
          {Object.entries(PLANS).map(([key, plan]) => (
            <Button
              key={key}
              as='a'
              onPress={handlePlanClick(key)}
              className={cn(
                'h-auto p-4 sm:p-6 flex flex-col items-stretch',
                'bg-content1 hover:bg-content2 transition-all',
                'rounded-xl shadow-lg hover:shadow-xl',
                'min-h-[400px]',
                company_id === key && 'border-2 border-primary'
              )}
            >
              {company_id === key && (
                <div className='text-primary text-xs sm:text-sm mb-3 sm:mb-4'>
                  ACTIVE - Renews on {new Date().toLocaleDateString()}
                </div>
              )}

              <h3 className='text-lg sm:text-xl font-bold mb-2'>{plan.name}</h3>

              {key !== 'enterprise' ? (
                <div className='mb-3 sm:mb-4'>
                  <span className='text-2xl sm:text-4xl font-bold'>
                    <span className='text-sm text-default-500'>USD $</span>
                    {billingInterval === 'monthly' ? plan.monthly : plan.yearly}
                  </span>
                  <span className='text-xs sm:text-sm text-default-500'>
                    /{billingInterval}
                  </span>
                </div>
              ) : (
                <Button color='primary' variant='flat' className='mb-3 sm:mb-4'>
                  Request a call
                </Button>
              )}

              <p className='text-xs sm:text-sm text-default-500 mb-4 sm:mb-6'>
                {plan.description}
              </p>

              <div className='flex-grow'>
                {Object.entries(plan.features).map(([feature, value]) => (
                  <div
                    key={feature}
                    className='flex justify-between py-1.5 sm:py-2 border-t border-default-200'
                  >
                    <span className='text-xs sm:text-sm'>{feature}</span>
                    <span className='text-xs sm:text-sm font-medium'>
                      {value}
                    </span>
                  </div>
                ))}
              </div>
            </Button>
          ))}
        </div>
      </div>
      <Spacer y={16} />
      <RadioGroup
        description='Select a package to buy credits.'
        label='Select Credits Package'
        orientation='horizontal'
        size='lg'
        isRequired={true}
        defaultValue={selectedPackage.package_id}
        className='flex flex-col justify-center items-center align-center'
      >
        {credit_packages.map((pkg) => (
          <Radio
            key={pkg.package_id}
            description={`${pkg.price} ${pkg.currency.toUpperCase()}`}
            value={pkg.package_id}
            classNames={{
              base: cn(
                'inline-flex m-0 bg-content1 hover:bg-content2 items-center justify-between',
                'flex-row-reverse max-w-[300px] min-w-[300px] cursor-pointer rounded-lg gap-4 p-4 border-2 border-transparent',
                'data-[selected=true]:border-primary'
              ),
              label: 'text-lg font-bold text-primary',
            }}
            onChange={() => handlePackageSelect(pkg)}
          >
            <h4>
              {pkg.package_id === '500_CREDITS' && (
                <Chip size='sm' className='mb-2' color='primary'>
                  Recommended
                </Chip>
              )}
              {pkg.package_id === '10000_CREDITS' && (
                <Chip size='sm' className='mb-2' color='warning'>
                  Best Value
                </Chip>
              )}
              <br></br>
              {pkg.label}
              <br></br>
            </h4>
          </Radio>
        ))}
      </RadioGroup>
      <Spacer y={2} />
      <div className='flex justify-start'>
        <Button
          color='primary'
          variant='solid'
          size='lg'
          onPress={handleBuyCredits}
        >
          Buy Credits
        </Button>
      </div>
      <Spacer y={16} />
      <Table
        isStriped
        aria-label='Credits Transactions'
        bottomContent={
          pages > 0 && (
            <div className='flex w-full justify-center'>
              <Pagination
                isCompact
                showControls
                showShadow
                color='primary'
                page={page}
                total={pages}
                onChange={onPageChange}
              />
            </div>
          )
        }
      >
        <TableHeader>
          <TableColumn>ID</TableColumn>
          <TableColumn>Order</TableColumn>
          <TableColumn>Transaction Type</TableColumn>
          <TableColumn>Amount</TableColumn>
          <TableColumn>Description</TableColumn>
        </TableHeader>
        <TableBody
          items={items}
          emptyContent='No transactions found.'
          loadingContent={<Spinner />}
        >
          {(item) => (
            <TableRow key={item.id}>
              <TableCell>{item.id}</TableCell>
              <TableCell>{item.order}</TableCell>
              <TableCell
                className={getTransactionTypeClass(item.transaction_type)}
              >
                {item.transaction_type}
              </TableCell>
              <TableCell
                className={getTransactionAmountClass(item.transaction_type)}
              >
                {ADD_CREDITS_TYPES.includes(item.transaction_type) ? '+' : '-'}
                {item.amount}
              </TableCell>
              <TableCell>{item.reason}</TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  )
}

export default BillingPage
