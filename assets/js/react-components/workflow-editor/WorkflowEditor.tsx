import type { Key } from 'react'
import React, {
  useCallback,
  useEffect,
  useLayoutEffect,
  useMemo,
  useState,
} from 'react'
import type { Edge, Node } from 'reactflow'
import { getOutgoers } from 'reactflow'
import { useEdgesState, useNodesState, useReactFlow } from 'reactflow'
import ReactFlow, {
  applyNodeChanges,
  Background,
  BackgroundVariant,
  type Connection,
  type EdgeChange,
  MarkerType,
  type NodeChange,
  Panel,
  Position,
} from 'reactflow'
import type { LayoutOptions } from 'elkjs/lib/elk.bundled.js'
import ELK from 'elkjs/lib/elk.bundled.js'
import NodeConnection from './edges/NodeConnection'
import ConnectionLine from './ConectionLine'
import TaskNode from './nodes/TaskNode'
import IteratorNode from './nodes/IteratorNode'
import ConvergerNode from './nodes/ConvergerNode'
import WorkflowToolsDropdown from './WorkflowToolsDropdown'
import TaskModal from './modal/TaskModal'
import DataSlotsModal from './modal/DataSlotsModal'
import AddIteratorModal from './modal/AddIteratorModal'
import AddFilterModal from './modal/AddFilterModal'
import { useDisclosure } from '@nextui-org/react'
import type {
  OnRemoveEdgeButtonClickCallback,
  OnAddFilterButtonClickCallback,
  OnEditFilterButtonClickCallback,
  TDefaultEdgeAttrs,
  TEdgeData,
  TInitialEdge,
  TWorkflowEditorProps,
  TFilter,
  TDataSlot,
} from 'types/workflow'
import type { TIODefinitions, TTask, TTaskTemplate } from 'types/task'
import {
  addLiveViewEventListener,
  removeLiveViewEventListener,
} from '../../util'
import WorkflowAction from './model/WorkflowAction'
import type { OnNodeMouseInteraction, TNodeData } from 'types/node'
import { Button } from '@nextui-org/react'
import { singularize } from 'utils'

// applyEdgeChanges from reactflow 11.11.4 seems to be broken,
// this implementation from 11.11.3 works correctly
// (copied from their GitHub repo)
const customApplyEdgeChanges = <EdgeType extends Edge = Edge>(
  changes: EdgeChange<EdgeType>[],
  edges: EdgeType[]
): EdgeType[] => {
  return customApplyChanges(changes, edges) as EdgeType[]
}

const customApplyChanges = (changes: any[], elements: any[]): any[] => {
  const updatedElements: any[] = []
  /*
   * By storing a map of changes for each element, we can a quick lookup as we
   * iterate over the elements array!
   */
  const changesMap = new Map<any, any[]>()
  const addItemChanges: any[] = []

  for (const change of changes) {
    if (change.type === 'add') {
      addItemChanges.push(change)
      continue
    } else if (change.type === 'remove' || change.type === 'replace') {
      /*
       * For a 'remove' change we can safely ignore any other changes queued for
       * the same element, it's going to be removed anyway!
       */
      changesMap.set(change.id, [change])
    } else {
      const elementChanges = changesMap.get(change.id)

      if (elementChanges) {
        /*
         * If we have some changes queued already, we can do a mutable update of
         * that array and save ourselves some copying.
         */
        elementChanges.push(change)
      } else {
        changesMap.set(change.id, [change])
      }
    }
  }

  for (const element of elements) {
    const changes = changesMap.get(element.id)

    /*
     * When there are no changes for an element we can just push it unmodified,
     * no need to copy it.
     */
    if (!changes) {
      updatedElements.push(element)
      continue
    }

    // If we have a 'remove' change queued, it'll be the only change in the array
    if (changes[0].type === 'remove') {
      continue
    }

    if (changes[0].type === 'replace') {
      updatedElements.push({ ...changes[0].item })
      continue
    }

    /**
     * For other types of changes, we want to start with a shallow copy of the
     * object so React knows this element has changed. Sequential changes will
     * each _mutate_ this object, so there's only ever one copy.
     */
    const updatedElement = { ...element }

    for (const change of changes) {
      customApplyChange(change, updatedElement)
    }

    updatedElements.push(updatedElement)
  }

  /*
   * we need to wait for all changes to be applied before adding new items
   * to be able to add them at the correct index
   */
  if (addItemChanges.length) {
    addItemChanges.forEach((change) => {
      if (change.index !== undefined) {
        updatedElements.splice(change.index, 0, { ...change.item })
      } else {
        updatedElements.push({ ...change.item })
      }
    })
  }

  return updatedElements
}

