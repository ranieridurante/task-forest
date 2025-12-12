import type { ModalProps } from '@nextui-org/react'
import type { PushEventFunction } from 'types/liveview'
import type React from 'react'
import type { TDataType } from 'types/workflow'

/**
 * Function responsible for updating the input data.
 * @param key Key of the input attribute.
 * @param newValue Value of the input attribute.
 */
type InputChange = (key: string, newValue: string | boolean | number) => void

/**
 * Function responsible for updating output information. Mainly for tasks with language models.
 * @param key Key of the output attribute.
 * @param type Data type of the output attribute.
 */
type OutputChange = (key: string, type?: string) => void

enum TaskConfigType {
  MODEL = 'model',
  ELIXIR = 'elixir',
  HTTP_REQUEST = 'http_request',
}

type TTaskPayload = {
  task_id?: string
  name: string
  workflow_id?: string
  task_type: TaskConfigType
  task_template_id: string
  params: {
    config_overrides?: {
      model_id: string
      model_params: {
        prompt: string
      }
    }
    inputs_definition: TIODefinitions
    outputs_definition?: TIODefinitions
  }
}

type TModelTaskConfig = {
  type: TaskConfigType.MODEL
  model_id: string
  available_models: string[]
  model_params: {
    prompt?: string
    capability?: string
    response_format?: { [key: string]: string }
    temperature?: number
  }
}

type TElixirTaskConfig = {
  type: TaskConfigType.ELIXIR
  module: string
}

type THttpRequestTaskConfig = {
  type: TaskConfigType.HTTP_REQUEST
  request_uri: string
  request_method: string
  request_host: string
  request_name: string
  request_params: { [key: string]: any }
  outputs_mapper?: { [key: string]: string }
  outputs_validations?: { [key: string]: any }
  request_headers_definition?: { [key: string]: any }
}

type TTaskConfig = {
  type: TaskConfigType
  sleep_after?: number
  sleep_before?: number
  max_concurrency?: number
} & (TModelTaskConfig | THttpRequestTaskConfig | TElixirTaskConfig)

type TIODefinition = {
  type: TDataType
  value?: any
}

type TIODefinitions = {
  [p: string]: TIODefinition
}

type TTask = {
  task_id?: string
  label?: string
  task_config: TTaskConfig
  inputs_definition: TIODefinitions
  outputs_definition: TIODefinitions
  workflow_id?: string
  task_template?: TTaskTemplate
  task_template_id: string
}

type TTaskTemplatesCollection = {
  [uuid: string]: TTaskTemplate
}

type TTaskTemplate = {
  id: string
  name: string
  description: string
  config: TTaskConfig
  provider_slug: string
  provider_logo: string
  provider_name: string
  provider_website: string
  inputs_definition: TIODefinitions
  outputs_definition: TIODefinitions
  style: {
    background_color: string
    icon: string
    icon_color?: string
  }
}

type TTaskProvider = {
  slug: string
  name: string
  style: {
    background_color: string
    icon: string
    icon_color?: string
  }
}

type TTaskModelFormProps = {
  task: TTask
  handleOutputChange: OutputChange
  handleModelChange: InputChange
}

type TTaskFormInputsProps = {
  placeholders?: TIODefinitions
  handleInputChange: InputChange
} & Pick<TTaskTemplate, 'inputs_definition'>

type TTaskFormOutputChipsProps = Pick<TTaskTemplate, 'outputs_definition'>

type TTaskFormProps = {
  task?: TTask
  setActualTask: React.Dispatch<React.SetStateAction<TTask | undefined>>
  handleInputChange: InputChange
  handleOutputChange: OutputChange
  handleModelChange: InputChange
}

type TTaskTemplateGridProps = {
  taskTemplates: TTaskTemplate[]
  onTaskTemplateSelect: (taskTemplate: TTaskTemplate) => void
}

type TTaskProviderGridProps = {
  taskProviders: Map<string, TTaskProvider>
  onTaskProviderSelect: (taskProviderSlug: string) => void
}

type TTaskModalProps = {
  task?: TTask
  taskTemplates: TTaskTemplatesCollection
  pushEvent: PushEventFunction
  workflow_id: string
} & Pick<ModalProps, 'isOpen' | 'onOpenChange' | 'onClose'>
