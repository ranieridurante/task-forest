import React, { useState, useRef, useEffect } from 'react'
import { singularize } from '../../../utils'
import type { NodeProps } from 'reactflow'
import { Handle, Position } from 'reactflow'
import {
  Button,
  Popover,
  PopoverContent,
  PopoverTrigger,
  Tooltip,
} from '@nextui-org/react'
import NodeHighlightIndicator, {
  onNodeMouseInteraction,
} from './NodeHighlightIndicator'
import type { NodeHighlightState, TIteratorNodeProps } from 'types/node'

/**
 * Component that represents a node of type List Processor.
 * @constructor
 */
const IteratorNode: React.FC<NodeProps<TIteratorNodeProps>> = ({ data }) => {
  /**
   * Function responsible for removing the List Processor.
   */
  const onDeleteListProcessorButtonClick = () => {
    data.pushEventFn('react.delete_iterator', {
      iterator_id: data.id,
      workflow_id: data.workflow_id,
    })
  }

  const [highlight, setHighlight] = useState<NodeHighlightState>({
    left: false,
    right: false,
  })
  const targetHandleRef = useRef<HTMLDivElement>(null)
  const sourceHandleRef = useRef<HTMLDivElement>(null)
  const threshold = 25 // Distance in pixels

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
      <div className='group/iterator-node'>
        <div
          className='group/iterator-node border-2 border-solid border-plombPink-500 rounded-lg shadow-md w-64 h-32 relative'
          style={{
            background: '#D9318B',
          }}
        >
          <Tooltip
            className='bg-plombYellow-100'
            classNames={{ base: 'pointer-events-none' }}
            content={
              <div className='flex items-center'>
                <iconify-icon
                  icon='mdi:repeat-variant'
                  width='32'
                  height='32'
                />
                <div className='px-1 py-2'>
                  <div className='text-small font-bold'>List Processor</div>
                  <div className='text-tiny font-italic'>
                    for
                    <b>
                      {' '}
                      {data.iterable_key}
                      []
                    </b>
                  </div>
                  <div className='text-tiny'>
                    Repeats the next tasks for each{' '}
                    <span className='font-bold'>
                      {singularize(data.iterable_key)}
                    </span>
                    .
                  </div>
                </div>
              </div>
            }
            placement='bottom'
            closeDelay={0}
          >
            <div
              className='flex flex-col gap-1 items-center justify-center h-full p-2.5'
              onMouseEnter={(e) =>
                onNodeMouseInteraction(
                  e,
                  data.id,
                  data.onNodeMouseInteraction,
                  setHighlight
                )
              }
              onMouseLeave={(e) =>
                onNodeMouseInteraction(
                  e,
                  data.id,
                  data.onNodeMouseInteraction,
                  setHighlight
                )
              }
            >
              <iconify-icon
                style={{
                  color: 'white',
                  fill: 'white',
                }}
                icon='mdi:repeat-variant'
                width='64'
                height='64'
              />
              <p className='text-white text-large font-bold font-italic text-center w-full text-ellipsis whitespace-nowrap overflow-hidden'>
                {data.iterable_key}
                []
              </p>
              <NodeHighlightIndicator
                highlight={highlight}
                background_color='#221F20'
              />
            </div>
          </Tooltip>
          <div className='absolute top-[-20px] right-[-20px] group-hover/iterator-node:opacity-100 opacity-0 transition-opacity flex gap-2'>
            <Popover placement='top' offset={5} backdrop='opaque' showArrow>
              <PopoverTrigger>
                <Button isIconOnly color='danger'>
                  <iconify-icon icon='tabler:trash' width='24' height='24' />
                </Button>
              </PopoverTrigger>
              <PopoverContent>
                {(titleProps) => (
                  <div className='flex flex-col px-1 py-2'>
                    <h3 className='text-small font-bold' {...titleProps}>
                      Deleting List Processor
                    </h3>
                    <div className='text-tiny my-1'>
                      <p>
                        Are you sure you want to delete this list processor?
                      </p>
                    </div>
                    <Button
                      style={{
                        alignSelf: 'end',
                      }}
                      color='danger'
                      onPress={onDeleteListProcessorButtonClick}
                    >
                      <iconify-icon
                        icon='tabler:trash'
                        width='24'
                        height='24'
                      />
                      Delete
                    </Button>
                  </div>
                )}
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

export default IteratorNode