// Applies a single change to an element. This is a *mutable* update.
const customApplyChange = (change: any, element: any): any => {
  switch (change.type) {
    case 'select': {
      element.selected = change.selected
      break
    }

    case 'position': {
      if (typeof change.position !== 'undefined') {
        element.position = change.position
      }

      if (typeof change.dragging !== 'undefined') {
        element.dragging = change.dragging
      }

      break
    }

    case 'dimensions': {
      if (typeof change.dimensions !== 'undefined') {
        element.measured ??= {}
        element.measured.width = change.dimensions.width
        element.measured.height = change.dimensions.height

        if (change.setAttributes) {
          if (
            change.setAttributes === true ||
            change.setAttributes === 'width'
          ) {
            element.width = change.dimensions.width
          }
          if (
            change.setAttributes === true ||
            change.setAttributes === 'height'
          ) {
            element.height = change.dimensions.height
          }
        }
      }

      if (typeof change.resizing === 'boolean') {
        element.resizing = change.resizing
      }

      break
    }
  }
}

/**
 * Horizontal size of a node.
 */
const NODE_WIDTH = 256

/**
 * Vertical size of a node.
 */
const NODE_HEIGHT = 128

/**
 * Horizontal size of a Converger node.
 */
const CONVERGER_NODE_WIDTH = 128

/**
 * Horizontal space between nodes.
 */
const NODE_HORIZONTAL_SPACE = NODE_WIDTH * 1.5

/**
 * Vertical space between nodes.
 */
const NODE_VERTICAL_SPACE = NODE_HEIGHT / 2

/**
 * Default edge properties.
 */
const DEFAULT_EDGE_PROPERTIES: TDefaultEdgeAttrs = {
  markerEnd: {
    type: MarkerType.ArrowClosed,
    width: 25,
    height: 25,
    color: '#5f5f60',
  },
  style: {
    strokeWidth: 2,
    strokeDasharray: '5 10',
    stroke: '#5f5f60',
  },
  animated: true,
}

/**
 * Default Elk layout options.
 */
const DEFAULT_LAYOUT_OPTIONS: LayoutOptions = {
  'elk.algorithm': 'layered',
  'elk.layered.layering.strategy': 'LONGEST_PATH_SOURCE',
  'elk.layered.nodePlacement.strategy': 'SIMPLE',
  'elk.layered.considerModelOrder.crossingCounterNodeInfluence': '0.5',
  'elk.layered.unnecessaryBendpoints': 'true',
  'elk.layered.crossingMinimization.strategy': 'INTERACTIVE',
  'elk.layered.nodePlacement.favorStraightEdges': 'true',
  'elk.layered.spacing.nodeNodeBetweenLayers': `${NODE_HORIZONTAL_SPACE}`,
  'elk.spacing.nodeNode': `${NODE_VERTICAL_SPACE}`,
  'elk.radial.rotation.outgoingEdgeAngles': 'true',
  'elk.direction': 'RIGHT',
}

const elk = new ELK()

/**
 * Callback that is executed when a task is edited within the workflow.
 */
let onTaskNodeEditButtonClick: (data: TTask) => void

