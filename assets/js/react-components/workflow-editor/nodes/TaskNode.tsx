import React, { useState, useRef, useEffect } from 'react'
import {
  Button,
  Chip,
  Popover,
  PopoverContent,
  PopoverTrigger,
  Tooltip,
} from '@nextui-org/react'
import type { NodeProps } from 'reactflow'
import { Handle, Position } from 'reactflow'
import NodeHighlightIndicator, {
  onNodeMouseInteraction,
} from './NodeHighlightIndicator'
import type { TTaskNodeProps, NodeHighlightState } from 'types/node'

/**
 * Component that represents a node of type Task.
 * @constructor
 */
const TaskNode: React.FC<NodeProps<TTaskNodeProps>> = (props) => {
  const { data } = props
  const targetHandleRef = useRef<HTMLDivElement>(null)
  const sourceHandleRef = useRef<HTMLDivElement>(null)
  const threshold = 25 // Distance in pixels

  const textSizeClass = () => {
    if (data.label.length > 20) {
      return 'text-lg'
    }

    if (data.label.length > 25) {
      return 'text-base'
    }

    return 'text-xl'
  }

  /**
   * Function responsible for invoking TaskModal to edit the task.
   * It is executed when clicking on the Edit button or when double-clicking on the node.
   */
  const onTaskNodeEditButtonClick = () => {
    data.onTaskNodeEditButtonClick({
      task_id: data.task_id,
      label: data.label,
      workflow_id: data.workflow_id,
      inputs_definition: data.inputs_definition,
      outputs_definition: data.outputs_definition,
      task_config: data.task_config,
      task_template_id: data.task_template_id,
      task_template: data.task_template,
    })
  }

  /**
   * Function responsible for removing the Task Node.
   */
  const onDeleteTaskButtonClick = () => {
    data.pushEventFn('react.delete_task', {
      task_id: data.task_id,
      workflow_id: data.workflow_id,
    })
  }

  const [highlight, setHighlight] = useState<NodeHighlightState>({
    left: false,
    right: false,
  })

  data.onHighlightNode = (show, side) => {
    highlight[side] = show
    setHighlight({
      ...highlight,
    })
  }

  useEffect(() => {
    const handleMouseMove = (event: MouseEvent) => {
      const handleInteraction = (
        handleRef: React.RefObject<HTMLDivElement>
      ) => {
        if (handleRef.current) {
          const rect = handleRef.current.getBoundingClientRect()
          const isNear =
            event.clientX > rect.left - threshold &&
            event.clientX < rect.right + threshold &&
            event.clientY > rect.top - threshold &&
            event.clientY < rect.bottom + threshold

          if (isNear) {
            handleRef.current.style.width = '2rem'
            handleRef.current.style.height = '2rem'
            handleRef.current.style.marginLeft =
              handleRef === targetHandleRef ? '-1rem' : ''
            handleRef.current.style.marginRight =
              handleRef === sourceHandleRef ? '-1rem' : ''
          } else {
            handleRef.current.style.width = '1.2rem'
            handleRef.current.style.height = '1.2rem'
            handleRef.current.style.marginLeft =
              handleRef === targetHandleRef ? '-0.5rem' : ''
            handleRef.current.style.marginRight =
              handleRef === sourceHandleRef ? '-0.5rem' : ''
          }
        }
      }

      handleInteraction(targetHandleRef)
      handleInteraction(sourceHandleRef)
    }

    document.addEventListener('mousemove', handleMouseMove)
    return () => {
      document.removeEventListener('mousemove', handleMouseMove)
    }
  }, [])

  return (
    <>
      <div className='group/task-node'>
        <div
          style={{
            borderColor: data.style.background_color,
            background: '#FFFCEB',
          }}
          className='border-2 border-solid border-plombBlack-500 rounded-lg shadow-md w-64 h-32 relative justify-center'
        >
          <Tooltip
            className='bg-plombYellow-100'
            classNames={{ base: 'pointer-events-none' }}
            content={
              <div className='flex items-center max-w-xs'>
                <iconify-icon icon={data.style.icon} width='32' height='32' />
                <div className='px-1 py-2 ml-2'>
                  <p className='text-small font-bold'>
                    {data.task_template?.name}
                  </p>
                  <p className='text-tiny'>{data.description}</p>
                  <p className='text-tiny mt-2 italic text-right'>
                    Double-click to edit!
                  </p>
                </div>
              </div>
            }
            showArrow
            placement='bottom'
            closeDelay={0}
            offset={5}
          >
            <div
              className='flex flex-col gap-1 items-center p-2.5 h-full justify-center'
              onDoubleClick={onTaskNodeEditButtonClick}
              onMouseEnter={(e) =>
                onNodeMouseInteraction(
                  e,
                  data.task_id,
                  data.onNodeMouseInteraction,
                  setHighlight
                )
              }
              onMouseLeave={(e) =>
                onNodeMouseInteraction(
                  e,
                  data.task_id,
                  data.onNodeMouseInteraction,
                  setHighlight
                )
              }
            >
              <iconify-icon
                style={{
                  color: data.style.background_color,
                  fill: data.style.background_color,
                }}
                icon={data.style.icon}
                width='48'
                height='48'
              />
              <p
                style={{
                  color: data.style.background_color,
                }}
                className={`${textSizeClass()} font-bold font-italic text-center w-full text-ellipsis whitespace-nowrap overflow-hidden`}
              >
                {data.label}
              </p>
              <NodeHighlightIndicator
                highlight={highlight}
                background_color={data.style.background_color}
              />
              {data.task_config.type === 'model' && (
                <Chip
                  style={{
                    backgroundColor: data.style.text_color,
                    color: data.style.background_color,
                  }}
                  className='text-sm mt-1'
                  size='sm'
                  variant='flat'
                >
                  {data.task_config.model_id}
                </Chip>
              )}
            </div>
          </Tooltip>
          <div className='absolute top-[-20px] right-[-20px] group-hover/task-node:opacity-100 opacity-0 transition-opacity flex gap-2'>
            <Button
              isIconOnly
              color='primary'
              onClick={onTaskNodeEditButtonClick}
            >
              <iconify-icon icon='uil:edit' width='24' height='24' />
            </Button>
            <Popover placement='top-end' offset={5} backdrop='opaque' showArrow>
              <PopoverTrigger>
                <Button isIconOnly color='danger'>
                  <iconify-icon icon='tabler:trash' width='24' height='24' />
                </Button>
              </PopoverTrigger>
              <PopoverContent>
                <div className='flex flex-col px-1 py-2'>
                  <h3 className='text-small font-bold'>
                    Deleting task &quot;
                    {data.label}
                    &quot;
                  </h3>
                  <div className='text-tiny my-1'>
                    <p>Are you sure you want to delete this task?</p>
                    <p className='italic'>This action cannot be undone.</p>
                  </div>
                  <Button
                    style={{
                      alignSelf: 'end',
                    }}
                    color='danger'
                    onClick={onDeleteTaskButtonClick}
                  >
                    <iconify-icon icon='tabler:trash' width='24' height='24' />
                    Delete
                  </Button>
                </div>
              </PopoverContent>
            </Popover>
          </div>
        </div>
      </div>
      <Handle
        type='target'
        position={Position.Left}
        ref={targetHandleRef}
        style={{
          marginLeft: '-0.5rem',
          width: '1.2rem',
          height: '1.2rem',
          backgroundColor: '#5A1A1A',
          transition: 'width 0.2s, height 0.2s, margin 0.2s',
        }}
      />
      <Handle
        type='source'
        position={Position.Right}
        ref={sourceHandleRef}
        style={{
          marginRight: '-0.5rem',
          width: '1.2rem',
          height: '1.2rem',
          backgroundColor: '#D9318B',
          transition: 'width 0.2s, height 0.2s, margin 0.2s',
        }}
      />
    </>
  )
}
export default TaskNode
