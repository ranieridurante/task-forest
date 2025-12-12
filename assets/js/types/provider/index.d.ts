import type { ModalProps } from '@nextui-org/react'
import type { PushEventFunction } from '../liveview'

type TNewProviderKeyPayload = {
  alias: string
  keys: {
    [key: string]: string
  }
}

type TStoredProviderKey = {
  keys: {
    [key: string]: string
  }
  alias: string
  id: string
  inserted_at: string
}

type TCompanyProviderApp = {
  id: string
  inserted_at: string
  name: string
  provider_slug: string
  config?: TCompanyProviderAppConfig
}

type TCompanyProviderAppConfig = {
  [key: string]: string
}

type TProviderKey = {
  [key: string]: {
    required: boolean
    name: string
    description: string
  }
}

type TProviderWithStoredKeys = {
  id: string
  name: string
  keys: TProviderKey
  stored_keys: TStoredProviderKey[]
  instructions: string
  logo: string
  slug: string
  app_config_definition: TProviderAppConfigDefinition
  app_setup_instructions: string
  apps: TCompanyProviderApp[]
}

type TProviderAppConfigDefinition = {
  user_fields: {
    [key: string]: {
      name: string
      required: boolean
      description: string
    }
  }
}

type TManageProviderKeysModalProps = Pick<
  ModalProps,
  'isOpen' | 'onOpenChange'
> & { provider: TProviderWithStoredKeys | null; pushEvent: PushEventFunction }

type TConnectedProviderListProps = {
  providers_with_stored_keys: TProviderWithStoredKeys[]
  company_id: string
}