/**
 * Callback executed when an Edge is deleted in the workflow
 */
let onRemoveEdgeButtonClick: OnRemoveEdgeButtonClickCallback

/**
 * Callback executed when a filter gets added
 */
let onAddFilterButtonClick: OnAddFilterButtonClickCallback

let onEditFilterButtonClick: OnEditFilterButtonClickCallback

/**
 * Callback executed when a Node has a mouse interaction.
 */
let onNodeMouseInteraction: OnNodeMouseInteraction

/**
 * Function responsible for generating a suitable layout for the graph.
 */
const getLaidOutedElements = async (
  nodes: Node<TNodeData>[],
  edges: Edge<TEdgeData>[]
) => {
  const laidOutGraph = await elk.layout({
    id: 'root',
    layoutOptions: DEFAULT_LAYOUT_OPTIONS,
    children: nodes.map((node) => ({
      id: node.id,
      // Adjust the target and source handle positions based on the layout
      // direction.
      targetPosition: 'left',
      sourcePosition: 'right',

      // Hardcode a width and height for elk to use when laid outing.
      width: node.type === 'convergerNode' ? CONVERGER_NODE_WIDTH : NODE_WIDTH,
      height: NODE_HEIGHT,
    })),
    // @ts-expect-error Type mismatch because elk.layout expects an array of ElkExtendedEdge.
    edges: edges,
  })

  return {
    nodes:
      nodes.map((node) => {
        const laidOutNode = laidOutGraph.children?.find((n) => n.id === node.id)
        if (laidOutNode) {
          return {
            ...node,
            position: {
              x: laidOutNode.x,
              y: laidOutNode.y,
            },
          }
        }

        return node
      }) || [],

    edges: laidOutGraph.edges || [],
  } as unknown as { nodes: Node<TNodeData>[]; edges: Edge<TEdgeData>[] }
}

const getFilterVariables = (
  availableVariables: TDataSlot[],
  availableIterableKeys: string[]
): { key: string; type: string }[] => {
  const singularizedIterableKeys = availableIterableKeys.map((key) => {
    const variableType = availableVariables.find(
      (variable) => variable.key === key
    )?.type

    const variableName = singularize(key)

    if (variableType?.startsWith('array_')) {
      return {
        key: variableName,
        type: variableType.substring(6),
      }
    } else {
      return {
        key: variableName,
        type: 'string',
      }
    }
  })

  return singularizedIterableKeys.concat(availableVariables)
}

/**
 * Returns a list of available Iterable Keys.
 */
const getAvailableIterableKeys = (
  currentKeys: string[],
  workflowInputDef: TIODefinitions,
  workflowOutputDef: TIODefinitions,
  taskNodes: Node<TNodeData>[]
) => {
  const availableKeys = currentKeys

  let mergedDefinitions: TIODefinitions = taskNodes.reduce((acc, node) => {
    return {
      ...acc,
      ...node.data.inputs_definition,
      ...node.data.outputs_definition,
    }
  }, {})

  mergedDefinitions = {
    ...workflowInputDef,
    ...workflowOutputDef,
    ...mergedDefinitions,
  }

  for (const [key, value] of Object.entries(mergedDefinitions)) {
    if (value.type.includes('array') && !availableKeys.includes(key)) {
      availableKeys.push(key)
    }
  }

  return availableKeys
}

/**
 * Returns a list of available variables.
 */
const getAvailableVariables = (
  currentVariables: TDataSlot[],
  workflowInputDef: TIODefinitions,
  workflowOutputDef: TIODefinitions,
  taskNodes: Node<TNodeData>[]
) => {
  const availableVariables = currentVariables
  const availableVariablesKeys = availableVariables.map(
    (value: TDataSlot) => value.key
  )

  let mergedDefinitions: TIODefinitions = taskNodes.reduce((acc, node) => {
    return {
      ...acc,
      ...node.data.inputs_definition,
      ...node.data.outputs_definition,
    }
  }, {})

  mergedDefinitions = {
    ...workflowInputDef,
    ...workflowOutputDef,
    ...mergedDefinitions,
  }

  for (const [key, value] of Object.entries(mergedDefinitions)) {
    if (!availableVariablesKeys.includes(key)) {
      const newValue = {
        key: key,
        type: value.type,
      }

      availableVariables.push(newValue)
    }
  }

  return availableVariables
}

