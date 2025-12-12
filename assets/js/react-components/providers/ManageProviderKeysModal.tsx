import {
  Accordion,
  AccordionItem,
  Button,
  Divider,
  Image,
  Input,
  Modal,
  ModalBody,
  ModalContent,
  ModalFooter,
  ModalHeader,
} from '@nextui-org/react'
import React, { useEffect, useState } from 'react'
import type {
  TCompanyProviderApp,
  TCompanyProviderAppConfig,
} from 'types/provider'
import {
  TProviderAppConfigDefinition,
  type TManageProviderKeysModalProps,
  type TNewProviderKeyPayload,
  type TStoredProviderKey,
} from 'types/provider'
import { parseMarkdown } from '../../util'

const ManageProviderKeysModal: React.FC<TManageProviderKeysModalProps> = ({
  ...props
}) => {
  const { isOpen, onOpenChange, provider, pushEvent } = props

  if (!provider) {
    return
  }

  const defaultAlias = `${provider.name} key`
  const [alias, setAlias] = useState<string>('')
  const [keys, setKeys] = useState<{ [key: string]: string }>({})
  const [providerKeys, setProviderKeys] = useState<TStoredProviderKey[]>([])

  const defaultAppName = `${provider.name} app`
  const [appName, setAppName] = useState<string>('')
  const [appConfig, setAppConfig] = useState<TCompanyProviderAppConfig>({})
  const [providerApps, setProviderApps] = useState<TCompanyProviderApp[]>([])

  // Function to handle changes in dynamic inputs
  const handleKeyChange = (keySlug: string, value: string) => {
    setKeys({
      ...keys,
      [keySlug]: value,
    })
  }

  const handleAppConfigChange = (keySlug: string, value: string) => {
    setAppConfig({
      ...appConfig,
      [keySlug]: value,
    })
  }

  const handleAddAccount = (appId: string) => {
    pushEvent('react.add_account', {
      app_id: appId,
    })
  }

  const handleAddKeyButton = () => {
    const newKey: TNewProviderKeyPayload = {
      alias: alias || defaultAlias,
      keys,
    }

    pushEvent('react.add_provider_key', {
      ...newKey,
      provider_id: provider.id,
    })

    setAlias('')
    setKeys({})
  }

  const handleAddNewAppButton = () => {
    pushEvent('react.configure_new_app', {
      name: appName || defaultAppName,
      config: appConfig,
      provider_slug: provider.slug,
      provider_id: provider.id,
    })

    setAppName('')
    setAppConfig({})
  }

  const handleDeleteKeyButton = (keyId: string) => {
    pushEvent('react.delete_provider_key', {
      key_id: keyId,
      provider_id: provider.id,
    })

    setProviderKeys(providerKeys.filter((key) => key.id !== keyId))
  }

  // TODO: implement handleDeleteAppButton w/ Liveview handler

  const handleDeleteAppButton = (appId: string) => {
    pushEvent('react.delete_app', {
      app_id: appId,
      provider_id: provider.id,
    })

    setProviderApps(providerApps.filter((app) => app.id !== appId))

    setProviderKeys(providerKeys.filter((key) => key.id !== keyId))
  }

  const buildAppCallbackUrl = (appId: string) => {
    return `https://app.plomb.ai/apps/${appId}/callback`
  }

  useEffect(() => {
    if (isOpen) {
      setAlias('')
      setKeys({})
      setProviderKeys(provider.stored_keys)

      setAppName('')
      setAppConfig({})
      setProviderApps(provider.apps)
    }
  }, [isOpen])

  useEffect(() => {
    const renderProviderKeys = (e: Event) => {
      const serverEventData = e.detail

      setProviderKeys(serverEventData.provider_stored_keys)
    }

    window.addEventListener(
      'phx:server.update_provider_stored_keys',
      renderProviderKeys
    )

    return () => {
      window.removeEventListener(
        'phx:server.update_provider_stored_keys',
        renderProviderKeys
      )
    }
  }, [])

  useEffect(() => {
    const renderProviderApps = (e: Event) => {
      const serverEventData = e.detail

      setProviderApps(serverEventData.provider_app_configs)
    }

    window.addEventListener(
      'phx:server.update_provider_app_configs',
      renderProviderApps
    )

    return () => {
      window.removeEventListener(
        'phx:server.update_provider_app_configs',
        renderProviderApps
      )
    }
  }, [])

  return (
    <Modal
      isOpen={isOpen}
      onOpenChange={onOpenChange}
      size='xl'
      scrollBehavior='inside'
      placement='top-center'
      backdrop='blur'
      className='bg-plombYellow-500'
    >
      <ModalContent>
        {() => (
          <>
            <ModalHeader className='flex-row'>
              <Image
                alt={provider.name}
                className='object-cover w-12 aspect-square mr-2'
                fallbackSrc={`https://fakeimg.pl/100x100?text=${provider.name}`}
                src={provider.logo}
              />
              <div className='text-plombBlack-500'>
                <h1>Manage provider keys</h1>
                <p className='text-tiny'>
                  for <b>{provider.name}</b>
                </p>
              </div>
            </ModalHeader>
            {!provider.app_config_definition && (
              <ModalBody>
                <p>
                  <i>
                    Here you can add your credentials for <b>{provider.name}</b>
                    . You can add and remove multiple keys.
                  </i>
                </p>
                <Accordion isCompact>
                  <AccordionItem
                    key='1'
                    aria-label='Accordion 1'
                    title='Instructions'
                    className='text-tiny'
                  >
                    {parseMarkdown(provider.instructions)}
                  </AccordionItem>
                </Accordion>
                <Divider orientation='horizontal' />
                <h4>Keys</h4>
                {providerKeys.length === 0 && (
                  <p className='text-tiny text-center'>
                    No keys are currently registered.
                  </p>
                )}
                {providerKeys.length > 0 && (
                  <div className='grid grid-cols-2 gap-4'>
                    {providerKeys.map((key) => (
                      <div
                        className='bg-white border-2 border-plombBlack-500 p-2 text-tiny relative rounded'
                        key={key.id}
                      >
                        <p>
                          <b>{key.alias}</b>
                        </p>
                        <p>
                          <b>Created at</b>:{key.inserted_at}
                        </p>
                        <Button
                          isIconOnly
                          className='absolute top-[-12px] right-[-12px]'
                          size='sm'
                          color='danger'
                          onPress={(e) => {
                            handleDeleteKeyButton(key.id)
                          }}
                        >
                          <iconify-icon
                            icon='tabler:trash'
                            width='24'
                            height='24'
                          />
                        </Button>
                      </div>
                    ))}
                  </div>
                )}
                <Divider orientation='horizontal' />
                <h1 className='text-lg font-bold'>Add new key</h1>
                <Input
                  key='key-alias'
                  autoFocus
                  startContent={
                    <iconify-icon
                      icon='fluent:tag-28-filled'
                      width='16'
                      height='16'
                    />
                  }
                  label='Key alias (optional)'
                  placeholder={defaultAlias}
                  variant='flat'
                  value={alias}
                  onValueChange={setAlias}
                />
                {Object.entries(provider.keys).map(([keySlug, key]) => (
                  <Input
                    key={keySlug}
                    startContent={
                      <iconify-icon
                        icon='ic:outline-key'
                        width='16'
                        height='16'
                      />
                    }
                    isRequired={key.required}
                    label={key.name || keySlug}
                    description={key.description}
                    variant='flat'
                    value={keys[keySlug] || ''}
                    onValueChange={(value) => handleKeyChange(keySlug, value)}
                  />
                ))}
                <Button
                  className='shrink-0'
                  color='primary'
                  startContent={
                    <iconify-icon
                      icon='ic:outline-key'
                      width='24'
                      height='24'
                    />
                  }
                  onPress={handleAddKeyButton}
                >
                  Add key
                </Button>
              </ModalBody>
            )}
            {provider.app_config_definition && (
              <ModalBody>
                <p>
                  <i>
                    Here you can authorize access for <b>{provider.name}</b>.
                    You can also add your own apps and authenticate through
                    them.
                  </i>
                </p>

                <Divider orientation='horizontal' />
                {providerApps.length === 0 && (
                  <p className='text-tiny text-center'>
                    No apps are currently configured.
                  </p>
                )}
                {providerApps.length > 0 && (
                  <>
                    <h4>Apps</h4>
                    <div className='grid grid-cols-2 gap-4'>
                      {providerApps.map((app) => (
                        <div
                          className='bg-white border-2 border-plombBlack-500 p-2 text-tiny relative rounded'
                          key={app.id}
                        >
                          <p>
                            <b>{app.name}</b>
                          </p>
                          <Button
                            className='mt-2'
                            size='md'
                            color='primary'
                            onPress={() => handleAddAccount(app.id)}
                          >
                            <iconify-icon
                              icon='ic:baseline-login'
                              width='24'
                              height='24'
                            />{' '}
                            Add Account
                          </Button>
                          <br></br>
                          <br></br>
                          <p>
                            <i>Redirect URL</i>:<br></br>
                            {buildAppCallbackUrl(app.id)}
                          </p>
                          <Button
                            isIconOnly
                            className='absolute top-[-12px] right-[-12px]'
                            size='sm'
                            color='danger'
                            onPress={() => {
                              if (
                                window.confirm(
                                  'Are you sure you want to delete this app? All your authorizations will be deleted as well and your workflows may stop working.'
                                )
                              ) {
                                handleDeleteAppButton(app.id)
                              }
                            }}
                          >
                            <iconify-icon
                              icon='tabler:trash'
                              width='24'
                              height='24'
                            />
                          </Button>
                        </div>
                      ))}
                    </div>
                  </>
                )}
                <Divider orientation='horizontal' />
                <h4>Keys</h4>
                {providerKeys.length === 0 && (
                  <p className='text-tiny text-center'>
                    No keys are currently registered.
                  </p>
                )}
                {providerKeys.length > 0 && (
                  <div className='grid grid-cols-2 gap-4'>
                    {providerKeys.map((key) => (
                      <div
                        className='bg-white border-2 border-plombBlack-500 p-2 text-tiny relative rounded'
                        key={key.id}
                      >
                        <p>
                          <b>{key.alias}</b>
                        </p>
                        <p>
                          <b>Created at</b>:{key.inserted_at}
                        </p>
                        <Button
                          isIconOnly
                          className='absolute top-[-12px] right-[-12px]'
                          size='sm'
                          color='danger'
                          onPress={(e) => {
                            handleDeleteKeyButton(key.id)
                          }}
                        >
                          <iconify-icon
                            icon='tabler:trash'
                            width='24'
                            height='24'
                          />
                        </Button>
                      </div>
                    ))}
                  </div>
                )}
                <Divider orientation='horizontal' />
                <Accordion isCompact>
                  <AccordionItem
                    key='1'
                    aria-label='Accordion 1'
                    title='Instructions'
                    className='text-tiny'
                  >
                    {parseMarkdown(provider.app_setup_instructions)}
                  </AccordionItem>
                </Accordion>
                <Divider orientation='horizontal' />
                <h1 className='text-lg font-bold'>Configure new app</h1>
                <Input
                  key='key-alias'
                  autoFocus
                  startContent={
                    <iconify-icon
                      icon='fluent:tag-28-filled'
                      width='16'
                      height='16'
                    />
                  }
                  label='App name (optional)'
                  placeholder={defaultAppName}
                  variant='flat'
                  value={appName}
                  onValueChange={setAppName}
                />
                {Object.entries(provider.app_config_definition.user_fields).map(
                  ([keySlug, key]) => (
                    <>
                      {!key.hidden && (
                        <Input
                          key={keySlug}
                          startContent={
                            <iconify-icon
                              icon='ic:outline-key'
                              width='16'
                              height='16'
                            />
                          }
                          isRequired={key.required}
                          label={key.name || keySlug}
                          description={key.description}
                          variant='flat'
                          value={appConfig[keySlug] || key.value || ''}
                          onValueChange={(value) =>
                            handleAppConfigChange(keySlug, value)
                          }
                        />
                      )}
                    </>
                  )
                )}
                <Button
                  className='shrink-0'
                  color='primary'
                  startContent={
                    <iconify-icon
                      icon='ic:outline-key'
                      width='24'
                      height='24'
                    />
                  }
                  onPress={handleAddNewAppButton}
                >
                  Add new app
                </Button>
              </ModalBody>
            )}
            <ModalFooter></ModalFooter>
          </>
        )}
      </ModalContent>
    </Modal>
  )
}

export default ManageProviderKeysModal
