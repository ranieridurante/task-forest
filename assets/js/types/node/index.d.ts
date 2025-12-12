import type { TIODefinitions, TTask, TTaskConfig, TTaskTemplate } from '../task'
import type { Node } from 'reactflow'

/**
 * Represents the current state of a node's visual indicators.
 */
type NodeHighlightState = {
  left: boolean
  right: boolean
}

/**
 * Callback executed when a Node has a mouse interaction.
 */
type OnNodeMouseInteraction = (
  nodeId: string,
  type: 'mouseenter' | 'mouseleave'
) => void

/**
 * Sets the state of a node's visual indicator.
 */
type OnHighlightNode = (show: boolean, side: 'left' | 'right') => void

/**
 * Node highlight properties
 */
type NodeHighlightProps = {
  onNodeMouseInteraction: OnNodeMouseInteraction
  onHighlightNode?: OnHighlightNode
}

type TNodeData = {
  task_id: string
  label: string
  workflow_id: string
  task_template_id: string
  task_template?: TTaskTemplate
  prompt: string
  inputs_definition: TIODefinitions
  outputs_definition: TIODefinitions
  pushEventFn: PushEventFunction
  onHighlightNode: OnHighlightNode
}

/**
 * TaskNode properties
 */
type TTaskNodeProps = {
  id: string
  label: string
  workflow_id: string
  description: string
  task_id: string
  task_template_id: string
  task_template?: TTaskTemplate
  inputs_definition: TIODefinitions
  outputs_definition: TIODefinitions
  style: {
    [key: string]: string
  }
  task_config: TTaskConfig
  pushEventFn: PushEventFunction
  onTaskNodeEditButtonClick: (data: TTask) => void
} & NodeHighlightProps

/**
 * Converger node properties
 */
type TConvergerNodeProps = {
  label: string
  converger_id: string
  pushEventFn: PushEventFunction
  workflow_id: string
} & NodeHighlightProps

/**
 * Iterator node properties
 */
type TIteratorNodeProps = {
  id: string
  label: string
  iterable_key: string
  workflow_id: string
  pushEventFn: PushEventFunction
} & NodeHighlightProps

/**
 * NodeHighlight componente properties
 */
type NodeHighlightIndicatorProps = {
  highlight: NodeHighlightState
  background_color: string
}