/**
 * Adds extra information to the edges.
 * @param edges Collection of Edges
 */
const updateEdgesProperties: (
  edges: TInitialEdge[] | Edge<T>
) => Edge<TEdgeData>[] = (edges) => {
  return edges.map((edge) => ({
    ...edge,
    ...DEFAULT_EDGE_PROPERTIES,
    pathOptions: {
      offset: 20,
      borderRadius: 15,
    },
    data: {
      ...edge.data,
      onRemoveEdgeButtonClick,
      onAddFilterButtonClick,
      onEditFilterButtonClick,
    },
  }))
}

/**
 * Adds extra information to a node.
 */
const updateNodeProperties = (
  node: Node<TNodeData>,
  nodeTaskTemplate: TTaskTemplate | undefined,
  pushEvent: PushEventFunction
) => {
  return {
    ...node,
    data: {
      ...(node.data || {}),
      task_template: nodeTaskTemplate,
      pushEventFn: pushEvent,
      onTaskNodeEditButtonClick,
      onNodeMouseInteraction: onNodeMouseInteraction,
    },
    sourcePosition: Position.Right,
    targetPosition: Position.Left,
  }
}

/**
 * Adds extra information to a node collection.
 */
const updateNodesProperties: (
  nodes: Node<TNodeData>[],
  pushEvent: PushEventFunction,
  taskTemplatesById: { [key: string]: TTaskTemplate }
) => Node<TNodeData>[] = (nodes, pushEvent, taskTemplatesById) =>
  nodes.map((node) => {
    let nodeTaskTemplate: TTaskTemplate | undefined = undefined
    if (taskTemplatesById) {
      nodeTaskTemplate = taskTemplatesById[node.data.task_template_id]
    }

    return updateNodeProperties(node, nodeTaskTemplate, pushEvent)
  })

/**
 * Component that represents a workflow editor using a graph.
 * @constructor
 */
const WorkflowEditor: React.FC<
  LiveReactComponentProps<TWorkflowEditorProps>
