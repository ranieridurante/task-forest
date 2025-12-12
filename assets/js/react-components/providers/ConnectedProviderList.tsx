import React, { useEffect, useState } from 'react'
import { Image, useDisclosure } from '@nextui-org/react'
import type {
  TConnectedProviderListProps,
  TProviderWithStoredKeys,
} from 'types/provider'
import ManageProviderKeysModal from './ManageProviderKeysModal'

const ConnectedProviderList = ({
  props,
  pushEvent,
}: LiveReactComponentProps<TConnectedProviderListProps>) => {
  const [providers, setProviders] = useState<TProviderWithStoredKeys[]>(
    props.providers_with_stored_keys
  )

  const [provider, setProvider] = useState<TProviderWithStoredKeys | null>(null)
  const { isOpen, onOpen, onOpenChange } = useDisclosure()

  const openManageProviderKeysModal = (provider: TProviderWithStoredKeys) => {
    setProvider(provider)
    onOpen()
  }

  useEffect(() => {
    const renderNewProvider = (e: Event) => {
      const serverEventData: TServerEvent = e.detail

      const providersWithStoredKeys: TProviderWithStoredKeys[] =
        serverEventData.connected_providers

      setProviders(providersWithStoredKeys)
    }

    window.addEventListener(
      'phx:server.update_connected_providers',
      renderNewProvider
    )

    return () => {
      window.removeEventListener(
        'phx:server.update_connected_providers',
        renderNewProvider
      )
    }
  }, [])

  return (
    <div className='flex gap-4 mt-8 flex-wrap ' id='providers'>
      {providers.map((provider) => (
        <>
          {console.log(provider)}
          <div
            key={provider.slug}
            className='flex flex-col w-32 aspect-square relative cursor-pointer bg-white rounded items-center justify-center'
            onClick={() => openManageProviderKeysModal(provider)}
          >
            <Image
              alt={provider.name}
              className={`object-cover w-24 aspect-square ${
                provider.stored_keys.length + provider.apps.length === 0
                  ? 'grayscale hover:grayscale-0'
                  : ''
              } hover:scale-110`}
              fallbackSrc={`https://fakeimg.pl/100x100?text=${provider.name}`}
              src={provider.logo}
            />
            <p className='text-tiny center mt-1 font-bold'>{provider.name}</p>
            {provider.stored_keys.length + provider.apps.length > 0 && (
              <p className='absolute top-[-12px] right-[-12px] border-1 w-6 aspect-square rounded-full z-10 border-black bg-plombDarkBrown-300 text-white flex text-tiny items-center justify-center'>
                {provider.stored_keys.length + provider.apps.length}
              </p>
            )}
          </div>
        </>
      ))}
      <ManageProviderKeysModal
        isOpen={isOpen}
        onOpenChange={onOpenChange}
        provider={provider}
        pushEvent={pushEvent}
      />
    </div>
  )
}

export default ConnectedProviderList
