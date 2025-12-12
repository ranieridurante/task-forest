import React, { useEffect, useMemo } from 'react'
import ReactFlow, {
  useEdgesState,
  useNodesState,
  MarkerType,
  Background,
  BackgroundVariant,
  ReactFlowProvider,
} from 'reactflow'
import ELK from 'elkjs/lib/elk.bundled'
import MiniNode from '../workflow-editor/nodes/MiniNode'
import type { TWorkflowPreviewProps } from 'types/workflow'
import type { Edge, Node } from 'reactflow'
import type { LayoutOptions } from 'elkjs/lib/elk.bundled.js'

/**
 * Horizontal size of a node.
 */
const NODE_WIDTH = 64

/**
 * Vertical size of a node.
 */
const NODE_HEIGHT = 64

/**
 * Horizontal space between nodes.
 */
const NODE_HORIZONTAL_SPACE = NODE_WIDTH / 2

/**
 * Vertical space between nodes.
 */
const NODE_VERTICAL_SPACE = NODE_HEIGHT / 2

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
 * Function responsible for generating a suitable layout for the graph.
 */
const getLaidOutedNodes = async (nodes: Node[], edges: Edge[]) => {
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
      width: NODE_WIDTH,
      height: NODE_HEIGHT,
    })),
    // @ts-expect-error Type mismatch because elk.layout expects an array of ElkExtendedEdge.
    edges: edges,
  })

  return (
    nodes.map((node) => {
      const laidOutNode = laidOutGraph.children?.find((n) => n.id === node.id)
      if (laidOutNode) {
        return {
          ...node,
          position: {
            x: laidOutNode.x || node.position.x,
            y: laidOutNode.y || node.position.y,
          },
        }
      }

      return node
    }) || []
  )
}

/**
 * Component that represents a preview of a workflow.
 * @constructor
 */
const WorkflowGraphPreview: React.FC<TWorkflowPreviewProps> = ({
  graph,
  taskWithProviderStyles,
}) => {
  const [nodes, setNodes] = useNodesState([])
  const [edges, setEdges] = useEdgesState([])

  const nodeTypes = useMemo(
    () => ({
      task: MiniNode,
    }),
    []
  )

  const MISSING_TASK_STYLE = {
    background_color: '#FF0000',
    icon: 'grommet-icons:document-missing',
  }

  useEffect(() => {
    let x = 0
    const originalNodes: Node[] = graph.tasks.map((taskId) => {
      x += 10
      return {
        id: taskId,
        type: 'task',
        data: taskWithProviderStyles[taskId] || MISSING_TASK_STYLE,
        position: { x: 10 * x, y: 5 * x },
      }
    })

    const convergersAndIteratorsIds = graph.steps.reduce(
      (acc: string[], { s, t }) => {
        if (!(s && t)) {
          return acc
        }

        if (
          (s.startsWith('iter_') || s.startsWith('converger_')) &&
          !acc.includes(s)
        ) {
          acc.push(s)
        }

        if (
          (t.startsWith('iter_') || t.startsWith('converger_')) &&
          !acc.includes(t)
        ) {
          acc.push(t)
        }
        return acc
      },
      []
    )

    convergersAndIteratorsIds.map((id) => {
      x += 10
      originalNodes.push({
        id,
        type: 'task',
        data: {
          icon: id.startsWith('converger_')
            ? 'mdi:merge'
            : 'mdi:repeat-variant',
          background_color: '#D9318B',
        },
        position: { x: 10 * x, y: 5 * x },
      })
    })

    const originalEdges: Edge[] = []
    for (const { s, t } of graph.steps) {
      if (!(s && t)) {
        continue
      }

      originalEdges.push({
        id: `${s}-${t}`,
        source: s,
        target: t,
        markerEnd: {
          type: MarkerType.ArrowClosed,
          width: 16,
          height: 16,
          color: '#5f5f60',
        },
        style: {
          strokeWidth: 1,
          strokeDasharray: '6 3',
          stroke: '#5f5f60',
        },
        animated: true,
      })
    }

    void (async () => {
      setNodes(await getLaidOutedNodes(originalNodes, originalEdges))
      setEdges(originalEdges)
    })()
  }, [])

  return (
    <>
      <div className='w-full h-[150px] bg-plombYellow-100 rounded-xl pointer-events-none'>
        <ReactFlowProvider>
          <ReactFlow
            nodes={nodes}
            nodeTypes={nodeTypes}
            edges={edges}
            zoomOnScroll={false}
            nodesDraggable={false}
            edgesFocusable={false}
            elementsSelectable={false}
            edgesUpdatable={false}
            panOnDrag={false}
            panOnScroll={false}
            autoPanOnConnect={false}
            fitView={true}
            fitViewOptions={{
              padding: 0.2,
              duration: 0,
              minZoom: 0.1,
              maxZoom: 1,
            }}
            minZoom={0.1}
            draggable={false}
            zoomOnDoubleClick={false}
            proOptions={{ hideAttribution: true }}
          >
            <Background variant={BackgroundVariant.Dots} gap={20} size={1} />
          </ReactFlow>
        </ReactFlowProvider>
      </div>
    </>
  )
}

export default WorkflowGraphPreview
