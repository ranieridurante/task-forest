import {
  Avatar,
  Button,
  Dropdown,
  DropdownItem,
  DropdownMenu,
  DropdownSection,
  DropdownTrigger,
  Link,
  Popover,
  PopoverContent,
  PopoverTrigger,
  Select,
  SelectItem,
  Tooltip,
} from '@nextui-org/react'
import React, { useEffect } from 'react'
import { generateGravatarUrl } from '../../utils'

type TServerEvent = {
  new_active_company: TCompany
}
import { user_has_permission } from 'permissions'

type TNavBarProps = {
  user_info: TUserInfo
  user_companies: TCompany[]
  active_company: TCompany
  allow_org_switch?: boolean
  render_logo?: boolean
}

export type TUserInfo = {
  email: string
  first_name: string
  last_name: string
  is_plomb_admin: boolean
}

export type TUserCompanyPermissions = {
  is_admin: boolean
  roles: string[]
}

export type TCompany = {
  name: string
  id: string
  website: string
  slug: string
} & TUserCompanyPermissions

const Sidebar = ({
  props,
  pushEvent,
}: LiveReactComponentProps<TNavBarProps>) => {
  const [activeOrg, setActiveOrg] = React.useState(props.active_company)

  const switchOrg = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const new_active_company_slug = e.target.value

    pushEvent('react.switch_organization', {
      new_active_company_slug: new_active_company_slug,
    })
  }

  useEffect(() => {
    const switchOrganization = (e: Event) => {
      const server_event_data: TServerEvent = (e as CustomEvent).detail
      const new_active_company: TCompany = server_event_data.new_active_company

      setActiveOrg(new_active_company)
    }

    window.addEventListener(
      'phx:server.switch_organization',
      switchOrganization
    )

    return () => {
      window.removeEventListener(
        'phx:server.switch_organization',
        switchOrganization
      )
    }
  }, [])

  let logoUrl = '/login'
  if (props.user_info) {
    logoUrl = '/'
  }

  return (
    <aside className='sticky top-6 h-fit mx-3'>
      <nav className=' flex flex-col gap-4'>
        {props.render_logo && (
          <Link
            size='lg'
            className='font-bold text-inherit text-2xl mr-4 text-primary'
            href={logoUrl}
          >
            <img
              className='w-[1.5rem] ml-3'
              src='/images/plomb-reduction.svg'
              alt='Plomb.ai Mini Logo'
            />
          </Link>
        )}
        <Dropdown placement='right' className='bg-plombYellow-200 '>
          <DropdownTrigger>
            <Avatar
              isBordered
              as='button'
              className='transition-transform ml-1 mt-1'
              color='primary'
              size='sm'
              src={generateGravatarUrl(props.user_info.email)}
              showFallback
              fallback={<iconify-icon icon='ph:user' width='24' height='24' />}
            />
          </DropdownTrigger>
          <DropdownMenu aria-label='Profile Actions' variant='flat'>
            <DropdownItem key='profile' className='h-14 gap-2'>
              <p className='font-semibold'>Hello, you’re signed in as</p>
              <p className='font-semibold'>{props.user_info.email}</p>
            </DropdownItem>
            <DropdownItem key='logout' color='danger' href='/logout'>
              Log out
            </DropdownItem>
          </DropdownMenu>
        </Dropdown>

        <Popover placement='right' className='bg-plombYellow-200'>
          <PopoverTrigger>
            <Avatar
              isBordered
              as='button'
              className='transition-transform ml-1 mt-1'
              color='primary'
              size='sm'
              radius='sm'
              showFallback
              fallback={
                <iconify-icon
                  icon='octicon:organization-24'
                  width='24'
                  height='24'
                />
              }
              src={`https://logo.clearbit.com/${activeOrg.website}`}
            />
          </PopoverTrigger>
          <PopoverContent>
            {props.allow_org_switch ? (
              <>
                {props.user_companies.length > 1 && (
                  <Select
                    disallowEmptySelection
                    selectionMode='single'
                    selectedKeys={[activeOrg.slug]}
                    onChange={switchOrg}
                    label='Switch organization'
                    className='w-[20rem]'
                    color='warning'
                  >
                    {props.user_companies.map((org) => (
                      <SelectItem key={org.slug} textValue={org.name}>
                        {org.name}
                      </SelectItem>
                    ))}
                  </Select>
                )}
                {props.user_companies.length === 1 && (
                  <div className='flex flex-col gap-2'>
                    <p className='font-semibold'>{activeOrg.name}</p>
                    {activeOrg.website && (
                      <p className='text-tiny'>{activeOrg.website}</p>
                    )}
                  </div>
                )}
              </>
            ) : (
              <div className='flex flex-col gap-2 '>
                <p className='font-semibold'>
                  Active Company: {activeOrg.name}
                </p>
                <p className='text-tiny'>
                  You can't switch companies while interacting with a workflow
                </p>
              </div>
            )}
          </PopoverContent>
        </Popover>
        <div className='h-1 rounded bg-plombYellow-300 max-w'></div>
        <Tooltip placement='right' content='Home' closeDelay={0}>
          <Link href='/home'>
            <Button
              isIconOnly={true}
              className='bg-plombLightBrown-500 text-plombYellow-100 fill-plombYellow-100'
            >
              <iconify-icon
                icon='mingcute:home-7-fill'
                width='24'
                height='24'
              />
            </Button>
          </Link>
        </Tooltip>
        {props.user_info.is_plomb_admin && (
          <Tooltip placement='right' content='Templates Market' closeDelay={0}>
            <Link href='/market'>
              <Button
                isIconOnly={true}
                className='bg-plombLightBrown-500 text-plombYellow-100 fill-plombYellow-100'
              >
                <iconify-icon icon='fa-solid:store' width='24' height='24' />
              </Button>
            </Link>
          </Tooltip>
        )}
        {user_has_permission(
          props.active_company.roles,
          props.active_company.is_admin,
          ['credentials_manager']
        ) && (
          <Tooltip
            placement='right'
            content='Connected Services'
            closeDelay={0}
          >
            <Link href='/provider-keys'>
              <Button
                isIconOnly={true}
                className='bg-plombLightBrown-500 text-plombYellow-100 fill-plombYellow-100'
              >
                <iconify-icon
                  icon='tdesign:app-filled'
                  width='24'
                  height='24'
                />
              </Button>
            </Link>
          </Tooltip>
        )}

        {user_has_permission(
          props.active_company.roles,
          props.active_company.is_admin,
          ['billing_manager']
        ) && (
          <Tooltip placement='right' content='Billing' closeDelay={0}>
            <Link href='/billing'>
              <Button
                isIconOnly={true}
                className='bg-plombLightBrown-500 text-plombYellow-100 fill-plombYellow-100'
              >
                <iconify-icon
                  icon='ph:credit-card-fill'
                  width='24'
                  height='24'
                />
              </Button>
            </Link>
          </Tooltip>
        )}

        <Tooltip placement='right' content='API Keys' closeDelay={0}>
          <Link href='/api-keys'>
            <Button
              isIconOnly={true}
              className='bg-plombLightBrown-500 text-plombYellow-100 fill-plombYellow-100'
            >
              <iconify-icon
                icon='material-symbols:key'
                width='24'
                height='24'
              />
            </Button>
          </Link>
        </Tooltip>

        {props.user_info.is_plomb_admin && (
          <>
            <div className='h-1 rounded bg-plombYellow-300 max-w'></div>
            <Tooltip placement='right' content='Providers' closeDelay={0}>
              <Link href='/admin/providers'>
                <Button
                  isIconOnly={true}
                  className='bg-plombPink-500 text-plombYellow-100 fill-plombYellow-100'
                >
                  <iconify-icon icon='ic:twotone-api' width='24' height='24' />
                </Button>
              </Link>
            </Tooltip>
            <Tooltip placement='right' content='Task templates' closeDelay={0}>
              <Link href='/admin/task-templates'>
                <Button
                  isIconOnly={true}
                  className='bg-plombPink-500 text-plombYellow-100 fill-plombYellow-100'
                >
                  <iconify-icon icon='tabler:template' width='24' height='24' />
                </Button>
              </Link>
            </Tooltip>
            <Tooltip
              placement='right'
              content='Workflow templates'
              closeDelay={0}
            >
              <Link href='/admin/workflow-templates'>
                <Button
                  isIconOnly={true}
                  className='bg-plombPink-500 text-plombYellow-100 fill-plombYellow-100'
                >
                  <iconify-icon
                    icon='zondicons:library'
                    width='24'
                    height='24'
                  />
                </Button>
              </Link>
            </Tooltip>
            <Tooltip
              placement='right'
              content='Phoenix Dashboard'
              closeDelay={0}
            >
              <Link href='/admin/dashboard/home' target='_blank'>
                <Button
                  isIconOnly={true}
                  className='bg-plombPink-500 text-plombYellow-100 fill-plombYellow-100'
                >
                  <iconify-icon
                    icon='ic:outline-dashboard'
                    width='24'
                    height='24'
                  />
                </Button>
              </Link>
            </Tooltip>
            <Tooltip placement='right' content='Oban Dashboard' closeDelay={0}>
              <Link href='/admin/oban' target='_blank'>
                <Button
                  isIconOnly={true}
                  className='bg-plombPink-500 text-plombYellow-100 fill-plombYellow-100'
                >
                  <iconify-icon
                    icon='carbon:batch-job'
                    width='24'
                    height='24'
                  />
                </Button>
              </Link>
            </Tooltip>
          </>
        )}
      </nav>
    </aside>
  )
}

export default Sidebar
