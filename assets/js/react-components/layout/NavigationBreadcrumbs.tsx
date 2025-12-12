import React from 'react'
import { Breadcrumbs, BreadcrumbItem, Button, Link } from '@nextui-org/react'

type TNavigationBreadcrumbsProps = {
  props: {
    routes: TNavigationBreadcrumbItemProps[]
    style?: React.CSSProperties
    btnStyle?: React.CSSProperties
    className?: string
  }
}

type TNavigationBreadcrumbItemProps = {
  href: string
  label: string
  active?: boolean
  icon?: string
}

const NavigationBreadcrumbs: React.FC<TNavigationBreadcrumbsProps> = ({
  props,
}) => {
  return (
    <div style={props.style} className={props.className}>
      <div className='flex flex-row items-center w-full'>
        <Breadcrumbs variant='solid'>
          {props.routes.map((route) => (
            <BreadcrumbItem
              key={route.href}
              isCurrent={route.active}
              className={route.active ? 'text-lg font-semibold' : 'text-lg'}
              startContent={
                route.icon && (
                  <iconify-icon icon={route.icon} width='16' height='16' />
                )
              }
              color='primary'
              href={route.href}
            >
              {route.label}
            </BreadcrumbItem>
          ))}
        </Breadcrumbs>
      </div>
    </div>
  )
}

export default NavigationBreadcrumbs
