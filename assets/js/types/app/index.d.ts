import type React from 'react'
import type { ModalProps } from '@nextui-org/react'
import type { TIODefinitions } from '../task'

// Common types

/**
 * Execution statuses.
 */
type TExecutionStatus =
  | 'completed'
  | 'cancelled'
  | 'started'
  | 'delayed'
  | 'pending'

/**
 * An object with just pairs of key-values.
 */
type KeyValueObject = {
  [key: string]: unknown
}

// Callback types

/**
 * Callback executed when the New Execution button or New Scheduled Trigger button has been clicked.
 * @param trigger (Optional) Scheduled Trigger to edit.
 */
type OnOpenExecutionModal = (trigger?: TScheduledTrigger | null) => void

/**
 * Callback executed when the Input/Output button has been clicked.
 */
type OnOpenInputOutputModal = (options: {
  /**
   * Scheduled trigger
   */
  trigger?: TScheduledTrigger

  /**
   * Execution info
   */
  execution?: TExecution

  /**
   * Default opened tab
   */
  activeTab: 'input' | 'output'
}) => void

// Model types

/**
 * A workflow execution
 */
type TExecution = {
  /**
   * Execution id.
   */
  id: string

  /**
   * Execution inputs.
   */
  inputs: KeyValueObject

  /**
   * Execution outputs.
   */
  outputs: KeyValueObject

  /**
   * Execution status.
   */
  status: TExecutionStatus

  /**
   * Execution inserted date.
   */
  inserted_at: string

  /**
   * Execution updated date.
   */
  updated_at: string

  /**
   * Workflow id.
   */
  workflow_id: string
}

/**
 * A scheduled trigger
 */
type TScheduledTrigger = {
  /**
   * Scheduled trigger id.
   */
  id: string

  /**
   * Scheduled trigger name.
   */
  name: string

  /**
   * Scheduled trigger cron expression.
   */
  cron_expression: string

  /**
   * Scheduled trigger inputs.
   */
  inputs: KeyValueObject

  /**
   * Scheduled trigger status.
   */
  active: boolean

  /**
   * Scheduled trigger insertion date.
   */
  inserted_at: string

  /**
   * Scheduled trigger update date.
   */
  updated_at: string

  /**
   * Workflow id.
   */
  workflow_id: string
}

// Component types

/**
 * App Dashboard page properties
 */
type TAppDashboardPageProps = {
  /**
   * Workflow id.
   */
  workflow_id: string

  /**
   * Execution list.
   */
  executions: TExecution[]

  /**
   * Scheduled triggers list.
   */
  scheduled_triggers: TScheduledTrigger[]

  /**
   * Workflow inputs definition.
   */
  workflow_inputs_definition: TIODefinitions

  /**
   * Execution time in seconds.
   */
  execution_time: number

  /**
   * Total executions.
   */
  total_executions: number
  workflow: TWorkflow

  active_triggers: number

  shortcuts: TShortcut[]
}

type TShortcut = {
  name: string
  description: string
  icon: string
  link: string
  data?: any
}

type TWorkflowHeaderProps = {
  props: {
    onSearch: (query: string) => void
    active_company: TCompany
    pushEvent: PushEventFunction
  }
}

/**
 * Workflow Stats properties
 */
type TWorkflowStatsProps = {
  /**
   * Execution time in seconds.
   */
  executionTime: number

  /**
   * Total executions.
   */
  totalExecutions: number

  activeTriggers: number
}

/**
 * Last Executions table properties
 */
type TLastExecutionsTableProps = {
  /**
   * Execution list.
   */
  executions: TExecution[]

  totalExecutions: number

  workflow_id: string

  pushEvent: PushEventFunction

  onOpenExecutionModal: OnOpenExecutionModal

  onOpenInputOutputModal: OnOpenInputOutputModal
}

/**
 * Scheduled Triggers table properties
 */
type TScheduledTriggersTableProps = {
  /**
   * Scheduled triggers list.
   */
  scheduledTriggers: TScheduledTrigger[]

  pushEvent: PushEventFunction

  onOpenExecutionModal: OnOpenExecutionModal

  onOpenInputOutputModal: OnOpenInputOutputModal
}

/**
 * Execution modal properties
 */
type TExecutionModalProps = {
  /**
   * Workflow id.
   */
  workflowId: string

  /**
   * Inputs definition
   */
  inputs: TIODefinitions

  /**
   * Scheduled trigger to edit.
   */
  trigger?: TScheduledTrigger | null

  pushEvent: PushEventFunction
} & Pick<ModalProps, 'isOpen' | 'onOpenChange' | 'onClose'>

type TRunWorkflowButtonProps = {
  text: string
  icon: string
  color: 'primary' | 'danger'
  isRunning: boolean
}

/**
 * Input/Output modal properties
 */
type TInputOutputModalProps = {
  /**
   * Execution data.
   */
  execution?: TExecution

  /**
   * Scheduled trigger data.
   */
  trigger?: TScheduledTrigger

  /**
   * Default opened tab
   */
  activeTab: 'input' | 'output'
} & Pick<ModalProps, 'isOpen' | 'onOpenChange' | 'onClose'>

/**
 * JSON tooltip properties
 */
type TJSONTooltipProps = {
  title: string

  json: KeyValueObject

  children: React.ReactNode
}
