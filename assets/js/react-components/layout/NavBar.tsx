import React from 'react'
import {
  Navbar,
  NavbarBrand,
  NavbarContent,
  NavbarItem,
  Link,
  Button,
  Chip,
  DropdownTrigger,
  DropdownMenu,
  DropdownItem,
  Dropdown,
  Avatar,
  avatar,
} from '@nextui-org/react'

type TNavBarProps = {
  user_info?: {
    email: string
    first_name: string
    last_name: string
  }
}

export default function NavBar({
  props,
}: LiveReactComponentProps<TNavBarProps>) {
  let logoUrl = '/login'
  if (props.user_info) {
    logoUrl = '/'
  }

  let avatarUrl = ''
  if (props.user_info) {
    avatarUrl = `https://api.dicebear.com/9.x/thumbs/svg?seed=${props.user_info.first_name}+${props.user_info.last_name}&scale=80&radius=50&backgroundColor=69d2e7,f1f4dc,1c799f,0a5b83&eyes=variant5W10,variant5W12,variant5W14,variant5W16,variant6W10,variant6W12,variant6W14,variant6W16,variant8W10,variant8W12,variant8W14,variant8W16&mouth=variant1,variant2,variant3,variant4&shapeColor=0a5b83,1c799f,69d2e7,f1f4dc`
  }

  return (
    <Navbar className='bg-white mb-3' maxWidth='full'>
      <NavbarBrand>
        <Link
          size='lg'
          className='font-bold text-inherit text-2xl mr-4 text-primary mt-4'
          href={logoUrl}
        >
          <img
            className='w-[5rem]'
            src='/images/plomb-logo.svg'
            alt='Plomb.ai Logo'
          />
        </Link>
      </NavbarBrand>

      {!props.user_info && (
        <NavbarContent as='div' justify='end'>
          <NavbarItem key='login'>
            <Button as={Link} href='/login' color='primary' variant='light'>
              Log in
            </Button>
          </NavbarItem>
          <NavbarItem key='signup'>
            <Button as={Link} href='/signup' color='primary' variant='solid'>
              Create account
            </Button>
          </NavbarItem>
        </NavbarContent>
      )}
    </Navbar>
  )
}
