import type { Edge } from 'reactflow'
import type { TIODefinitions, TTaskTemplatesCollection } from '../task'
import type { TCompany, TUserInfo } from '../../react-components/layout/Sidebar'
import type { ModalProps } from '@nextui-org/react'

type TDataType =
  | 'string'
  | 'text'
  | 'number'
  | 'object'
  | 'file'
  | 'boolean'
  | 'string_array'
  | 'text_array'
  | 'number_array'
  | 'object_array'

type TInitialEdge = {
  id: string
  source: string
  target: string
  type?: string
}

/**
 * Callback executed when an Edge is deleted in the workflow
 */
type OnRemoveEdgeButtonClickCallback = (source: string, target: string) => void

type OnAddFilterButtonClickCallback = (source: string, target: string) => void

type OnEditFilterButtonClickCallback = (filter: TFilter) => void

type OnDeleteWorkflowModal = (workflow: TWorkflowCardItem) => void

type OnCreateWorkflowTemplateModal = (workflow: TWorkflowCardItem) => void

type HandleDuplicateWorkflow = (workflow_id: string) => void

type TEdgeData = {
  onRemoveEdgeButtonClick: OnRemoveEdgeButtonClickCallback
  onAddFilterButtonClick: OnAddFilterButtonClickCallback
  onEditFilterButtonClick: OnEditFilterButtonClickCallback
}

type TDefaultEdgeAttrs = Required<
  Pick<Edge, 'markerEnd' | 'style' | 'animated'>
>

type TProvider = {
  slug: string
  name: string
  logo: string
  website: string
}

type TWorkflowPlaygroundProps = {
  workflow: TWorkflow
}

type TWorkflowEditorProps = {
  workflow: TWorkflowData
  initial_nodes: TNode[]
  initial_edges: TEdge[]
  user_task_templates?: TTaskTemplatesCollection
  routes: {
    href: string
    label: string
    active?: boolean
  }[]
  active_providers: TProvider[]
  featured_providers: TProvider[]
}

type TWorkflowData = {
  id: string
  name: string
  description?: string
  config: unknown
  inputs_definition: TIODefinitions
  outputs_definition: TIODefinitions
} & TWorkflow

export type TWorkflow = {
  id: string
  name: string
  description?: string
  graph: string
  inputs_definition: TIODefinitions
  outputs_definition: TIODefinitions
  config: unknown
  api_endpoint: string
  company_id: string
}

type TWorkflowGraph = {
  steps: {
    s?: string
    t?: string
  }[]
  tasks: string[]
}

type TWorkflowTemplateCardItem = {
  featured: boolean
  published: boolean
  tasks_updated_at: string
  slug: string
  usage_count: number
}

type TWorkflowTemplateCreationData = {
  name: string
  short_description: string
  markdown_description: string
  publish_as: TWorkflowTemplateCreationDataPublishAs
}

type TWorkflowTemplateCreationDataPublishAs = 'user' | 'organization'

type TWorkflowCardItem = {
  api_endpoint: string
  company_id: string
  description?: string
  graph: TWorkflowGraph
  id: string
  name: string
  updated_at: string
  workflows_inputs_definition: {
    [key: string]: string
  }
  workflow_template?: TWorkflowTemplateCardItem
}

type TTaskWithProviders = {
  [key: string]: string
}

type TFilter = {
  source: string
  target: string
  variable_key?: string
  variable_type?: string
  property_path?: string
  property_path_type?: string
  comparison_condition?: string
  comparison_condition_value_type?: string
  comparison_value?: string
}

type TFilterComparisonConditionDefinition = {
  [id: string]: { value_type: string }
}

type TDataSlot = {
  key: string
  type: string
  value?: any
}

type TProviderStyle = {
  background_color: string
  icon: string
  border_color?: string
  icon_color?: string
  text_color?: string
}

type TProviderStyles = {
  [key: string]: TProviderStyle
}

type TTaskWithProviderStyles = {
  [key: string]: TProviderStyle
}

type TWorkflowsPageProps = {
  active_company: TCompany
  user_info: TUserInfo
  company_id: string
  provider_styles: TProviderStyles
  tasks_with_providers: TTaskWithProviders
  userIsWorkflowBuilder: boolean
  userIsWorkflowBuilderAPIIntegratorOrUser: boolean
  workflows: TWorkflowCardItem[]
}

type TDeleteWorkflowModalProps = {
  workflow: TWorkflowCardItem
  taskWithProviderStyles: TTaskWithProviderStyles
  pushEvent: PushEventFunction
} & Pick<ModalProps, 'isOpen' | 'onOpenChange' | 'onClose'>

type TCreateWorkflowTemplateModalProps = {
  workflow: TWorkflowCardItem
  pushEvent: PushEventFunction
} & Pick<ModalProps, 'isOpen' | 'onOpenChange' | 'onClose'>

type TWorkflowCardProps = {
  workflow: TWorkflowCardItem
  taskWithProviderStyles: TTaskWithProviderStyles
  isPlombAdmin: boolean
  onOpenDeleteWorkflowModal: OnDeleteWorkflowModal
  onOpenCreateWorkflowTemplateModal: OnCreateWorkflowTemplateModal
  handleDuplicateWorkflow: HandleDuplicateWorkflow
}

type TWorkflowPreviewProps = {
  graph: TWorkflowGraph
  taskWithProviderStyles: TTaskWithProviderStyles
}