> = ({ props, pushEvent }) => {
  const nodeTypes = useMemo(
    () => ({
      convergerNode: ConvergerNode,
      taskNode: TaskNode,
      iteratorNode: IteratorNode,
    }),
    []
  )

  const edgeTypes = useMemo(() => ({ nodeConnection: NodeConnection }), [])

  const updatedInitialNodes = updateNodesProperties(
    props.initial_nodes,
    pushEvent,
    props.user_task_templates || {}
  )

  const initialAvailableIterableKeys = getAvailableIterableKeys(
    [],
    props.workflow.inputs_definition,
    props.workflow.outputs_definition,
    updatedInitialNodes
  )

  const initialAvailableVariables = getAvailableVariables(
    [],
    props.workflow.inputs_definition,
    props.workflow.outputs_definition,
    updatedInitialNodes
  )

  const initialFilterVariables = getFilterVariables(
    initialAvailableVariables,
    initialAvailableIterableKeys
  )

  const [nodes, setNodes] = useNodesState<TNodeData>([])
  const [edges, setEdges] = useEdgesState<TEdgeData>([])
  const [availableIterableKeys, setAvailableIterableKeys] = useState(
    initialAvailableIterableKeys
  )
  const [availableVariables, setAvailableVariables] = useState(
    initialAvailableVariables
  )
  const [filterVariables, setFilterVariables] = useState(initialFilterVariables)

  const [editingTask, setEditingTask] = useState<TTask>()
  const [editingFilter, setEditingFilter] = useState<TFilter>()
  const { getNodes } = useReactFlow<TNodeData, TEdgeData>()

  /**
   * These hooks handle the modals functionality.
   */
  const modalHooks = {
    task: useDisclosure(),
    dataSlots: useDisclosure(),
    addIterator: useDisclosure(),
    filter: useDisclosure(),
  }

  /**
   * Function that is executed when an item is selected from the Workflow tools dropdown
   * @param key WorkflowAction key
   */
  const onWorkflowToolsDropdownActionSelected = (key: Key) => {
    switch (key as WorkflowAction) {
      case WorkflowAction.ADD_TASK:
        return modalHooks.task.onOpen()
      case WorkflowAction.ADD_CONVERGER:
        return pushEvent('react.create_converger', {
          workflow_id: props.workflow.id,
        })
      case WorkflowAction.ADD_ITERATOR:
        return modalHooks.addIterator.onOpen()
      case WorkflowAction.ORGANIZE_CANVAS:
        return organizeCanvas()
      case WorkflowAction.EDIT_APP:
        return modalHooks.dataSlots.onOpen()
      case WorkflowAction.APP_DASHBOARD:
        return (window.location.href = `/workflows/${props.workflow.id}/app-dashboard`)
      case WorkflowAction.PLAYGROUND:
        return (window.location.href = `/workflows/${props.workflow.id}/playground`)
    }
  }

  onTaskNodeEditButtonClick = (data: TTask) => {
    setEditingTask(data)
    modalHooks.task.onOpen()
  }

  onRemoveEdgeButtonClick = (source, target) => {
    pushEvent('react.delete_step', {
      source,
      target,
    })
  }

  onAddFilterButtonClick = (source, target) => {
    const filterData = {
      source,
      target,
    }

    setEditingFilter(filterData)
    modalHooks.filter.onOpen()
  }

  onEditFilterButtonClick = (filter) => {
    setEditingFilter(filter)
    modalHooks.filter.onOpen()
  }

  const updatedInitialEdges = updateEdgesProperties(props.initial_edges)

  onNodeMouseInteraction = useCallback(
    (nodeId, type) => {
      const targetEdges = edges.filter((e) => e.target === nodeId)
      const sourceEdges = edges.filter((e) => e.source === nodeId)
      const targetNodes = targetEdges.map((e) =>
        nodes.find((n) => n.id === e.source)
      )
      const sourceNodes = sourceEdges.map((e) =>
        nodes.find((n) => n.id === e.target)
      )

      for (const node of targetNodes) {
        if (node && node.data.onHighlightNode) {
          node.data.onHighlightNode(false, 'left')
          node.data.onHighlightNode(type === 'mouseenter', 'right')
        }
      }
      for (const node of sourceNodes) {
        if (node && node.data.onHighlightNode) {
          node.data.onHighlightNode(false, 'right')
          node.data.onHighlightNode(type === 'mouseenter', 'left')
        }
      }
    },
    [nodes, edges]
  )

  const organizeCanvas = useCallback(async () => {
    const { nodes: laidOutedNodes, edges: laidOutedEdges } =
      await getLaidOutedElements(nodes, edges)

    setNodes(laidOutedNodes)
    setEdges(laidOutedEdges)
  }, [updatedInitialNodes, updatedInitialEdges])

  const onConnect = useCallback(
    (connection: Connection) => {
      pushEvent('react.create_step', {
        source: connection.source,
        target: connection.target,
        workflow_id: props.workflow.id,
      })
    },
    [setEdges]
  )

  const onLayout = useCallback(
    async ({ useInitialNodes = false }) => {
      const ns = useInitialNodes ? updatedInitialNodes : nodes
      const es = useInitialNodes ? updatedInitialEdges : edges

      const { nodes: laidOutedNodes, edges: laidOutedEdges } =
        await getLaidOutedElements(ns, es)

      setNodes(laidOutedNodes)
      setEdges(laidOutedEdges)
    },
    [nodes, edges]
  )

  /**
   * Verifies that a connection between two nodes is valid.
   * @param connection
   */
  const isValidConnection = useCallback(
    (connection: Connection) => {
      // If it is a connection to the same node.
      if (connection.source === connection.target) {
        return false
      }

      // If a connection already exists between the source node and the target node.
      if (
        edges.find(
          (edge) =>
            edge.source === connection.source &&
            edge.target === connection.target
        )
      ) {
        return false
      }

      // If the connection causes a cycle between nodes.
      const targetNode = getNodes().find(
        (node) => node.id === connection.target
      )
      if (targetNode) {
        const hasCycle = (node: Node, visited = new Set()) => {
          if (visited.has(node.id)) return false

          visited.add(node.id)

          for (const outgoingNode of getOutgoers(node, nodes, edges)) {
            if (outgoingNode.id === connection.source) return true
            if (hasCycle(outgoingNode, visited)) return true
          }
        }

        if (hasCycle(targetNode)) {
          return false
        }
      }

      // A Converger node cannot connect to another Converger node.
      const sourceNode = getNodes().find(
        (node) => node.id === connection.source
      )
      if (sourceNode && targetNode) {
        if (
          sourceNode.type === 'convergerNode' &&
          targetNode.type === 'convergerNode'
        ) {
          return false
        }
      }

      // TODO Must have a single start and end node

      return true
    },
    [nodes, edges]
  )

  useLayoutEffect(() => {
    ;(async () => {
      await onLayout({ useInitialNodes: true })
    })()
  }, [])

  const onNodesChange = useCallback(
    (changes: NodeChange[]) => {
      return setNodes((oldNodes) => {
        const nodesContext =
          oldNodes && oldNodes.length > 0 ? oldNodes : [...nodes]

        const updatedNodes = applyNodeChanges(changes, nodesContext)

        const updatedAvailableIterableKeys = getAvailableIterableKeys(
          availableIterableKeys,
          props.workflow.inputs_definition,
          props.workflow.outputs_definition,
          updatedNodes
        )

        setAvailableIterableKeys(updatedAvailableIterableKeys)

        const updatedAvailableVariables = getAvailableVariables(
          [],
          props.workflow.inputs_definition,
          props.workflow.outputs_definition,
          updatedNodes
        )

        setAvailableVariables(updatedAvailableVariables)

        const updatedFilterVariables = getFilterVariables(
          updatedAvailableVariables,
          updatedAvailableIterableKeys
        )

        setFilterVariables(updatedFilterVariables)

        return updateNodesProperties(
          updatedNodes,
          pushEvent,
          props.user_task_templates || {}
        )
      })
    },
    [nodes, edges]
  )

  const onEdgesChange = useCallback((changes: EdgeChange[]) => {
    setEdges((oldEdges) => {
      oldEdges = oldEdges && oldEdges.length > 0 ? oldEdges : [...edges]

      const updatedEdges = customApplyEdgeChanges(changes, oldEdges)

      return updateEdgesProperties(updatedEdges)
    })
  }, [])

  useEffect(() => {
    /**
     * Callback executed when the server sends an update to the editor.
     */
    const onUpdateEditorEvent: LiveViewEventCallback<
      'server.update_editor'
    > = ({ changes: { edge_changes, node_changes } }) => {
      if (node_changes && node_changes.length) {
        for (const change of node_changes) {
          if (change.type === 'add') {
            const actualNodes = getNodes()
            change.item = updateNodeProperties(
              change.item,
              undefined,
              pushEvent
            )

            const oldNode = actualNodes.find((n) => n.id === change.item.id)
            if (oldNode) {
              // If node already exists, just update it's position.
              change.item.position = oldNode.position
            } else if (edge_changes && edge_changes.length) {
              // It is a new node, not a replacement.
              // Search edge and node.
              const sourceEdge = edge_changes.find(
                (e) => e.item.target === change.item.id
              )
              if (sourceEdge) {
                const sourceNode = getNodes().find(
                  (n) => n.id === sourceEdge.item.source
                )
                if (sourceNode) {
                  change.item.position = {
                    x:
                      sourceNode.position.x +
                      NODE_WIDTH +
                      NODE_HORIZONTAL_SPACE,
                    y: sourceNode.position.y,
                  }
                }
              }
            }
          }
        }

        onNodesChange(node_changes)
      }

      if (edge_changes && edge_changes.length) {
        onEdgesChange(edge_changes)
      }
    }

    addLiveViewEventListener('server.update_editor', onUpdateEditorEvent)
    return () => {
      removeLiveViewEventListener('server.update_editor', onUpdateEditorEvent)
    }
  }, [])

  return (
    <>
      <div className='mt-2 rounded-2xl h-full'>
        <ReactFlow
          nodes={nodes}
          edges={edges}
          onNodesChange={onNodesChange}
          onEdgesChange={onEdgesChange}
          onConnect={onConnect}
          connectionLineComponent={ConnectionLine}
          isValidConnection={isValidConnection}
          nodeTypes={nodeTypes}
          edgeTypes={edgeTypes}
          snapGrid={[20, 20]}
          snapToGrid={true}
          zoomOnDoubleClick={false}
          deleteKeyCode={null}
          translateExtent={[
            [-1400, -1200],
            [7000, 2000],
          ]}
          minZoom={0.4}
          maxZoom={1}
          zoomOnScroll={false}
          panOnDrag={true}
          selectionOnDrag={false}
          panOnScroll={true}
          panOnScrollSpeed={4}
          defaultViewport={{
            x: 100,
            y: 100,
            zoom: 0.6,
          }}
          fitView={true}
          fitViewOptions={{
            duration: 0,
            minZoom: 0.4,
            maxZoom: 1,
          }}
          onPaneClick={modalHooks.task.onOpen}
        >
          <Panel position='bottom-left'>
            <WorkflowToolsDropdown
              onDropdownActionSelected={onWorkflowToolsDropdownActionSelected}
            />
          </Panel>
          <Background
            color='cccccc'
            variant={BackgroundVariant.Dots}
            gap={20}
            size={1}
          />
        </ReactFlow>
      </div>
      <TaskModal
        isOpen={modalHooks.task.isOpen}
        onOpenChange={modalHooks.task.onOpenChange}
        onClose={() => {
          setEditingTask(undefined)
          modalHooks.task.onClose()
        }}
        pushEvent={pushEvent}
        taskTemplates={props.user_task_templates || {}}
        task={editingTask}
        workflow_id={props.workflow.id}
      />
      <DataSlotsModal
        isOpen={modalHooks.dataSlots.isOpen}
        onOpenChange={modalHooks.dataSlots.onOpenChange}
        onClose={modalHooks.dataSlots.onClose}
        pushEvent={pushEvent}
        workflow_id={props.workflow.id}
        inputsDefinition={props.workflow.inputs_definition}
      />
      <AddIteratorModal
        isOpen={modalHooks.addIterator.isOpen}
        onOpenChange={modalHooks.addIterator.onOpenChange}
        onClose={modalHooks.addIterator.onClose}
        workflow_id={props.workflow.id}
        pushEvent={pushEvent}
        available_iterable_keys={availableIterableKeys}
      />
      <AddFilterModal
        isOpen={modalHooks.filter.isOpen}
        onOpenChange={modalHooks.filter.onOpenChange}
        onClose={() => {
          setEditingFilter(undefined)
          modalHooks.filter.onClose()
        }}
        pushEvent={pushEvent}
        available_variables={filterVariables}
        filter={editingFilter}
        workflow_id={props.workflow.id}
      />
    </>
  )
}

export default WorkflowEditor
